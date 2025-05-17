# frozen_string_literal: true

require 'rack'

module JSONRPC
  # Middleware for JSON-RPC compliance
  class Middleware
    DEFAULT_PATH = '/'

    def initialize(app, options = {})
      @app = app
      @options = options
      @parser = Parser.new
      @validator = Validator.new
      @path = options.fetch(:path, DEFAULT_PATH)
    end

    def call(env)
      @env = env
      @req = Rack::Request.new(env)

      if @req.path == @path && @req.post?
        handle_jsonrpc_request(@req)
      else
        @app.call(env)
      end
    end

    private

    def handle_jsonrpc_request(req)
      body = read_request_body(req.env)

      begin
        parsed = @parser.parse(body)

        case parsed
        when Request
          req.env['jsonrpc.request'] = parsed
        when Notification
          req.env['jsonrpc.notification'] = parsed
        when BatchRequest
          # Check if the batch contains any errors from parsing
          return handle_batch_with_parse_errors(parsed) if batch_has_parse_errors?(parsed)

          req.env['jsonrpc.batch'] = parsed
        end
      rescue ParseError, InvalidRequestError => e
        req.env['jsonrpc.error'] = e
        # These errors must be returned immediately per JSON-RPC spec
        return json_response(200, e.to_response)
      end

      validation_errors = @validator.validate(parsed) #if JSONRPC.configuration.validate_procedure_signatures

      return json_response(200, validation_errors.to_response) if validation_errors

      @app.call(req.env)
    end

    def batch_has_parse_errors?(batch_request)
      batch_request.requests.any? { |item| item.is_a?(Error) }
    end

    def handle_batch_with_parse_errors(batch_request)
      responses = []
      valid_requests = []

      # Separate errors from valid requests
      batch_request.requests.each do |item|
        if item.is_a?(Error)
          responses << Response.new(id: item.request_id, error: item)
        else
          valid_requests << item
        end
      end

      # Process valid requests if any exist
      unless valid_requests.empty?
        valid_batch = BatchRequest.new(valid_requests)

        # Validate the valid requests
        validation_errors = @validator.validate(valid_batch)

        if validation_errors.nil?
          # Set up environment for processing valid requests
          @req.env['jsonrpc.batch'] = valid_batch

          # Call the application to process valid requests
          status, _headers, body = @app.call(@req.env)

          # Parse the response from the application
          if status == 200 && !body.empty?
            app_responses = JSON.parse(body.join)
            responses.concat(app_responses.map { |resp| Response.new(id: resp['id'], result: resp['result']) })
          end
        elsif validation_errors.is_a?(Array)
          # Add validation errors to responses
          validation_errors.each { |error| responses << Response.new(id: error.request_id, error: error) }
        else
          responses << Response.new(id: validation_errors.request_id, error: validation_errors)
        end
      end

      # Return all responses (errors and successful ones)
      batch_response = BatchResponse.new(responses)
      json_response(200, batch_response.to_h)
    end

    def json_response(status, body)
      [status, { 'content-type' => 'application/json' }, [body.is_a?(String) ? body : JSON.generate(body)]]
    end

    def read_request_body(env)
      body = env[Rack::RACK_INPUT]
      return unless body

      body_content = body.read
      body.rewind if body.respond_to?(:rewind)
      body_content
    end
  end
end
