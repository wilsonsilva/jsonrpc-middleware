# frozen_string_literal: true

module JSONRPC
  # A JSON-RPC 2.0 Batch Response object
  #
  # A Batch Response is an Array containing Response objects, corresponding to
  # a Batch Request. The Server should respond with one Response for each Request
  # (except for Notifications which don't receive responses).
  #
  # @example Create a batch response
  #   batch = JSONRPC::BatchResponse.new([
  #     JSONRPC::Response.new(result: 7, id: "1"),
  #     JSONRPC::Response.new(result: 19, id: "2"),
  #     JSONRPC::Response.new(error: JSONRPC::Error.new(code: -32600, message: "Invalid Request"), id: nil)
  #   ])
  #
  class BatchResponse
    include Enumerable

    # The collection of response objects in this batch
    # @return [Array<JSONRPC::Response>]
    #
    attr_reader :responses

    # Creates a new JSON-RPC 2.0 Batch Response object
    #
    # @param responses [Array<JSONRPC::Response>] an array of response objects
    # @raise [ArgumentError] if responses is not an Array
    # @raise [ArgumentError] if responses is empty
    # @raise [ArgumentError] if any response is not a valid Response
    #
    def initialize(responses)
      validate_responses(responses)
      @responses = responses
    end

    # Converts the batch response to a JSON-compatible Array
    #
    # @return [Array<Hash>] the batch response as a JSON-compatible Array
    #
    def to_h
      responses.map(&:to_h)
    end

    def to_json(*)
      to_h.to_json(*)
    end

    # Implements the Enumerable contract by yielding each response in the batch
    #
    # @yield [response] Yields each response in the batch to the block
    # @yieldparam response [JSONRPC::Response] a response in the batch
    # @return [Enumerator] if no block is given
    # @return [BatchResponse] self if a block is given
    #
    def each(&)
      return to_enum(:each) unless block_given?

      responses.each(&)
      self
    end

    def to_response
      responses.map(&:to_response)
    end

    private

    # Validates that the responses is a valid array of Response objects
    #
    # @param responses [Array] the array of responses
    # @raise [ArgumentError] if responses is not an Array
    # @raise [ArgumentError] if responses is empty
    # @raise [ArgumentError] if any response is not a valid Response
    #
    def validate_responses(responses)
      raise ArgumentError, 'Responses must be an Array' unless responses.is_a?(Array)
      raise ArgumentError, 'Batch response cannot be empty' if responses.empty?

      responses.each_with_index do |response, index|
        raise ArgumentError, "Response at index #{index} is not a valid Response" unless response.is_a?(Response)
      end
    end
  end
end
