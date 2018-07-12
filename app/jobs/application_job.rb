class ApplicationJob < ActiveJob::Base
  queue_as :default

  def self.job_options(options)
    @job_options = options || {
      retry: 0
    }
  end

  def self.get_job_options
    @job_options || {
      retry: 0
    }
  end
end
