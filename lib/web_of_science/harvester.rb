require 'identifiers'

module WebOfScience

  # Application logic to harvest publications from Web of Science;
  # This is the bridge between the WebOfScience API and the Easydeposit2 application.
  # This class is responsible for processing WebOfScience API response data
  # to integrate it into the application data models.

  class Harvester
    # Harvest all publications for an institution
    # @param [Array<String>] institution
    # @return [Array<String>] WosUIDs that create Publications
    def process_institution(institution)
      raise(ArgumentError, 'Institution cannot be nil') if institution.nil?
      logger.info('processing')
      uids = WebOfScience::Queries.new.search_by_institution(institution).merged_uids
      logger.info("#{uids.count} found by institution query")
      uids = process_records(queries.retrieve_by_id(uids))
      logger.info("processed #{uids.count} publications")
      uids
    rescue StandardError => err
      NotificationManager.error(err, "#{self.class} - harvest failed for institution", self)
    end

    private

      delegate :logger, :queries, to: :WebOfScience

      # Process records retrieved by any means
      # @param retriever [WebOfScience::Retriever]
      # @return [Array<String>] WosUIDs that create Publications
      def process_records(retriever)
        uids = []
        uids += WebOfScience::ProcessRecords.new(retriever.next_batch).execute while retriever.next_batch?
        uids.flatten.compact
      end
  end
end
