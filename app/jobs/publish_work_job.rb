# frozen_string_literal: true

require 'fileutils'

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
      job.warn(message: "Publication already exists in the repository. Found #{published_works(repository_client, publication).count} on server with #{publication.web_of_science_source_record[:uid]}. Skipped publishing at #{Time.now}", restartable: false)
      false
    else
      publish!(repository_client, publication)
      job.completed(message: "Published to the repository at #{Time.now}", restartable: false)
      true
    end
  end

  ##
  # Check to see if this publication has already been published
  # @param repository_client [Repository::Client] - the client to query
  # @param publication [Publication] - the publication with a WOS uid
  # @return [Boolean] - true if any number of result documents are found on the server
  def publication_exists?(repository_client, publication)
    published_works(repository_client, publication).count.positive?
  end

  ##
  # Query the repository API to see if this publication has already been published.
  # @param repository_client [Repository::Client] - the client to query
  # @param publication [Publication] - the publication with a WOS uid
  def published_works(repository_client, publication)
    @published_works ||= repository_client.search('web_of_science_uid', publication.web_of_science_source_record[:uid])
  end

  ##
  # Publish the work to the repository
  # @param repository_client [Repository::Client] - the client to publish to
  # @param publication [Publication] - the publication record to publish
  def publish!(repository_client, publication)
    files = stage_attached_files(publication)
    response = repository_work(repository_client, publication, files).publish
    publication.update(pub_url: publication_url(repository_client, response[:response]))
  rescue StandardError => e
    logger.error "#{e.message} => #{e.backtrace}"
  end

  ##
  # Copy files from ActiveStorage to a location that is accessible to the application
  # for uploading to the repository. ActiveStorage files aren't always or necessarily
  # on the local disk and this ensures that they will be during the upload process.
  # @param publication [Publication] - the publication having attached files for upload
  # @return [Array<Hash<string, string>>] - the path and content_type of each file to be uploaded
  def stage_attached_files(publication)
    uploaded_files = []
    publication.publication_files.each do |f|
      temp_file_path = File.join(Rails.root, 'tmp/publishing_staged_uploads', f.key, f.filename.to_s)
      temp_file_directory = File.dirname(temp_file_path)
      FileUtils.mkdir_p(temp_file_directory) unless File.directory?(temp_file_directory)
      File.open(temp_file_path, 'wb') do |file|
        file.write(f.download)
      end
      uploaded_files << { path: temp_file_path, content_type: f.content_type }
    end
    uploaded_files
  end

  ##
  # The full URL to the newly created work on the repository
  # @param repository_client [Repository::Client] - the client to publish to
  # @param publication [Publication] - the publication record to publish
  # @return [String] - the full url
  def publication_url(repository_client, response)
    "#{repository_client.url}#{response.headers[:location]}"
  end

  def repository_work(repository_client, publication, files)
    @repository_work ||= Repository::Work.new(
      client: repository_client,
      data: publication.web_of_science_source_record.record.to_h,
      files: files,
      work_type: ENV.fetch('REPOSITORY_PUBLISH_WORK_TYPE', 'Article').downcase,
      admin_set_title: ENV.fetch('REPOSITORY_PUBLISH_ADMIN_SET_NAME', 'One Step').downcase,
      web_of_science_uid: publication.web_of_science_source_record[:uid]
    )
  end

  def repository_client
    @repository_client ||= Repository::Client.new
  end
end
