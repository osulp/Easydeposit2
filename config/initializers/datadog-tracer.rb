# frozen_string_literal: true

if %w[production staging].include? Rails.env
  Datadog.configure do |c|
    c.use :rails, service_name: "ed2-#{Rails.env}"
    c.use :http, service_name: "ed2-#{Rails.env}-http"
    c.use :sidekiq, service_name: "ed2-#{Rails.env}-sidekiq"
    c.use :redis, service_name: "ed2-#{Rails.env}-redis"
  end
end