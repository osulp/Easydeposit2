require 'identifiers'

module WebOfScience

  # Application logic to harvest publications from Web of Science;
  # This is the bridge between the WebOfScience API and the Easydeposit2 application.
  # This class is responsible for processing WebOfScience API response data
  # to integrate it into the application data models.

  class Harvester
    #include WebOfScience::Contributions

    # @param [Enumerable<Author>] authors
    # @param [Hash] options
    # @return [void]
    def harvest(authors, options = {})
      count = authors.count
      logger.info("#{self.class} - started harvest - #{count} authors")
      author_success = 0
      authors.each do |author|
        process_author(author, options)
        author_success += 1
      end
      logger.info("#{self.class} - completed harvest - #{author_success} of #{count} processed")
    rescue StandardError => err
      NotificationManager.error(err, "harvest(authors) failed - #{author_success} of #{count} processed", self)
    end

    # Harvest all publications for an author
    # @param [Author] author
    # @param [Hash] options
    # @return [Array<String>] WosUIDs that create Publications
    def process_author(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      log_info(author, 'processing')
      uids = WebOfScience::QueryAuthor.new(author, options).uids
      log_info(author, "#{uids.count} found by author query")
      uids = process_uids(author, uids)
      log_info(author, "processed #{uids.count} new publications")
      uids
    rescue StandardError => err
      NotificationManager.error(err, "#{self.class} - harvest failed for author #{author.id}", self)
    end

    # Harvest all publications for an institution
    # @param [Array<String>] institution
    # @return [Array<String>] WosUIDs that create Publications
    def process_institution(institution)
      raise(ArgumentError, 'Institution cannot be nil') if institution.nil?
      logger.info('processing')
      uids = WebOfScience::Queries.new.search_by_institution(institution).merged_uids
      logger.info("#{uids.count} found by institution query")
      uids = process_records(queries.retrieve_by_id(uids))
      logger.info("processed #{uids.count} new publications")
      uids
    rescue StandardError => err
      NotificationManager.error(err, "#{self.class} - harvest failed for institution", self)
    end

    # Harvest WOS-UID publications for an author
    # @param author [Author]
    # @param uids [Array<String>] WOS-UID values (not URIs)
    # @return [Array<String>] WosUIDs that create Publications
    def process_uids(author, uids)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'uids must be Enumerable') unless uids.is_a? Enumerable
      log_info(author, "#{uids.count} UIDs for search")
      # TODO: get all the links for the UIDs and modify contribution checks to use all identifiers
      uids -= author_contributions(author, uids)
      log_info(author, "#{uids.count} UIDs without contributions")
      return [] if uids.empty?
      process_records author, queries.retrieve_by_id(uids)
    end

    private

      delegate :logger, :queries, to: :WebOfScience

      # Consistent log prefix for status updates
      # @param author [Author]
      # @param [String] message
      # @return [void]
      def log_info(author, message)
        prefix = "#{self.class} - "
        prefix += "author #{author.id} - " if author.is_a?(Author)
        logger.info "#{prefix} - #{message}"
      end

      # Process records retrieved by any means
      # @param author [Author]
      # @param retriever [WebOfScience::Retriever]
      # @return [Array<String>] WosUIDs that create Publications
      #def process_records(author, retriever)
      #  uids = []
      #  uids += WebOfScience::ProcessRecords.new(author, retriever.next_batch).execute while retriever.next_batch?
      #  uids.flatten.compact
      #end

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