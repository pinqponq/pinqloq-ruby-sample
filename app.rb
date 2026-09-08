require "sinatra/base"
require "json"
require "pinqloq"

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
    SUPPORTED_LOG_LEVELS = {
      "debug" => Pinqloq::LogLevel::DEBUG,
      "information" => Pinqloq::LogLevel::INFORMATION,
      "warning" => Pinqloq::LogLevel::WARNING,
      "error" => Pinqloq::LogLevel::ERROR,
      "fatal" => Pinqloq::LogLevel::FATAL
    }.freeze
    REDACTION_ENDPOINT_PATH = "/demo/redaction/endpoint"

    set :public_folder, File.join(__dir__, "public")
    set :host_authorization, permitted_hosts: []

    PINQLOQ = if ENV["PINQLOQ_SECRET_KEY"]
      Pinqloq.create(
        secret_key: ENV.fetch("PINQLOQ_SECRET_KEY"),
        api_logs_collection_name: ENV.fetch("PINQLOQ_HTTP_COLLECTION"),
        device_identifier: "ruby-sample"
      )
    end

    if PINQLOQ
      use Pinqloq::Rack::RequestLogging,
          logger: PINQLOQ.logger,
          pinqloq_options: PINQLOQ.options,
          exclude_paths: ["/style.css", "/app.js", "/api/config"],
          redact_fields: ["taxNumber"],
          redact_paths: [REDACTION_ENDPOINT_PATH]

      at_exit { PINQLOQ.shutdown }
    end

    get "/" do
      send_file File.join(settings.public_folder, "index.html")
    end

    get "/api/config" do
      content_type :json
      JSON.generate(
        configured: !PINQLOQ.nil?,
        httpCollection: ENV["PINQLOQ_HTTP_COLLECTION"],
        manualCollection: ENV["PINQLOQ_MANUAL_COLLECTION"]
      )
    end

    get "/demo/http/:status" do
      status_code = params[:status].to_i
      halt 404, JSON.generate(error: "unsupported status") unless SUPPORTED_STATUSES.include?(status_code)

      content_type :json
      status status_code
      JSON.generate(scenario: status_code, message: SCENARIO_MESSAGES.fetch(status_code))
    end

    post "/demo/manual/:level" do
      halt 503, JSON.generate(error: "pinqloq not configured") unless PINQLOQ

      level = SUPPORTED_LOG_LEVELS.fetch(params[:level]) { halt 400, JSON.generate(error: "unsupported level") }

      PINQLOQ.logger.enqueue(
        Pinqloq::LogEntry.new(
          event: "ruby_sample.manual_event",
          device_identifier: "ruby-sample",
          log_level: level,
          log_source_type: Pinqloq::LogSourceType::BACKEND,
          collection_name: ENV.fetch("PINQLOQ_MANUAL_COLLECTION"),
          metadata: { "triggeredFrom" => "test-lab" },
          detail: { "note" => "Synthetic manual event from the Ruby sample test lab." }
        )
      )

      content_type :json
      JSON.generate(status: "queued", level: params[:level])
    end

    post "/demo/redaction/fields" do
      halt 503, JSON.generate(error: "pinqloq not configured") unless PINQLOQ

      payload = JSON.parse(request.body.read)
      content_type :json
      JSON.generate(status: "captured", fields: payload.keys)
    end

    post REDACTION_ENDPOINT_PATH do
      halt 503, JSON.generate(error: "pinqloq not configured") unless PINQLOQ

      payload = JSON.parse(request.body.read)
      content_type :json
      JSON.generate(status: "captured", fields: payload.keys)
    end
  end
end
