class PublishMailer < ApplicationMailer
  before_action { @emails = params[:emails] }
  default to: -> { @emails }

  def published_email
    @user = params[:user]
    @publication = params[:publication]
    mail subject: "#{@publication.web_of_science_source_record[:uid]} work published to repository."
  end
end
