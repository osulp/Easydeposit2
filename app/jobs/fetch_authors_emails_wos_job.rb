# frozen_string_literal: true

##
# Fetch authors emails from Web of Science full record and
# save them to AuthorPublication
class FetchAuthorsEmailsWosJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_job: nil)
    job = previous_job || Job.create(Job::FETCH_AUTHORS_EMAILS_WOS)

    job.update(
      publication: publication,
      message: "Attempting to fetch authors emails from Web of Science at #{Time.now}",
      status: Job::STARTED[:name]
    )

    current_user.jobs << job if current_user

    # get emails of authors from Web Of Science full records
    emails = fetch_authors_emails(publication)
    create_or_update_publication_emails(emails, publication)

    message = 'Found no authors emails for this publication in the Web of Science full records'
    message = "Found #{emails.count} author emails in Web of Science full records." if emails.length
    job.completed(message: message, restartable: false)
  rescue StandardError => e
    msg = 'FetchAuthorsEmailsWosJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    job.error(message: "#{msg} : #{e.message}")
  end

  private

  def fetch_authors_emails(publication)
    logger.info('Fetch authors emails from Web of Science full record complete')
    WebOfScience::FetchAuthorsEmailsWos.fetch_from_api(publication)
  end

  def create_or_update_publication_emails(emails, publication)
    emails.each do |e|
      record = AuthorPublication.find_or_create_by(email: e, publication: publication)
      record.save
    end
  end
end
