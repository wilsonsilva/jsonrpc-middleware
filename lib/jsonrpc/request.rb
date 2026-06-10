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
  class Request < Dry::Struct
    # JSON-RPC protocol version
    #
    # @api public
    #
    # @example
    #   request.jsonrpc # => "2.0"
    #
    # @return [String]
    #
    attribute :jsonrpc, Types::String.default('2.0')

    # The method name to invoke
    #
    # @api public
    #
    # @example
    #   request.method # => "subtract"
    #
    # @return [String]
    #
    attribute :method, Types::String.constrained(format: /\A(?!rpc\.)/)

    # Parameters to pass to the method
    #
    # @api public
    #
    # @example
    #   request.params # => { "minuend": 42, "subtrahend": 23 }
    #
    # @return [Hash, Array, nil]
    #
    attribute? :params, (Types::Hash | Types::Array).optional

    # The request identifier
    #
    # @api public
    #
    # @example
    #   request.id # => 1
    #
    # @return [String, Integer, nil]
    #
    attribute? :id, Types::String | Types::Integer | Types::Nil

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
      MultiJson.dump(to_h, *)
    end

    # Compares this request to another object for value equality
    #
    # @api public
    #
    # @example
    #   request == JSONRPC::Request.new(method: "subtract", params: [42, 23], id: 1)
    #
    # @param other [Object] the object to compare against
    #
    # @return [Boolean] true if the other object is an equivalent request
    #
    def ==(other)
      other.instance_of?(Request) &&
        method == other.method &&
        params == other.params &&
        id == other.id
    end

    alias eql? ==

    # Returns a hash code based on the request's attributes
    #
    # @api public
    #
    # @return [Integer] the hash code
    #
    def hash
      [method, params, id].hash
    end

    # The method name to invoke
    #
    # @api public
    #
    # @example
    #   request.method # => "subtract"
    #
    # @return [String]
    #
    def method = attributes[:method]
  end
end
