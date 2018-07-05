class InstitutionHarvestJob < ActiveJob::Base
  queue_as :default

  # Performs an asynchronous harvest and save publications
  # @return [void]
  def perform(institution)
    web_of_science(institution)
  rescue => e
    msg = "InstitutionHarvestJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    raise
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
