require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validações" do
    it "é válido com atributos válidos" do
      expect(user).to be_valid
    end

    it "requer nome" do
      user.nome = nil
      expect(user).not_to be_valid
      expect(user.errors[:nome]).to include(I18n.t("errors.messages.blank"))
    end

    it "limita nome a 100 caracteres" do
      user.nome = "a" * 101
      expect(user).not_to be_valid
    end

    it "requer email" do
      user.email = nil
      expect(user).not_to be_valid
    end

    it "valida formato do email" do
      user.email = "invalido"
      expect(user).not_to be_valid
    end

    it "requer email único" do
      create(:user, email: "duplicado@teste.com")
      user.email = "duplicado@teste.com"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include(I18n.t("errors.messages.taken"))
    end

    it "requer senha com mínimo 6 caracteres" do
      user.password = "abc12"
      expect(user).not_to be_valid
    end

    it "aceita senha com 6+ caracteres" do
      user.password = "abcdef"
      expect(user).to be_valid
    end

    it "não valida senha em atualizações sem mudança de senha" do
      user.save!
      user.nome = "Nome Atualizado"
      expect(user).to be_valid
    end
  end

  describe "bcrypt" do
    it "hashes a senha com bcrypt" do
      user.password = "minha-senha-segura"
      user.save!
      expect(user.password_digest).to start_with("$2a$") # bcrypt hash prefix
    end

    it "autentica com senha correta" do
      user.password = "minha-senha-segura"
      user.save!
      expect(user.authenticate("minha-senha-segura")).to be_truthy
    end

    it "rejeita senha incorreta" do
      user.password = "minha-senha-segura"
      user.save!
      expect(user.authenticate("senha-errada")).to be_falsey
    end
  end

  describe "associações" do
    it "tem muitos conteúdos" do
      assoc = described_class.reflect_on_association(:conteudos)
      expect(assoc.macro).to eq(:has_many)
    end

    it "destrói conteúdos em cascata" do
      user = create(:user)
      create(:conteudo, user: user)
      expect { user.destroy }.to change(Conteudo, :count).by(-1)
    end
  end
end
