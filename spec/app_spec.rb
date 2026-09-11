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

  it "reports the connection state without leaking a secret key" do
    get "/api/config"

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body).to include("configured")
    expect(body).not_to include("secretKey")
  end

  it "rejects a manual event before a session is configured" do
    skip "a session is configured in this environment" if PinqloqSample::SESSION.configured?

    post "/demo/manual/information"

    expect(last_response.status).to eq(503)
  end

  it "rejects a session with missing fields" do
    post "/api/session", JSON.generate(secretKey: "", httpCollection: "a", manualCollection: "b"),
         { "CONTENT_TYPE" => "application/json" }

    expect(last_response.status).to eq(400)
  end

  it "rejects a session whose collections are identical" do
    post "/api/session", JSON.generate(secretKey: "lgl_x", httpCollection: "same", manualCollection: "same"),
         { "CONTENT_TYPE" => "application/json" }

    expect(last_response.status).to eq(400)
  end
end
