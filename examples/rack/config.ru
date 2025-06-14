# frozen_string_literal: true

require 'jsonrpc'
require '../procedures'
require './app'

# Rack builder syntax
#
app = Rack::Builder.new do
  use JSONRPC::Middleware
  run App.new
end

run app

# Rack classic syntax
#
# use JSONRPC::Middleware
# run App.new
