require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EasyDeposit2
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    # lib/**/ load lib subdirectories
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Auto-load API and its subdirectories
    # config.paths.add 'app/api', glob: '**/*.rb'
    # config.autoload_paths += Dir["#{Rails.root}/app/api/*"]

    # Allows for the application to use classes in
    # lib
    config.enable_dependency_loading = true
    config.autoload_paths << Rails.root.join('lib')

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # load and inject local_env.yml key/values into ENV
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(ERB.new(File.read(env_file)).result).each do |key, value|
        # Allows for array values, but they have to be split later.
        value = value.join('|') if value.is_a?(Array)
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end

    config.rubycas.cas_base_url = ENV["ED2_CAS_BASE_URL"] || 'https://cas.myorganization.com'

    config.active_job.queue_adapter = ENV['ACTIVE_JOB_QUEUE_ADAPTER'].present? ? ENV['ACTIVE_JOB_QUEUE_ADAPTER'].to_sym : :inline

    config.action_mailer.delivery_method = :sendmail
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_deliveries = true
    config.action_mailer.default_options = {
      from: ENV['ED2_EMAIL_FROM']
    }
    config.action_mailer.default_url_options = {
      host: ENV['ED2_APPLICATION_HOST_NAME']
    }

    config.middleware.use ActionDispatch::Session::CookieStore, {:key => '_Easydeposit2_session', :cookie_only => true}
  end
end
