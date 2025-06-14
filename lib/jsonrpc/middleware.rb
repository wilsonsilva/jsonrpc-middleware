# frozen_string_literal: true

require 'rack'

module JSONRPC
  # Middleware for JSON-RPC compliance
  class Middleware
    DEFAULT_PATH = '/'

    def initialize(app, options = {})
      @app = app
      @parser = Parser.new
      @validator = Validator.new
      @path = options.fetch(:path, DEFAULT_PATH)
    end

    def call(env)
      @req = Rack::Request.new(env)

      if jsonrpc_request?
        handle_jsonrpc_request
      else
        @app.call(env)
      end
    end

    private

    def jsonrpc_request?
      @req.path == @path && @req.post?
    end

    def handle_jsonrpc_request
      parsed_request = parse_request
      return parsed_request if parsed_request.is_a?(Array) # Early return for parse errors

      validation_result = validate_request(parsed_request)
      return validation_result if validation_result.is_a?(Array) # Early return for validation errors

      # Set parsed request in environment and call app
      store_request_in_env(parsed_request)
      @app.call(@req.env)
    rescue StandardError
      error = InternalError.new(request_id: parsed_request.is_a?(Request) ? parsed_request.id : nil)
      @req.env['jsonrpc.error'] = error
      json_response(200, error.to_response)
    end

    def parse_request
      body = read_request_body
      parsed = @parser.parse(body)

      # Handle batch requests with parse errors separately
      return handle_mixed_batch_errors(parsed) if parsed.is_a?(BatchRequest) && parse_errors?(parsed)

      parsed
    rescue ParseError, InvalidRequestError => e
      @req.env['jsonrpc.error'] = e
      json_response(200, e.to_response)
    end

    def validate_request(parsed_request)
      validation_errors = @validator.validate(parsed_request)

      case validation_errors
      when Array
        handle_batch_validation_errors(parsed_request, validation_errors)
      when Error
        json_response(200, validation_errors.to_response)
      when nil
        nil # No errors, continue processing
      end
    end

    def store_request_in_env(parsed_request)
      case parsed_request
      when Request
        @req.env['jsonrpc.request'] = parsed_request
      when Notification
        @req.env['jsonrpc.notification'] = parsed_request
      when BatchRequest
        @req.env['jsonrpc.batch'] = parsed_request
      end
    end

    # Batch handling methods

    def parse_errors?(batch_request)
      batch_request.requests.any?(Error)
    end

    def handle_mixed_batch_errors(batch_request)
      error_responses = collect_parse_error_responses(batch_request)
      valid_requests = collect_valid_requests(batch_request)

      if valid_requests.any?
        success_responses = process_valid_batch_requests(valid_requests)
        error_responses.concat(success_responses)
      end

      json_response(200, BatchResponse.new(error_responses).to_h)
    end

    def handle_batch_validation_errors(batch_request, validation_errors)
      responses = build_ordered_responses(batch_request, validation_errors)
      valid_requests, indices = extract_valid_requests(batch_request, validation_errors)

      if valid_requests.any?
        success_responses = process_valid_batch_requests(valid_requests)
        merge_success_responses(responses, success_responses, indices)
      end

      json_response(200, BatchResponse.new(responses.compact).to_h)
    end

    def collect_parse_error_responses(batch_request)
      batch_request.requests.filter_map do |item|
        Response.new(id: item.request_id, error: item) if item.is_a?(Error)
      end
    end

    def collect_valid_requests(batch_request)
      batch_request.requests.reject { |item| item.is_a?(Error) }
    end

    def build_ordered_responses(batch_request, validation_errors)
      responses = Array.new(batch_request.requests.size)

      batch_request.requests.each_with_index do |request, index|
        responses[index] = Response.new(id: request.id, error: validation_errors[index]) if validation_errors[index]
      end

      responses
    end

    def extract_valid_requests(batch_request, validation_errors)
      valid_requests = []
      valid_indices = []

      batch_request.requests.each_with_index do |request, index|
        unless validation_errors[index]
          valid_requests << request
          valid_indices << index
        end
      end

      [valid_requests, valid_indices]
    end

    def process_valid_batch_requests(valid_requests)
      valid_batch = BatchRequest.new(valid_requests)

      # For mixed error scenarios, validate the remaining requests
      validation_errors = @validator.validate(valid_batch)
      return [] if validation_errors

      @req.env['jsonrpc.batch'] = valid_batch
      status, _headers, body = @app.call(@req.env)

      return [] unless status == 200 && !body.empty?

      app_responses = JSON.parse(body.join)
      app_responses.map do |resp|
        Response.new(id: resp['id'], result: resp['result'], error: resp['error'])
      end
    end

    def merge_success_responses(responses, success_responses, valid_indices)
      success_responses.each_with_index do |response, app_index|
        original_index = valid_indices[app_index]
        responses[original_index] = response
      end
    end

    # Utility methods

    def json_response(status, body)
      [status, { 'content-type' => 'application/json' }, [body.is_a?(String) ? body : JSON.generate(body)]]
    end

    def read_request_body
      body = @req.env[Rack::RACK_INPUT]
      return unless body

      body_content = body.read
      body.rewind if body.respond_to?(:rewind)
      body_content
    end
  end
end
