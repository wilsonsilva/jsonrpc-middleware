# frozen_string_literal: true

require 'rack'
require 'jsonrpc'

class TestApp
  include JSONRPC::Helpers

  def call(env)
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
      raise 'Internal JSON-RPC error.'
    end
  end

  def handle_batch(batch)
    batch.process_each { |request_or_notification| handle_single(request_or_notification) }
  end
end

JSONRPC.configure do
  procedure(:add, allow_positional_arguments: true) do
    params do
      required(:addends).filled(:array)
      required(:addends).value(:array).each(type?: Numeric)
    end

    rule(:addends) do
      key.failure('must contain at least one addend') if value.empty?
    end
  end

  procedure(:subtract) do
    params do
      required(:minuend).filled(:integer)
      required(:subtrahend).filled(:integer)
    end
  end

  procedure(:multiply) do
    params do
      required(:multiplicand).filled
      required(:multiplier).filled
    end

    rule(:multiplicand) do
      key.failure('must be a number') unless value.is_a?(Numeric)
    end

    rule(:multiplier) do
      key.failure('must be a number') unless value.is_a?(Numeric)
    end
  end

  procedure(:divide) do
    params do
      required(:dividend).filled(:integer)
      required(:divisor).filled(:integer)
    end

    rule(:divisor) do
      key.failure("can't be 0") if value.zero?
    end
  end

  # Used only to test internal server errors
  procedure(:explode) do
    params do
      # No params
    end
  end
end
