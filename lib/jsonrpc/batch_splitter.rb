# frozen_string_literal: true

module JSONRPC
  # Splits a JSON-RPC batch into individual JSON-RPC requests
  class BatchSplitter
    def initialize(app, options = {})
      @double_encode_json = options[:encode_json] == false
      @app = app
    end

    def call(env)
      return @app.call(env) unless env['PATH_INFO'] == @endpoint && env['REQUEST_METHOD'] == "POST"

      input_requests = read_request_body(env) rescue []
      internal_requests = Array.wrap(input_requests)

      internal_requests = internal_requests.map { |op| internal_response(env, op) }

      [200, {}, [JSON.generate(internal_requests)]]
    end

    private

    def read_request_body(env)
      body = env[Rack::RACK_INPUT]
      return unless body

      body_content = body.read
      body.rewind if body.respond_to?(:rewind)
      body_content
    end

    def internal_response(env, op)
      status, headers, body = @app.call(new_env_from_op(env, op))
      internal_response = {
        status: status,
        headers: headers,
        body: body.join
      }

      if @double_encode_json && headers['content-type'].include?('application/json')
        internal_response[:body] = JSON.parse(internal_response[:body])
      end

      internal_response
    end

    def new_env_from_op(env, op)
      path, query_string = op['url'].split '?'

      op_env = env.dup.merge(
        'REQUEST_METHOD' => op['method'].upcase,
        'PATH_INFO' => path
      )

      add_headers(op, op_env)
      add_get_params(op, op_env, query_string)

      op_env['rack.input'] = StringIO.new(op['body']) unless op['body'].nil?
      op_env
    end

    def add_headers(op, op_env)
      op['headers'] ||= {}

      op['headers'].reject{|k,v| k =~ /^rack/i}.each do |name, value|
        op_env["HTTP_#{name.gsub("-", "_").upcase}"] = value
        op_env[name] = value
      end
    end

    def add_get_params(op, op_env, query_string)
      qs_params = URI.decode_www_form(query_string || "")
      params = op['params'] || []

      op_env['QUERY_STRING'] = URI.encode_www_form(qs_params + params.to_a)
      op_env
    end
  end
end
