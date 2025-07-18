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

    # The collection of request objects in this batch (may include errors)
    #
    # @api public
    #
    # @example Accessing requests in a batch
    #   batch = JSONRPC::BatchRequest.new([request1, request2])
    #   batch.requests # => [#<JSONRPC::Request...>, #<JSONRPC::Request...>]
    #
    # @return [Array<JSONRPC::Request, JSONRPC::Notification, JSONRPC::Error>]
    #
    attr_reader :requests

    # Creates a new JSON-RPC 2.0 Batch Request object
    #
    # @api public
    #
    # @example Create a batch request
    #   requests = [
    #     JSONRPC::Request.new(method: 'add', params: [1, 2], id: 1),
    #     JSONRPC::Notification.new(method: 'notify', params: ['hello'])
    #   ]
    #   batch = JSONRPC::BatchRequest.new(requests)
    #
    # @param requests [Array<JSONRPC::Request, JSONRPC::Notification, JSONRPC::Error>] an array of request objects
    #   or errors
    # @raise [ArgumentError] if requests is not an Array
    #
    # @raise [ArgumentError] if requests is empty
    #
    # @raise [ArgumentError] if any request is not a valid Request, Notification, or Error
    #
    def initialize(requests)
      validate_requests(requests)
      @requests = requests
    end

    # Converts the batch request to a JSON-compatible Array
    #
    # @api public
    #
    # @example Convert batch to hash
    #   batch.to_h # => [{"jsonrpc":"2.0","method":"add","params":[1,2],"id":1}]
    #
    # @return [Array<Hash>] the batch request as a JSON-compatible Array
    #
    def to_h
      requests.map { |item| item.respond_to?(:to_h) ? item.to_h : item }
    end

    # Converts the batch to JSON format
    #
    # @api public
    #
    # @example Convert batch to JSON
    #   batch.to_json # => '[{"id":"1","method":"sum","params":[1,2,4]}]'
    #
    # @return [String] the JSON-formatted batch
    #
    def to_json(*)
      to_h.to_json(*)
    end

    # Implements the Enumerable contract by yielding each request in the batch
    #
    # @api public
    #
    # @example Iterate over requests
    #   batch.each { |request| puts request.method }
    #
    # @yield [request] Yields each request in the batch to the block
    #
    # @yieldparam request [JSONRPC::Request, JSONRPC::Notification, JSONRPC::Error] a request in the batch
    #
    # @return [Enumerator] if no block is given
    #
    # @return [BatchRequest] self if a block is given
    #
    def each(&)
      return to_enum(:each) unless block_given?

      requests.each(&)
      self
    end

    # Returns the number of requests in the batch
    #
    # @api public
    #
    # @example Get batch size
    #   batch.size # => 3
    #
    # @return [Integer] the number of requests in the batch
    #
    def size
      requests.size
    end

    # Alias for size method providing Array-like interface
    #
    # @api public
    #
    # @example Get batch length
    #   batch.length # => 3
    #
    # @return [Integer] the number of requests in the batch
    #
    alias length size

    # Handles each request/notification in the batch and returns responses
    #
    # @api public
    #
    # @example Handle batch with a block
    #   batch.process_each do |request_or_notification|
    #     # Process the request/notification
    #     result = some_processing(request_or_notification.params)
    #     result
    #   end
    #
    # @yield [request_or_notification] Yields each request/notification in the batch
    #
    # @yieldparam request_or_notification [JSONRPC::Request, JSONRPC::Notification] a request or notification
    #   in the batch
    #
    # @yieldreturn [Object] the result of processing the request. Notifications yield no results.
    #
    # @return [Array<JSONRPC::Response>] responses for requests only (notifications return no response)
    #
    def process_each
      raise ArgumentError, 'Block required' unless block_given?

      flat_map do |request_or_notification|
        result = yield(request_or_notification)

        if request_or_notification.is_a?(JSONRPC::Request)
          JSONRPC::Response.new(id: request_or_notification.id, result:)
        end
      end.compact
    end

    private

    # Validates the requests array
    #
    # @api private
    #
    # @param requests [Array] the array of requests
    #
    # @raise [ArgumentError] if requests is not an Array
    #
    # @raise [ArgumentError] if requests is empty
    #
    # @raise [ArgumentError] if any request is not a valid Request, Notification, or Error
    #
    # @return [void]
    #
    def validate_requests(requests)
      raise ArgumentError, 'Requests must be an Array' unless requests.is_a?(Array)
      raise ArgumentError, 'Batch request cannot be empty' if requests.empty?

      requests.each_with_index do |request, index|
        unless request.is_a?(Request) || request.is_a?(Notification) || request.is_a?(Error)
          raise ArgumentError, "Request at index #{index} is not a valid Request, Notification, or Error"
        end
      end
    end
  end
end
