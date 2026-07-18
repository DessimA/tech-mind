require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Cache via Valkey (Redis OSS) com fallback para memória
  config.cache_store = if ENV["REDIS_HOST"].present?
    :redis_cache_store, {
      url: "redis://#{ENV.fetch('REDIS_HOST', 'valkey')}:#{ENV.fetch('REDIS_PORT', '6379')}/1",
      expires_in: ENV.fetch("CACHE_TTL", 300).to_i.seconds,
      namespace: "techmind:cache"
    }
  else
    :memory_store
  end

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true

  config.action_dispatch.trusted_proxies = %w[127.0.0.1 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16]

  config.hosts << "backend"
  config.hosts << ".onrender.com" if ENV["RENDER"].present?
  config.hosts << /.*/ if Rails.env.development?

  config.middleware.use Rack::Attack
end
