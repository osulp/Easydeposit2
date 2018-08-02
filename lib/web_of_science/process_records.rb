# frozen_string_literal: true

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

    # @return [Array<String>] WosUIDs that create a new SA@OSU Publication
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

    # TODO
    # Add the workflow to deposit the publication into SA@OSU (after publication is created)
    # ----------------------------------------------------------------
    # @return [Array<String>] WosUIDs that successfully create a new Publication
    def create_publications
      return [] if records.empty?
      # save records to WebOfScienceSourceRecord
      wssrs = save_wos_records
      wssrs_hash = wssrs.map(&:uid).zip(wssrs).to_h
      new_uids = []
      records.each do |rec|
        pub = Publication.by_wos_uid(rec.uid).first
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
      # unnecessary?
      #process_links(unmatched_recs)
      batch = unmatched_recs.map do |rec|
        attribs = { source_data: rec.to_xml }
        attribs[:doi] = rec.doi if rec.doi.present?
        attribs[:pmid] = rec.pmid if rec.pmid.present?
        attribs
      end
      already_fetched_recs + WebOfScienceSourceRecord.create!(batch)
    end

    # @param [WebOfScience::Record] record
    # @param [WebOfScienceSourceRecord] WebOfScienceSourceRecord
    # @return [Boolean] WebOfScience::Record created a new Publication?
    def create_publication(record, wssr)
      publication = Publication.create!( # autosaves contrib
        active: true,
        pub_hash: record.pub_hash,
      ) do |pub|
        pub.web_of_science_source_record = wssr if wssr.publication.blank?
      end
      Event.create(Event::HARVESTED_NEW.merge({
        message: record.uid,
        publication: publication
      }))
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
    #def process_links(recs)
    #  links = retrieve_links(recs)
    #  return [] if links.blank?
    #  recs.each { |rec| rec.identifiers.update(links[rec.uid]) if rec.database == 'WOS' }
    #rescue StandardError => err
    #  NotificationManager.error(err, 'process_links failed', self)
    #end

    # Retrieve a batch of publication identifiers for WOS records from the Links-API
    # @example {"WOS:000288663100014"=>{"pmid"=>"21253920", "doi"=>"10.1007/s12630-011-9462-1"}}
    # @return [Hash<String => Hash<String => String>>]
    #def retrieve_links(recs)
    #  link_uids = recs.map { |rec| rec.uid if rec.database == 'WOS' }.compact
    #  return {} if link_uids.blank?
    #  links_client.links(link_uids)
    #rescue StandardError => err
    #  NotificationManager.error(err, 'retrieve_links failed', self)
    #end
  end
end
