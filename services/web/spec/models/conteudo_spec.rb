require "rails_helper"

RSpec.describe Conteudo, type: :model do
  subject { build(:conteudo) }

  it "e valido com atributos validos" do
    expect(subject).to be_valid
  end

  it "e invalido sem titulo" do
    subject.titulo = nil
    expect(subject).not_to be_valid
  end

  it "e invalido sem texto" do
    subject.texto = nil
    expect(subject).not_to be_valid
  end

  it "e invalido com titulo muito curto" do
    subject.titulo = "ab"
    expect(subject).not_to be_valid
  end

  it "e invalido com texto muito curto" do
    subject.texto = "curto"
    expect(subject).not_to be_valid
  end

  it "status padrao e pending" do
    user = create(:user)
    conteudo = Conteudo.create!(titulo: "Test", texto: "Texto maior que dez caracteres para validacao passar.", user: user)
    expect(conteudo.status).to eq("pending")
  end

  describe "enums" do
    Conteudo.statuses.each_key do |s|
      it "aceita status #{s}" do
        subject.status = s
        expect(subject).to be_valid
      end
    end
  end
end
