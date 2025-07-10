# frozen_string_literal: true

# Define the JSONRPC controller
class JsonrpcController < ApplicationController
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
    batch.flat_map do |request_or_notification|
      result = handle_single(request_or_notification)
      JSONRPC::Response.new(id: request_or_notification.id, result:) if request_or_notification.is_a?(JSONRPC::Request)
    end.compact
  end
end
