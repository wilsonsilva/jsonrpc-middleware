# frozen_string_literal: true

module JSONRPC
  # JSON-RPC 2.0 Method Not Found Error (-32601)
  #
  # Raised when the method does not exist / is not available.
  #
  # @example Create a method not found error
  #   error = JSONRPC::MethodNotFound.new(data: { requested_method: "unknown_method" })
  #
  class MethodNotFoundError < Error
    # Creates a new Method Not Found Error with code -32601
    #
    # @api public
    #
    # @example Create a method not found error
    #   error = JSONRPC::MethodNotFoundError.new
    #
    # @example Create a method not found error with method name
    #   error = JSONRPC::MethodNotFoundError.new(data: { method: "unknown_method" })
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'The requested RPC method does not exist or is not supported.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: -32_601,
        data:,
        request_id:
      )
    end
  end
end
