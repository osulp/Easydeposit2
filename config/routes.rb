Rails.application.routes.draw do
  root to: 'home#index'
  devise_for :users
  devise_for :cas_users

  get '/claim/:claim_link', to: 'publications#claim', as: 'claim'

  ##
  # Endpoint for Pub harvester
  get '/publications/harvest', to: 'publications#harvest', defaults: { format: :json }
  resources :publications do
    get 'publish', to: 'publications#publish', as: 'publish'
    delete 'file/:file_id', to: 'publications#delete_file', as: 'delete_file'
    get 'event/:event_id', to: 'publications#restart_event', as: 'restart_event'
  end

  # Only allow CAS users who are admin to access RailsAdmin and Sidekiq
  authenticate :cas_user, -> u { u.admin? } do
    mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
end
