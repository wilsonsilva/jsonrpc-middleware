# frozen_string_literal: true

module JSONRPC
  # Container for dry-types
  #
  # @api private
  #
  # @see https://dry-rb.org/gems/dry-types/ Dry::Types documentation
  #
  module Types
    send(:include, Dry.Types()) # Uses send to fix a YARD documentation bug
  end
end
