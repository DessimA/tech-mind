require "net/http"
require "json"

module SecretsManager
  SECRET_NAME = "techmind/db-credentials"
  ENDPOINT = ENV.fetch("AWS_ENDPOINT", "http://localstack:4566")
  REGION = ENV.fetch("AWS_REGION", "us-east-1")
  RETRIES = 5
  RETRY_DELAY = 2

  def self.read_db_credentials
    last_error = nil

    RETRIES.times do |attempt|
      begin
        uri = URI("#{ENDPOINT}/secretsmanager/getsecretvalue")
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 2
        http.read_timeout = 2

        request = Net::HTTP::Post.new(uri)
        request["X-Amz-Target"] = "secretsmanager.GetSecretValue"
        request["Content-Type"] = "application/x-amz-json-1.1"
        request.body = JSON.generate({ "SecretId" => SECRET_NAME })

        response = http.request(request)

        if response.is_a?(Net::HTTPOK)
          body = JSON.parse(response.body)
          secret = JSON.parse(body["SecretString"])
          return {
            host: secret["host"],
            port: secret["port"],
            username: secret["username"],
            password: secret["password"],
            dbname: secret["dbname"]
          }
        end

        last_error = "HTTP #{response.code}"
      rescue StandardError => e
        last_error = e.message
      end

      sleep RETRY_DELAY if attempt < RETRIES - 1
    end

    warn "SecretsManager: fallback para env vars apos #{RETRIES} tentativas (#{last_error})"
    nil
  end
end
