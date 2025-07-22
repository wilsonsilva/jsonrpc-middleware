# frozen_string_literal: true

module JSONRPC
  # This constraint allows Rails routes to be matched based on JSON-RPC
  # batch requests, enabling batch-specific routing to dedicated controllers.
  #
  # @example Using in Rails routes
  #   post '/', to: 'jsonrpc#handle_batch', constraints: JSONRPC::BatchConstraint.new
  #
  # @api private
  #
  class BatchConstraint
    # Check if the request is a JSON-RPC batch request
    #
    # @param request [ActionDispatch::Request] The Rails request object
    # @return [Boolean] true if the request is a batch request, false otherwise
    #
    def matches?(request)
      jsonrpc_batch = request.env['jsonrpc.batch']

      # Return true if we have a batch request in the environment
      !jsonrpc_batch.nil?
    end
  end
end
