# frozen_string_literal: true

module JSONRPC
  # JSON-RPC 2.0 Parse Error (-32700)
  #
  # Raised when invalid JSON was received by the server.
  # An error occurred on the server while parsing the JSON text.
  #
  # @example Create a parse error
  #   error = JSONRPC::ParseError.new(data: { details: "Unexpected end of input" })
  #
  class ParseError < Error
    # Creates a new Parse Error with code -32700
    #
    # @api public
    #
    # @example Create a parse error with default message
    #   error = JSONRPC::ParseError.new
    #
    # @example Create a parse error with custom data
    #   error = JSONRPC::ParseError.new(data: { detail: "Unexpected end of input" })
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    #
    def initialize(
      message = 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.',
      data: nil
    )
      super(
        message,
        code: -32_700,
        data: data
      )
    end
  end
end
