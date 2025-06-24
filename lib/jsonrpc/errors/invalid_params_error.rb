# frozen_string_literal: true

module JSONRPC
  # JSON-RPC 2.0 Invalid Params Error (-32602)
  #
  # Raised when invalid method parameter(s) were provided.
  #
  # @example Create an invalid params error
  #   error = JSONRPC::InvalidParamsError.new(data: { details: "Expected array of integers" })
  #
  class InvalidParamsError < Error
    # Creates a new Invalid Params Error with code -32602
    #
    # @api public
    #
    # @example Create an invalid params error
    #   error = JSONRPC::InvalidParamsError.new
    #
    # @example Create an invalid params error with validation details
    #   error = JSONRPC::InvalidParamsError.new(data: { errors: ["param a is required"] })
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'Invalid method parameter(s).',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: -32_602,
        data:,
        request_id:
      )
    end
  end
end
