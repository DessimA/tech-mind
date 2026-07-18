require "net/http"

module Web
  class ConteudosController < ApplicationController
    before_action :authenticate_user!

    def index
      page = (params[:page] || 1).to_i.clamp(1, 999)
      cache_key = "conteudos:user:#{current_user.id}:page:#{page}:q:#{params[:q]}:sort:#{params[:sort]}"

      @conteudos = cached_conteudos(cache_key) do
        order_clause = case params[:sort]
        when "created_at_asc" then { created_at: :asc }
        when "titulo_asc" then { titulo: :asc }
        else { created_at: :desc }
        end

        conteudos = current_user.conteudos.order(order_clause)

        if params[:q].present?
          q = params[:q].strip
          conteudos = conteudos.where(
            "titulo ILIKE ? OR informacoes_adicionais @> ARRAY[?]::text[]",
            "%#{q}%", q
          )
        end

        conteudos.page(page).per(20)
      end
    end

    def show
      @conteudo = current_user.conteudos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to conteudos_path, alert: "Conteúdo não encontrado."
    end

    def new
      @conteudo = Conteudo.new
    end

    def create
      @conteudo = current_user.conteudos.new(conteudo_params)
      @conteudo.status = :processing

      ActiveRecord::Base.transaction do
        @conteudo.save!

        # Chama ML Service sincronamente
        result = call_ml_service(@conteudo.texto)

        if result
          @conteudo.update!(
            categoria: result["categoria"],
            probabilidade: result["probabilidade"],
            informacoes_adicionais: result["informacoes_adicionais"],
            status: :done
          )
        else
          @conteudo.update!(status: :failed)
        end

        invalidate_cache
      end

      redirect_to @conteudo, notice: classificado?(@conteudo) ? "Conteúdo cadastrado e classificado!" : "Conteúdo cadastrado, mas a classificação falhou."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    private

    def conteudo_params
      params.require(:conteudo).permit(:titulo, :texto)
    end

    def call_ml_service(texto)
      ml_host = ENV.fetch("ML_HOST", "ml-service")
      ml_port = ENV.fetch("ML_PORT", "8000")
      timeout = ENV.fetch("ML_TIMEOUT", "8").to_i

      uri = URI("http://#{ml_host}:#{ml_port}/predict")

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = [timeout / 2, 3].max
      http.read_timeout = timeout

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate({ texto: texto })

      response = http.request(request)

      if response.is_a?(Net::HTTPOK)
        JSON.parse(response.body)
      else
        Rails.logger.warn "ML Service: HTTP #{response.code}"
        nil
      end
    rescue Net::TimeoutError, Errno::ECONNREFUSED => e
      Rails.logger.warn "ML Service: #{e.class} - #{e.message}"
      nil
    end

    def cached_conteudos(key)
      cached = Rails.cache.read(key)
      if cached
        @from_cache = true
        return cached
      end

      result = yield
      Rails.cache.write(key, result, expires_in: ENV.fetch("CACHE_TTL", 300).to_i)
      result
    end

    def invalidate_cache
      Rails.cache.delete_matched("conteudos:user:#{current_user.id}:*")
    rescue StandardError
      nil
    end

    def classificado?(conteudo)
      conteudo.status == "done"
    end
    helper_method :classificado?
  end
end
