require "rails_helper"

RSpec.describe "Api::V1::Conteudos", type: :request do
  let(:user) { create(:user, password: "minha-senha") }
  let!(:conteudo) { create(:conteudo, user: user, status: :done, categoria: "Backend") }

  before do
    # API usa sessão (mesma do web), então precisa logar
    post login_path, params: { email: user.email, password: "minha-senha" }

    # Stub ML Service para evitar WebMock bloqueando
    stub_request(:post, "http://ml:8000/predict")
      .to_return(status: 200, body: { categoria: "Backend", probabilidade: 0.95, informacoes_adicionais: [] }.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "GET /api/v1/conteudos" do
    it "retorna lista paginada de conteúdos" do
      get api_v1_conteudos_path
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("data")
      expect(body).to have_key("meta")
      expect(body["meta"]).to include("current_page", "total_pages", "total_count")
    end

    it "retorna apenas conteúdos do usuário" do
      outro = create(:conteudo, user: create(:user))
      get api_v1_conteudos_path
      ids = response.parsed_body["data"].map { |c| c["id"] }
      expect(ids).to include(conteudo.id)
      expect(ids).not_to include(outro.id)
    end

    it "suporta paginação" do
      create_list(:conteudo, 25, user: user)
      get api_v1_conteudos_path, params: { page: 2, per_page: 5 }
      body = response.parsed_body
      expect(body["meta"]["current_page"]).to eq(2)
      expect(body["meta"]["per_page"]).to eq(5)
    end

    it "respeita limite máximo de per_page" do
      get api_v1_conteudos_path, params: { per_page: 200 }
      expect(response.parsed_body["meta"]["per_page"]).to eq(100)
    end
  end

  describe "GET /api/v1/conteudos/:id" do
    it "retorna detalhes do conteúdo" do
      get api_v1_conteudo_path(conteudo)
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(conteudo.id)
      expect(body["titulo"]).to eq(conteudo.titulo)
    end

    it "retorna 404 para conteúdo inexistente" do
      get api_v1_conteudo_path(99999)
      expect(response).to have_http_status(:not_found)
    end

    it "retorna 401 se não autenticado" do
      post logout_path
      get api_v1_conteudo_path(conteudo)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/conteudos" do
    let(:valid_params) do
      { titulo: "API Content", texto: "Technical text for API testing with enough characters to be valid here now." * 3 }
    end

    it "cria conteúdo via API" do
      expect {
        post api_v1_conteudos_path, params: valid_params
      }.to change(Conteudo, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "retorna erro de validação" do
      post api_v1_conteudos_path, params: { titulo: "ab", texto: "curto" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/conteudos/:id" do
    it "atualiza e reclassifica o conteúdo" do
      patch api_v1_conteudo_path(conteudo), params: { titulo: "API Atualizado", texto: "Texto atualizado pela API com caracteres suficientes." }
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(conteudo.id)
      expect(conteudo.reload.titulo).to eq("API Atualizado")
    end

    it "retorna 404 para conteúdo inexistente" do
      patch api_v1_conteudo_path(99999), params: { titulo: "X" }
      expect(response).to have_http_status(:not_found)
    end

    it "retorna 401 se não autenticado" do
      post logout_path
      patch api_v1_conteudo_path(conteudo), params: { titulo: "X" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/conteudos/:id" do
    it "remove o conteúdo" do
      expect {
        delete api_v1_conteudo_path(conteudo)
      }.to change(Conteudo, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "retorna 404 para conteúdo inexistente" do
      delete api_v1_conteudo_path(99999)
      expect(response).to have_http_status(:not_found)
    end

    it "retorna apenas conteúdos do usuário" do
      outro = create(:conteudo, user: create(:user))
      expect {
        delete api_v1_conteudo_path(outro)
      }.not_to change(Conteudo, :count)
    end
  end

  describe "POST /api/v1/conteudos/:id/reclassify" do
    it "reclassifica conteúdo" do
      post reclassify_api_v1_conteudo_path(conteudo)
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(conteudo.id)
      expect(conteudo.reload.status).to eq("done")
    end

    it "retorna 404 para conteúdo inexistente" do
      post reclassify_api_v1_conteudo_path(99999)
      expect(response).to have_http_status(:not_found)
    end

    it "não permite reclassificar conteúdo de outro usuário" do
      outro = create(:conteudo, user: create(:user))
      post reclassify_api_v1_conteudo_path(outro)
      expect(response).to have_http_status(:not_found)
    end
  end
end
