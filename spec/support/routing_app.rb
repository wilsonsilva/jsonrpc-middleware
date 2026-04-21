# frozen_string_literal: true

JSONRPC.configure do
  procedure('math.multiply') do
    params do
      required(:multiplicand).filled
      required(:multiplier).filled
    end
  end

  procedure('math.advanced.divide') do
    params do
      required(:dividend).filled(:integer)
      required(:divisor).filled(:integer)
    end

    rule(:divisor) do
      key.failure("can't be 0") if value.zero?
    end
  end

  procedure(:ping)
end

module RoutingApp
  class Application < Rails::Application
    config.eager_load = false
    config.logger = Logger.new(File::NULL)
    config.secret_key_base = 'test-secret-key-base'
    config.hosts.clear

    routes.append do
      jsonrpc '/' do
        batch to: 'routing_batch#handle'

        method :add, to: 'routing_math#add'

        namespace 'math' do
          method :multiply, to: 'routing_math#multiply'

          namespace 'advanced' do
            method :divide, to: 'routing_math#divide'
          end
        end

        method :subtract, to: 'routing_math#subtract'

        method :ping, to: 'routing_api#ping'
      end

      post '/', to: 'routing_notify#handle'
      get '/plain', to: 'routing_plain#show'
    end
  end
end

# rubocop:disable Style/OneClassPerFile
class RoutingMathController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def add
    render jsonrpc: jsonrpc_params['addends'].sum
  end

  def subtract
    render jsonrpc: jsonrpc_params['minuend'] - jsonrpc_params['subtrahend']
  end

  def multiply
    render jsonrpc: jsonrpc_params['multiplicand'] * jsonrpc_params['multiplier']
  end

  def divide
    render jsonrpc: jsonrpc_params['dividend'] / jsonrpc_params['divisor']
  end
end

class RoutingApiController < ActionController::API
  def ping
    render jsonrpc: jsonrpc_request?
  end
end

class RoutingBatchController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def handle
    responses = jsonrpc_batch.process_each do |request_or_notification|
      case request_or_notification.method
      when 'add'
        request_or_notification.params['addends'].sum
      when 'subtract'
        request_or_notification.params['minuend'] - request_or_notification.params['subtrahend']
      when 'ping'
        'pong'
      end
    end

    render jsonrpc: responses
  end
end

class RoutingNotifyController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def handle
    render jsonrpc: nil
  end
end

class RoutingPlainController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    render jsonrpc: { status: 'ok' }
  end
end
# rubocop:enable Style/OneClassPerFile

RoutingApp::Application.initialize!
