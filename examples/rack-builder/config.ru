require './app'
require 'jsonrpc'

app = Rack::Builder.new do
  use Jason::Middleware, methods: %w[add divide]

  run App.new
end

run app
