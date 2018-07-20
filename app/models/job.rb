# frozen_string_literal: true

require 'json'

##
# AR model for tracking and restarting jobs related to publications
class Job < ActiveRecord::Base
  belongs_to :publication, autosave: true, inverse_of: :jobs, optional: true
  belongs_to :user, inverse_of: :jobs, optional: true
  belongs_to :cas_user, inverse_of: :jobs, optional: true

  # rubocop:disable Style/MutableConstant

  # Restartable Methods
  RESTARTABLE_METHODS = {
    publish_work: PublishWorkJob.to_s,
    email_published_work: EmailPublishedWorkJob.to_s,
    fetch_authors_directory_api: FetchAuthorsDirectoryApiJob.to_s
    fetch_author_emails: FetchAuthorEmailsJob.to_s
  }

  # Statuses
  DEFAULT =     { name: '',           class: 'primary', icon: 'help_outline', tooltip: '' }
  COMPLETED =   { name: 'completed',  class: 'success', icon: 'done_outline', tooltip: 'Completed' }
  ERROR =       { name: 'error',      class: 'danger',  icon: 'error',        tooltip: 'Error' }
  STARTED =     { name: 'started',    class: 'info',    icon: 'watch_later',  tooltip: 'Processing' }
  WARN =        { name: 'warn',       class: 'warning', icon: 'warning',      tooltip: 'Warning' }
  EMAIL =       { name: 'email',      class: 'success', icon: 'mail_outline', tooltip: 'Emailed' }

  # Types of Jobs
  HARVESTED_NEW =   { name: 'Harvested New Publication',              status: COMPLETED[:name] }
  HARVEST =         { name: 'Harvest Record(s) from Web Of Science',  status: WARN[:name] }
  FILE_ADDED =      { name: 'File(s) added',                          status: COMPLETED[:name] }
  FILE_DELETED =    { name: 'File(s) deleted',                        status: COMPLETED[:name] }
  EMAIL_PUBLISHED = { name: 'Publish Work Notification Email',
                      status: STARTED[:name],
                      restartable: true,
                      restartable_state: JSON.dump(method: RESTARTABLE_METHODS[:email_published_work]) }
  PUBLISH_WORK =    { name: 'Publish Work',
                      status: STARTED[:name],
                      restartable: true,
                      restartable_state: JSON.dump(method: RESTARTABLE_METHODS[:publish_work]) }
  FETCH_AUTHORS_DIRECTORY_API = { name: 'Fetch Authors from Directory API',
                                  status: STARTED[:name],
                                  restartable: true,
                                  restartable_state: JSON.dump(method: RESTARTABLE_METHODS[:fetch_authors_directory_api]) }
  FETCH_AUTHOR_EMAILS = { name: 'Fetch Author Emails',
                      status: STARTED[:name],
                      restartable: true,
                      restartable_state: JSON.dump(method: RESTARTABLE_METHODS[:fetch_author_emails]) }

  def completed(options = nil)
    save_record(options.merge(status: options[:status] || COMPLETED[:name]))
  end

  def error(options = nil)
    save_record(options.merge(status: options[:status] || ERROR[:name]))
  end

  def warn(options = nil)
    save_record(options.merge(status: options[:status] || WARN[:name]))
  end

  def status_hash
    case status
    when COMPLETED[:name]
      COMPLETED
    when ERROR[:name]
      ERROR
    when WARN[:name]
      WARN
    when STARTED[:name]
      STARTED
    when EMAIL[:name]
      EMAIL
    else
      DEFAULT
    end
  end

  ##
  # Called by the end-user from a button surfaced on the UI; retry the
  # restartable job related to this record.
  def retry(current_user)
    raise 'Missing reference to the current user.' unless current_user
    return unless restartable
    # check if the restartable method is in the array as a security
    # method to control which classes can be called
    state = JSON.parse(restartable_state)
    klass = state['method'].constantize
    klass.perform_later(publication: publication, current_user: current_user, previous_job: self)
  end

  private

  def save_record(options)
    update_columns(
      status: options[:status],
      message: options[:message].presence || '',
      restartable: options[:restartable].nil? ? restartable : options[:restartable],
      restartable_state: options[:restartable_state].presence || restartable_state
    )
  end
end
