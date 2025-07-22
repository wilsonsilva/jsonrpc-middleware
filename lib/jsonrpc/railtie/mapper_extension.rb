# frozen_string_literal: true

module JSONRPC
  # Extension module for ActionDispatch::Routing::Mapper
  #
  # @api private
  #
  module MapperExtension
    # Define JSON-RPC routes with a DSL
    #
    # @param path [String] the path to handle JSON-RPC requests on
    #
    # @example Define JSON-RPC routes
    #   jsonrpc '/api/v1' do
    #     # Handle batch requests
    #     batch to: 'batch#handle'
    #
    #     method 'user.create', to: 'users#create'
    #     method 'user.get', to: 'users#show'
    #
    #     namespace 'posts' do
    #       method 'create', to: 'posts#create'
    #       method 'list', to: 'posts#index'
    #     end
    #   end
    #
    # @return [void]
    #
    def jsonrpc(path = '/', &)
      dsl = JSONRPC::RoutesDsl.new(self, path)
      dsl.instance_eval(&)
    end
  end
end
