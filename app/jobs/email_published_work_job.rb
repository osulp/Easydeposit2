class EmailPublishedWorkJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user:, previous_event: nil)
    system_email = ENV['ED2_EMAIL_FROM']
    event = previous_event || Event.create(Event::EMAIL_PUBLISHED.merge({ restartable: false, status: Event::STARTED[:name] }))

    event.update(
      publication: publication,
      message: "Initiated by #{current_user.email}",
      restartable: false,
      status: Event::STARTED[:name]
    )

    current_user.events << event if current_user

    emails = [system_email.split(',')].flatten
    emails << current_user[:email] if current_user
    emails << publication.author_publications.map(&:email) if Rails.env.production?
    emails.each do |email|
      logger.debug "EmailPublishedWorkJob.perform: Emailing published email to #{email}"
      PublishMailer.with(email: email, user: current_user, publication: publication).published_email.deliver_now
    end
    event.completed(
      message: "Email initiated by #{current_user.email} at #{Time.now}",
      restartable: false,
      status: Event::EMAIL[:name]
    )
  rescue => e
    msg = 'EmailPublishedWorkJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    event.error(restartable: true, message: "#{msg} : #{e.message}") if event
  end
end
