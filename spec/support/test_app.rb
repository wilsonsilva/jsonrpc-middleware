# frozen_string_literal: true

require 'rack'
require 'json'

class TestApp
  class InvalidParamsError < StandardError; end

  def initialize
    @methods = {}
    setup_rpc_methods
  end

  def call(env)
    req = Rack::Request.new(env)

    # Only process POST requests to the JSON-RPC endpoint
    if req.post? && req.path == '/jsonrpc'
      handle_jsonrpc(req)
    else
      [404, { 'content-type' => 'text/plain' }, ['Not Found']]
    end
  rescue StandardError => e
    if ENV['DEBUG']
      puts "Error: #{e.message}"
      puts e.backtrace.join("\n")
    end

    [
      500,
      { 'content-type' => 'application/json' },
      [JSON.generate(jsonrpc_error_response(-32_603, 'Internal error', nil).to_json)]
    ]
  end

  private

  def handle_jsonrpc(req)
    # Parse JSON request
    begin
      payload = read_request_body(req.env)

      if payload.nil?
        return [200, { 'content-type' => 'application/json' },
                [jsonrpc_error_response(-32_700, 'Parse error', nil, is_notification: true).to_json]]
      end
    rescue JSON::ParserError
      return [200, { 'content-type' => 'application/json' },
              [jsonrpc_error_response(-32_700, 'Parse error', nil, is_notification: true).to_json]]
    end

    # Handle batch requests
    if payload.is_a?(Array)
      if payload.empty?
        return [200, { 'content-type' => 'application/json' },
                [jsonrpc_error_response(-32_600, 'Invalid request', nil, batch: true).to_json]]
      end

      results = payload.map { |request| process_request(request, batch: true) }
      # Remove nils (notifications) from results
      responses = results.compact.select { |r| r.is_a?(Hash) && r.key?('id') }

      return [204, {}, []] if responses.empty?

      return [200, { 'content-type' => 'application/json' }, [JSON.generate(responses)]]

    end

    # Handle single request
    result = process_request(payload)
    # Only treat as notification if the 'id' key is missing entirely
    is_notification = payload.is_a?(Hash) && !payload.key?('id')
    if is_notification
      [204, {}, []]
    else
      [200, { 'content-type' => 'application/json' }, [JSON.generate(result)]]
    end
  end

  def read_request_body(env)
    body = env[Rack::RACK_INPUT]
    return unless (body_content = body.read) && !body_content.empty?

    body.rewind if body.respond_to?(:rewind) # somebody might try to read this stream
    JSON.parse(body_content)
  end

  def process_request(request, batch: false)
    # Validate JSON-RPC request
    unless request.is_a?(Hash) && request['jsonrpc'] == '2.0' && request['method'].is_a?(String)
      is_notification = request.is_a?(Hash) && !request.key?('id')
      request_id = request.is_a?(Hash) && request.key?('id') ? request['id'] : nil
      return jsonrpc_error_response(-32_600, 'Invalid request', request_id, batch: batch,
                                                                            is_notification: is_notification)
    end

    method_name = request['method']
    params = request['params'] || {}
    id = request['id']
    is_notification = !request.key?('id')

    # Check if method exists
    unless @methods.key?(method_name)
      return jsonrpc_error_response(-32_601, 'Method not found', id,
                                    is_notification: is_notification)
    end

    # If notification, do not return a response object
    return nil if is_notification

    # Execute method
    begin
      result = @methods[method_name].call(params)
      {
        'jsonrpc' => '2.0',
        'result' => result,
        'id' => id
      }
    rescue ZeroDivisionError
      jsonrpc_error_response(-32_000, "Can't divide by 0", id, is_notification: is_notification)
    rescue InvalidParamsError
      jsonrpc_error_response(-32_602, 'Invalid params', id, is_notification: is_notification)
    rescue StandardError => e
      if ENV['DEBUG']
        puts "Error in method '#{method_name}': #{e.message}"
        puts e.backtrace.join("\n")
      end

      jsonrpc_error_response(-32_603, 'Internal error', id, is_notification: is_notification)
    end
  end

  def jsonrpc_error_response(code, message, id, batch: false, is_notification: false)
    response = {
      'jsonrpc' => '2.0',
      'error' => {
        'code' => code,
        'message' => message
      },
      'id' => id
    }

    # Only omit 'id' if this is a notification (no id key at all) and not a batch
    response.delete('id') if is_notification && !batch

    response
  end

  def setup_rpc_methods
    @methods['divide'] = lambda { |params|
      raise InvalidParamsError unless params.is_a?(Hash)
      raise InvalidParamsError if !params['dividend'].is_a?(Numeric) || !params['divisor'].is_a?(Numeric)

      params['dividend'] / params['divisor']
    }

    @methods['sum'] = lambda { |params|
      raise InvalidParamsError unless params.is_a?(Array)

      params.sum
    }
  end
end
