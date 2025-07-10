# frozen_string_literal: true

require 'rack'

module JSONRPC
  # Rack middleware for handling JSON-RPC 2.0 requests
  #
  # @api public
  #
  # This middleware intercepts HTTP POST requests at a specified path and processes them
  # as JSON-RPC 2.0 messages. It handles parsing, validation, and error responses according
  # to the JSON-RPC 2.0 specification.
  #
  # @example Basic usage
  #   use JSONRPC::Middleware
  #
  # @example Custom path
  #   use JSONRPC::Middleware, path: '/api/v1/rpc'
  #
  class Middleware
    # Default path for JSON-RPC requests
    #
    # @api public
    #
    # @return [String] The default path '/'
    #
    DEFAULT_PATH = '/'

    # Initializes the JSON-RPC middleware
    #
    # @api public
    #
    # @example Basic initialization
    #   middleware = JSONRPC::Middleware.new(app)
    #
    # @example With custom path
    #   middleware = JSONRPC::Middleware.new(app, path: '/api/jsonrpc')
    #
    # @param app [#call] The Rack application to wrap
    # @param options [Hash] Configuration options
    # @option options [String] :path ('/') The path to handle JSON-RPC requests on
    # @option options [Boolean] :rescue_internal_errors (nil) Override config rescue_internal_errors
    # @option options [Boolean] :log_internal_errors (true) Override config log_internal_errors
    #
    def initialize(app, options = {})
      @app = app
      @parser = Parser.new
      @validator = Validator.new
      @path = options.fetch(:path, DEFAULT_PATH)
      @config = JSONRPC.configuration
      @log_internal_errors = options.fetch(:log_internal_errors, @config.log_internal_errors)
      @rescue_internal_errors = options.fetch(:rescue_internal_errors, @config.rescue_internal_errors)
    end

    # Rack application call method
    #
    # @api public
    #
    # @example Processing a request
    #   status, headers, body = middleware.call(env)
    #
    # @param env [Hash] The Rack environment
    #
    # @return [Array] Rack response tuple [status, headers, body]
    #
    def call(env)
      @req = Rack::Request.new(env)

      if jsonrpc_request?
        handle_jsonrpc_request
      else
        @app.call(env)
      end
    end

    private

    # Determines if the current request should be handled as JSON-RPC
    #
    # @api private
    #
    # @return [Boolean] true if the request matches the configured path and is a POST request
    #
    def jsonrpc_request?
      @req.path == @path && @req.post?
    end

    # Handles a JSON-RPC request through the complete processing pipeline
    #
    # @api private
    #
    # @return [Array] Rack response tuple
    #
    # @raise [StandardError] Catches all errors and converts to Internal Error response
    #
    def handle_jsonrpc_request
      parsed_request = parse_request
      return parsed_request if parsed_request.is_a?(Array) # Early return for parse errors

      if @config.validate_procedure_signatures
        validation_result = validate_request(parsed_request)
        return validation_result if validation_result.is_a?(Array) # Early return for validation errors
      end

      # Set parsed request in environment and call app
      store_request_in_env(parsed_request)
      @app.call(@req.env)
    rescue StandardError => e
      log_internal_error(e) if @log_internal_errors

      data = {}
      data = { class: e.class.name, message: e.message, backtrace: e.backtrace } if @config.render_internal_errors
      error = InternalError.new(request_id: parsed_request.is_a?(Request) ? parsed_request.id : nil, data:)
      @req.env['jsonrpc.error'] = error

      raise e unless @rescue_internal_errors

      json_response(200, error.to_response)
    end

    # Parses the request body into JSON-RPC objects
    #
    # @api private
    #
    # @return [Request, Notification, BatchRequest, Array] Parsed request or error response
    #
    # @raise [ParseError] When JSON parsing fails
    #
    # @raise [InvalidRequestError] When request structure is invalid
    #
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

    # Validates the parsed request using registered procedure definitions
    #
    # @api private
    #
    # @param parsed_request [Request, Notification, BatchRequest] The parsed request to validate
    #
    # @return [Array, nil] Validation error response or nil if valid
    #
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

    # Stores the parsed request in the Rack environment for downstream processing
    #
    # @api private
    #
    # @param parsed_request [Request, Notification, BatchRequest] The request to store
    #
    # @return [void]
    #
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

    # Checks if any requests in a batch contain parse errors
    #
    # @api private
    #
    # @param batch_request [BatchRequest] The batch request to check
    #
    # @return [Boolean] true if any request is an Error object
    #
    def parse_errors?(batch_request)
      batch_request.requests.any?(Error)
    end

    # Handles batch requests that contain a mix of parse errors and valid requests
    #
    # @api private
    #
    # @param batch_request [BatchRequest] The batch request containing mixed errors
    #
    # @return [Array] Rack response tuple with error and success responses
    #
    def handle_mixed_batch_errors(batch_request)
      error_responses = collect_parse_error_responses(batch_request)
      valid_requests = collect_valid_requests(batch_request)

      if valid_requests.any?
        success_responses = process_valid_batch_requests(valid_requests)
        error_responses.concat(success_responses)
      end

      json_response(200, BatchResponse.new(error_responses).to_h)
    end

    # Handles batch requests with validation errors by building appropriate responses
    #
    # @api private
    #
    # @param batch_request [BatchRequest] The batch request with validation errors
    # @param validation_errors [Array] Array of validation errors corresponding to each request
    #
    # @return [Array] Rack response tuple with mixed error and success responses
    #
    def handle_batch_validation_errors(batch_request, validation_errors)
      responses = build_ordered_responses(batch_request, validation_errors)
      valid_requests, indices = extract_valid_requests(batch_request, validation_errors)

      if valid_requests.any?
        success_responses = process_valid_batch_requests(valid_requests)
        merge_success_responses(responses, success_responses, indices)
      end

      json_response(200, BatchResponse.new(responses.compact).to_h)
    end

    # Collects error responses from parse errors in a batch request
    #
    # @api private
    #
    # @param batch_request [BatchRequest] The batch request to process
    #
    # @return [Array<Response>] Array of error responses
    #
    def collect_parse_error_responses(batch_request)
      batch_request.requests.filter_map do |item|
        Response.new(id: item.request_id, error: item) if item.is_a?(Error)
      end
    end

    # Collects valid (non-error) requests from a batch request
    #
    # @api private
    #
    # @param batch_request [BatchRequest] The batch request to process
    #
    # @return [Array<Request, Notification>] Array of valid requests
    #
    def collect_valid_requests(batch_request)
      batch_request.requests.reject { |item| item.is_a?(Error) }
    end

    # Builds ordered array of responses maintaining request order for batch processing
    #
    # @api private
    #
    # @param batch_request [BatchRequest] The original batch request
    # @param validation_errors [Array] Array of validation errors corresponding to each request
    #
    # @return [Array<Response, nil>] Array of responses with nil for valid requests
    #
    def build_ordered_responses(batch_request, validation_errors)
      responses = Array.new(batch_request.requests.size)

      batch_request.requests.each_with_index do |request, index|
        responses[index] = Response.new(id: request.id, error: validation_errors[index]) if validation_errors[index]
      end

      responses
    end

    # Extracts valid requests and their indices from a batch with validation errors
    #
    # @api private
    #
    # @param batch_request [BatchRequest] The batch request to process
    # @param validation_errors [Array] Array of validation errors
    #
    # @return [Array<Array<Request>, Array<Integer>>] Valid requests and their original indices
    #
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

    # Processes valid batch requests by delegating to the application
    #
    # @api private
    #
    # @param valid_requests [Array<Request, Notification>] Valid requests to process
    #
    # @return [Array<Response>] Array of successful responses from the application
    #
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

    # Merges successful responses into their original positions
    #
    # @api private
    #
    # @param responses [Array<Response, nil>] Array of responses with error responses and nils
    # @param success_responses [Array<Response>] Successful responses from the application
    # @param valid_indices [Array<Integer>] Original indices of the valid requests
    #
    # @return [void]
    #
    def merge_success_responses(responses, success_responses, valid_indices)
      success_responses.each_with_index do |response, app_index|
        original_index = valid_indices[app_index]
        responses[original_index] = response
      end
    end

    # Utility methods

    # Creates a JSON HTTP response
    #
    # @api private
    #
    # @param status [Integer] HTTP status code
    # @param body [Hash, String] Response body to serialize as JSON
    #
    # @return [Array] Rack response tuple [status, headers, body]
    #
    def json_response(status, body)
      [status, { 'content-type' => 'application/json' }, [body.is_a?(String) ? body : JSON.generate(body)]]
    end

    # Reads and returns the request body from the Rack environment
    #
    # @api private
    #
    # @return [String, nil] The request body content or nil if no body
    #
    def read_request_body
      body = @req.env[Rack::RACK_INPUT]
      return unless body

      body_content = body.read
      body.rewind if body.respond_to?(:rewind)
      body_content
    end

    # Logs internal errors to stdout with full backtrace
    #
    # @api private
    #
    # @example Log an internal error
    #   log_internal_error(StandardError.new("Something went wrong"))
    #
    # @param error [Exception] The error to log
    #
    # @return [void]
    #
    def log_internal_error(error)
      puts "Internal error: #{error.message}"
      puts error.backtrace.join("\n")
    end
  end
end
