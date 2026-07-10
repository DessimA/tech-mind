class ClassificationJob
  include Sidekiq::Job
  sidekiq_options retry: ENV.fetch("SIDEKIQ_RETRY_MAX", 3).to_i

  def perform(conteudo_id)
    conteudo = Conteudo.find(conteudo_id)
    return if conteudo.status == "done"

    conteudo.update!(status: "processing")

    S3Writer.upload_texto(conteudo.id, conteudo.titulo, conteudo.texto)

    ml_host = ENV.fetch("ML_HOST", "ml-service")
    ml_port = ENV.fetch("ML_PORT", "8000")
    uri = URI("http://#{ml_host}:#{ml_port}/predict")

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate({ texto: conteudo.texto })

    response = http.request(request)

    if response.is_a?(Net::HTTPOK)
      result = JSON.parse(response.body)
      conteudo.update!(
        categoria: result["categoria"],
        probabilidade: result["probabilidade"],
        informacoes_adicionais: result["informacoes_adicionais"],
        status: "done"
      )
    elsif response.code.to_i == 503
      fail!(conteudo, "Modelo ML indisponível")
    else
      fail!(conteudo, "HTTP #{response.code}: #{response.body}")
    end
  rescue ActiveRecord::RecordNotFound
    logger.warn "ClassificationJob: conteudo #{conteudo_id} nao encontrado"
  rescue StandardError => e
    fail!(conteudo, e.message) if conteudo
  end

  private

  def fail!(conteudo, reason)
    conteudo&.update!(status: "failed")
    raise ClassificationError, reason
  end
end

class ClassificationError < StandardError; end
