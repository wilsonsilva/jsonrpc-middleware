# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Error object
  #
  # @api public
  #
  # When a rpc call encounters an error, the Response Object must contain an Error object
  # with specific properties according to the JSON-RPC 2.0 specification.
  #
  # @example Create an error
  #   error = JSONRPC::Error.new(
  #     "Invalid Request",
  #     code: -32600,
  #     data: { detail: "Additional information about the error" }
  #   )
  #
  class Error < StandardError
    # The request identifier (optional for notifications)
    #
    # @api public
    #
    # @example Get request ID
    #   error.request_id # => "1"
    #
    # @example Set request ID
    #   error.request_id = "2"
    #
    # @return [String, Integer, nil]
    #
    attr_accessor :request_id

    # Error code indicating the error type
    #
    # @api public
    #
    # @example Get error code
    #   error.code # => -32600
    #
    # @example Set error code
    #   error.code = -32601
    #
    # @return [Integer]
    #
    attr_accessor :code

    # Short description of the error
    #
    # @api public
    #
    # @example Get error message
    #   error.message # => "Invalid Request"
    #
    # @example Set error message
    #   error.message = "Method not found"
    #
    # @return [String]
    #
    attr_accessor :message

    # Additional information about the error (optional)
    #
    # @api public
    #
    # @example Get error data
    #   error.data # => { "detail" => "Additional info" }
    #
    # @example Set error data
    #   error.data = { "field" => "invalid" }
    #
    # @return [Hash, Array, String, Number, Boolean, nil]
    #
    attr_accessor :data

    # Creates a new JSON-RPC 2.0 Error object
    #
    # @api public
    #
    # @example Create an error with code and message
    #   error = JSONRPC::Error.new("Invalid Request", code: -32600)
    #
    # @example Create an error with additional data
    #   error = JSONRPC::Error.new("Invalid params", code: -32602, data: { "field" => "missing" })
    #
    # @param message [String] short description of the error
    # @param code [Integer] a number indicating the error type
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    # @raise [ArgumentError] if code is not an Integer
    #
    # @raise [ArgumentError] if message is not a String
    #
    def initialize(message, code:, data: nil, request_id: nil)
      super(message)

      validate_code(code)
      validate_message(message)

      @code = code
      @message = message
      @data = data
      @request_id = request_id
    end

    # Converts the error to a JSON-compatible Hash
    #
    # @api public
    #
    # @example Convert error to hash
    #   error.to_h # => { code: -32600, message: "Invalid Request" }
    #
    # @return [Hash] the error as a JSON-compatible Hash
    #
    def to_h
      hash = { code:, message: }
      hash[:data] = data unless data.nil?
      hash
    end

    # Converts the error to JSON
    #
    # @api public
    #
    # @example Convert error to JSON
    #   error.to_json # => '{"code":-32600,"message":"Invalid Request"}'
    #
    # @return [String] the error as a JSON string
    #
    def to_json(*)
      MultiJson.dump(to_h, *)
    end

    # Converts the error to a complete JSON-RPC response
    #
    # @api public
    #
    # @example Convert error to response
    #   error.to_response # => { jsonrpc: "2.0", error: { code: -32600, message: "Invalid Request" }, id: nil }
    #
    # @return [Hash] a complete JSON-RPC response with this error
    #
    def to_response
      Response.new(id: request_id, error: self).to_h
    end

    private

    # Validates that the code is a valid Integer
    #
    # @api private
    #
    # @param code [Integer] the error code
    #
    # @raise [ArgumentError] if code is not an Integer
    #
    # @return [void]
    #
    def validate_code(code)
      raise ArgumentError, 'Error code must be an Integer' unless code.is_a?(Integer)
    end

    # Validates that the message is a String
    #
    # @api private
    #
    # @param message [String] the error message
    #
    # @raise [ArgumentError] if message is not a String
    #
    # @return [void]
    #
    def validate_message(message)
      raise ArgumentError, 'Error message must be a String' unless message.is_a?(String)
    end
  end
end
