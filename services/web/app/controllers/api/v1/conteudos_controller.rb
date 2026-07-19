module Api
  module V1
    class ConteudosController < ApplicationController
      include Cacheable

      skip_before_action :authenticate_user!, only: [ :index, :show, :create, :update, :destroy ]
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

      before_action :authenticate_api!

      def index
        page = (params[:page] || 1).to_i.clamp(1, 999)
        per_page = [ (params[:per_page] || 20).to_i, 100 ].min
        cache_key = "#{cache_namespace}:page:#{page}:per:#{per_page}:q:#{params[:q]}:sort:#{params[:sort]}"

        result = cached_conteudos(cache_key) do
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

          {
            data: paginated.map { |c| list_item(c) },
            meta: {
              current_page: page,
              total_pages: (total.to_f / per_page).ceil,
              total_count: total,
              per_page: per_page
            }
          }
        end

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

          result = MlService.new(conteudo.texto).call

          if result.success?
            conteudo.update!(
              categoria: result.data["categoria"],
              probabilidade: result.data["probabilidade"],
              informacoes_adicionais: result.data["informacoes_adicionais"],
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

      def update
        conteudo = @api_user.conteudos.find(params[:id])

        ActiveRecord::Base.transaction do
          conteudo.update!(conteudo_params.merge(status: :processing))

          result = MlService.new(conteudo.texto).call

          if result.success?
            conteudo.update!(
              categoria: result.data["categoria"],
              probabilidade: result.data["probabilidade"],
              informacoes_adicionais: result.data["informacoes_adicionais"],
              status: :done
            )
          else
            conteudo.update!(status: :failed)
          end

          invalidate_cache
        end

        render json: ConteudoSerializer.new(conteudo.reload).as_json
      end

      def destroy
        conteudo = @api_user.conteudos.find(params[:id])
        conteudo.destroy!
        invalidate_cache
        head :no_content
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

      def cache_user
        @api_user
      end

      def cache_namespace
        "conteudos:v1:user:#{@api_user.id}"
      end

      def authenticate_api!
        if session[:user_id]
          @api_user = User.find_by(id: session[:user_id])
        end

        unless @api_user
          render json: { error: "unauthorized", mensagem: "Autenticação necessária" }, status: :unauthorized
          nil
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
