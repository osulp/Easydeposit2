# frozen_string_literal: true

##
# Fetch authors emails from Web of Science full record and
# save them to AuthorPublication
class FetchAuthorsEmailsWosJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_event: nil)
    event = previous_event || Event.create(Event::FETCH_AUTHORS_EMAILS_WOS)

    event.update(
      publication: publication,
      message: "Attempting to fetch authors emails from Web of Science at #{Time.now}",
      restartable: false,
      status: Event::STARTED[:name]
    )

    current_user.events << event if current_user

    # get emails of authors from Web Of Science full records
    emails = fetch_authors_emails(publication)
    create_or_update_publication_emails(emails, publication)

    message = 'Found no authors emails for this publication in the Web of Science full records'
    message = "Found #{emails.count} author emails in Web of Science full records." if emails.length
    event.completed(message: message, restartable: false)
    logger.debug "FetchAuthorsEmailsWosJob: Publication.may_recruit_authors? #{publication[:id]} = #{publication.may_recruit_authors?}"
    publication.recruit_authors! if publication.may_recruit_authors?
  rescue StandardError => e
    msg = 'FetchAuthorsEmailsWosJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    event.error(message: "#{msg} : #{e.message}", restartable: true) if event
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
