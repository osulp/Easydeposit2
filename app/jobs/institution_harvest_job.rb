class InstitutionHarvestJob < ActiveJob::Base
  queue_as :default

  # Performs an asynchronous harvest and save publications
  # @return [void]
  def perform(institution)
    job = Job.create(Job::HARVEST.merge({ status: 'started' }))
    web_of_science(institution)
    job[:status] = 'completed'
  rescue => e
    msg = "InstitutionHarvestJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    job[:status] = 'error'
    job[:message] = "#{msg} : #{e.message}"
    raise
  ensure
    job.save
  end

  private

  # @param [String] institution
  # @return [void]
  def web_of_science(institution)
    return unless Settings.WOS.enabled
    WebOfScience.harvester.process_institution(institution)
    logger.info('Harvest by institution complete')
  end
end
