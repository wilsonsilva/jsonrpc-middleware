# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 batch request object
  #
  # A batch request is an Array filled with Request objects to send several requests at once.
  # The Server should respond with an Array containing the corresponding Response objects.
  #
  # @example Create a batch request with multiple requests
  #   batch = JSONRPC::BatchRequest.new([
  #     JSONRPC::Request.new(method: "sum", params: [1, 2, 4], id: "1"),
  #     JSONRPC::Notification.new(method: "notify_hello", params: [7]),
  #     JSONRPC::Request.new(method: "subtract", params: [42, 23], id: "2")
  #   ])
  #
  class BatchRequest
    include Enumerable

    # The collection of request objects in this batch
    # @return [Array<JSONRPC::Request, JSONRPC::Notification>]
    #
    attr_reader :requests

    # Creates a new JSON-RPC 2.0 Batch Request object
    #
    # @param requests [Array<JSONRPC::Request, JSONRPC::Notification>] an array of request objects
    # @raise [ArgumentError] if requests is not an Array
    # @raise [ArgumentError] if requests is empty
    # @raise [ArgumentError] if any request is not a valid Request or Notification
    #
    def initialize(requests)
      validate_requests(requests)
      @requests = requests
    end

    # Converts the batch request to a JSON-compatible Array
    #
    # @return [Array<Hash>] the batch request as a JSON-compatible Array
    #
    def to_h
      requests.map(&:to_h)
    end

    def to_json(*)
      to_h.to_json(*)
    end

    # Implements the Enumerable contract by yielding each request in the batch
    #
    # @yield [request] Yields each request in the batch to the block
    # @yieldparam request [JSONRPC::Request, JSONRPC::Notification] a request in the batch
    # @return [Enumerator] if no block is given
    # @return [BatchRequest] self if a block is given
    #
    def each(&)
      return to_enum(:each) unless block_given?

      requests.each(&)
      self
    end

    private

    # Validates that the requests is a valid array of Request/Notification objects
    #
    # @param requests [Array] the array of requests
    # @raise [ArgumentError] if requests is not an Array
    # @raise [ArgumentError] if requests is empty
    # @raise [ArgumentError] if any request is not a valid Request or Notification
    #
    def validate_requests(requests)
      raise ArgumentError, 'Requests must be an Array' unless requests.is_a?(Array)
      raise ArgumentError, 'Batch request cannot be empty' if requests.empty?

      requests.each_with_index do |request, index|
        unless request.is_a?(Request) || request.is_a?(Notification)
          raise ArgumentError, "Request at index #{index} is not a valid Request or Notification"
        end
      end
    end
  end
end
