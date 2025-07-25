# frozen_string_literal: true

require 'zeitwerk'
require 'dry-validation'
require 'multi_json'

Dry::Validation.load_extensions(:predicates_as_macros)

# JSON-RPC 2.0 middleware implementation for Ruby
#
# @api public
#
# This module provides a complete implementation of the JSON-RPC 2.0 specification
# as Rack middleware. It handles parsing, validation, and error handling for
# JSON-RPC requests, notifications, and batch operations.
#
# @example Basic configuration
#   JSONRPC.configure do
#     procedure('add') do
#       params do
#         required(:a).value(:integer)
#         required(:b).value(:integer)
#       end
#     end
#   end
#
# @example Using the middleware
#   use JSONRPC::Middleware, path: '/api/v1/rpc'
#
module JSONRPC
  # Configures the JSON-RPC middleware with procedure definitions
  #
  # @api public
  #
  # @example Configure procedures
  #   JSONRPC.configure do
  #     procedure('subtract') do
  #       params do
  #         required(:minuend).value(:integer)
  #         required(:subtrahend).value(:integer)
  #       end
  #     end
  #   end
  #
  # @yield Block containing procedure definitions using the Configuration DSL
  #
  # @return [void]
  #
  def self.configure(&)
    Configuration.instance.instance_eval(&)
  end

  # Returns the current JSON-RPC configuration instance
  #
  # @api public
  #
  # @example Access configuration
  #   config = JSONRPC.configuration
  #   config.procedure?('add') # => true/false
  #
  # @return [Configuration] The singleton configuration instance
  #
  def self.configuration
    Configuration.instance
  end
end

loader = Zeitwerk::Loader.for_gem
loader.log! if ENV['DEBUG_ZEITWERK'] == 'true'
loader.enable_reloading
loader.collapse("#{__dir__}/jsonrpc/errors")
loader.collapse("#{__dir__}/jsonrpc/railtie")

unless defined?(Rails)
  loader.ignore("#{__dir__}/jsonrpc/railtie.rb")
  loader.ignore("#{__dir__}/jsonrpc/railtie/method_constraint.rb")
end

loader.inflector.inflect('jsonrpc' => 'JSONRPC')
loader.setup
loader.eager_load
