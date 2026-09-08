require "rack/test"
require_relative "../app"

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
