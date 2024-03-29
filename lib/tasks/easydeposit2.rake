# frozen_string_literal: true

require 'csv'

namespace :easydeposit2 do
  desc 'A rake task to ingest from WoS search CSV dump will be an interim solution to get ED2 ingesting articles again. call like rake easydeposit2:ingest_csv["/path/to/file"]'
  task :ingest_csv, [:path] => [:environment] do |_t, args|
    csv_file = args[:path]
    raise(ArgumentError, 'Path cannot be nil') if args[:path].nil?

    process_ingest_csv(csv_file)
  end
end

def process_ingest_csv(path)
  datetime_today = Time.now.strftime('%Y%m%d%H%M%S') # "20171021125903"
  logger = ActiveSupport::Logger.new("#{Rails.root}/log/process-import-csv-#{datetime_today}.log")
  logger.info "Processing ED2 ingest to works in csv: #{path}"
  csv = CSV.table(path, converters: nil)
  docs = create_records(csv)
  logger.info("Create Records with UIDs of: #{docs.uids.inspect}")

  # Pass Records into WebOfScience::ProcessRecords and execute
  # This calls execute and creates all the Publications and returns the UIDs.
  # Creating the Publications kicks off the FetchAuthor jobs which will fail, need to mark them complete to move forward
  uids = []
  # ProcessRecords execute will create publications that are article type and new to database
  uids += WebOfScience::ProcessRecords.new(docs).execute
  uids.flatten.compact

  # find Publication by uid
  # call add_author_email and add abstract on each publication
  # call event update
  # call EmailArticleRecruitJob this will kick off the author emailing job
  uids.each do |uid|
    logger.info("Start email processing for publication with UID: #{uid}")
    pub = Publication.by_wos_uid(uid).first
    logger.error("Cannot find Publication of #{uid}") if pub.nil?
    (emails, abstract) = find_by_uid_csv(csv, uid)
    update_pub_event(pub)
    pub.update(abstract: abstract) unless abstract.blank?
    authors = emails.map { |e| { email: e } }
    pub.add_author_emails(authors)
    pub.recruit_authors!
  end
end

# Convert WoS export in csv to SOAP XML format, and create Records with the XML
# @param csv table
# The row is expected to be double quotes, like: "ZnCl2 ""Water-in-Salt"" Electrolyte Transforms..."
def create_records(csv)
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.return do
      csv.each do |row|
        xml.records do
          xml.uid row[:ut]
          xml.title do
            xml.label 'Title'
            xml.value row[:ti]
          end unless row[:ti].nil?
          xml.doctype do
            xml.label 'Doctype'
            xml.value row[:dt]
          end
          xml.source do
            xml.label 'Issue'
            xml.value row[:is]
          end
          xml.source do
            xml.label 'Pages'
            xml.value row[:pg]
          end
          xml.source do
            xml.label 'Published.BiblioDate'
            xml.value row[:pd]
          end
          xml.source do
            xml.label 'Published.BiblioYear'
            xml.value row[:py]
          end
          xml.source do
            xml.label 'Source.Title'
            xml.value row[:so]
          end unless row[:so].nil?
          xml.source do
            xml.label 'Conference.Title'
            xml.value row[:ct]
          end unless row[:ct].nil?
          xml.source do
            xml.label 'Conference.Location'
            xml.value row[:cl]
          end unless row[:cl].nil?
          xml.source do
            xml.label 'Funding.Text'
            xml.value row[:fx]
          end unless row[:fx].nil?
          xml.source do
            xml.label 'Volume'
            xml.value row[:vl]
          end
          xml.authors do
            xml.label 'Authors'
            Array.wrap(row[:af].split('; ')).each do |name|
              xml.value name
            end
            Array.wrap(row[:ca].split('; ')).each do |name|
              xml.value name
            end
          end unless row[:af].nil? && row[:ca].nil?
          xml.source do
            xml.label 'Publisher'
            xml.value row[:pu]
          end
          xml.editors do
              xml.label 'Editors'
              Array.wrap(row[:be].split('; ')).each do |name|
                xml.value name
              end
          end unless row[:be].nil?
          xml.keywords do
            xml.label 'Keywords'
            Array.wrap(row[:de].split('; ')).each do |keyword|
              xml.value keyword
            end
          end unless row[:de].nil?
          xml.languages do
            xml.label 'Languages'
            lang = "http://id.loc.gov/vocabulary/iso639-2/#{ISO_639.find_by_english_name(row[:la]).first}"
            xml.value lang
          end
          xml.other do
            xml.label 'Identifier.Doi'
            xml.value row[:di]
          end unless row[:di].nil?
          xml.other do
            xml.label 'Identifier.Doi'
            xml.value row[:d2]
          end unless row[:d2].nil?
          xml.other do
            xml.label 'Identifier.Issn'
            xml.value row[:sn]
          end unless row[:sn].nil?
          xml.other do
            xml.label 'Identifier.Issn'
            xml.value row[:ei]
          end unless row[:ei].nil?
          xml.other do
            xml.label 'Identifier.Isbn'
            xml.value row[:bn]
          end unless row[:bn].nil?
        end
      end
    end
  end
  # Need to call Record.new explicitly as inputs for ProcessRecords
  WebOfScience::Records.new(records: builder.to_xml)
end

# find emails and abstract from csv for a publication by uid
# @param csv [CSV table] uid [String]
# return emails [Array] abstract [String]
def find_by_uid_csv(csv, uid)
  emails = []
  abstract = ''
  csv.each do |row|
    next unless row[:ut].casecmp(uid).zero?

    if row[:em].include? ';'
      emails = row[:em].split(';').flatten
    else
      emails << row[:em]
    end
    abstract = row[:ab] unless row[:ab].blank?
    return emails, abstract
  end
  # return empty data when no match is found
  [[], '']
end

# update two fetch author events as complete for the passing publication as required to run recruit_author job
def update_pub_event(pub)
  event = Event.create(Event::FETCH_AUTHORS_DIRECTORY_API)

  event.update(
    publication: pub,
    message: "Initializing stubbed event for CSV ingest at #{Time.now}",
    restartable: false,
    status: Event::STARTED[:name]
  )
  event.completed(message: "Completing stubbed event for CSV ingest at #{Time.now}", restartable: false)

  event = Event.create(Event::FETCH_WOS_CONTENT)

  event.update(
    publication: pub,
    message: "Initializing stubbed event for CSV ingest at #{Time.now}",
    restartable: false,
    status: Event::STARTED[:name]
  )
  event.completed(message: "Completing stubbed event for CSV ingest at #{Time.now}", restartable: false)
end
