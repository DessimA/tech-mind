require "rails_helper"

RSpec.describe "V1::Conteudos", type: :request do
  let(:valid_params) { { titulo: "Introducao ao Docker", texto: "Guia completo sobre containers Docker e orquestracao com Kubernetes" } }

  describe "GET /v1/conteudos" do
    let!(:conteudo) { Conteudo.create!(titulo: "Ruby on Rails", texto: "Framework web escrito em Ruby") }

    it "retorna lista paginada" do
      get "/v1/conteudos"
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"]).to be_an(Array)
      expect(body["meta"]).to include("current_page", "total_pages", "total_count")
    end

    it "retorna dados no formato esperado" do
      get "/v1/conteudos"
      item = response.parsed_body["data"].first
      expect(item).to include("id", "titulo", "categoria", "status", "created_at")
    end

    it "filtra por q" do
      get "/v1/conteudos", params: { q: "Ruby" }
      ids = response.parsed_body["data"].map { |c| c["id"] }
      expect(ids).to include(conteudo.id)
    end

    it "filtro sem match retorna vazio" do
      get "/v1/conteudos", params: { q: "zzzzzzz" }
      expect(response.parsed_body["data"]).to be_empty
    end
  end

  describe "GET /v1/conteudos/:id" do
    let!(:conteudo) { Conteudo.create!(titulo: "Ruby on Rails", texto: "Framework web escrito em Ruby", status: :done) }

    it "retorna o conteudo" do
      get "/v1/conteudos/#{conteudo.id}"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["titulo"]).to eq("Ruby on Rails")
    end

    it "retorna 404 para id inexistente" do
      get "/v1/conteudos/99999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /v1/conteudos" do
    it "cria conteudo com status pending" do
      post "/v1/conteudos", params: valid_params
      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["status"]).to eq("pending")
      expect(body["titulo"]).to eq("Introducao ao Docker")
    end

    it "rejeita titulo vazio" do
      post "/v1/conteudos", params: { titulo: "", texto: "valido" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejeita texto curto" do
      post "/v1/conteudos", params: { titulo: "valido", texto: "curto" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejeita titulo muito curto" do
      post "/v1/conteudos", params: { titulo: "ab", texto: "texto valido para teste" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "enfileira job de classificacao" do
      expect { post "/v1/conteudos", params: valid_params }
        .to change(ClassificationJob.jobs, :size).by(1)
    end
  end

  describe "GET /v1/health" do
    it "retorna health check" do
      get "/v1/health"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("ok")
    end

    it "inclui status do banco" do
      get "/v1/health"
      expect(response.parsed_body).to include("database" => "ok")
    end

    it "inclui status do sidekiq" do
      get "/v1/health"
      expect(response.parsed_body).to include("sidekiq" => "ok")
    end
  end
end
