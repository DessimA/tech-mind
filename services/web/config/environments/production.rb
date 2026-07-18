require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.active_support.report_deprecations = false

  # Cache via Valkey (Redis OSS) com fallback para memória
  if ENV["REDIS_HOST"].present?
    config.cache_store = :redis_cache_store, {
      url: "redis://#{ENV.fetch('REDIS_HOST', 'valkey')}:#{ENV.fetch('REDIS_PORT', '6379')}/1",
      expires_in: ENV.fetch("CACHE_TTL", 300).to_i.seconds,
      namespace: "techmind:cache"
    }
  else
    config.cache_store = :memory_store
  end

  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  config.middleware.use Rack::Attack
end
