module V1
  class ConteudosController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

    def index
      page = (params[:page] || 1).to_i.clamp(1, 999)
      per_page = [(params[:per_page] || 20).to_i, 100].min
      cache_key = "conteudos:list:page:#{page}:per:#{per_page}:q:#{params[:q]}"

      cached = Rails.cache.read(cache_key)
      if cached
        return render json: cached
      end

      conteudos = Conteudo.order(created_at: :desc)
      q = params[:q]&.strip
      if q.present?
        conteudos = conteudos.where(
          "titulo ILIKE ? OR ? = ANY(informacoes_adicionais)",
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
      conteudo = Conteudo.find(params[:id])
      render json: ConteudoSerializer.new(conteudo).as_json
    end

    def create
      conteudo = Conteudo.create!(conteudo_params)
      ClassificationJob.perform_async(conteudo.id)
      invalidate_cache

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

    def invalidate_cache
      Rails.cache.delete_matched("conteudos:list:*")
    rescue StandardError
      nil
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
