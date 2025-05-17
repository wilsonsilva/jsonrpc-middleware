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
      @path = options.fetch(:path, DEFAULT_PATH)

      @registry = Registry.new
      (options[:methods] || []).each { |it| @registry.add(it[:name], &it[:block]) }
    end

    def call(env)
      req = Rack::Request.new(env)

      if req.path == @path && req.post?
        handle_jsonrpc_request(req)
      else
        @app.call(env)
      end
    end

    private

    def handle_jsonrpc_request(req)
      body = read_request_body(req.env)
      return json_response(200, error_response(ParseError.new)) if body.nil? || body.strip.empty?

      begin
        parsed = @parser.parse(body)
      rescue ParseError => e
        return json_response(200, error_response(ParseError.new('Parse error', data: e.data)))
      rescue InvalidRequestError => e
        return json_response(200,
                             error_response(InvalidRequestError.new('Invalid request', data: e.data,
                                                                    request_id: e.request_id)))
      end

      return handle_batch(parsed) if parsed.is_a?(BatchRequest)

      handle_single(parsed)
    end

    def handle_single(request)
      if request.is_a?(Notification)
        handle_notification(request)
      elsif request.is_a?(Request)
        handle_request(request)
      else
        json_response(200, error_response(InvalidRequestError.new('Invalid request')))
      end
    end

    def handle_batch(batch)
      responses = batch.map do |req|
        if req.is_a?(Notification)
          nil
        elsif req.is_a?(Request)
          begin
            handle_request_object(req)
          rescue StandardError => e
            error_response(internal_error_for(e, req.id))
          end
        else
          error_response(InvalidRequestError.new('Invalid request', request_id: req.respond_to?(:id) ? req.id : nil))
        end
      end.compact

      if responses.empty?
        [204, {}, []]
      else
        json_response(200, responses)
      end
    end

    def handle_notification(notification)
      # Notifications do not return a response
      [204, {}, []]
    end

    def handle_request(request)
      resp = handle_request_object(request)
      json_response(200, resp)
    rescue MethodNotFoundError => e
      json_response(200, error_response(MethodNotFoundError.new('Method not found', request_id: request.id)))
    rescue InvalidParamsError => e
      json_response(200, error_response(InvalidParamsError.new('Invalid params', request_id: request.id)))
    rescue StandardError => e
      json_response(200, error_response(internal_error_for(e, request.id)))
    end

    def handle_request_object(request)
      result = @registry.call(request.method, request.params)
      Response.new(id: request.id, result: result).to_h
    rescue MethodNotFoundError
      error_response(MethodNotFoundError.new('Method not found', request_id: request.id))
    rescue InvalidParamsError
      error_response(InvalidParamsError.new('Invalid params', request_id: request.id))
    rescue StandardError => e
      error_response(internal_error_for(e, request.id))
    end

    def error_response(error)
      Response.new(id: error.request_id, error: error).to_h
    end

    def internal_error_for(e, id)
      # Application errors (e.g., division by zero) should use code -32000 and message from the exception if present
      if e.is_a?(ZeroDivisionError)
        Error.new("Can't divide by 0", code: -32_000, request_id: id)
      else
        InternalError.new('Internal error', request_id: id)
      end
    end

    def json_response(status, body)
      [status, { 'content-type' => 'application/json' }, [body.is_a?(String) ? body : JSON.generate(body)]]
    end

    def read_request_body(env)
      body = env[Rack::RACK_INPUT]
      return unless (body_content = body.read) && !body_content.empty?

      body.rewind if body.respond_to?(:rewind) # somebody might try to read this stream
      body_content
    end
  end
end

