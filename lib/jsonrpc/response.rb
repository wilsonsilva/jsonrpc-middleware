# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Response object
  #
  # When a rpc call is made, the Server must reply with a Response, except for notifications.
  # A Response object can contain either a result (for success) or an error (for failure),
  # but never both.
  #
  # @example Create a successful response
  #   response = JSONRPC::Response.new(result: 19, id: 1)
  #
  # @example Create an error response
  #   error = JSONRPC::Error.new(code: -32601, message: "Method not found")
  #   response = JSONRPC::Response.new(error: error, id: 1)
  #
  class Response
    # JSON-RPC protocol version
    # @return [String]
    #
    attr_reader :jsonrpc

    # The result of the method invocation (for success)
    # @return [Object, nil]
    #
    attr_reader :result

    # The error object (for failure)
    # @return [JSONRPC::Error, nil]
    #
    attr_reader :error

    # The request identifier
    # @return [String, Integer, nil]
    #
    attr_reader :id

    # Creates a new JSON-RPC 2.0 Response object
    #
    # @param result [Object, nil] the result of the method invocation (for success)
    # @param error [JSONRPC::Error, nil] the error object (for failure)
    # @param id [String, Integer, nil] the request identifier
    # @raise [ArgumentError] if both result and error are present or both are nil
    # @raise [ArgumentError] if error is present but not a JSONRPC::Error
    # @raise [ArgumentError] if id is not a String, Integer, or nil
    #
    def initialize(id:, result: nil, error: nil)
      @jsonrpc = '2.0'

      validate_result_and_error(result, error)
      validate_id(id)

      @result = result
      @error = error
      @id = id
    end

    # Checks if the response is successful
    #
    # @return [Boolean] true if the response contains a result, false if it contains an error
    #
    def success?
      !@result.nil?
    end

    # Checks if the response is an error
    #
    # @return [Boolean] true if the response contains an error, false if it contains a result
    #
    def error?
      !@error.nil?
    end

    # Converts the response to a JSON-compatible Hash
    #
    # @return [Hash] the response as a JSON-compatible Hash
    #
    def to_h
      hash = {
        jsonrpc: jsonrpc,
        id: id
      }

      if success?
        hash[:result] = result
      else
        hash[:error] = error.to_h
      end

      hash
    end

    def to_json(*)
      to_h.to_json(*)
    end

    private

    # Validates that exactly one of result or error is present
    #
    # @param result [Object, nil] the result
    # @param error [JSONRPC::Error, nil] the error
    # @raise [ArgumentError] if both result and error are present or both are nil
    # @raise [ArgumentError] if error is present but not a JSONRPC::Error
    #
    def validate_result_and_error(result, error)
      raise ArgumentError, 'Either result or error must be present' if result.nil? && error.nil?

      raise ArgumentError, 'Response cannot contain both result and error' if !result.nil? && !error.nil?

      return unless !error.nil? && !error.is_a?(Error)

      raise ArgumentError, 'Error must be a JSONRPC::Error'
    end

    # Validates that the id meets JSON-RPC 2.0 requirements
    #
    # @param id [String, Integer, nil] the request identifier
    # @raise [ArgumentError] if id is not a String, Integer, or nil
    #
    def validate_id(id)
      return if id.nil?

      raise ArgumentError, 'ID must be a String, Integer, or nil' unless id.is_a?(String) || id.is_a?(Integer)

      return unless id.is_a?(Integer)

      raise ArgumentError, 'ID should not contain fractional parts'
    end
  end
end
