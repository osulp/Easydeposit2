# frozen_string_literal: true

require 'faraday'
require 'nokogiri'

module WebOfScience
  # Fetch author emails and abstract from Web Of Science records
  class FetchWosContent
    # @param publication [Publication]
    # return Hash {emails: [String], abstract: <String>}
    def self.fetch_from_api(publication)
      wssr = publication.web_of_science_source_record
      uid = wssr.uid
      source_url_prefix = Settings.WOS.source_url_prefix
      redirect_url_prefix = Settings.WOS.redirect_url_prefix

      links_client = Clarivate::LinksClient.new
      links = links_client.links([uid], fields: ['sourceURL'])

      connection = Faraday.new(source_url_prefix) do |f|
        f.request :url_encoded
        # comment logger for debug because output could overwhelm
        f.response :logger
        f.adapter Faraday.default_adapter
      end

      # location from Link http://gateway.webofknowledge.com/gateway/Gateway.cgi?GWVersion=2&SrcApp=PARTNER_APP&SrcAuth=LinksAMR&KeyUT=WOS:000429846700001&DestLinkType=FullRecord&DestApp=ALL_WOS&UsrCustomerID=3dc17a6ed097c11e7f6c459392a2955e
      # prefix_url should be removed for Faraday
      location = links[uid]['sourceURL'].gsub(/#{source_url_prefix}/, '')
      content = ''
      fetched_hash = { 'emails' => [], 'abstract' => '' }

      success = false
      until success
        response = connection.get location
        if response.status == 302 || response.status == 301
          location = response.headers[:location]
          unless location.start_with?('http')
            connection.url_prefix = redirect_url_prefix
          end
        else
          success = true
          content = response.body
        end
      end

      # example of emails: <p class="FR_field"> <span class="FR_label">E-mail Addresses:</span><a href="mailto:john.smith@education.edu">john.smith@education.edu</a> </p>
      fetched_hash['emails'] = content.scan(/mailto:(.*?)\"/).flatten

      doc = Nokogiri::HTML(content)
      fetched_hash['abstract'] = doc.xpath('//div[@class="block-record-info"]/div[text()="Abstract"]/../p[@class="FR_field"]').text
      fetched_hash
    end
  end
end
