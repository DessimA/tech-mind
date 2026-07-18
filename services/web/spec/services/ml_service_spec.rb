require "rails_helper"

RSpec.describe MlService do
  describe "#call" do
    let(:texto) { "Artigo sobre deploy automatizado com Docker e Kubernetes" }

    subject(:service) { described_class.new(texto) }

    context "quando o ML responde com sucesso" do
      before do
        stub_request(:post, "http://ml:8000/predict")
          .with(body: { texto: texto }.to_json)
          .to_return(
            status: 200,
            body: {
              categoria: "DevOps",
              probabilidade: 0.95,
              informacoes_adicionais: ["docker", "kubernetes", "deploy"]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "retorna Response com success? true e dados parseados" do
        result = service.call
        expect(result).to be_success
        expect(result.data["categoria"]).to eq("DevOps")
        expect(result.data["probabilidade"]).to eq(0.95)
        expect(result.data["informacoes_adicionais"]).to match_array(["docker", "kubernetes", "deploy"])
      end
    end

    context "quando o ML retorna HTTP nao-200" do
      before do
        stub_request(:post, "http://ml:8000/predict")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "retorna Response com success? false e mensagem de erro" do
        result = service.call
        expect(result).not_to be_success
        expect(result.error).to include("500")
      end
    end

    context "quando a conexao eh recusada" do
      before do
        stub_request(:post, "http://ml:8000/predict")
          .to_raise(Errno::ECONNREFUSED)
      end

      it "retorna Response com success? false e loga warning" do
        expect(Rails.logger).to receive(:warn).with(/ECONNREFUSED/)
        result = service.call
        expect(result).not_to be_success
        expect(result.error).to include("ECONNREFUSED")
      end
    end

    context "quando ocorre timeout de leitura" do
      before do
        stub_request(:post, "http://ml:8000/predict")
          .to_raise(Net::ReadTimeout)
      end

      it "retorna Response com success? false e loga warning" do
        expect(Rails.logger).to receive(:warn).with(/ReadTimeout/)
        result = service.call
        expect(result).not_to be_success
        expect(result.error).to include("ReadTimeout")
      end
    end

    context "quando ocorre timeout de conexao" do
      before do
        stub_request(:post, "http://ml:8000/predict")
          .to_raise(Net::OpenTimeout)
      end

      it "retorna Response com success? false e loga warning" do
        expect(Rails.logger).to receive(:warn).with(/OpenTimeout/)
        result = service.call
        expect(result).not_to be_success
        expect(result.error).to include("OpenTimeout")
      end
    end

    context "com host e porta customizados" do
      let(:custom_host) { "ml-custom" }
      let(:custom_port) { "9000" }

      subject(:service) { described_class.new(texto, host: custom_host, port: custom_port) }

      before do
        stub_request(:post, "http://ml-custom:9000/predict")
          .to_return(
            status: 200,
            body: { categoria: "Backend" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "faz requisicao para o host/port informado" do
        result = service.call
        expect(result).to be_success
        expect(result.data["categoria"]).to eq("Backend")
      end
    end

    context "com texto em branco" do
      let(:texto) { "   " }

      before do
        stub_request(:post, "http://ml:8000/predict")
          .with(body: { texto: "" }.to_json)
          .to_return(
            status: 200,
            body: { categoria: "Outros" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "strip e envia texto vazio para o ML" do
        result = service.call
        expect(result).to be_success
      end
    end
  end

  describe "Response struct" do
    subject(:response) { described_class::Response.new(success?: true, data: { "cat" => "Backend" }) }

    it "responde a success? e data" do
      expect(response.success?).to be true
      expect(response.data).to eq({ "cat" => "Backend" })
    end
  end
end
