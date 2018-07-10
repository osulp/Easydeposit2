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
  DEFAULT =     { name: '',           class: 'primary', icon: 'help_outline' }
  COMPLETED =   { name: 'completed',  class: 'success', icon: 'star' }
  ERROR =       { name: 'error',      class: 'danger',  icon: 'error' }
  STARTED =     { name: 'started',    class: 'info',    icon: 'watch_later' }
  WARN =        { name: 'warn',       class: 'warning', icon: 'warning' }

  # Types of Jobs
  HARVESTED_NEW = { name: 'Harvested New Publication',              status: COMPLETED[:name] }
  HARVEST =       { name: 'Harvest Record(s) from Web Of Science',  status: WARN[:name] }
  FILE_ADDED =    { name: 'File(s) added',                          status: COMPLETED[:name] }
  FILE_DELETED =  { name: 'File(s) deleted',                        status: COMPLETED[:name] }

  PUBLISH_WORK =  { name: 'Publish Work',
                    status: STARTED[:name],
                    restartable: true,
                    restartable_state: JSON.dump({
                      method: RESTARTABLE_METHODS[:publish_work]
                    }) }

  def completed(options=nil)
    save_record(options.merge({
      status: COMPLETED[:name]
    }))
  end

  def error(options=nil)
    save_record(options.merge({
      status: ERROR[:name]
    }))
  end

  def warn(options=nil)
    save_record(options.merge({
      status: WARN[:name]
    }))
  end

  def get_status
    return case status
    when COMPLETED[:name]
      COMPLETED
    when ERROR[:name]
      ERROR
    when WARN[:name]
      WARN
    when STARTED[:name]
      STARTED
    else
      DEFAULT
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
    self.update_columns({
      status: options[:status],
      message: options[:message].presence || '',
      restartable: options[:restartable].nil? ? self.restartable : options[:restartable],
      restartable_state: options[:restartable_state].presence || self.restartable_state
    })
  end

  def set_restartable_state_job_id
    if restartable && !restartable_state.blank?
      state = JSON.parse(restartable_state)
      state[:job_id] = id
      self.update_columns(restartable_state: JSON.dump(state))
    end
  end
end
