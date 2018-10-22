# frozen_string_literal: true

require 'faraday'
require 'json'

module OsuApi
  OSU_API_URL = 'OSU_API_URL'
  OSU_API_OAUTH2_TOKEN = 'OSU_API_OAUTH2_TOKEN'
  OSU_API_DIRECTORY_SEARCH = 'OSU_API_DIRECTORY_SEARCH'
  OSU_API_CONSUMER_KEY = 'OSU_API_CONSUMER_KEY'
  OSU_API_CONSUMER_SECRET = 'OSU_API_CONSUMER_SECRET'

  ##
  # OSU API Client for querying Person Directory
  class Client
    def initialize
      @key = ENV.fetch(OSU_API_CONSUMER_KEY)
      @secret = ENV.fetch(OSU_API_CONSUMER_SECRET)
      @url = ENV.fetch(OSU_API_URL)
    end

    def directory_query(name)
      url = "#{ENV.fetch(OSU_API_DIRECTORY_SEARCH)}?q=#{CGI.escape(name)}"
      logger.debug("OsuApi::Client directory query : #{url}")
      json = get(url)
      people = json['data']&.map { |p| Person.new(p['attributes']) } || []
      people.count == 1 ? people : []
    rescue Faraday::ClientError => ce
      if ce.response[:status] == 400
        logger.debug("OsuApi::Client directory query found too many matches, unable to return a meaningful list of results : #{ce.response[:body]}")
        return []
      end
    end

    private

    # A default logger - a subclass can override the default
    # @return [Logger]
    def logger
      @logger ||= Rails.logger
    end

    # :nocov:
    def connection
      @connection ||= Faraday.new(url: @url) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.adapter Faraday.default_adapter
      end
    end

    def url_encoded_connection
      @url_encoded_connection ||= Faraday.new(url: @url) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    ##
    # Fetch an OAuth2 token and cache it
    # since the API sets these keys to be valid for 24hr.
    def token
      @token ||= Rails.cache.fetch('osu_api_token', expires_in: 23.hours) do
        logger.debug("Fetching new OAuth2 Token from OSU API : #{@url}")
        json = post(url_encoded_connection,
                    ENV.fetch(OSU_API_OAUTH2_TOKEN),
                    client_id: @key,
                    client_secret: @secret,
                    grant_type: 'client_credentials')
        json['access_token']
      end
    end

    def get(url)
      response = connection.get url, {}, headers
      raise response.reason_phrase unless response.success?
      logger.debug("OSU API GET Response.body: #{response.body}")
      JSON.parse(response.body)
    end

    def post(connection, url, data)
      response = connection.post(url, data)
      JSON.parse(response.body)
    end

    def headers(content_type = '')
      headers = { 'Authorization' => "Bearer #{token}" }
      headers['Content-Type'] = content_type unless content_type.blank?
      headers
    end
    # :nocov:
  end
end
