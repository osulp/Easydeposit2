# frozen_string_literal: true

namespace :resend_article_recruit_email do
  desc 'Re-send article recruit email for publications without attachment'
  task resendarticlerecruitemail: :environment do
    Publication.all.each do |pub|
      # Find publications without attachment
      if pub.publication_files.empty?
        # Call re-send article recruit email
        ResendEmailArticleRecruitJob.perform_later(pub)
      end
    end
  end
end