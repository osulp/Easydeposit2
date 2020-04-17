# frozen_string_literal: true

require 'csv'

namespace :easydeposit2 do
  desc 'A rake task to ingest from WoS search CSV dump will be an interim solution to get ED2 ingesting articles again.'
  task ingest_csv: :environment do
    csv_file = ENV['csv']
    process_ingest_csv(csv_file)
  end
end

def process_ingest_csv(csv_file)
  datetime_today = Time.now.strftime('%Y%m%d%H%M%S') # "20171021125903"
  logger = ActiveSupport::Logger.new("#{Rails.root}/log/process-import-csv-#{datetime_today}.log")
  logger.info "Processing ED2 ingest to works in csv: #{csv_file}"

  csv = CSV.table(csv_file, converters: nil)
  records = []
  csv.each do |row|
    records << create_record(logger, row)
  end

  # Pass Records into WebOfScience::ProcessRecords and execute
  # This calls execute and creates all the Publications and returns the UIDs.
  # Creating the Publications kicks off the FetchAuthor job which will fail and dead end. Ignore this
  uids = []
  uids += WebOfScience::ProcessRecords.new(records).execute
  uids.flatten.compact

  # find Publication by uid
  # call add_author_email and add abstract on each publication
  # call EmailArticleRecruitJob this will kick off the author emailing job
  uids.each do |uid|
    pub = Publication.find(uid: uid).first
    logger.error("Cannot find Publication of #{uid}") if pub.nil?
    (emails, abstract) = find_by_uid_csv(csv, uid)
    pub.update(abstract: abstract) unless abstract.blank?
    authors = emails.map { |e| { email: e } }
    pub.add_author_emails(authors)
    pub.recruit_authors!
    # EmailArticleRecruitJob.perform_later(publication: pub)
  end

end

# Convert WoS export in csv to SOAP XML format, and create Record with the XML
# @param row [String] row in csv
# The row is expected to be double quotes, like: "ZnCl2 ""Water-in-Salt"" Electrolyte Transforms..."
def create_record(logger, row)
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.return {
      xml.uid row[:UID]
    }
    xml.title {
      xml.label 'Title'
      xml.value row[:titles]
    } unless row[:titles].nil?
    xml.doctype {
      xml.label 'Doctype'
      xml.value row[:doctypes]
    }
    xml.source {
      xml.label 'Issue'
      xml.value row[:issues]
    }
    xml.source {
      xml.label 'Pages'
      xml.value row[:pages]
    }
    xml.source {
      xml.label 'Published.BiblioDate'
      xml.value row[:Biblio_dates]
    }
    xml.source {
      xml.label 'Published.BiblioYear'
      xml.value row[:Biblio_years]
    }
    xml.source {
      xml.label 'SourceTitle'
      xml.value row[:source_titles]
    } unless row[:source_titles].nil?
    xml.source {
      xml.label 'Volume'
      xml.value row[:volumes]
    }
    xml.authors {
      xml.label 'Authors'
      Array.wrap(row[:authors]).each do |name|
        xml.value name
      end
    } unless row[:authors].nil?
    xml.keywords {
      xml.label 'Keywords'
      Array.wrap(row[:keywords]).each do |keyword|
        xml.value keyword
      end
    } unless row[:keywords].nil?
    xml.other {
      xml.label 'Identifier.Doi'
      xml.value row[:dois]
    } unless row[:dois].nil?
    xml.other {
      xml.label 'Identifier.Issn'
      xml.value row[:issns]
    } unless row[:issns].nil?
  end
  WebOfScience::XmlParser.parse(builder.to_xml, nil)
end

# find emails and abstract from csv for a publication by uid
# @param csv [CSV table] uid [String]
# return emails [Array] abstract [String]
def find_by_uid_csv(csv, uid)
  emails = []
  csv.each do |row|
    if row[:UID].casecmp(uid).zero?
      if row[:author_emails].include? ";"
        emails = row[:author_emails].split(';').flatten
      else
        emails << row[:author_emails]
      end
      abstract = row[:abstract] unless row[:abstract].blank?
    end
  end
  return emails, abstract
end