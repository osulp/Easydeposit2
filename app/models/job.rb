class Job < ActiveRecord::Base
  belongs_to :publication, autosave: true, inverse_of: :jobs, optional: true
  belongs_to :user, inverse_of: :jobs, optional: true
  belongs_to :cas_user, inverse_of: :jobs, optional: true

  COMPLETED = 'completed'.freeze
  ERROR = 'error'.freeze
  WARN = 'warn'.freeze
  HARVESTED_NEW = { name: 'Harvested New Publication',              status: COMPLETED }
  HARVEST =       { name: 'Harvest Record(s) from Web Of Science',  status: WARN }
  FILE_ADDED =    { name: 'File(s) added',                          status: COMPLETED }
  FILE_DELETED =  { name: 'File(s) deleted',                        status: COMPLETED }

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

  private
  def save_record(options)
    status = options[:status]
    message = options[:message] || ''
    save
  end
end
