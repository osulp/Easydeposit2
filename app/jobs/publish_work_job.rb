class PublishWorkJob < ApplicationJob
  # Defaults to 0
  #job_options retry: 0

  def perform(publication:, current_user: nil, previous_job: nil)
    job = previous_job || Job.create(Job::PUBLISH_WORK)

    job.update({
      publication: publication,
      message: "Attempting to publish at #{DateTime.now}",
      status: Job::STARTED[:name]
    })

    current_user.jobs << job if current_user

    # get the persisted state to decide what to execute
    state = job[:restartable_state]

    if rand(2) == 1
      job.completed({
        message: "Completed at #{DateTime.now}",
        restartable: false
      })

      publication.update(pub_at: DateTime.now)

      # Email the current_user and all users related to the publication
      # when the work is published.
      email_job = publication.jobs.where(name: Job::EMAIL_PUBLISHED[:name]).first
      # Instantiating a new job then calling perform, since this particular job is a Sidekiq::Worker intended to not automatically
      # retry upon failure.
      EmailPublishedWorkJob.perform_later(current_user: current_user, publication: publication, previous_job: email_job)

    else
      job.warn({
        message: "Completed at #{DateTime.now}",
        restartable: true
      })
    end
  rescue => e
    msg = "PublishWorkJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    job.error({message: "#{msg} : #{e.message}"})
  end
end
