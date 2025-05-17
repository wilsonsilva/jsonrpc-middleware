# frozen_string_literal: true

module JSONRPC
  module Middleware
    # JSON-RPC method registry
    class Registry
      attr_reader :methods

      def initialize
        @methods = {}
      end

      def add(name, &block)
        @methods[name] = block
      end

      def call(name, params)
        method = @methods[name]
        raise MethodNotFoundError unless method

        method.call(params)
      rescue ArgumentError
        raise InvalidParamsError
      end
    end
  end
end
