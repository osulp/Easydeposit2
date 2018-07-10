module Repository
  class Work

    attr_reader :client
    def initialize(client, work_type, data, file_path, file_content_type, admin_set_title)
      @client = client
      @data = data
      @file_content_type = file_content_type
      @file_path = file_path
      @work_type = work_type
      @admin_set_id = get_admin_set_id(admin_set_title)
    end

    def publish
      raise "Cannot find file #{@file_path}, can't publish." unless has_file?
      raise "Missing content type #{@file_content_type}, can't publish." if @file_content_type.blank?
      raise "No data fields to publish." if @data.blank?
      work = @client.publish(work_payload, publish_url)
      advanced = @client.set_workflow(work, 'Approve', 'Published by ED2')
      advanced
    end

    private
    def work_payload
      @data['admin_set_id'] = @admin_set_id
      payload = {
        "#{@work_type}" => @data,
        uploaded_files: [file_id],
        agreement: 1
      }
    end

    def get_admin_set_id(title)
      @client.admin_sets['admin_sets'].select {|a| a['title'].any? {|t| t.casecmp(title).zero? } }.first['id']
    end

    def has_file?
      File.file?(@file_path)
    end

    def file_id
      response = @client.upload_file(@file_path, @file_content_type)
      response['files'][0]['id']
    end

    def publish_url
      "/concern/#{@work_type.pluralize}.json"
    end
  end
end
