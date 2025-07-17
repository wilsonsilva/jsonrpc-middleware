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

  procedure(:ping) do
    params do
      # no params
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
    post '/', to: 'jsonrpc#echo', constraints: JSONRPC::MethodConstraint.new('echo')
    post '/', to: 'jsonrpc#ping', constraints: JSONRPC::MethodConstraint.new('ping')
  end
end

# Define the JSONRPC controller
class JsonrpcController < ActionController::Base
  def echo
    render jsonrpc: jsonrpc_request.params
  end

  def ping
    render jsonrpc: 'pong'
  end
end

App.initialize!

run App
