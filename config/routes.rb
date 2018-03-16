Rails::Application.routes.draw do
  if Rails.env.development?
    mount RailsDb::Engine => '/rails/db', :as => 'rails_db'
  end
end