Rails.application.routes.draw do
  get '/publications' => 'publications#harvest'
  get '/publications/index' => 'publications#index'
  get '/publications/sourcelookup' => 'publications#sourcelookup'

  # make publication index root
  root 'home#index'

  ##
  # Endpoint for Pub harvester
  get '/publications/harvest', to: 'publications#harvest', defaults: { format: :json }
  #
  # Endpoint for Author harvester
  post '/authors/:cap_profile_id/harvest', to: 'authors#harvest', defaults: { format: :json }

end
