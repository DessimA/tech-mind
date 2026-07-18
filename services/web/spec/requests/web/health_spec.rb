require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /health" do
    it "retorna status ok" do
      get health_path
      expect(response).to have_http_status(:ok)
    end

    it "retorna JSON com campos esperados (formato .json)" do
      get health_path, headers: { "Accept" => "application/json" }
      body = response.parsed_body
      expect(body["status"]).to eq("ok")
      expect(body).to have_key("database")
      expect(body).to have_key("uptime")
    end

    it "retorna texto simples para HTML" do
      get health_path
      expect(response.body).to eq("OK")
    end
  end

  describe "GET /v1/health" do
    it "também retorna ok" do
      get "/v1/health"
      expect(response).to have_http_status(:ok)
    end
  end
end
