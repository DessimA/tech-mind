require "rails_helper"

RSpec.describe "Web::Conteudos", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user, password: "minha-senha") }
  let!(:conteudo) { create(:conteudo, user: user, status: :done, categoria: "Backend") }
  let!(:outro_conteudo) { create(:conteudo, user: user, status: :processing) }

  before do
    post login_path, params: { email: user.email, password: "minha-senha" }

    # Stub ML Service para evitar WebMock bloqueando
    stub_request(:post, "http://ml:8000/predict")
      .to_return(status: 200, body: { categoria: "Backend", probabilidade: 0.95, informacoes_adicionais: [] }.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "GET /conteudos" do
    it "lista os conteúdos do usuário" do
      get conteudos_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(conteudo.titulo)
    end

    it "não lista conteúdos de outros usuários" do
      outro_user = create(:user)
      outro = create(:conteudo, user: outro_user, titulo: "Conteúdo de outro usuário")
      get conteudos_path
      expect(response.body).not_to include(outro.titulo)
    end

    it "suporta paginação" do
      create_list(:conteudo, 25, user: user)
      get conteudos_path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
    end

    it "suporta busca por título" do
      get conteudos_path, params: { q: conteudo.titulo[0..10] }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(conteudo.titulo)
    end
  end

  describe "GET /conteudos/:id" do
    it "mostra detalhes do conteúdo" do
      get conteudo_path(conteudo)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(conteudo.titulo)
      expect(response.body).to include(conteudo.categoria) if conteudo.categoria.present?
    end

    it "não mostra badge Groq quando probabilidade > 0" do
      get conteudo_path(conteudo)
      expect(response.body).not_to include("Groq")
    end

    it "mostra badge Groq quando probabilidade é 0 e categoria é válida" do
      groq_conteudo = create(:conteudo, user: user, status: :done, categoria: "Backend", probabilidade: 0.0)
      get conteudo_path(groq_conteudo)
      expect(response.body).to include("Groq")
    end

    it "não mostra badge Groq quando categoria é Desconhecida mesmo com probabilidade 0" do
      desconhecida = create(:conteudo, user: user, status: :done, categoria: "Desconhecida", probabilidade: 0.0)
      get conteudo_path(desconhecida)
      expect(response.body).not_to include("Groq")
    end

    it "retorna 404 para conteúdo de outro usuário" do
      outro = create(:conteudo, user: create(:user))
      get conteudo_path(outro)
      expect(response).to redirect_to(conteudos_path)
    end
  end

  describe "GET /conteudos/new" do
    it "renderiza formulário de novo conteúdo" do
      get new_conteudo_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cadastrar")
    end
  end

  describe "POST /conteudos" do
    let(:valid_params) do
      { conteudo: { titulo: "Novo Conteúdo Tech", texto: "Texto técnico sobre desenvolvimento de software com mais de 10 caracteres." * 3 } }
    end

    it "cria um novo conteúdo (fallback do ML falha, status failed)" do
      expect {
        post conteudos_path, params: valid_params
      }.to change(Conteudo, :count).by(1)
    end

    it "rejeita título curto" do
      post conteudos_path, params: { conteudo: { titulo: "ab", texto: "texto com mais de 10 caracteres para validação aqui" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejeita texto curto" do
      post conteudos_path, params: { conteudo: { titulo: "Título válido", texto: "curto" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "quando não autenticado" do
      it "redireciona para login" do
        post logout_path
        post conteudos_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /conteudos/:id/edit" do
    it "renderiza formulário de edição" do
      get edit_conteudo_path(conteudo)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Editar")
      expect(response.body).to include(conteudo.titulo)
    end

    it "redireciona para conteúdo de outro usuário" do
      outro = create(:conteudo, user: create(:user))
      get edit_conteudo_path(outro)
      expect(response).to redirect_to(conteudos_path)
    end
  end

  describe "PATCH /conteudos/:id" do
    it "atualiza e reclassifica o conteúdo" do
      patch conteudo_path(conteudo), params: { conteudo: { titulo: "Título Atualizado", texto: "Texto atualizado com mais de 10 caracteres para testar" } }
      expect(response).to redirect_to(conteudo_path(conteudo))
      expect(conteudo.reload.titulo).to eq("Título Atualizado")
    end

    it "rejeita título curto" do
      patch conteudo_path(conteudo), params: { conteudo: { titulo: "ab", texto: "texto com mais de 10 caracteres para validação aqui" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "não permite editar conteúdo de outro usuário" do
      outro = create(:conteudo, user: create(:user))
      patch conteudo_path(outro), params: { conteudo: { titulo: "Hacked" } }
      expect(response).to redirect_to(conteudos_path)
    end
  end

  describe "DELETE /conteudos/:id" do
    it "remove o conteúdo" do
      expect {
        delete conteudo_path(conteudo)
      }.to change(Conteudo, :count).by(-1)
      expect(response).to redirect_to(conteudos_path)
    end

    it "não permite remover conteúdo de outro usuário" do
      outro = create(:conteudo, user: create(:user))
      expect {
        delete conteudo_path(outro)
      }.not_to change(Conteudo, :count)
    end
  end
end
