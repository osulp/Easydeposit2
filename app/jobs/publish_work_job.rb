# frozen_string_literal: true

##
# Publish the work to the repository
class PublishWorkJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_job: nil)
    job = previous_job || Job.create(Job::PUBLISH_WORK)

    job.update(
      publication: publication,
      message: "Attempting to publish at #{Time.now}",
      status: Job::STARTED[:name]
    )

    current_user.jobs << job if current_user
    if published?(publication, job)
      email_published_notification(current_user, publication)
      publication.update(pub_at: Time.now)
    end
  rescue StandardError => e
    msg = 'PublishWorkJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    job.error(message: "#{msg} : #{e.message}")
  end

  private

  def email_published_notification(current_user, publication)
    # Email the current_user and all users related to the publication
    # when the work is published.
    email_job = publication.jobs.where(name: Job::EMAIL_PUBLISHED[:name]).first
    # Instantiating a new job then calling perform
    EmailPublishedWorkJob.perform_later(current_user: current_user, publication: publication, previous_job: email_job)
  end

  def published?(publication, job)
    if publication_exists?(publication)
      job.warn(message: "Publication already exists in the repository. Skipped publishing at #{Time.now}", restartable: false)
      false
    else
      publish!(publication)
      job.completed(message: "Published to the repository at #{Time.now}", restartable: false)
      true
    end
  end

  def publication_exists?(publication)
    # Use Repository API to query existence of this work by its WOS.uid
  end

  def publish!(publication)
    # Use the Repository API to publish the work
  end
end
