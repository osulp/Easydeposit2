
# frozen_string_literal: true

module WebOfScience
  # Retrieve records from the Web of Science (or Web of Knowledge)
  # - expose retrieval API to fetch records in batches
  # - the "next_batch?" is like "next?"
  # - the "next_batch" is like "next"
  class Retriever
    attr_reader :records_found
    attr_reader :records_retrieved

    # @param [Symbol] operation SOAP operation like :search, :retrieve_by_id etc.
    # @param [Hash] message SOAP query message
    # @param [Integer] batch_size number of records to fetch by batch (MAX_RECORDS = 100)
    # @example
    #   WebOfScience::Retriever.new(:cited_references, message)
    def initialize(operation, message, batch_size = MAX_RECORDS)
      @batch_iteration = 0
      @batch_size = batch_size
      @query = default_params.merge(message)
      @operation = operation
      @response_type = "#{operation}_response".to_sym
    end

    def default_params
      {
        databaseId: 'WOS',
        count: MAX_RECORDS,
        firstRecord: 1,
      }
    end

    # @return [Boolean] all records retrieved?
    def records_retrieved?
      @batch_one.nil? ? false : records_retrieved == records_found
    end

    # Retrieve and merge all records
    # WARNING - this can exceed memory allocations
    # @return [WebOfScience::Records]
    def merged_records
      all_records = batch_one
      while next_batch?
        this_batch = next_batch
        all_records = all_records.merge_records(this_batch) unless this_batch.nil?
      end
      all_records
    end

    # Retrieve and collect all record UIDs
    # @return [Array<String>] WosUIDs
    def merged_uids
      uids = batch_one.uids
      uids += next_batch.uids while next_batch?
      uids
      # Get only top n uid for testing
      # uids.reverse.take(1)
    end

    # @return [Boolean] are more records available?
    def next_batch?
      @batch_one.nil? || records_retrieved < records_found
    end

    # Retrieve the next batch of records (without merging).
    # @return [WebOfScience::Records, nil]
    def next_batch
      return batch_one if @batch_one.nil?
      return if records_retrieved?
      retrieve_batch
    end

    # Reset the batch retrieval to start again (after the first batch)
    # Never discard batch_one, it belongs to the query_id
    # @return [void]
    def reset
      @batch_iteration = 0
      @records_retrieved = batch_one.count
    end

    private

    # this is the maximum number that can be returned in a single query by WoS
    MAX_RECORDS = 100

    attr_reader :batch_size
    attr_reader :operation # SOAP operations, like :search, :retrieve_by_id etc.
    attr_reader :query
    attr_reader :query_id
    attr_reader :response_type

    delegate :client, to: :WebOfScience

    # Fetch the first batch of results.  The first query-response is special; it's the only
    # response that contains the entire query response metadata, with query_id and records_found.
    # @return [WebOfScience::Records]
    def batch_one
      @batch_one ||= begin
        query = @query.merge({firstRecord: 1})
        response = client.search(query)
        records = response_records(response)
        @records_found = response['QueryResult']['RecordsFound']
        @records_retrieved = records.count
        @query_id = response['QueryResult']['QueryID']
        records
      end
    end

    # The retrieve operation is different from the first query, because it uses
    # a query_id and a :retrieve operation to retrieve additional records
    # @return [WebOfScience::Records]
    def retrieve_batch
      @batch_iteration += 1
      offset = (@batch_iteration * batch_size) + 1
      query = @query.merge({firstRecord: offset})
      response = client.search(query)
      records = response_records(response)
      @records_retrieved += records.count
      records
    end

    ###################################################################
    # WoS SOAP Response Parsers

    # @param response [Savon::Response] a WoS SOAP response
    # @param response_type [Symbol] a WoS SOAP response type
    # @return [WebOfScience::Records]
    def response_records(response)
      WebOfScience::Records.new(json: response)
    end
  end
  end
