# frozen_string_literal: true

require 'mechanize'
require 'uri'

module WebOfScience
  # This class complements the WebOfScience::Harvester and
  # Process records retrieved by any means
  class ProcessRecords
    # @param records [WebOfScience::Records]
    def initialize(records)
      raise(ArgumentError, 'records must be an WebOfScience::Records') unless records.is_a? WebOfScience::Records
      raise 'Nothing to do when Settings.WOS.ACCEPTED_DBS is empty' if Settings.WOS.ACCEPTED_DBS.empty?
      @records = records.select { |rec| Settings.WOS.ACCEPTED_DBS.include? rec.database }
    end

    # TODO: Add call of methods to send recruiting emails for deposit (after publication is created)
    # @return [Array<String>] WosUIDs that create a new Publication
    def execute
      return [] if records.empty?
      create_publications
    rescue StandardError => err
      NotificationManager.error(err, 'ProcessRecords failed', self)
      []
    end

    private

    attr_reader :records

    delegate :links_client, to: :WebOfScience

    # from the incoming (db-filtered) records
    # map(&:uids) is like calling record.uid and returns uids
    def uids
      @uids ||= records.map(&:uid)
    end

    # @return [Array<String>] WosUIDs that successfully create a new Publication
    def create_publications
      return [] if records.empty?
      # save records to WebOfScienceSourceRecord
      wssrs = save_wos_records
      wssrs_hash = wssrs.map(&:uid).zip(wssrs).to_h
      new_uids = []
      records.each do |rec|
        pub = matching_publication(rec)
        wssr = wssrs_hash[rec.uid]
        if pub
          # if a publication already exists for the same uid, update tables in ED2 to link wssr and publication
          wssr.link_publication(pub) if wssr.publication.blank?
        else
          # else create publication
          create_publication(rec, wssr) && new_uids << rec.uid
        end
      end
      new_uids.uniq
     end

    # Save new WebOfScienceSourceRecords.  This method guarantees to all subsequent processing
    # that each WOS uid in @records now has a WebOfScienceSourceRecord.
    # @param [Array<WebOfScience::Record>] recs
    # @return [Array<WebOfScienceSourceRecord>] created records
    def save_wos_records
      return if records.empty?
      already_fetched_recs = WebOfScienceSourceRecord.where(uid: uids)
      already_fetched_uids = already_fetched_recs.pluck(:uid)
      unmatched_recs = records.reject { |rec| already_fetched_uids.include? rec.uid }
      process_links(unmatched_recs)
      batch = unmatched_recs.map do |rec|
        attribs = { source_data: rec.to_xml }
        attribs[:doi] = rec.doi if rec.doi.present?
        attribs[:pmid] = rec.pmid if rec.pmid.present?
        attribs[:authoremails], attribs[:contactnames] = get_author_emails(rec)
        attribs
      end
      already_fetched_recs + WebOfScienceSourceRecord.create!(batch)
    end

    # @param [WebOfScience::Record] record
    # @param [WebOfScienceSourceRecord] WebOfScienceSourceRecord
    # @return [Boolean] WebOfScience::Record created a new Publication?
    def create_publication(record, wssr)
      Publication.create!( # autosaves contrib
        active: true,
        pub_hash: record.pub_hash,
        wos_uid: record.uid,
        pubhash_needs_update: true
      ) do |pub|
        pub.web_of_science_source_record = wssr if wssr.publication.blank?
      end
    end

    # WOS Links API methods
    # Integrate a batch of publication identifiers from the Links-API
    #
    # IMPORTANT: add nothing to PublicationIdentifiers here, or new_records will reject them
    # Note: the WebOfScienceSourceRecord is already saved, it could be updated with
    #       additional identifiers if there are fields defined for it.  Otherwise, these
    #       identifiers will get added to PublicationIdentifier after a Publication is created.
    # @param [Array<WebOfScience::Record>] recs
    # @return [void]
    def process_links(recs)
      links = retrieve_links(recs)
      return [] if links.blank?
      recs.each { |rec| rec.identifiers.update(links[rec.uid]) if rec.database == 'WOS' }
    rescue StandardError => err
      NotificationManager.error(err, 'process_links failed', self)
    end

    # Retrieve a batch of publication identifiers for WOS records from the Links-API
    # @example {"WOS:000288663100014"=>{"pmid"=>"21253920", "doi"=>"10.1007/s12630-011-9462-1"}}
    # @return [Hash<String => Hash<String => String>>]
    def retrieve_links(recs)
      link_uids = recs.map { |rec| rec.uid if rec.database == 'WOS' }.compact
      return {} if link_uids.blank?
      links_client.links(link_uids)
    rescue StandardError => err
      NotificationManager.error(err, 'retrieve_links failed', self)
    end

    # Does record have a contribution for this author? (based on matching PublicationIdentifiers)
    # Note: must use unique identifiers, don't use ISSN or similar series level identifiers
    # OSU uses only WosUID for searches
    # @param [WebOfScience::Record] record
    # @return [::Publication, nil] a matched Publication for WoS record
    def matching_publication(record)
      Publication.joins(:publication_identifiers).where(
        "publication_identifiers.identifier_value IS NOT NULL AND (
         (publication_identifiers.identifier_type = 'WosUID' AND publication_identifiers.identifier_value = ?))",
        record.uid
      ).first
    end

    # Parse reprint author emails and reprint author names from Web of Science Full Record:
    # https://images.webofknowledge.com/images/help/WOS/hp_full_record.html
    # @param: [WebOfScience::Record] record
    # @returns [Array<String>, Array<String>] reprint author emails, reprint author names
    def get_author_emails(rec)
      wos_uid = rec.uid if rec.uid.present?
      links_client = Clarivate::LinksClient.new
      links = links_client.links(wos_uid, fields: ['sourceURL'])
      agent = Mechanize.new
      page = agent.get(links[wos_uid]['sourceURL'])
      author_emails = []
      # <span class="FR_label">E-mail Addresses:</span><a href="mailto:zhenxing.feng@oregonstate.edu">zhenxing.feng@oregonstate.edu</a>; <a href="mailto:huangyq@mail.buct.edu.cn">huangyq@mail.buct.edu.cn</a>
      page.link_with(href: %r{^mailto:}).map do |link|
        author_emails.push(link.text.gsub(/^mailto:/, ''))
      end
      contact_names = []
      # <span class="FR_label">Reprint Address: </span>Huang, YQ (reprint author)
      pages.search(".FR_label").at("span:contains('Reprint Address')").map do |s|
        contact_names.push(s.text.gsub(/\ \(reprint author\)\ $/), '')
      end
      return author_emails, contact_names
    rescue StandardError => err
      NotificationManager.error(err, "#{self.class} - get author emails failed for uid #{rec.uid}", self)
    end
  end
end
