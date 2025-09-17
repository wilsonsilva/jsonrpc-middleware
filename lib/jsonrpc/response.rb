# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Response object
  #
  # @api public
  #
  # Represents the outcome of a method invocation, either containing a result for
  # successful calls or an error for failed ones. This follows the JSON-RPC 2.0 specification.
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
  class Response < Dry::Struct
    transform_keys(&:to_sym)

    # JSON-RPC protocol version
    #
    # @api public
    #
    # @example
    #   response.jsonrpc # => "2.0"
    #
    # @return [String]
    #
    attribute :jsonrpc, Types::String.default('2.0')

    # The result of the method invocation (for success)
    #
    # @api public
    #
    # @example
    #   response.result # => 42
    #
    # @return [Object, nil]
    #
    attribute? :result, Types::Any

    # The error object (for failure)
    #
    # @api public
    #
    # @example
    #   response.error # => #<JSONRPC::Error...>
    #
    # @return [JSONRPC::Error, nil]
    #
    attribute? :error, Types.Instance(JSONRPC::Error).optional

    # The request identifier
    #
    # @api public
    #
    # @example
    #   response.id # => 1
    #
    # @return [String, Integer, nil]
    #
    attribute? :id, Types::String | Types::Integer | Types::Nil

    # Creates a new JSON-RPC 2.0 Response object
    #
    # @api public
    #
    # @example Create a successful response
    #   JSONRPC::Response.new(id: 1, result: 42)
    #
    # @example Create an error response
    #   error = JSONRPC::Error.new("Method not found", code: -32601)
    #   JSONRPC::Response.new(id: 1, error: error)
    #
    # @param result [Object, nil] the result of the method invocation (for success)
    # @param error [JSONRPC::Error, nil] the error object (for failure)
    # @param id [String, Integer, nil] the request identifier
    #
    # @raise [ArgumentError] if both result and error are present or both are nil
    #
    # @raise [ArgumentError] if error is present but not a JSONRPC::Error
    #
    # @raise [ArgumentError] if id is not a String, Integer, or nil
    #

    # Checks if the response is successful
    #
    # @api public
    #
    # @example
    #   response.success? # => true
    #
    # @return [Boolean] true if the response contains a result, false if it contains an error
    #
    def success?
      !result.nil?
    end

    # Checks if the response is an error
    #
    # @api public
    #
    # @example
    #   response.error? # => false
    #
    # @return [Boolean] true if the response contains an error, false if it contains a result
    #
    def error?
      !error.nil?
    end

    # Converts the response to a JSON-compatible Hash
    #
    # @api public
    #
    # @example
    #   response.to_h # => { jsonrpc: "2.0", result: 42, id: 1 }
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

    # Converts the response to a JSON string
    #
    # @api public
    #
    # @example
    #   response.to_json # => '{"jsonrpc":"2.0","result":42,"id":1}'
    #
    # @return [String] the response as a JSON string
    #
    def to_json(*)
      MultiJson.dump(to_h, *)
    end
  end
end
