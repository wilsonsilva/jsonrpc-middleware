# frozen_string_literal: true

module JSONRPC
  # JSON-RPC 2.0 Invalid Request Error (-32600)
  #
  # Raised when the JSON sent is not a valid Request object.
  #
  # @example Create an invalid request error
  #   error = JSONRPC::InvalidRequestError.new(data: { details: "Method must be a string" })
  #
  class InvalidRequestError < Error
    # Creates a new Invalid Request Error with code -32600
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: -32_600,
        data:,
        request_id:
      )
    end
  end
end
