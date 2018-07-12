class InstitutionHarvestJob < ApplicationJob
  # Defaults to 0
  #job_options retry: 0

  # Performs an asynchronous harvest and save publications
  # @return [void]
  def perform(institution)
    job = Job.create(Job::HARVEST.merge({ status: 'started' }))
    uids = web_of_science(institution)
    job.completed({message: "#{uids.count} records harvested."})
  rescue => e
    msg = "InstitutionHarvestJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    job.error({message: "#{msg} : #{e.message}"})
    raise
  end

  private

  # @param [String] institution
  # @return [void]
  def web_of_science(institution)
    return unless Settings.WOS.enabled
    uids = WebOfScience.harvester.process_institution(institution)
    logger.info('Harvest by institution complete')
    uids
  end
end
