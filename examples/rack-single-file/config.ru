# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'jsonrpc-middleware', path: '../..', require: 'jsonrpc'
  gem 'puma'
  gem 'rack'
  gem 'rackup'
end

JSONRPC.configure do
  procedure(:echo) do
    params do
      required(:message).filled(:string)
    end
  end
end

# App is a Rack app that handles JSON-RPC requests, notifications, and batches using JSONRPC::Helpers.
class App
  include JSONRPC::Helpers

  def call(env)
    @env = env

    if jsonrpc_request?
      result = handle_single(jsonrpc_request)
      jsonrpc_response(result)
    elsif jsonrpc_notification?
      handle_single(jsonrpc_notification)
      jsonrpc_notification_response
    else
      responses = handle_batch(jsonrpc_batch)
      jsonrpc_batch_response(responses)
    end
  end

  private

  def handle_single(request_or_notification) = request_or_notification.params

  def handle_batch(batch)
    batch.process_each { |request_or_notification| handle_single(request_or_notification) }
  end
end

use JSONRPC::Middleware
run App.new
