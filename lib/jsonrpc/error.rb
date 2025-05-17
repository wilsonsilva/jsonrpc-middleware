# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Error object
  #
  # When a rpc call encounters an error, the Response Object must contain an Error object
  # with specific properties according to the JSON-RPC 2.0.
  #
  # @example Create an error
  #   error = JSONRPC::Error.new(
  #     code: -32600,
  #     message: "Invalid Request",
  #     data: { detail: "Additional information about the error" }
  #   )
  #
  class Error < StandardError
    # The request identifier (optional for notifications)
    # @return [String, Integer, nil]
    #
    attr_accessor :request_id

    # Error code indicating the error type
    # @return [Integer]
    #
    attr_accessor :code

    # Short description of the error
    # @return [String]
    #
    attr_accessor :message

    # Additional information about the error (optional)
    # @return [Hash, Array, String, Number, Boolean, nil]
    #
    attr_accessor :data

    # Creates a new JSON-RPC 2.0 Error object
    #
    # @param message [String] short description of the error
    # @param code [Integer] a number indicating the error type
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    # @raise [ArgumentError] if code is not an Integer
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
    # @return [Hash] the error as a JSON-compatible Hash
    #
    def to_h
      hash = { code:, message: }
      hash[:data] = data unless data.nil?
      hash
    end

    def to_json(*)
      to_h.to_json(*)
    end

    private

    # Validates that the code is a valid Integer
    #
    # @param code [Integer] the error code
    # @raise [ArgumentError] if code is not an Integer
    #
    def validate_code(code)
      raise ArgumentError, 'Error code must be an Integer' unless code.is_a?(Integer)
    end

    # Validates that the message is a String
    #
    # @param message [String] the error message
    # @raise [ArgumentError] if message is not a String
    #
    def validate_message(message)
      raise ArgumentError, 'Error message must be a String' unless message.is_a?(String)
    end
  end
end
