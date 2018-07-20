require 'faraday'

module WebOfScience
  # Fetch author emails from Web Of Science records
  class FetchAuthorEmails
    # @param publication [Publication]
    def fetch_from_api(publication)
      wssr = publication.web_of_science_source_record
      uid = wssr.uid
      source_url_prefix = Settings.WOS.source_url_prefix
      redirect_url_prefix = Settings.WOS.redirect_url_prefix

      links_client = Clarivate::LinksClient.new
      links = links_client.links([uid], fields: ['sourceURL'])
      location = links[uid]['sourceURL']

      connection = Faraday.new(source_url_prefix) do |f|
        f.request :url_encoded
        f.response :logger
        f.adapter Faraday.default_adapter
      end

      success = false
      while(!success)
        response = connection.get location
        if response.status == 302 || response.status == 301
          location = response.headers[:location]
          unless location.start_with?('http')
            connection.url_prefix = redirect_url_prefix
          end
        else
          success = true
          puts response.body
        end
      end

    end
  end
end