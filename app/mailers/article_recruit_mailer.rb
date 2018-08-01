class ArticleRecruitMailer < ApplicationMailer
  before_action { @emails = params[:emails] }
  default to: -> { @emails }

  def published_email
    @user = params[:user]
    @publication = params[:publication]
    mail subject: "Oregon State University Library invites you to deposit your recent publication: #{@publication.web_of_science_source_record[:uid]}"
  end
end
