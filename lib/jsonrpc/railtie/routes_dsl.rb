# frozen_string_literal: true

module JSONRPC
  # DSL context for defining JSON-RPC routes within a jsonrpc block
  #
  # @example Simple method routing
  #   jsonrpc '/api/v1' do
  #     method 'ping', to: 'system#ping'
  #     method 'status', to: 'system#status'
  #   end
  #
  # @example Single-level namespace
  #   jsonrpc '/api/v1' do
  #     namespace 'users' do
  #       method 'create', to: 'users#create'  # becomes users.create
  #       method 'list', to: 'users#index'     # becomes users.list
  #     end
  #   end
  #
  # @example Nested namespaces (smart home control system)
  #   jsonrpc '/' do
  #     # Handle batch requests with dedicated controller
  #     batch to: 'batch#handle'
  #
  #     method 'on', to: 'main#on'
  #     method 'off', to: 'main#off'
  #
  #     namespace 'lights' do
  #       method 'on', to: 'lights#on'    # becomes lights.on
  #       method 'off', to: 'lights#off'  # becomes lights.off
  #     end
  #
  #     namespace 'climate' do
  #       method 'on', to: 'climate#on'   # becomes climate.on
  #       method 'off', to: 'climate#off' # becomes climate.off
  #
  #       namespace 'fan' do
  #         method 'on', to: 'fan#on'     # becomes climate.fan.on
  #         method 'off', to: 'fan#off'   # becomes climate.fan.off
  #       end
  #     end
  #   end
  #
  # @api private
  #
  class RoutesDsl
    # Initialize a new routes DSL context
    #
    # @param mapper [ActionDispatch::Routing::Mapper] the Rails route mapper
    # @param path_prefix [String] the base path for JSON-RPC requests
    #
    def initialize(mapper, path_prefix = '/')
      @mapper = mapper
      @path_prefix = path_prefix
      @namespace_stack = []
    end

    # Define a JSON-RPC method route
    #
    # @param jsonrpc_method [String] the JSON-RPC method name
    # @param to [String] the Rails controller action (e.g., 'users#create')
    #
    # @example Map a JSON-RPC method to controller action
    #   method 'user.create', to: 'users#create'
    #
    # @example Method within a namespace
    #   namespace 'posts' do
    #     method 'create', to: 'posts#create'  # becomes posts.create
    #   end
    #
    # @return [void]
    #
    def method(jsonrpc_method, to:)
      full_method_name = build_full_method_name(jsonrpc_method)
      constraint = JSONRPC::MethodConstraint.new(full_method_name)

      @mapper.post @path_prefix, {
        to: to,
        constraints: constraint
      }
    end

    # Define a route for handling JSON-RPC batch requests
    #
    # @param to [String] the Rails controller action (e.g., 'batches#handle')
    #
    # @example Map batch requests to a controller action
    #   batch to: 'batches#handle'
    #
    # @return [void]
    def batch(to:)
      constraint = JSONRPC::BatchConstraint.new

      @mapper.post @path_prefix, {
        to: to,
        constraints: constraint
      }
    end

    # Create a namespace for grouping related JSON-RPC methods
    #
    # Namespaces can be nested to create hierarchical method names.
    # Each level of nesting adds a dot-separated prefix to the method names.
    #
    # @param name [String] the namespace name
    #
    # @example Single-level namespace
    #   namespace 'posts' do
    #     method 'create', to: 'posts#create' # becomes posts.create
    #     method 'delete', to: 'posts#delete' # becomes posts.list
    #   end
    #
    # @example Nested namespaces
    #   namespace 'climate' do
    #     method 'on', to: 'climate#on'   # becomes climate.on
    #     method 'off', to: 'climate#off' # becomes climate.off
    #
    #     namespace 'fan' do
    #       method 'on', to: 'fan#on'     # becomes climate.fan.on
    #       method 'off', to: 'fan#off'   # becomes climate.fan.off
    #     end
    #   end
    #
    # @return [void]
    #
    def namespace(name, &)
      @namespace_stack.push(name)
      instance_eval(&)
      @namespace_stack.pop
    end

    private

    # Build the full method name including namespaces
    #
    # @param method_name [String] the base method name
    # @return [String] the full method name with namespace prefixes
    #
    def build_full_method_name(method_name)
      if @namespace_stack.any?
        "#{@namespace_stack.join(".")}.#{method_name}"
      else
        method_name
      end
    end
  end
end
