require "rails_helper"

RSpec.describe "Web::Sessions", type: :request do
  let(:user) { create(:user, password: "minha-senha") }

  describe "GET /login" do
    it "renderiza o formulário de login" do
      get login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Entrar")
    end

    it "redireciona para /conteudos se já estiver logado" do
      post login_path, params: { email: user.email, password: "minha-senha" }
      get login_path
      expect(response).to redirect_to(conteudos_path)
    end
  end

  describe "POST /login" do
    it "loga com credenciais válidas" do
      post login_path, params: { email: user.email, password: "minha-senha" }
      expect(response).to redirect_to(conteudos_path)
      follow_redirect!
      expect(response.body).to include(user.nome)
    end

    it "rejeita senha inválida" do
      post login_path, params: { email: user.email, password: "senha-errada" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Email ou senha inválidos")
    end

    it "rejeita email inexistente" do
      post login_path, params: { email: "naoexiste@teste.com", password: "senha" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /logout" do
    it "desloga o usuário" do
      post login_path, params: { email: user.email, password: "minha-senha" }
      post logout_path
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Logout realizado com sucesso.")
    end
  end
end
