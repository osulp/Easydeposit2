source 'https://rubygems.org'

gem 'rails'
gem 'responders', '~> 2.4'

# Use Puma as the app server
gem 'puma', '~> 3.0'
gem 'puma_worker_killer'

gem 'bootstrap', '~> 4.1.1'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.1'
# JS Runtime. See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer'

gem 'mysql2', '~> 0.4.10'

gem 'config'

# Redis background job queue
gem 'sidekiq'

gem 'faraday'
gem 'htmlentities'
gem 'httpclient', '~> 2.8'
# Altmetric utilities related to the extraction, validation and normalization of various scholarly identifiers
gem 'identifiers', '~> 0.10'
# To use Jbuilder templates for JSON
gem 'jbuilder'
gem 'jquery-rails'
gem 'kaminari'
gem 'libv8'
gem 'nokogiri', '>= 1.7.1'
gem 'paper_trail'
gem 'pry-rails'
gem 'rake'
gem 'savon', '~> 2.12'
gem 'simple_form'

gem 'haml'
gem 'haml-rails'

gem 'devise'
gem 'devise_cas_authenticatable'

# CAS Authentication gems
gem 'rubycas-client', git: 'https://github.com/osulp/rubycas-client'
gem 'rubycas-client-rails', git: 'https://github.com/osulp/rubycas-client-rails'

gem 'rails_admin', '~> 1.3'

# Use Capistrano for deployment
gem 'capistrano', '~> 3.8.0'
gem 'capistrano-passenger'
gem 'capistrano-rails'
gem 'capistrano-rbenv'
gem 'capistrano3-puma'

gem 'aasm'

group :production, :staging do
  gem 'ddtrace'
end

group :development, :test do
  gem 'debase'
  # Great gem for inspecting the database in development/test at localhost:3000/rails/db
  gem 'rails_db'
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'rspec-rails', '~> 3.7'
  gem 'rspec_junit_formatter'
  gem 'rubocop'
  gem 'ruby-debug-ide'
end

group :development do
  gem 'byebug'
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'web-console', '~> 3.3'
end

group :test do
  gem 'capybara'
  gem 'coveralls', '~> 0.8', require: false
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'poltergeist'
  gem 'simplecov', '~> 0.13', require: false
  gem 'single_cov'
  gem 'vcr'
  gem 'webmock'
end
