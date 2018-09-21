# frozen_string_literal: true

##
# Send article recruit emails so authors can attach files to publications in EasyDeposit
class ArticleRecruitMailer < ApplicationMailer
  before_action { @emails = params[:emails] }

  ##
  # For a publication that has multiple author emails (AuthorPublication):
  # create a separate email for each author with the corresponding claim_link stored in AuthorPublication
  def recruit_email
    @publication = params[:publication]
    @emails.each do |email|
      @author_publication = AuthorPublication.includes(:publication)
                                             .where(email: email)
                                             .first
      mail(to: email, subject: "Oregon State University Library invites you to deposit your recent publication: #{@publication.web_of_science_source_record[:uid]}")
    end
  end
end
