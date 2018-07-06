Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  root to: 'home#index'
  devise_for :users
  devise_for :cas_users

  resources :publications do
    delete 'file/:file_id', to: 'publications#delete_file', as: 'delete_file'
  end

  ##
  # Endpoint for Pub harvester
  get '/publications/harvest', to: 'publications#harvest', defaults: { format: :json }
end
