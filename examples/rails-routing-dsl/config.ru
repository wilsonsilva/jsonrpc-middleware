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

  # Define the allowed JSON-RPC methods. Calls to methods absent from this list will return a method not found error.
  procedure 'on'
  procedure 'off'
  procedure 'lights.on'
  procedure 'lights.off'
  procedure 'climate.on'
  procedure 'climate.off'
  procedure 'climate.fan.on'
  procedure 'climate.fan.off'
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
    jsonrpc '/' do
      # Handle batch requests with a dedicated controller
      batch to: 'batch#handle'

      method :on, to: 'main#on'
      method :off, to: 'main#off'

      namespace 'lights' do
        method :on, to: 'lights#on'    # becomes lights.on
        method :off, to: 'lights#off'  # becomes lights.off
      end

      namespace 'climate' do
        method :on, to: 'climate#on'   # becomes climate.on
        method :off, to: 'climate#off' # becomes climate.off

        namespace 'fan' do
          method :on, to: 'fan#on'     # becomes climate.fan.on
          method :off, to: 'fan#off'   # becomes climate.fan.off
        end
      end
    end
  end
end

# Controller for main system operations
class MainController < ActionController::Base
  def on
    render jsonrpc: { device: 'main_system', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'main_system', status: 'off' }
  end
end

# Controller for lights operations
class LightsController < ActionController::Base
  def on
    render jsonrpc: { device: 'lights', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'lights', status: 'off' }
  end
end

# Controller for climate operations
class ClimateController < ActionController::Base
  def on
    render jsonrpc: { device: 'climate_system', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'climate_system', status: 'off' }
  end
end

# Controller for climate fan operations
class FanController < ActionController::Base
  def on
    render jsonrpc: { device: 'fan', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'fan', status: 'off' }
  end
end

# Controller for batch operations
class BatchController < ActionController::Base
  def handle
    # Process each request in the batch and collect results
    results = jsonrpc_batch.process_each do |request_or_notification|
      result = case request_or_notification.method
               when 'on'
                 { device: 'main_system', status: 'on' }
               when 'off'
                 { device: 'main_system', status: 'off' }
               when 'lights.on'
                 { device: 'lights', status: 'on' }
               when 'lights.off'
                 { device: 'lights', status: 'off' }
               when 'climate.on'
                 { device: 'climate_system', status: 'on' }
               when 'climate.off'
                 { device: 'climate_system', status: 'off' }
               when 'climate.fan.on'
                 { device: 'fan', status: 'on' }
               when 'climate.fan.off'
                 { device: 'fan', status: 'off' }
               else
                 { error: 'Unknown method', method: request_or_notification.method }
               end

      result
    end

    render jsonrpc: results
  end
end

App.initialize!

run App
