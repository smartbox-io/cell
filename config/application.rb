require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

require "ipaddr"

# Require the gems listed in Gemfile, including any gems
# you"ve limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class Srv::Application < Rails::Application
  # Initialize configuration defaults for originally generated Rails version.
  config.load_defaults 5.1

  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Only loads a smaller set of middleware suitable for API only apps.
  # Middleware like session, flash, cookies can be added back manually.
  # Skip views, helpers and assets when generating a new resource.
  config.api_only = true

  config.active_job.queue_adapter = :sidekiq

  config.action_dispatch.trusted_proxies = ["127.0.0.1", "::1"].map { |proxy| IPAddr.new proxy }
end
