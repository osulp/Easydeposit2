Rails.application.routes.draw do
  get '/publications' => 'publications#index'
  get '/publications/sourcelookup' => 'publications#sourcelookup'

  ##
  # Endpoint for Author harvester
  post '/authors/:cap_profile_id/harvest', to: 'authors#harvest', defaults: { format: :json }

end