class InstitutionHarvestJob < ActiveJob::Base
  queue_as :default

  # Performs an asynchronous harvest and save publications
  # @return [void]
  def perform(institution)
    #sciencewire(author, harvest_alternate_names)
    web_of_science(institution)
  rescue => e
    msg = "InstitutionHarvestJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    #Honeybadger.notify(e, context: { message: msg })
    raise
  end

  private

  # @param [Author] author
  # @return [void]
  def log_pubs(author)
    pubs = Contribution.where(author_id: author.id).map(&:publication).each do |p|
      logger.info "publication #{p.id}: #{p.pub_hash[:apa_citation]}"
    end
    logger.info "Number of publications #{pubs.count}"
  end

  # @param [Author] author
  # @param [Boolean] harvest_alternate_names
  # @return [void]
  def sciencewire(author, harvest_alternate_names)
    return unless Settings.SCIENCEWIRE.enabled
    harvester = ScienceWireHarvester.new
    harvester.use_author_identities = harvest_alternate_names
    harvester.harvest_pubs_for_author_ids author.id
    log_pubs(author)
  end

  # @param [String] institution
  # @return [void]
  def web_of_science(institution)
    return unless Settings.WOS.enabled
    # TODO: enable alternate names
    #WebOfScience.harvester.process_author(author)
    #log_pubs(author)
    WebOfScience.harvester.process_institution(institution)
    logger.info('Harvest by institution complete')
  end
end