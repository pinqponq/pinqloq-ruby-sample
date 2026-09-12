require "sinatra/base"
require "json"
require "monitor"
require "pinqloq"

module PinqloqSample
  DEVICE_IDENTIFIER = "ruby-sample"
  REDACTION_ENDPOINT_PATH = "/demo/redaction/endpoint"
  EXCLUDED_PATHS = ["/style.css", "/app.js", "/api/config", "/api/session"].freeze

  class SessionStore
    include MonitorMixin

    def initialize
      super()
      @client = nil
      @http_collection = nil
      @manual_collection = nil
    end

    def configure(secret_key:, http_collection:, manual_collection:)
      synchronize do
        previous = @client
        @client = Pinqloq.create(
          secret_key: secret_key,
          api_logs_collection_name: http_collection,
          device_identifier: DEVICE_IDENTIFIER
        )
        @http_collection = http_collection
        @manual_collection = manual_collection
        previous&.shutdown
      end
    end

    def configured?
      synchronize { !@client.nil? }
    end

    def client
      synchronize { @client }
    end

    def http_collection
      synchronize { @http_collection }
    end

    def manual_collection
      synchronize { @manual_collection }
    end

    def shutdown
      synchronize { @client&.shutdown }
    end
  end

  SESSION = SessionStore.new
  at_exit { SESSION.shutdown }

  class DynamicRequestLogging
    def initialize(app)
      @app = app
      @cached_for = nil
      @delegate = nil
    end

    def call(env)
      client = SESSION.client
      return @app.call(env) if client.nil?

      if @cached_for != client.object_id
        @delegate = Pinqloq::Rack::RequestLogging.new(
          @app,
          logger: client.logger,
          pinqloq_options: client.options,
          exclude_paths: EXCLUDED_PATHS,
          redact_fields: ["taxNumber"],
          redact_paths: [REDACTION_ENDPOINT_PATH]
        )
        @cached_for = client.object_id
      end

      @delegate.call(env)
    end
  end

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

    set :public_folder, File.join(__dir__, "public")
    set :host_authorization, permitted_hosts: []

    use DynamicRequestLogging

    get "/" do
      send_file File.join(settings.public_folder, "index.html")
    end

    get "/api/config" do
      content_type :json
      JSON.generate(
        configured: SESSION.configured?,
        httpCollection: SESSION.http_collection,
        manualCollection: SESSION.manual_collection
      )
    end

    post "/api/session" do
      body = JSON.parse(request.body.read) rescue {}
      secret_key = body["secretKey"].to_s.strip
      http_collection = body["httpCollection"].to_s.strip
      manual_collection = body["manualCollection"].to_s.strip

      if secret_key.empty? || http_collection.empty? || manual_collection.empty?
        halt 400, JSON.generate(error: "secretKey, httpCollection and manualCollection are all required")
      end

      if http_collection == manual_collection
        halt 400, JSON.generate(error: "httpCollection and manualCollection must be different")
      end

      SESSION.configure(
        secret_key: secret_key,
        http_collection: http_collection,
        manual_collection: manual_collection
      )

      content_type :json
      JSON.generate(configured: true, httpCollection: http_collection, manualCollection: manual_collection)
    end

    get "/demo/http/:status" do
      status_code = params[:status].to_i
      halt 404, JSON.generate(error: "unsupported status") unless SUPPORTED_STATUSES.include?(status_code)

      content_type :json
      status status_code
      JSON.generate(scenario: status_code, message: SCENARIO_MESSAGES.fetch(status_code))
    end

    post "/demo/manual/:level" do
      client = SESSION.client
      halt 503, JSON.generate(error: "pinqloq not configured") if client.nil?

      level = SUPPORTED_LOG_LEVELS.fetch(params[:level]) { halt 400, JSON.generate(error: "unsupported level") }

      client.enqueue(
        Pinqloq::LogEntry.new(
          event: "ruby_sample.manual_event",
          device_identifier: DEVICE_IDENTIFIER,
          log_level: level,
          log_source_type: Pinqloq::LogSourceType::BACKEND,
          collection_name: SESSION.manual_collection,
          metadata: { "triggeredFrom" => "test-lab" },
          detail: { "note" => "Synthetic manual event from the Ruby sample test lab." }
        )
      )

      content_type :json
      JSON.generate(status: "queued", level: params[:level])
    end

    post "/demo/redaction/fields" do
      halt 503, JSON.generate(error: "pinqloq not configured") unless SESSION.configured?

      payload = JSON.parse(request.body.read)
      content_type :json
      JSON.generate(status: "captured", fields: payload.keys)
    end

    post REDACTION_ENDPOINT_PATH do
      halt 503, JSON.generate(error: "pinqloq not configured") unless SESSION.configured?

      payload = JSON.parse(request.body.read)
      content_type :json
      JSON.generate(status: "captured", fields: payload.keys)
    end
  end
end
