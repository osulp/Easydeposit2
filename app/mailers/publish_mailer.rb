class PublishMailer < ApplicationMailer
  before_action { @email = params[:email] }
  default to: -> { @email }

  def published_email
    @user = params[:user]
    @publication = params[:publication]
    mail subject: "#{@publication.web_of_science_source_record[:uid]} work published to repository."
  end
end
