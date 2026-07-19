require "rails_helper"

RSpec.describe "TrustedProxies", type: :request do
  it "honra X-Forwarded-For quando proxy confiável" do
    get health_path, headers: {
      "REMOTE_ADDR" => "10.0.0.1",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4, 10.0.0.1"
    }
    expect(response).to have_http_status(:ok)
  end
end
