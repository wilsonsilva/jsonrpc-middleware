# frozen_string_literal: true

module JSONRPC
  # Framework-agnostic helpers for JSON-RPC
  module Helpers
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class methods for registering JSON-RPC procedure handlers
    module ClassMethods
      def jsonrpc_method(method_name, &)
        Configuration.instance.procedure(method_name, &)
      end
    end

    def jsonrpc_batch? = @env.key?('jsonrpc.batch')
    def jsonrpc_notification? = @env.key?('jsonrpc.notification')
    def jsonrpc_request? = @env.key?('jsonrpc.request')

    # Get the current JSON-RPC request object
    def jsonrpc_batch = @env['jsonrpc.batch']
    def jsonrpc_request = @env['jsonrpc.request']
    def jsonrpc_notification = @env['jsonrpc.notification']

    # Create a JSON-RPC response
    def jsonrpc_response(result)
      [200, { 'content-type' => 'application/json' }, [Response.new(id: jsonrpc_request.id, result: result).to_json]]
    end

    # Create a JSON-RPC response
    def jsonrpc_batch_response(responses)
      # If batch contained only notifications, responses will be empty or contain only nils
      return [204, {}, []] if responses.compact.empty?

      [200, { 'content-type' => 'application/json' }, [responses.to_json]]
    end

    def jsonrpc_notification_response
      [204, {}, []]
    end

    # Create a JSON-RPC error response
    def jsonrpc_error(error)
      Response.new(id: jsonrpc_request.id, error: error).to_json
    end

    # Get the current JSON-RPC request params object
    def jsonrpc_params
      jsonrpc_request.params
    end

    # Create a Parse error (-32700)
    # Used when invalid JSON was received by the server
    def jsonrpc_parse_error(data: nil)
      jsonrpc_error(ParseError.new(data: data))
    end

    # Create an Invalid Request error (-32600)
    # Used when the JSON sent is not a valid Request object
    def jsonrpc_invalid_request_error(data: nil)
      jsonrpc_error(InvalidRequestError.new(data: data))
    end

    # Create a Method not found error (-32601)
    # Used when the method does not exist / is not available
    def jsonrpc_method_not_found_error(data: nil)
      jsonrpc_error(MethodNotFoundError.new(data: data))
    end

    # Create an Invalid params error (-32602)
    # Used when invalid method parameter(s) were received
    def jsonrpc_invalid_params_error(data: nil)
      jsonrpc_error(InvalidParamsError.new(data: data))
    end

    # Create an Internal error (-32603)
    # Used for implementation-defined server errors
    def jsonrpc_internal_error(data: nil)
      jsonrpc_error(InternalError.new(data: data))
    end
  end
end
