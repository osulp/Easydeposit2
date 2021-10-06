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
      @abstract = args[:abstract]
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
          conference_name: @data['conference_titles'].first,
          conference_location: @data['conference_locations'].first,
          date_issued: formalize_date("#{@data['biblio_dates'].first} #{@data['biblio_years'].first}"),
          doi: "https://doi.org/#{@data['dois'].first}",
          editor: @data['editors'],
          file_extent: @data['pages'].map { |p| "#{p} pages" },
          funding_statement: @data['funding_text'],
          isbn: @data['isbns'],
          issn: @data['issns'],
          has_journal: @data['source_titles'].first.titleize,
          has_volume: @data['volumes'].first,
          language: @data['languages'],
          license: ENV.fetch('REPOSITORY_PUBLISH_LICENSE', 'http://creativecommons.org/licenses/by/4.0/'),
          nested_ordered_abstract_attributes: create_nested_attribute([@abstract], 'abstract'),
          nested_ordered_contributor_attributes: create_nested_attribute(@data['researcher_names'], 'contributor'),
          nested_ordered_creator_attributes: create_nested_attribute(@data['authors'], 'creator'),
          nested_ordered_title_attributes: create_nested_attribute(@data['titles'], 'title'),
          publisher: @data['publisher'].first.titleize,
          resource_type: [ENV.fetch('REPOSITORY_PUBLISH_RESOURCE_TYPE', 'Article')],
          rights_statement: ENV.fetch('REPOSITORY_PUBLISH_RIGHTS_STATEMENT', 'http://rightsstatements.org/vocab/InC/1.0/'),
          subject: @data['keywords'],
          web_of_science_uid: @web_of_science_uid
        },
        uploaded_files: file_ids,
        agreement: 1
      }
    end

    ##
    # Create expected data structure for nested ordered attribute
    # Input: work_data_array: data of work to be published in array
    #         attribute_name[String]
    # Output: nested hash, for example: "nested_ordered_creator_attributes"=>{"70188320304080"=>{"creator"=>"Yoke, Kaseylin T", "index"=>"0"}, "71739809440388"=>{"creator"=>"Schellman, Dr. Heidi", "index"=>"1"}, "73291298587176"=>{"creator"=>"MINERvA Collaboration, Fermilab", "index"=>"2"}}
    def create_nested_attribute(work_data_array, attr_name)
      nested_hash = {}
      work_data_array.map.with_index { |a, i|
        key = Time.now.to_i + i * 10
        nested_hash[key] = { attr_name.to_s => a, index: i } }
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

    # Convert Web of Science date into format compatible with ScholarsArchive
    # Input: biblio_date and biblio_year from Web of Science
    # Output: date in YYYY-MM-DD format
    def formalize_date(pubdate_str)
      # e.g., DEC 2, 2021
      formalize_date_obj = Date.strptime(pubdate_str, '%b %d, %Y')
      # e.g., 25-Dec, 2019
      formalize_date_obj = Date.strptime(pubdate_str, '%d-%b, %Y') if formalize_date_obj.blank?
      # e.g., Jul 2019
      formalize_date_obj = Date.strptime(pubdate_str, '%b %Y') if formalize_date_obj.blank?
      # e.g., 2019
      formalize_date_obj = Date.strptime(pubdate_str, '%Y') if formalize_date_obj.blank?
      if formalize_date_obj.blank?
        formalize_date_str = nil
      else
        formalize_date_str = formalize_date_obj.to_s
      end
    rescue StandardError => e
      Rails.logger.warn "Repository Work formalize date error #{e.message}"
      nil
    end
  end
end
