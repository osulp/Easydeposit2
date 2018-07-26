# frozen_string_literal: true

##
# Publish the work to the repository
class PublishWorkJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_job: nil)
    repository_client = Repository::Client.new
    job = previous_job || Job.create(Job::PUBLISH_WORK)

    job.update(
      publication: publication,
      message: "Attempting to publish at #{Time.now}",
      status: Job::STARTED[:name]
    )

    current_user.jobs << job if current_user
    if published_new?(repository_client, publication, job)
      email_published_notification(current_user, publication)
      publication.update(pub_at: Time.now)
    end
  rescue StandardError => e
    msg = 'PublishWorkJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    job.error(message: "#{msg} : #{e.message}")
  end

  private

  ##
  # Email the current_user and all users related to the publication
  # when the work is published.
  # @param [User] - the user the job is running on behalf of
  # @param [Publication] - the publication which was published
  def email_published_notification(current_user, publication)
    email_job = publication.jobs.where(name: Job::EMAIL_PUBLISHED[:name]).first
    # Instantiating a new job then calling perform
    EmailPublishedWorkJob.perform_later(current_user: current_user, publication: publication, previous_job: email_job)
  end

  ##
  # Check the repository to see if this publication has been published, or publish it if it hasn't been already
  # @param repository_client [Repository::Client] - the client to the repository API
  # @param publication [Publication] - the publication
  # @param job [Job] - the current job (new or retried) that is being processed
  # @return [Boolean] - true if the Publication was newly published, false if it is already on the server
  def published_new?(repository_client, publication, job)
    if publication_exists?(repository_client, publication)
      job.warn(message: "Publication already exists in the repository. Found #{published_works.count} on server with #{publication.web_of_science_source_record[:uid]}. Skipped publishing at #{Time.now}", restartable: false)
      false
    else
      publish!(repository_client, publication)
      job.completed(message: "Published to the repository at #{Time.now}", restartable: false)
      true
    end
  end

  ##
  # Query the repository API to see if this publication has already been published.
  # @param repository_client [Repository::Client] - the client to query
  # @param publication [Publication] - the publication with a WOS uid
  # @return [Boolean] - true if any number of result documents are found on the server
  def publication_exists?(repository_client, publication)
    # Use Repository API to query existence of this work by its WOS.uid
    published_works.count.positive?
  end

  def published_works
    @published_works ||= repository_client.search('web_of_science_uid', publication.web_of_science_source_record[:uid])
  end

  ##
  # Publish the work to the repository
  # @param repository_client [Repository::Client] - the client to publish to
  # @param publication [Publication] - the publication record to publish
  def publish!(repository_client, publication)
    # Use the Repository API to publish the work
    #
    # Get all file details related to publication [{path:, content_type:},...]
    # Init a Repository::Work
    # Publish work
    # Set Publication[:pub_url]
  rescue StandardError => e
    # Log specific errors during repository publishing
  end
end
