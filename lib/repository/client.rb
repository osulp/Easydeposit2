require 'faraday'
require 'json'

module Repository
  REPOSITORY_ADMIN_SET_URL='REPOSITORY_ADMIN_SET_URL'.freeze
  REPOSITORY_AUTHENTICATION_TOKEN='REPOSITORY_AUTHENTICATION_TOKEN'.freeze
  REPOSITORY_AUTHENTICATION_USERNAME='REPOSITORY_AUTHENTICATION_USERNAME'.freeze
  REPOSITORY_UPLOAD_URL='REPOSITORY_UPLOAD_URL'.freeze
  REPOSITORY_URL='REPOSITORY_URL'.freeze
  REPOSITORY_WORKFLOW_URL='REPOSITORY_WORKFLOW_URL'.freeze
  HTTP_AUTH_HEADER='ED2_AUTHENTICATION'.freeze

  attr_reader :url, :username, :token
  class Client
    def initialize
      @token = ENV.fetch(REPOSITORY_AUTHENTICATION_TOKEN)
      @url = ENV.fetch(REPOSITORY_URL)
      @username = ENV.fetch(REPOSITORY_AUTHENTICATION_USERNAME)
    end

    ##
    # Publish the work to the provided worktype related url.
    # @param work [Hash] the work and data to be published
    # @param publish_url [String] the appropriate url to create a new work of a particular worktype
    # @return [Hash] the newly created work with all of its data
    def publish(work, publish_url)
      response = post(work, publish_url)
      JSON.parse(response.body)
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
      url = ENV.fetch(REPOSITORY_WORKFLOW_URL).gsub("{work_id}", work['id'])
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

    ##
    # Check the state of the provided work to see if it is active or not. An inactive work is likely to be on a
    # workflow and could be advanced to the approved state.
    # @param work [Hash] a fully populated work, typically provided by the server after publishing
    # @return [Boolean] true if the work.state.id indicates it is active
    def active_work?(work)
      work['state']['id'].end_with?('ObjState#active')
    end

    def admin_sets
      @admin_sets ||= fetch_all_admin_sets
    end

    private
      def connection
        @connection ||= Faraday.new(url: @url) do |faraday|
          faraday.use Faraday::Response::RaiseError
          faraday.response :logger do |l|
            l.filter(/(#{HTTP_AUTH_HEADER}:) (.+)/, '\1[FILTERED]')
          end
          faraday.adapter Faraday.default_adapter
        end
      end

      # A default logger - a subclass can override the default
      # @return [Logger]
      def logger
        @logger ||= Rails.logger
      end

      def post_file(data, url)
        faraday = Faraday.new(url: @url) do |f|
          f.use Faraday::Response::RaiseError
          f.request :multipart
          f.request :url_encoded
          f.response :logger do |l|
            l.filter(/(#{HTTP_AUTH_HEADER}:) (.+)/, '\1[FILTERED]')
          end
          f.adapter :net_http
        end
        response = faraday.post url, data, headers()

        raise response.reason_phrase unless response.success?
        logger.debug("response.body: #{response.body}")
        response
      end

      def post(data, url)
        response = connection.post url, JSON.dump(data), headers('application/json')
        raise response.reason_phrase unless response.success?
        logger.debug("response.body: #{response.body}")
        response
      end

      def put(data, url)
        response = connection.put url, JSON.dump(data), headers('application/json')
        logger.debug("response.body: #{response.body}")
        response.finished?
      end

      def get(url)
        response = connection.get url, {}, headers('application/json')
        raise response.reason_phrase unless response.success?
        logger.debug("response.body: #{response.body}")
        response
      end

      def headers(content_type = '')
        headers = { "#{HTTP_AUTH_HEADER}" => "#{@username}|#{@token}" }
        headers['Content-Type'] = content_type unless content_type.blank?
        headers
      end
  end
end
