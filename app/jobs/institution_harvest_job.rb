class InstitutionHarvestJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  # Performs an asynchronous harvest and save publications
  # @return [void]
  def perform(institution)
    event = Event.create(Event::HARVEST.merge({ status: 'started' }))
    uids = web_of_science(institution)
    event.completed({message: "#{uids.count} records harvested."})
  rescue => e
    msg = "InstitutionHarvestJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    event.error({message: " failed harvesting publications, error has been logged."}) if event
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
