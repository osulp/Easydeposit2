Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  root to: 'home#index'
  devise_for :users
  devise_for :cas_users

  get '/publications' => 'publications#harvest'
  get '/publications/index' => 'publications#index'
  get '/publications/sourcelookup' => 'publications#sourcelookup'

  ##
  # Endpoint for Pub harvester
  get '/publications/harvest', to: 'publications#harvest', defaults: { format: :json }
  #
  # Endpoint for Author harvester
  post '/authors/:cap_profile_id/harvest', to: 'authors#harvest', defaults: { format: :json }

end
