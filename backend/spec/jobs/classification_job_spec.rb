require "rails_helper"

RSpec.describe ClassificationJob, type: :job do
  let(:conteudo) { Conteudo.create!(titulo: "Ruby on Rails", texto: "Framework web escrito em Ruby para APIs REST") }
  let(:ml_url) { "http://#{ENV.fetch('ML_HOST', 'ml-service')}:#{ENV.fetch('ML_PORT', '8000')}/predict" }

  before do
    stub_request(:post, ml_url)
      .to_return(
        status: 200,
        body: { categoria: "Backend", probabilidade: 0.85, informacoes_adicionais: ["ruby"] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  it "processa e atualiza status para done" do
    ClassificationJob.new.perform(conteudo.id)
    conteudo.reload
    expect(conteudo.status).to eq("done")
    expect(conteudo.categoria).to eq("Backend")
    expect(conteudo.probabilidade).to be_present
  end

  it "marca como failed quando ML retorna erro" do
    stub_request(:post, ml_url).to_return(status: 503)

    expect { ClassificationJob.new.perform(conteudo.id) }
      .to raise_error(ClassificationError, "Modelo ML indisponível")
    conteudo.reload
    expect(conteudo.status).to eq("failed")
  end

  it "nao levanta erro para id inexistente" do
    expect { ClassificationJob.new.perform(99999) }
      .not_to raise_error
  end
end
