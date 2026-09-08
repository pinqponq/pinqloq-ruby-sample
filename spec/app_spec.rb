require_relative "spec_helper"

RSpec.describe PinqloqSample::App do
  def app
    PinqloqSample::App
  end

  PinqloqSample::App::SUPPORTED_STATUSES.each do |status_code|
    it "returns #{status_code} for /demo/http/#{status_code}" do
      get "/demo/http/#{status_code}"

      expect(last_response.status).to eq(status_code)
      expect(JSON.parse(last_response.body)["scenario"]).to eq(status_code)
    end
  end

  it "rejects an unsupported status" do
    get "/demo/http/999"

    expect(last_response.status).to eq(404)
  end

  it "serves the test lab page at root" do
    get "/"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("pinqloq")
  end

  it "reports whether pinqloq is configured" do
    get "/api/config"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to include("configured")
  end

  it "rejects a manual event when pinqloq is not configured" do
    skip "pinqloq is configured in this environment" if PinqloqSample::App::PINQLOQ

    post "/demo/manual/information"

    expect(last_response.status).to eq(503)
  end
end
