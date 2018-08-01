class EmailPublishedWorkJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user:, previous_event: nil)
    event = previous_event || Event.create(Event::EMAIL_PUBLISHED.merge({ restartable: false, status: Event::STARTED[:name] }))

    event.update({
      publication: publication,
      message: "Initiated by #{current_user.email}",
      restartable: false,
      status: Event::STARTED[:name]
    })

    current_user.events << event if current_user

    emails = [current_user.email]
    emails << publication.users.map(&:email)
    emails << publication.cas_users.map(&:email)

    PublishMailer.with(emails: emails, user: current_user, publication: publication).published_email.deliver_now

    event.completed({
      message: "Email initiated by #{current_user.email} at #{DateTime.now}",
      restartable: false,
      status: Event::EMAIL[:name]
    })
  rescue => e
    msg = "EmailPublishedWorkJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    event.error({restartable: true, message: "#{msg} : #{e.message}"})
  end
end
