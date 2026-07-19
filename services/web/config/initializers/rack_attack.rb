class Rack::Attack
  # Rate limit geral da API
  throttle("api/ip", limit: ENV.fetch("RATE_LIMIT_MAX", 100).to_i, period: ENV.fetch("RATE_LIMIT_PERIOD", 60).to_i) do |req|
    req.ip unless req.path.start_with?("/health")
  end

  # Rate limit específico para login (anti brute force)
  throttle("login/ip", limit: ENV.fetch("RATE_LIMIT_LOGIN_MAX", 10).to_i, period: ENV.fetch("RATE_LIMIT_LOGIN_PERIOD", 60).to_i) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  self.throttled_responder = ->(env) {
    retry_after = env["rack.attack.match_data"]&.dig(:period) || 60

    if env["PATH_INFO"]&.start_with?("/v1/")
      # API response
      [
        429,
        { "Content-Type" => "application/json" },
        [ { error: "rate_limited", mensagem: "Muitas requisições. Tente novamente em #{retry_after} segundos." }.to_json ]
      ]
    else
      # HTML response
      [
        429,
        { "Content-Type" => "text/html" },
        [ "<html><body><h1>429</h1><p>Muitas requisições. Tente novamente em #{retry_after} segundos.</p></body></html>" ]
      ]
    end
  }
end
