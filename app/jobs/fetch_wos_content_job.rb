# frozen_string_literal: true

##
# Fetch authors emails and abstract from Web of Science full record and
# save them to AuthorPublication
class FetchWosContentJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_event: nil)
    event = previous_event || Event.create(Event::FETCH_WOS_CONTENT)

    event.update(
      publication: publication,
      message: "Attempting to fetch content from Web of Science at #{Time.now}",
      restartable: false,
      status: Event::STARTED[:name]
    )

    current_user.events << event if current_user

    # get emails of authors, and abstract from Web Of Science full records
    wos_content = fetch_wos_content(publication)
    create_or_update_publication_emails(wos_content[:emails], publication)
    publication.update(abstract: wos_content[:abstract])

    message = 'Found no authors emails or abstract for this publication in the Web of Science full record'
    message = "Found #{wos_content[:emails].count} author emails and abstract in Web of Science full records." if wos_content[:emails].length
    event.completed(message: message, restartable: false)
    logger.debug "FetchWosContentJob: Publication.may_recruit_authors? #{publication[:id]} = #{publication.may_recruit_authors?}"
    publication.recruit_authors! if publication.may_recruit_authors?
  rescue StandardError => e
    msg = 'FetchWosContentJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    event.error(message: "#{msg} : #{e.message}", restartable: true) if event
  end

  private

  def fetch_wos_content(publication)
    logger.info('Fetch authors emails and abstract from Web of Science full record')
    WebOfScience::FetchAuthorsEmailsWos.fetch_from_api(publication)
  end

  def create_or_update_publication_emails(emails, publication)
    emails.each do |e|
      record = AuthorPublication.find_or_create_by(email: e, publication: publication)
      record.save
    end
  end
end
