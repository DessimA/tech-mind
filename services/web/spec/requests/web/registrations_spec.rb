require "rails_helper"

RSpec.describe "Web::Registrations", type: :request do
  describe "GET /register" do
    it "renderiza o formulário de cadastro" do
      get register_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar Conta")
    end
  end

  describe "POST /register" do
    let(:valid_params) do
      { nome: "Novo Usuário", email: "novo@exemplo.com", password: "senha-segura" }
    end

    it "cria um novo usuário" do
      expect {
        post register_path, params: valid_params
      }.to change(User, :count).by(1)
    end

    it "loga automaticamente após cadastro" do
      post register_path, params: valid_params
      expect(response).to redirect_to(conteudos_path)
    end

    it "rejeita senha curta" do
      post register_path, params: valid_params.merge(password: "abc")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("errors.messages.too_short", count: 6))
    end

    it "rejeita email duplicado" do
      create(:user, email: "duplicado@exemplo.com")
      post register_path, params: valid_params.merge(email: "duplicado@exemplo.com")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("errors.messages.taken"))
    end

    it "rejeita nome em branco" do
      post register_path, params: valid_params.merge(nome: "")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("errors.messages.blank"))
    end
  end
end
