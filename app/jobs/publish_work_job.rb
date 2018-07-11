class PublishWorkJob < ActiveJob::Base
  queue_as :default

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
    raise
  end
end
