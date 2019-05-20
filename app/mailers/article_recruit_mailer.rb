# frozen_string_literal: true

##
# Send article recruit emails so authors can attach files to publications in EasyDeposit
class ArticleRecruitMailer < ApplicationMailer
  before_action { @email = params[:email] }

  def recruit_email
    @publication = params[:publication]
    @author_publication = @publication.author_publications.where(email: @email).first
    mail(to: @email, subject: "Oregon State University Library invites you to deposit your recent publication: #{@publication.web_of_science_source_record[:uid]}")
  end

  def resend_recruit_email
    @publication = params[:publication]
    @author_publication = @publication.author_publications.where(email: @email).first
    mail(to: @email, subject: "REMINDER: Oregon State University Library invites you to deposit your recent publication: #{@publication.web_of_science_source_record[:uid]}")
  end
end
