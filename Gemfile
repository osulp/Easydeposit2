source 'https://rubygems.org'

gem 'rails', '~> 7.0'
gem 'responders', '~> 3.1'

# Use Puma as the app server
gem 'puma', '~> 5.6'
gem 'puma_worker_killer'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.1'

gem 'mysql2', '~> 0.5.2'

gem 'config'

# Redis background job queue
gem 'sidekiq', '7.1.3'
gem 'ffi', '1.13.1'
gem 'sassc', '< 2.2.0'

# Honeycomb
gem 'honeycomb-beeline', '>= 2.4.0'
gem 'libhoney', '>= 1.18.0'

gem 'faraday'
gem 'htmlentities'
gem 'httpclient', '~> 2.8'
# Altmetric utilities related to the extraction, validation and normalization of various scholarly identifiers
gem 'identifiers', '~> 0.10'
gem 'iso-639'
# To use Jbuilder templates for JSON
gem 'jbuilder'
gem 'jquery-rails'
gem 'kaminari'
gem 'libv8'
gem 'nokogiri', '>= 1.10.1'
gem 'paper_trail'
gem 'pry-rails'
gem 'rake'
gem 'rb-readline'
gem 'savon', '~> 2.12'
gem 'simple_form'

gem 'haml'
gem 'haml-rails'

gem 'devise'
gem 'devise_cas_authenticatable'

# CAS Authentication gems
gem 'rubycas-client', git: 'https://github.com/osulp/rubycas-client'
gem 'rubycas-client-rails', git: 'https://github.com/osulp/rubycas-client-rails'

gem 'rails_admin', '~> 3.1'

# Use Capistrano for deployment
gem 'capistrano', '~> 3.8.0'
gem 'capistrano-passenger'
gem 'capistrano-rails'
gem 'capistrano-rbenv'
gem 'capistrano3-puma'

# Function Supports
gem 'aasm'

# Security audit update
gem 'activejob', '>= 5.2.1.1'
gem 'activestorage', '>= 5.2.1.1'
gem 'loofah', '>= 2.2.3'
gem 'rack', '>= 2.0.6'
gem 'railties', '>= 5.2.2.1'
gem 'bootstrap', '>= 4.3.1'
gem 'actionview', '>= 5.2.2.1'

group :development, :test do
  gem 'debase', '>= 0.2.5.beta2'
  # Great gem for inspecting the database in development/test at localhost:3000/rails/db
  gem 'rails_db'
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'rspec-rails', '~> 4.0'
  gem 'rspec_junit_formatter'
  gem 'rubocop'
  gem 'ruby-debug-ide'
end

group :development do
  gem 'byebug'
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'web-console', '~> 4.2'
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
