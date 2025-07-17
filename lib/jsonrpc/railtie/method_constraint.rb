# frozen_string_literal: true

module JSONRPC
  # This constraint allows Rails routes to be matched based on the JSON-RPC
  # method name in the request, enabling method-specific routing.
  #
  # @example Using in Rails routes
  #   post '/', to: 'jsonrpc#echo', constraints: JSONRPC::Railtie::MethodConstraint.new('echo')
  #   post '/', to: 'jsonrpc#ping', constraints: JSONRPC::Railtie::MethodConstraint.new('ping')
  #
  # @api private
  #
  class MethodConstraint
    # Initialize a new method constraint
    #
    # @param jsonrpc_method_name [String] The JSON-RPC method name to match against
    #
    def initialize(jsonrpc_method_name)
      @jsonrpc_method_name = jsonrpc_method_name
    end

    # Check if the request matches the configured method name
    #
    # @param request [ActionDispatch::Request] The Rails request object
    # @return [Boolean] true if the JSON-RPC method matches, false otherwise
    #
    def matches?(request)
      jsonrpc_request = request.env['jsonrpc.request']

      return false unless jsonrpc_request

      jsonrpc_request.method == @jsonrpc_method_name
    end
  end
end
