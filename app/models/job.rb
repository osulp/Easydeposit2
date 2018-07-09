require 'json'

class Job < ActiveRecord::Base
  belongs_to :publication, autosave: true, inverse_of: :jobs, optional: true
  belongs_to :user, inverse_of: :jobs, optional: true
  belongs_to :cas_user, inverse_of: :jobs, optional: true

  after_create :set_restartable_state_job_id

  # Restartable Methods
  RESTARTABLE_METHODS = {
    publish_work: PublishWorkJob.to_s
  }

  # Statuses
  COMPLETED = 'completed'.freeze
  ERROR = 'error'.freeze
  STARTED = 'started'.freeze
  WARN = 'warn'.freeze

  # Types of Jobs
  HARVESTED_NEW = { name: 'Harvested New Publication',              status: COMPLETED }
  HARVEST =       { name: 'Harvest Record(s) from Web Of Science',  status: WARN }
  FILE_ADDED =    { name: 'File(s) added',                          status: COMPLETED }
  FILE_DELETED =  { name: 'File(s) deleted',                        status: COMPLETED }

  PUBLISH_WORK =  { name: 'Publish Work',
                    status: STARTED,
                    restartable: true,
                    restartable_state: JSON.dump({
                      method: RESTARTABLE_METHODS[:publish_work]
                    }) }

  def completed(options=nil)
    save_record(options.merge({
      status: COMPLETED
    }))
  end

  def error(options=nil)
    save_record(options.merge({
      status: ERROR
    }))
  end

  def warn(options=nil)
    save_record(options.merge({
      status: WARN
    }))
  end

  def status_class
    return case status
    when COMPLETED
      "success"
    when ERROR
      "danger"
    when WARN
      "warning"
    else
      "primary"
    end
  end

  ##
  # Static method to find a job from the provided state
  def self.from_state(state)
    Job.find(state['job_id'])
  end

  ##
  # Called by the end-user from a button surfaced on the UI; retry the
  # restartable job related to this record.
  def retry
    if restartable && !restartable_state.blank?
      #check if the restartable method is in the array as a security method to control which classes can be called
      state = JSON.parse(restartable_state)
      klass = state['method'].constantize
      klass.new.perform(state)
    end
  end

  private
  def save_record(options)
    status = options[:status]
    message = options[:message] || ''
    save
  end

  def set_restartable_state_job_id
    if restartable && !restartable_state.blank?
      state = JSON.parse(restartable_state)
      state[:job_id] = id
      self.update_columns(restartable_state: JSON.dump(state))
    end
  end
end
