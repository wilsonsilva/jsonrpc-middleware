# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'jsonrpc'

# App is a Sinatra::Base subclass that provides JSON-RPC endpoint handling for requests and batches.
class App < Sinatra::Base
  set :host_authorization, permitted_hosts: []
  set :raise_errors, true
  set :show_exceptions, false

  use JSONRPC::Middleware
  helpers JSONRPC::Helpers

  post '/' do
    @env = env # Set the @env instance variable to use the JSONRPC helpers below

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

  def handle_single(request_or_notification)
    params = request_or_notification.params

    case request_or_notification.method
    when 'add'
      addends = params.is_a?(Array) ? params : params['addends'] # Handle positional and named arguments
      addends.sum
    when 'subtract'
      params['minuend'] - params['subtrahend']
    when 'multiply'
      params['multiplicand'] * params['multiplier']
    when 'divide'
      params['dividend'] / params['divisor']
    when 'explode'
      raise 'An internal error has occurred.'
    end
  end

  def handle_batch(batch)
    batch.process_each { |request_or_notification| handle_single(request_or_notification) }
  end
end
