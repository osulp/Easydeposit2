source 'https://rubygems.org'

gem 'grape', '~> 0.19'
gem 'rails'
gem 'responders', '~> 2.4'

# Use Puma as the app server
gem 'puma', '~> 3.0'
gem 'puma_worker_killer'

# Use sass-powered bootstrap
gem 'bootstrap-sass', '~> 3.3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.1'
# JS Runtime. See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer'

gem 'mysql2', '~> 0.4.10'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

gem 'nokogiri', '>= 1.7.1'

gem 'activerecord-import'
# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'
gem 'bibtex-ruby'
gem 'bio'
gem 'citeproc-ruby', '~> 1.1'
gem 'config'
gem 'csl-styles', '~> 1.0'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'dotiw'
gem 'faraday'
gem 'high_voltage'
gem 'htmlentities', '~> 4.3'
gem 'httpclient', '~> 2.8'
# Altmetric utilities related to the extraction, validation and normalization of various scholarly identifiers
gem 'identifiers', '~> 0.10'
# To use Jbuilder templates for JSON
gem 'jbuilder'
gem 'jquery-rails'
gem 'kaminari'
gem 'libv8'
gem 'okcomputer' # for monitoring
gem 'paper_trail'
gem 'parallel'
gem 'pry-rails'
gem 'pubmed_search'
gem 'rake'
gem 'savon', '~> 2.12'
gem 'simple_form'
gem 'StreetAddress', '~> 1.0', '>= 1.0.6'
gem 'turnout'
gem 'whenever', require: false
gem 'yaml_db'


gem 'devise'
# CAS Authentication gems
gem 'rubycas-client', git: 'https://github.com/osulp/rubycas-client'
gem 'rubycas-client-rails', git: 'https://github.com/osulp/rubycas-client-rails'
gem 'devise_cas_authenticatable'

group :development, :test do
  gem 'debase'
  gem 'dlss_cops' # includes rubocop
  gem 'rails_db'
  gem 'rspec'
  gem 'rspec-rails', '~> 3.7'
  gem 'ruby-debug-ide'
end

group :development do
  gem 'byebug'
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'thin' # app server
  gem 'web-console', '~> 3.3'
end

group :test do
  gem 'capybara'
  gem 'coveralls', '~> 0.8', require: false
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'simplecov', '~> 0.13', require: false
  gem 'single_cov'
  gem 'vcr'
  gem 'webmock'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shell'
  gem 'dlss-capistrano'
  gem 'capistrano3-delayed-job', '~> 1.0'
end
