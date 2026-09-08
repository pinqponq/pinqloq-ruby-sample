require "sinatra/base"
require "json"

module PinqloqSample
  class App < Sinatra::Base
    SUPPORTED_STATUSES = [200, 400, 401, 404, 500].freeze
    SCENARIO_MESSAGES = {
      200 => "ok",
      400 => "bad request",
      401 => "unauthorized",
      404 => "not found",
      500 => "internal server error"
    }.freeze

    set :public_folder, File.join(__dir__, "public")
    set :host_authorization, permitted_hosts: []

    get "/" do
      send_file File.join(settings.public_folder, "index.html")
    end

    get "/demo/http/:status" do
      status_code = params[:status].to_i
      halt 404, JSON.generate(error: "unsupported status") unless SUPPORTED_STATUSES.include?(status_code)

      content_type :json
      status status_code
      JSON.generate(scenario: status_code, message: SCENARIO_MESSAGES.fetch(status_code))
    end
  end
end
