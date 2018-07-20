class FetchAuthorEmailsJob < ApplicationJob
  # Defaults to 0
  #job_options retry: 0

  def perform(publication:, current_user: nil, previous_job: nil)
    job = previous_job || Job.create(Job::FETCH_AUTHOR_EMAILS)

    job.update({
                   publication: publication,
                   message: "Attempting to fetch author emails at #{DateTime.now}",
                   status: Job::STARTED[:name]
               })

    current_user.jobs << job if current_user

    # get the persisted state to decide what to execute
    state = job[:restartable_state]

    fetch_author_emails(publication)
    job.completed({message: "Fetched author emails for: #{publication.title}"})
  rescue => e
    msg = "FetchAuthorEmailsJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    job.error({message: "#{msg} : #{e.message}"})
  end

  private

  def fetch_author_emails(publication)
    WebOfScience::FetchAuthorEmails.fetch_from_api(publication)
    logger.info('Fetch author emails complete')
  end

end