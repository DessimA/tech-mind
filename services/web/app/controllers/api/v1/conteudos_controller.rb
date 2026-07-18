require "net/http"

module Api
  module V1
    class ConteudosController < ApplicationController
      skip_before_action :authenticate_user!, only: [:index, :show, :create]
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

      before_action :authenticate_api!

      def index
        page = (params[:page] || 1).to_i.clamp(1, 999)
        per_page = [(params[:per_page] || 20).to_i, 100].min
        cache_key = "conteudos:v1:user:#{@api_user.id}:page:#{page}:per:#{per_page}:q:#{params[:q]}:sort:#{params[:sort]}"

        cached = Rails.cache.read(cache_key)
        if cached
          return render json: cached
        end

        order_clause = case params[:sort]
        when "created_at_asc" then { created_at: :asc }
        when "titulo_asc" then { titulo: :asc }
        else { created_at: :desc }
        end

        conteudos = @api_user.conteudos.order(order_clause)
        q = params[:q]&.strip
        if q.present?
          conteudos = conteudos.where(
            "titulo ILIKE ? OR informacoes_adicionais @> ARRAY[?]::text[]",
            "%#{q}%", q
          )
        end

        paginated = conteudos.page(page).per(per_page)
        total = conteudos.count

        result = {
          data: paginated.map { |c| list_item(c) },
          meta: {
            current_page: page,
            total_pages: (total.to_f / per_page).ceil,
            total_count: total,
            per_page: per_page
          }
        }

        Rails.cache.write(cache_key, result, expires_in: ENV.fetch("CACHE_TTL", 300).to_i)
        render json: result
      end

      def show
        conteudo = @api_user.conteudos.find(params[:id])
        render json: ConteudoSerializer.new(conteudo).as_json
      end

      def create
        conteudo = @api_user.conteudos.new(conteudo_params)
        conteudo.status = :processing

        ActiveRecord::Base.transaction do
          conteudo.save!

          result = call_ml_service(conteudo.texto)
          if result
            conteudo.update!(
              categoria: result["categoria"],
              probabilidade: result["probabilidade"],
              informacoes_adicionais: result["informacoes_adicionais"],
              status: :done
            )
          else
            conteudo.update!(status: :failed)
          end

          invalidate_cache
        end

        render json: {
          id: conteudo.id,
          titulo: conteudo.titulo,
          status: conteudo.status,
          created_at: conteudo.created_at.iso8601
        }, status: :created
      end

      private

      def conteudo_params
        params.permit(:titulo, :texto)
      end

      def list_item(c)
        {
          id: c.id,
          titulo: c.titulo,
          categoria: c.categoria,
          probabilidade: c.probabilidade&.to_f,
          informacoes_adicionais: c.informacoes_adicionais,
          status: c.status,
          created_at: c.created_at.iso8601
        }
      end

      def call_ml_service(texto)
        ml_host = ENV.fetch("ML_HOST", "ml")
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
          nil
        end
      rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED => e
        Rails.logger.warn "ML Service: #{e.class} - #{e.message}"
        nil
      end

      def invalidate_cache
        Rails.cache.delete_matched("conteudos:v1:user:#{@api_user.id}:*")
      rescue StandardError
        nil
      end

      def authenticate_api!
        if session[:user_id]
          @api_user = User.find_by(id: session[:user_id])
        end

        unless @api_user
          render json: { error: "unauthorized", mensagem: "Autenticação necessária" }, status: :unauthorized
          return
        end
      end

      def not_found
        render json: { error: "not_found", mensagem: "Conteúdo não encontrado" }, status: :not_found
      end

      def unprocessable(exception)
        record = exception.record
        render json: {
          error: "validation_failed",
          mensagem: record.errors.full_messages.first,
          detalhes: record.errors.messages.transform_values { |v| v.map(&:to_s) }
        }, status: :unprocessable_entity
      end
    end
  end
end
