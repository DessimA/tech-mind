require "net/http"
require "json"

class MlService
  TIMEOUT_DEFAULT = 8
  HOST_DEFAULT   = "ml".freeze
  PORT_DEFAULT   = "8000".freeze

  Response = Struct.new(:success?, :data, :error, keyword_init: true)

  def initialize(texto, host: nil, port: nil, timeout: nil)
    @texto   = texto.to_s.strip
    @host    = host || ENV.fetch("ML_HOST", HOST_DEFAULT)
    @port    = port || ENV.fetch("ML_PORT", PORT_DEFAULT)
    @timeout = (timeout || ENV.fetch("ML_TIMEOUT", TIMEOUT_DEFAULT.to_s)).to_i
  end

  def call
    uri = URI("http://#{@host}:#{@port}/predict")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = [ @timeout / 2, 3 ].max
    http.read_timeout = @timeout

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate({ texto: @texto })

    response = http.request(request)

    if response.is_a?(Net::HTTPOK)
      data = JSON.parse(response.body)
      Response.new(success?: true, data: data)
    else
      Rails.logger.warn "[ML Service] HTTP #{response.code} para texto=#{@texto.truncate(80)}"
      Response.new(success?: false, error: "HTTP #{response.code}")
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, JSON::ParserError,
         SocketError, Net::HTTPBadResponse => e
    Rails.logger.warn "[ML Service] #{e.class}: #{e.message} para texto=#{@texto.truncate(80)}"
    Response.new(success?: false, error: "#{e.class}: #{e.message}")
  end
end
