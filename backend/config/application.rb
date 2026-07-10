require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/secrets_manager"

module TechMind
  class Application < Rails::Application
    config.before_configuration do
      if ENV["DB_HOST"].present?
        puts "SecretsManager: usando env vars (ignorando Secrets Manager)"
      else
        creds = SecretsManager.read_db_credentials
        if creds
          ENV["DB_HOST"] ||= creds[:host]
          ENV["DB_PORT"] ||= creds[:port]
          ENV["DB_USER"] ||= creds[:username]
          ENV["DB_PASSWORD"] ||= creds[:password]
          ENV["DB_NAME"] ||= creds[:dbname]
          puts "SecretsManager: credenciais lidas do Secrets Manager"
        end
      end
    end

    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.active_job.queue_adapter = :sidekiq

    config.api_only = true

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
