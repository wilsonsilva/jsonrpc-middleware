# frozen_string_literal: true

require 'zeitwerk'
require 'dry-validation'

Dry::Validation.load_extensions(:predicates_as_macros)

# Encapsulates all the gem's logic
module JSONRPC
  def self.configure(&)
    Configuration.instance.instance_eval(&)
  end

  def self.configuration
    Configuration.instance
  end
end

loader = Zeitwerk::Loader.for_gem
loader.log! if ENV['DEBUG_ZEITWERK'] == 'true'
loader.enable_reloading
loader.collapse("#{__dir__}/jsonrpc/errors")
loader.inflector.inflect('jsonrpc' => 'JSONRPC')
loader.setup
loader.eager_load
