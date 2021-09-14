# frozen_string_literal: true

namespace :publications do
  search_terms = ENV.fetch('ED2_WOS_SEARCH_TERMS', nil)&.split('|')

  desc 'Initiate a background job to harvest WOS records.'
  task harvest: :environment do
    raise 'ENV missing ED2_WOS_SEARCH_TERMS configuration, unable to harvest records.' unless search_terms
    InstitutionHarvestJob.perform_later(search_terms)
  end
end
