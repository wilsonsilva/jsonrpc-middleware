# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Request object
  #
  # @api public
  #
  # Represents a call to a specific method with optional parameters and an identifier.
  #
  # @example Create a request with positional parameters
  #   request = JSONRPC::Request.new(method: "subtract", params: [42, 23], id: 1)
  #
  # @example Create a request with named parameters
  #   request = JSONRPC::Request.new(method: "subtract", params: { minuend: 42, subtrahend: 23 }, id: 3)
  #
  class Request
    # JSON-RPC protocol version
    #
    # @api public
    #
    # @example
    #   request.jsonrpc # => "2.0"
    #
    # @return [String]
    #
    attr_reader :jsonrpc

    # The method name to invoke
    #
    # @api public
    #
    # @example
    #   request.method # => "subtract"
    #
    # @return [String]
    #
    attr_reader :method

    # Parameters to pass to the method
    #
    # @api public
    #
    # @example
    #   request.params # => { "minuend": 42, "subtrahend": 23 }
    #
    # @return [Hash, Array, nil]
    #
    attr_reader :params

    # The request identifier
    #
    # @api public
    #
    # @example
    #   request.id # => 1
    #
    # @return [String, Integer, nil]
    #
    attr_reader :id

    # Creates a new JSON-RPC 2.0 Request object
    #
    # @api public
    #
    # @example Create a request with positional parameters
    #   JSONRPC::Request.new(method: "subtract", params: [42, 23], id: 1)
    #
    # @param method [String] the name of the method to be invoked
    # @param params [Hash, Array, nil] the parameters to be used during method invocation
    # @param id [String, Integer, nil] the request identifier
    #
    # @raise [ArgumentError] if method is not a String or is reserved
    #
    # @raise [ArgumentError] if params is not a Hash, Array, or nil
    #
    # @raise [ArgumentError] if id is not a String, Integer, or nil
    #
    def initialize(method:, id:, params: nil)
      @jsonrpc = '2.0'

      validate_method(method)
      validate_params(params)
      validate_id(id)

      @method = method
      @params = params
      @id = id
    end

    # Converts the request to a JSON-compatible Hash
    #
    # @api public
    #
    # @example
    #   request.to_h
    #   # => { jsonrpc: "2.0", method: "subtract", params: [42, 23], id: 1 }
    #
    # @return [Hash] the request as a JSON-compatible Hash
    #
    def to_h
      hash = {
        jsonrpc: jsonrpc,
        method: method,
        id: id
      }

      hash[:params] = params unless params.nil?
      hash
    end

    # Converts the request to a JSON string
    #
    # @api public
    #
    # @example
    #   request.to_json
    #   # => '{"jsonrpc":"2.0","method":"subtract","params":[42,23],"id":1}'
    #
    # @return [String] the request as a JSON string
    #
    def to_json(*)
      to_h.to_json(*)
    end

    private

    # Validates that the method name meets JSON-RPC 2.0 requirements
    #
    # @api private
    #
    # @param method [String] the method name
    #
    # @raise [ArgumentError] if method is not a String or is reserved
    #
    # @return [void]
    #
    def validate_method(method)
      raise ArgumentError, 'Method must be a String' unless method.is_a?(String)

      return unless method.start_with?('rpc.')

      raise ArgumentError, "Method names starting with 'rpc.' are reserved"
    end

    # Validates that the params is a valid structure according to JSON-RPC 2.0
    #
    # @api private
    #
    # @param params [Hash, Array, nil] the parameters
    #
    # @raise [ArgumentError] if params is not a Hash, Array, or nil
    #
    # @return [void]
    #
    def validate_params(params)
      return if params.nil?

      return if params.is_a?(Hash) || params.is_a?(Array)

      raise ArgumentError, 'Params must be an Object, Array, or omitted'
    end

    # Validates that the id meets JSON-RPC 2.0 requirements
    #
    # @api private
    #
    # @param id [String, Integer, nil] the request identifier
    #
    # @raise [ArgumentError] if id is not a String, Integer, or nil
    #
    # @return [void]
    #
    def validate_id(id)
      return if id.nil?

      raise ArgumentError, 'ID must be a String, Integer, or nil' unless id.is_a?(String) || id.is_a?(Integer)
    end
  end
end
