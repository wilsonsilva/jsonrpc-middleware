# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails', '~> 8.0.2'
  gem 'puma', '~> 6.6.0'
  gem 'jsonrpc-middleware', path: '../../', require: 'jsonrpc'
end

require 'rails'
require 'action_controller/railtie'

JSONRPC.configure do |config|
  config.rescue_internal_errors = true # set to +false+ if you want to raise JSONRPC::InternalError manually

  procedure(:echo) do
    params do
      required(:message).filled(:string)
    end
  end
end

# Define the application
class App < Rails::Application
  config.root = __dir__
  config.cache_classes = true
  config.eager_load = true
  config.active_support.deprecation = :stderr
  config.consider_all_requests_local = true
  config.active_support.to_time_preserves_timezone = :zone
  config.logger = nil
  config.hosts.clear

  routes.append do
    post '/', to: 'jsonrpc#handle'
  end
end

# Define the JSONRPC controller
class JsonrpcController < ActionController::Base
  def handle
    if jsonrpc_request?
      result = handle_single(jsonrpc_request)
      render jsonrpc: result
    elsif jsonrpc_notification?
      handle_single(jsonrpc_notification)
      render jsonrpc: nil
    else
      responses = handle_batch(jsonrpc_batch)
      render jsonrpc: responses
    end
  end

  private

  def handle_single(request_or_notification) = request_or_notification.params

  def handle_batch(batch)
    batch.process_each { |request_or_notification| handle_single(request_or_notification) }
  end
end

App.initialize!

run App
