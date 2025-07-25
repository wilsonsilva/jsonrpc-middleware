# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Notification object
  #
  # @api public
  #
  # Represents a method call that does not expect a response. Unlike a
  # Request, a Notification omits the "id" field, indicating that no
  # response should be sent.
  #
  # A Notification is a Request object without an "id" member.
  # Notifications are not confirmable by definition since they do not have a Response object.
  #
  # @example Create a notification with parameters
  #   notification = JSONRPC::Notification.new(method: "update", params: [1, 2, 3, 4, 5])
  #
  # @example Create a notification without parameters
  #   notification = JSONRPC::Notification.new(method: "heartbeat")
  #
  class Notification
    # JSON-RPC protocol version
    #
    # @api public
    #
    # @example
    #   notification.jsonrpc # => "2.0"
    #
    # @return [String]
    #
    attr_reader :jsonrpc

    # The method name to invoke
    #
    # @api public
    #
    # @example
    #   notification.method # => "update"
    #
    # @return [String]
    #
    attr_reader :method

    # Parameters to pass to the method
    #
    # @api public
    #
    # @example
    #   notification.params # => [1, 2, 3, 4, 5]
    #
    # @return [Hash, Array, nil]
    #
    attr_reader :params

    # Creates a new JSON-RPC 2.0 Notification object
    #
    # @api public
    #
    # @example Create a notification with array parameters
    #   JSONRPC::Notification.new(method: "update", params: [1, 2, 3])
    #
    # @example Create a notification with named parameters
    #   JSONRPC::Notification.new(method: "log", params: { level: "info", message: "Hello" })
    #
    # @param method [String] the name of the method to be invoked
    # @param params [Hash, Array, nil] the parameters to be used during method invocation
    #
    # @raise [ArgumentError] if method is not a String or is reserved
    #
    # @raise [ArgumentError] if params is not a Hash, Array, or nil
    #
    def initialize(method:, params: nil)
      @jsonrpc = '2.0'

      validate_method(method)
      validate_params(params)

      @method = method
      @params = params
    end

    # Converts the notification to a JSON-compatible Hash
    #
    # @api public
    #
    # @example
    #   notification.to_h # => { jsonrpc: "2.0", method: "update", params: [1, 2, 3] }
    #
    # @return [Hash] the notification as a JSON-compatible Hash
    #
    def to_h
      hash = {
        jsonrpc: jsonrpc,
        method: method
      }

      hash[:params] = params unless params.nil?
      hash
    end

    # Converts the notification to a JSON string
    #
    # @api public
    #
    # @example
    #   notification.to_json # => '{"jsonrpc":"2.0","method":"update","params":[1,2,3]}'
    #
    # @return [String] the notification as a JSON string
    #
    def to_json(*)
      MultiJson.dump(to_h, *)
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
  end
end
