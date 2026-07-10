class Rack::Attack
  throttle("api/ip", limit: ENV.fetch("RATE_LIMIT_MAX", 100).to_i, period: ENV.fetch("RATE_LIMIT_PERIOD", 60).to_i) do |req|
    req.ip
  end

  self.throttled_responder = ->(env) {
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "rate_limited", mensagem: "Muitas requisições. Tente novamente em #{ENV.fetch('RATE_LIMIT_PERIOD', 60)} segundos." }.to_json]
    ]
  }
end
