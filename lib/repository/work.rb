# frozen_string_literal: true

module Repository
  ##
  # Repository work model
  class Work
    attr_reader :client

    ##
    # Initialize a work model for file upload and publishing
    # @param args [Hash] - a hash of work params as follows
    #   client: [Repository::Client] - the repository API client
    #   data: [Hash] - properties for the work to be published
    #   files: [Array<Hash>] - array of files to be uploaded shaped as {path: [String], content_type: [String]}
    #   work_type: [String] - the work type to be published, matches the model name in the repository (ie. article)
    #   admin_set_title: [String] - the admin set the work will be published to, matches a name of an admin set in the repository
    def initialize(args)
      validate!(args)
      @client = args[:client]
      @data = args[:data]
      @files = args[:files]
      @work_type = args[:work_type]
      @admin_set_id = admin_set_id(args[:admin_set_title])
    end

    def publish
      raise "Cannot publish, missing file(s) for upload: #{missing_files.map { |f| f[:path] }}" unless missing_files.blank?
      work = client_publish(work_payload, publish_url)
      advanced = client_set_workflow(work, 'Approve', 'Published by ED2')
      advanced
    end

    private

    def client_publish(work_payload, publish_url)
      @client.publish(work_payload, publish_url)
    end

    def client_set_workflow(work, action, comment)
      @client.set_workflow(work, action, comment)
    end

    def validate!(args)
      raise 'Missing client' unless args[:client]
      raise 'Missing data' unless args[:data]
      raise 'Missing files' unless args[:files]
      raise 'Missing work_type' unless args[:work_type]
      raise 'Missing admin_set_title' unless args[:admin_set_title]
    end

    def work_payload
      @data['admin_set_id'] = @admin_set_id
      {
        @work_type.to_s => @data,
        uploaded_files: uploaded_file_ids,
        agreement: 1
      }
    end

    def admin_set_id(title)
      @client.admin_sets['admin_sets'].select { |a| a['title'].any? { |t| t.casecmp(title).zero? } }.first['id']
    end

    def missing_files
      @missing_files ||= @files.reject { |f| File.file?(f[:path]) }
    end

    ##
    # Upload each of the associated files, fetching the resulting
    # id returned from the server. These will be associated with the
    # work as it is published to the repository.
    # @return [Array<Integer>] - the uploaded file id's created on the server
    def uploaded_file_ids
      file_ids = []
      @files.each do |f|
        response = @client.upload_file(f[:path], f[:content_type])
        file_ids << response['files'][0]['id']
      end
      file_ids
    end

    def publish_url
      "/concern/#{@work_type.pluralize}.json"
    end
  end
end
