# frozen_string_literal: true

require 'faraday'
require 'json'

module Repository
  REPOSITORY_ADMIN_SET_URL = 'REPOSITORY_ADMIN_SET_URL'
  REPOSITORY_AUTHENTICATION_TOKEN = 'REPOSITORY_AUTHENTICATION_TOKEN'
  REPOSITORY_AUTHENTICATION_USERNAME = 'REPOSITORY_AUTHENTICATION_USERNAME'
  REPOSITORY_SEARCH_URL = 'REPOSITORY_SEARCH_URL'
  REPOSITORY_UPLOAD_URL = 'REPOSITORY_UPLOAD_URL'
  REPOSITORY_URL = 'REPOSITORY_URL'
  REPOSITORY_WORKFLOW_URL = 'REPOSITORY_WORKFLOW_URL'
  HTTP_AUTH_HEADER = 'API-AUTHENTICATION'

  ##
  # The Repository client for interfacing with the repository API
  class Client
    attr_reader :url, :username, :token

    def initialize
      @token = ENV.fetch(REPOSITORY_AUTHENTICATION_TOKEN)
      @url = ENV.fetch(REPOSITORY_URL)
      @username = ENV.fetch(REPOSITORY_AUTHENTICATION_USERNAME)
    end

    ##
    # Publish the work to the provided worktype related url.
    # @param work [Hash] the work and data to be published
    # @param publish_url [String] the appropriate url to create a new work of a particular worktype
    # @return [Hash<String, String>] the HTTP response and the newly created work with all of its data
    def publish(work, publish_url)
      response = post(work, publish_url)
      { response: response, work: JSON.parse(response.body) }
    end

    ##
    # Upload a file to the server. Ingesting a new work into a Hyrax server expects
    # that the ID of the uploaded file(s) is included when publishing a work. The typical
    # process would be to upload a number of files first, then publish the work including
    # the file ID's to be attached to the work.
    # @param path [String] the full path to the file to be uploaded
    # @param content [String] the http Content-Type of the file being uploaded
    # @return [Hash] an array of files that were uploaded
    # ie. files: [{id: 1, name: 'test', size: '12345', deleteUrl: '/uploads/6', deleteType: 'DELETE' }]
    def upload_file(path, content_type)
      url = ENV.fetch(REPOSITORY_UPLOAD_URL)
      data = {
        files: [
          Faraday::UploadIO.new(path, content_type)
        ]
      }
      response = post_file(data, url)
      JSON.parse(response.body)
    end

    ##
    # Set the workflow to a provided action and with a comment
    # @param work [Hash] the work to be advanced in a workflow
    # @param workflow_action_name [String] the name of the workflow action to advance to
    # @param comment [String] a comment to post along with the action advancement
    # @return [Boolean] true if the update finished, the hyrax server issues an HTTP redirect on successful updates
    def set_workflow(work, workflow_action_name, comment)
      url = ENV.fetch(REPOSITORY_WORKFLOW_URL).gsub('{work_id}', work['id'])
      workflow_action = {
        workflow_action:  {
          name: workflow_action_name,
          comment: comment
        }
      }
      put(workflow_action, url)
    end

    ##
    # Fetch a list of all of the admin sets from the server
    # @return [Hash] a hash with an array of admin sets from the server
    # ie. admin_sets:[{id:'admin_set/default', title:['Default Admin Set'], description:null}, ...]
    def fetch_all_admin_sets
      response = get(ENV.fetch(REPOSITORY_ADMIN_SET_URL))
      JSON.parse(response.body)
    end

    def admin_sets
      @admin_sets ||= fetch_all_admin_sets
    end

    ##
    # Search repository for field=value to determine if a work has already been published.
    # example: "web_of_science_uid", "WOS:8675309"
    # @param property [String] - the property name to search
    # @param value [String] - the property value to search
    # @return [Array<SolrDocument>] - an array of Solr document search results
    def search(property, value)
      url = ENV.fetch(REPOSITORY_SEARCH_URL).gsub('{property}', property).gsub('{value}', value)
      response = get(url)
      json = JSON.parse(response.body)
      docs = json['response']['docs']
      logger.debug "#{url} query returned #{docs.count} result(s)"
      docs
    end

    private

    # :nocov:
    def connection
      @connection ||= Faraday.new(url: @url) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.response :logger do |l|
          l.filter(/(#{HTTP_AUTH_HEADER}:) (.+)/, '\1[FILTERED]')
        end
        faraday.adapter Faraday.default_adapter
      end
    end

    def multipart_connection
      Faraday.new(url: @url) do |f|
        f.use Faraday::Response::RaiseError
        f.request :multipart
        f.request :url_encoded
        f.response :logger do |l|
          l.filter(/(#{HTTP_AUTH_HEADER}:) (.+)/, '\1[FILTERED]')
        end
        f.adapter :net_http
      end
    end
    # :nocov:

    # A default logger - a subclass can override the default
    # @return [Logger]
    def logger
      @logger ||= Rails.logger
    end

    def post_file(data, url)
      response = multipart_connection.post url, data, headers
      raise response.reason_phrase unless response.success?
      logger.debug("Repository::Client Response.body: #{response.body}")
      response
    end

    def post(data, url)
      response = connection.post url, JSON.dump(data), headers('application/json')
      raise response.reason_phrase unless response.success?
      logger.debug("Repository::Client Response.body: #{response.body}")
      response
    end

    def put(data, url)
      response = connection.put url, JSON.dump(data), headers('application/json')
      logger.debug("Repository::Client Response.body: #{response.body}")
      response.finished?
    end

    def get(url)
      response = connection.get url, {}, headers('application/json')
      raise response.reason_phrase unless response.success?
      logger.debug("Repository::Client Response.body: #{response.body}")
      response
    end

    def headers(content_type = '')
      headers = { HTTP_AUTH_HEADER.to_s => "#{@username}|#{@token}" }
      headers['Content-Type'] = content_type unless content_type.blank?
      headers
    end
  end
end
