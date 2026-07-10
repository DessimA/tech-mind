require "aws-sdk-secretsmanager"

module SecretsManager
  SECRET_NAME = "techmind/db-credentials"
  RETRIES = 5
  RETRY_DELAY = 2

  def self.read_db_credentials
    last_error = nil

    RETRIES.times do |attempt|
      begin
        client = Aws::SecretsManager::Client.new(
          endpoint: ENV.fetch("AWS_ENDPOINT", "http://localstack:4566"),
          region: ENV.fetch("AWS_REGION", "us-east-1"),
          access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID", "test"),
          secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY", "test"),
          http_open_timeout: 2,
          http_read_timeout: 2
        )

        response = client.get_secret_value(secret_id: SECRET_NAME)
        secret = JSON.parse(response.secret_string)

        return {
          host: secret["host"],
          port: secret["port"],
          username: secret["username"],
          password: secret["password"],
          dbname: secret["dbname"]
        }
      rescue Aws::Errors::ServiceError => e
        last_error = "#{e.class}: #{e.message}"
      rescue StandardError => e
        last_error = e.message
      end

      sleep RETRY_DELAY if attempt < RETRIES - 1
    end

    warn "SecretsManager: fallback para env vars apos #{RETRIES} tentativas (#{last_error})"
    nil
  end
end
