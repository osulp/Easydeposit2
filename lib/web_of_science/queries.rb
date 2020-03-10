module WebOfScience

    # Queries on the Web of Science (or Web of Knowledge)
    class Queries
  
      # this is the _only_ value allowed by the WOS-API
      QUERY_LANGUAGE = 'en'.freeze
  
      attr_reader :database
  
      # @param database [String] a WOS database identifier (default 'WOK')
      def initialize(database = 'WOS')
        @database = database
      end
  
      # @param uids [Array<String>] a list of WOS UIDs
      # @return [WebOfScience::Retriever]
      def retrieve_by_id(uids)
        raise(ArgumentError, 'uids must be an Enumerable of WOS-UID String') if uids.blank? || !uids.is_a?(Enumerable)
        uid_query = uids.map { |uid| "UT=#{uid}" }.join(' OR ')
        user_query(uid_query)
      end

      # @param institutions [Array<String>] a set of institutions
      # Use options to limit the symbolic time span for harvesting publications; this limit applies
      # to the dates publications are added or updated in WOS collections, not publication dates.
      # If symbolicTimeSpan is specified, the timeSpan parameter must be omitted.
      # @return [WebOfScience::Retriever]
      def search_by_institution(institutions = [])
        raise(ArgumentError, 'must enter an institution name') if institutions.empty?
        inst_query = institutions.map { |inst| "OG=#{inst}" }.join(' OR ')
        user_query(inst_query)
      end
  
      # @param message [Hash] search params (see WebOfScience::Queries#params_for_search)
      # @return [WebOfScience::Retriever]
      def search(message)
        WebOfScience::Retriever.new(:search, message)
      end
  
      # Convenience method, does the params_for_search expansion
      # @param message [Hash] Query string like 'TS=particle swarm AND PY=(2007 OR 2008)'
      # @return [WebOfScience::Retriever]
      def user_query(message)
        search(params_for_search(message))
      end
  
      # @param user_query [String] (defaults to '')
      # @return [Hash] search query parameters for full records
      def params_for_search(user_query = '')
        {
          databaseId: database,
          usrQuery: "(#{user_query}) AND DT=Article",
          loadTimeSpan: '4W',
        }
      end
    end
  end