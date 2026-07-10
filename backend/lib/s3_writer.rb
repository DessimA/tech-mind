require "aws-sdk-s3"

module S3Writer
  BUCKET = "techmind-content"

  def self.upload_texto(conteudo_id, titulo, texto)
    client = Aws::S3::Client.new(
      endpoint: ENV.fetch("AWS_ENDPOINT", "http://localstack:4566"),
      region: ENV.fetch("AWS_REGION", "us-east-1"),
      access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID", "test"),
      secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY", "test"),
      force_path_style: true,
      http_open_timeout: 5,
      http_read_timeout: 5
    )

    key = "conteudos/#{conteudo_id}/texto.txt"
    body = "---\ntitulo: #{titulo}\n---\n\n#{texto}"

    client.put_object(
      bucket: BUCKET,
      key: key,
      body: body,
      content_type: "text/plain"
    )

    key
  rescue Aws::Errors::ServiceError => e
    Rails.logger.warn "S3Writer: falha ao enviar texto #{conteudo_id} (#{e.message})"
    nil
  end
end
