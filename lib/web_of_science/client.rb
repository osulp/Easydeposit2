require 'rest_client'
require 'json'

module WebOfScience

  # A Web of Science (or Web of Knowledge) client
  # OSU subscribes to WoKSearchLite, not WoKSearchExpanded
  # See also:
  # https://clarivate.com/products/web-of-science/data-integration/
  # http://ipscience-help.thomsonreuters.com/wosWebServicesLite/WebServicesLiteOverviewGroup/Introduction.html
  # It uses the rest-client gem for REST, see 
  class Client
    API_VERSION = '3.0'.freeze # Based on USER GUIDE July 7, 2015
    SEARCH_ENDPOINT = 'https://api.clarivate.com/api/wos'.freeze

    def initialize(auth_code, log_level = Settings.WOS.LOG_LEVEL.to_sym)
      @auth_code = auth_code
      @log_level = log_level
    end

    # A client for the authorization endpoint, using WSDL
    # @return [Savon::Client]
    def headers
      {
        'X-APIKey': @auth_code,
      }
    end

    # A client for the search endpoint, using WSDL
    # @return [Savon::Client]
    def search(query)
      byebug
      results ||= RestClient.get("#{SEARCH_ENDPOINT}?#{query.to_query}", headers)
      JSON.parse(results.body)
    end
  end
end