# frozen_string_literal: true

require 'json'

module JSONRPC
  # JSON-RPC 2.0 Parser for converting raw JSON into JSONRPC objects
  #
  # The Parser handles converting raw JSON strings into appropriate JSONRPC objects
  # based on the JSON-RPC 2.0 protocol specification.
  #
  # @example Parse a request
  #   parser = JSONRPC::Parser.new
  #   request = parser.parse('{"jsonrpc":"2.0","method":"subtract","params":[42,23],"id":1}')
  #
  # @example JSONRPC::Parse a batch request
  #   parser = JSONRPC::Parser.new
  #   batch = parser.parse('[{"jsonrpc":"2.0","method":"sum","params":[1,2],"id":"1"},
  #                         {"jsonrpc":"2.0","method":"notify_hello","params":[7]}]')
  #
  class Parser
    # Parse a JSON-RPC 2.0 message
    #
    # @param json [String] the JSON-RPC 2.0 message
    #
    # @return [Request, Notification, BatchRequest] the parsed object
    #
    # @raise [ParseError] if the JSON is invalid
    # @raise [InvalidRequestError] if the request structure is invalid
    #
    def parse(json)
      begin
        data = JSON.parse(json)
      rescue JSON::ParserError => e
        raise ParseError.new(data: { details: e.message })
      end

      if data.is_a?(Array)
        parse_batch(data)
      else
        parse_single(data)
      end
    end

    private

    # Parse a single JSON-RPC 2.0 message
    #
    # @param data [Hash] the parsed JSON data
    # @return [Request, Notification] the parsed request or notification
    # @raise [InvalidRequestError] if the request structure is invalid
    #
    def parse_single(data)
      validate_jsonrpc_version(data)
      validate_request_structure(data)

      method = data['method']
      params = data['params']
      id = data['id']

      if id.nil?
        Notification.new(method: method, params: params)
      else
        Request.new(method: method, params: params, id: id)
      end
    rescue ArgumentError => e
      request_id = data.is_a?(Hash) ? data['id'] : nil

      raise InvalidRequestError.new(data: { details: e.message }, request_id:)
    end

    # Parse a batch JSON-RPC 2.0 message
    #
    # @param data [Array] the array of request data
    # @return [BatchRequest] the batch request
    # @raise [InvalidRequestError] if any request in the batch is invalid
    #
    def parse_batch(data)
      raise InvalidRequestError.new(data: { details: 'Batch request cannot be empty' }) if data.empty?

      requests = []

      data.each_with_index do |item, index|
        requests << parse_single(item)
      rescue InvalidRequestError => e
        # Re-raise with index information for better error reporting
        details = e.data&.fetch(:details, nil)

        # Get request ID from the item if it's a hash
        request_id = item.is_a?(Hash) ? item['id'] : nil
        raise InvalidRequestError.new(data: { index: index, details: details }, request_id:)
      end

      BatchRequest.new(requests)
    rescue ArgumentError => e
      request_id = data.is_a?(Hash) ? data['id'] : nil

      raise InvalidRequestError.new(data: { details: e.message }, request_id:)
    end

    # Validate the JSON-RPC 2.0 version
    #
    # @param data [Hash] the request data
    # @raise [InvalidRequestError] if the version is missing or invalid
    #
    def validate_jsonrpc_version(data)
      raise InvalidRequestError.new(data: { details: 'Request must be an object' }) unless data.is_a?(Hash)

      jsonrpc = data['jsonrpc']

      # Get request ID from the data
      request_id = data['id']

      raise InvalidRequestError.new(data: { details: "Missing 'jsonrpc' property" }, request_id:) if jsonrpc.nil?

      return if jsonrpc == '2.0'

      raise InvalidRequestError.new(data: { details: "Invalid JSON-RPC version, must be '2.0'" }, request_id:)
    end

    # Validate the request structure according to JSON-RPC 2.0 specification
    #
    # @param data [Hash] the request data
    # @raise [InvalidRequestError] if the request structure is invalid
    #
    def validate_request_structure(data)
      method = data['method']

      # Get ID for possible errors
      id = data['id']

      raise InvalidRequestError.new(data: { details: "Missing 'method' property" }, request_id: id) if method.nil?

      unless method.is_a?(String)
        raise InvalidRequestError.new(data: { details: 'Method must be a string' },
                                      request_id: id)
      end

      params = data['params']

      unless params.nil? || params.is_a?(Array) || params.is_a?(Hash)
        raise InvalidRequestError.new(data: { details: 'Params must be an object, array, or omitted' }, request_id: id)
      end

      id = data['id']
      unless id.nil? || id.is_a?(String) || id.is_a?(Integer) || id.nil?
        raise InvalidRequestError.new(
          data: { details: 'ID must be a string, number, null, or omitted' },
          request_id: id
        )
      end

      return unless id.is_a?(Integer)

      raise InvalidRequestError.new(data: { details: 'ID should not contain fractional parts' }, request_id: id)
    end
  end
end
