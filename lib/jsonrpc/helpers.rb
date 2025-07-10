# frozen_string_literal: true

module JSONRPC
  # Framework-agnostic helpers for JSON-RPC
  module Helpers
    # Extends the including class with ClassMethods when module is included
    #
    # @api public
    #
    # @example Include helpers in a class
    #   class MyController
    #     include JSONRPC::Helpers
    #   end
    #
    # @param base [Class] The class including this module
    #
    # @return [void]
    #
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class methods for registering JSON-RPC procedure handlers
    module ClassMethods
      # Registers a JSON-RPC procedure with the given method name
      #
      # @api public
      #
      # @example Register a procedure
      #   jsonrpc_method('add') do
      #     params do
      #       required(:a).value(:integer)
      #       required(:b).value(:integer)
      #     end
      #   end
      #
      # @param method_name [String, Symbol] the name of the method
      #
      # @yield Block containing the procedure definition
      #
      # @return [Configuration::Procedure] the registered procedure
      #
      def jsonrpc_method(method_name, &)
        Configuration.instance.procedure(method_name, &)
      end
    end

    # Checks if the current request is a batch request
    #
    # @api public
    #
    # @example Check if request is batch
    #   jsonrpc_batch? # => true/false
    #
    # @return [Boolean] true if current request is a batch
    #
    def jsonrpc_batch? = env.key?('jsonrpc.batch')

    # Checks if the current request is a notification
    #
    # @api public
    #
    # @example Check if request is notification
    #   jsonrpc_notification? # => true/false
    #
    # @return [Boolean] true if current request is a notification
    #
    def jsonrpc_notification? = env.key?('jsonrpc.notification')

    # Checks if the current request is a regular request
    #
    # @api public
    #
    # @example Check if request is regular request
    #   jsonrpc_request? # => true/false
    #
    # @return [Boolean] true if current request is a regular request
    #
    def jsonrpc_request? = env.key?('jsonrpc.request')

    # Gets the current JSON-RPC batch request object
    #
    # @api public
    #
    # @example Get current batch
    #   batch = jsonrpc_batch
    #
    # @return [BatchRequest, nil] the current batch request or nil
    #
    def jsonrpc_batch = env['jsonrpc.batch']

    # Gets the current JSON-RPC request object
    #
    # @api public
    #
    # @example Get current request
    #   request = jsonrpc_request
    #
    # @return [Request, nil] the current request or nil
    #
    def jsonrpc_request = env['jsonrpc.request']

    # Gets the current JSON-RPC notification object
    #
    # @api public
    #
    # @example Get current notification
    #   notification = jsonrpc_notification
    #
    # @return [Notification, nil] the current notification or nil
    #
    def jsonrpc_notification = env['jsonrpc.notification']

    # Creates a JSON-RPC response
    #
    # @api public
    #
    # @example Create a successful response
    #   jsonrpc_response(42) # => [200, headers, body]
    #
    # @param result [Object] the result to return
    #
    # @return [Array] Rack response tuple
    #
    def jsonrpc_response(result)
      [200, { 'content-type' => 'application/json' }, [Response.new(id: jsonrpc_request.id, result: result).to_json]]
    end

    # Creates a JSON-RPC batch response
    #
    # @api public
    #
    # @example Create a batch response
    #   jsonrpc_batch_response([response1, response2]) # => [200, headers, body]
    #
    # @param responses [Array] array of responses
    #
    # @return [Array] Rack response tuple
    #
    def jsonrpc_batch_response(responses)
      # If batch contained only notifications, responses will be empty or contain only nils
      return [204, {}, []] if responses.compact.empty?

      [200, { 'content-type' => 'application/json' }, [responses.to_json]]
    end

    # Creates a response for a notification (no content)
    #
    # @api public
    #
    # @example Create notification response
    #   jsonrpc_notification_response # => [204, {}, []]
    #
    # @return [Array] Rack response tuple with 204 status
    #
    def jsonrpc_notification_response
      [204, {}, []]
    end

    # Creates a JSON-RPC error response
    #
    # @api public
    #
    # @example Create error response
    #   error = JSONRPC::Error.new(code: -32600, message: "Invalid Request")
    #   jsonrpc_error(error) # => JSON string
    #
    # @param error [Error] the error object
    #
    # @return [String] JSON-formatted error response
    #
    def jsonrpc_error(error)
      Response.new(id: jsonrpc_request.id, error: error).to_json
    end

    # Gets the current JSON-RPC request params object
    #
    # @api public
    #
    # @example Get request parameters
    #   params = jsonrpc_params # => [1, 2, 3] or {"a": 1, "b": 2}
    #
    # @return [Array, Hash, nil] the request parameters
    #
    def jsonrpc_params
      jsonrpc_request.params
    end

    # Creates a Parse error (-32700) for invalid JSON
    #
    # @api public
    #
    # @example Create parse error
    #   jsonrpc_parse_error # => JSON error response
    #
    # @param data [Object, nil] additional error data
    #
    # @return [String] JSON-formatted error response
    #
    def jsonrpc_parse_error(data: nil)
      jsonrpc_error(ParseError.new(data: data))
    end

    # Creates an Invalid Request error (-32600) for invalid Request objects
    #
    # @api public
    #
    # @example Create invalid request error
    #   jsonrpc_invalid_request_error # => JSON error response
    #
    # @param data [Object, nil] additional error data
    #
    # @return [String] JSON-formatted error response
    #
    def jsonrpc_invalid_request_error(data: nil)
      jsonrpc_error(InvalidRequestError.new(data: data))
    end

    # Creates a Method not found error (-32601) for missing methods
    #
    # @api public
    #
    # @example Create method not found error
    #   jsonrpc_method_not_found_error # => JSON error response
    #
    # @param data [Object, nil] additional error data
    #
    # @return [String] JSON-formatted error response
    #
    def jsonrpc_method_not_found_error(data: nil)
      jsonrpc_error(MethodNotFoundError.new(data: data))
    end

    # Creates an Invalid params error (-32602) for invalid parameters
    #
    # @api public
    #
    # @example Create invalid params error
    #   jsonrpc_invalid_params_error # => JSON error response
    #
    # @param data [Object, nil] additional error data
    #
    # @return [String] JSON-formatted error response
    #
    def jsonrpc_invalid_params_error(data: nil)
      jsonrpc_error(InvalidParamsError.new(data: data))
    end

    # Creates an Internal error (-32603) for server errors
    #
    # @api public
    #
    # @example Create internal error
    #   jsonrpc_internal_error # => JSON error response
    #
    # @param data [Object, nil] additional error data
    #
    # @return [String] JSON-formatted error response
    #
    def jsonrpc_internal_error(data: nil)
      jsonrpc_error(InternalError.new(data: data))
    end

    # Gets the Rack environment hash from @env or the Rails Request
    #
    # @api private
    #
    # @return [Hash] the Rack environment hash
    #
    def env
      @env ||= request.env
    end
  end
end
