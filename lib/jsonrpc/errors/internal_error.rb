# frozen_string_literal: true

module JSONRPC
  # JSON-RPC 2.0 Internal Error (-32603)
  #
  # Raised when there was an internal JSON-RPC error.
  #
  # @example Create an internal error
  #   error = JSONRPC::Errors::InternalError.new(data: { details: "Unexpected server error" })
  #
  class InternalError < Error
    # Creates a new Internal Error with code -32603
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(message = 'Internal JSON-RPC error.', data: nil, request_id: nil)
      super(
        message,
        code: -32_603,
        data:,
        request_id:
      )
    end
  end
end
