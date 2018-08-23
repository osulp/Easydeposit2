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
      @web_of_science_uid = args[:web_of_science_uid]
    end

    def publish
      raise "Cannot publish, missing file(s) for upload: #{missing_files.map { |f| f[:path] }}" unless missing_files.blank?
      file_ids = uploaded_file_ids
      response = client_publish(repository_data(file_ids), publish_url)
      client_set_workflow(response[:work], 'Approve', 'Published by ED2') if workflow_required?
      response
    end

    private

    def workflow_required?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('REPOSITORY_PUBLISH_REQUIRES_WORKFLOW_APPROVAL', 'true'))
    end

    def repository_data(file_ids)
      {
        @work_type.to_s => {
          admin_set_id: @admin_set_id,
          contributor: @data['researcher_names'],
          date_issued: "#{@data['biblio_dates'].first} #{@data['biblio_years'].first}",
          doi: @data['dois'],
          isbn: @data['isbns'],
          issn: @data['issns'],
          journal_title: @data['source_titles'].first,
          journal_volume: @data['volumes'].first,
          license: ENV.fetch('REPOSITORY_PUBLISH_LICENSE', 'http://creativecommons.org/licenses/by/4.0/'),
          nested_ordered_creator_attributes: @data['authors'].map.with_index { |a, i| { creator: a, index: i } },
          resource_type: [ENV.fetch('REPOSITORY_PUBLISH_RESOURCE_TYPE', 'Article')],
          rights_statement: ENV.fetch('REPOSITORY_PUBLISH_RIGHTS_STATEMENT', 'http://rightsstatements.org/vocab/InC/1.0/'),
          title: @data['titles'],
          web_of_science_uid: @web_of_science_uid
        },
        uploaded_files: file_ids,
        agreement: 1
      }
    end

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
