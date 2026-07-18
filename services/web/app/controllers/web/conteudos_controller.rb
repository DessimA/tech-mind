module Web
  class ConteudosController < ApplicationController
    include Cacheable

    def index
      page = (params[:page] || 1).to_i.clamp(1, 999)
      cache_key = "#{cache_namespace}:page:#{page}:q:#{params[:q]}:sort:#{params[:sort]}"

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

        result = MlService.new(@conteudo.texto).call

        if result.success?
          @conteudo.update!(
            categoria: result.data["categoria"],
            probabilidade: result.data["probabilidade"],
            informacoes_adicionais: result.data["informacoes_adicionais"],
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

    def cache_user
      current_user
    end

    def cache_namespace
      "conteudos:user:#{current_user.id}"
    end

    def classificado?(conteudo)
      conteudo.status == "done"
    end
    helper_method :classificado?
  end
end
