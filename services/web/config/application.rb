require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module TechMind
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    # Cache via Redis/Valkey (fallback para memória)
    config.cache_store = if ENV["REDIS_HOST"].present?
      :redis_cache_store, {
        url: "redis://#{ENV.fetch('REDIS_HOST', 'valkey')}:#{ENV.fetch('REDIS_PORT', '6379')}/1",
        expires_in: ENV.fetch("CACHE_TTL", 300).to_i.seconds,
        namespace: "techmind:cache"
      }
    else
      :memory_store
    end

    # Sessão via cookie (Render free tier tem filesystem efêmero)
    config.session_store :cookie_store,
      key: "_techmind_session",
      secure: Rails.env.production?,
      httponly: true,
      expire_after: 24.hours

    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    # Configurações de i18n
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [:"pt-BR"]

    # Rate limiting
    config.middleware.use Rack::Attack

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
