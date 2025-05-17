# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Notification object
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
    # @return [String]
    #
    attr_reader :jsonrpc

    # The method name to invoke
    # @return [String]
    #
    attr_reader :method

    # Parameters to pass to the method
    # @return [Hash, Array, nil]
    #
    attr_reader :params

    # Creates a new JSON-RPC 2.0 Notification object
    #
    # @param method [String] the name of the method to be invoked
    # @param params [Hash, Array, nil] the parameters to be used during method invocation
    # @raise [ArgumentError] if method is not a String or is reserved
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

    def to_json(*)
      to_h.to_json(*)
    end

    private

    # Validates that the method name meets JSON-RPC 2.0 requirements
    #
    # @param method [String] the method name
    # @raise [ArgumentError] if method is not a String or is reserved
    #
    def validate_method(method)
      raise ArgumentError, 'Method must be a String' unless method.is_a?(String)

      return unless method.start_with?('rpc.')

      raise ArgumentError, "Method names starting with 'rpc.' are reserved"
    end

    # Validates that the params is a valid structure according to JSON-RPC 2.0
    #
    # @param params [Hash, Array, nil] the parameters
    # @raise [ArgumentError] if params is not a Hash, Array, or nil
    #
    def validate_params(params)
      return if params.nil?

      return if params.is_a?(Hash) || params.is_a?(Array)

      raise ArgumentError, 'Params must be an Object, Array, or omitted'
    end
  end
end
