Rails.application.routes.draw do
  get '/publications' => 'publications#index'
  get '/publications/sourcelookup' => 'publications#sourcelookup'

  ##
  # Endpoint for Pub harvester
  post '/publications/harvest', to: 'publications#harvest', defaults: { format: :json }
  #
  # Endpoint for Author harvester
  post '/authors/:cap_profile_id/harvest', to: 'authors#harvest', defaults: { format: :json }

end