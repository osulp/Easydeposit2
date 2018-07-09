class PublishWorkJob < ActiveJob::Base
  queue_as :default

  def perform(state=nil)
    job = get_job(state)
    job.update({
      message: "Executed at #{DateTime.now}",
      status: Job::STARTED[:name]
    })

    # get the persisted state to decide what to execute
    state = job[:restartable_state]

    if rand(2) == 1
      job.completed({
        message: "Completed at #{DateTime.now}",
        restartable: false
      })
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

  private
  def get_job(state=nil)
    if state
      Job.from_state(state)
    else
      Job.create(Job::PUBLISH_WORK)
    end
  end
end
