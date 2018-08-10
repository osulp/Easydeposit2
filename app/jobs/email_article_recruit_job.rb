# frozen_string_literal: true

##
# Job for sending article recruit email
class EmailArticleRecruitJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_event: nil)
    system_email = ENV['ED2_EMAIL_FROM']
    event = previous_event || Event.create(Event::EMAIL_ARTICLE_RECRUIT.merge(restartable: false, status: Event::STARTED[:name]))

    event.update(
      publication: publication,
      message: "Initiated by #{current_user ? current_user[:email] : system_email }",
      restartable: false,
      status: Event::STARTED[:name]
    )

    current_user.events << event if current_user

    emails = [system_email]
    emails << current_user[:email] if current_user
    emails << publication.author_publications.map(&:email)
    logger.debug "EmailArticleRecruitJob.perform: Emailing recruitment email to #{emails.join('; ')}"

    # TODO: pass all emails to mailer
    ArticleRecruitMailer.with(emails: emails[0], publication: publication).recruit_email.deliver_now

    event.completed(
      message: "Article author recruitment email completed by #{current_user ? current_user[:email] : system_email} at #{Time.now}",
      restartable: false,
      status: Event::EMAIL[:name]
    )
    publication.await_claim!
  rescue => e
    msg = 'EmailArticleRecruitJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    event.error(restartable: true, message: "#{msg} : #{e.message}")
  end
end
