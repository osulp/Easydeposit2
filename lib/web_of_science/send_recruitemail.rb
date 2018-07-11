# frozen_string_literal: true
require 'mechanize'

module WebOfScience

  # Scrape reprint email address from Web of Science full record
  # save emails to Publication and send article recruitment email to the addresses
  class SendRecruitemail
    # @param [WebOfScienceSourceRecord] WebOfScienceSourceRecord
    # @param [Publication] publication
    # @return [Array <String>] scraped reprint addresses
    def scrape_emails(wssr, publication)
      uid = wssr.uid if wssr.uid.present?
      links_client = Clarivate::LinksClient.new
      links = links_client.links(uid, fields: ['sourceURL'])
      agent = Mechanize.new
      page = agent.get(links[wos_uid]['sourceURL'])
      reprint_emails = []
      # sample full record
      # <span class="FR_label">E-mail Addresses:</span><a href="mailto:zhenxing.feng@oregonstate.edu">zhenxing.feng@oregonstate.edu</a>; <a href="mailto:huangyq@mail.buct.edu.cn">huangyq@mail.buct.edu.cn</a>
      page.link_with(href: %r{^mailto:}).map do |link|
        reprint_emails.push(link.text.gsub(/^mailto:/, ''))
      end
      publication.reprintemails = reprint_emails
      return reprint_emails
    rescue StandardError => err
      NotificationManager.error(err, "#{self.class} - get author emails failed for uid #{rec.uid}", self)
    end

    # @param reprint emails
    # return nil
    def send_emails(emails)
      # TODO

    end
  end
end