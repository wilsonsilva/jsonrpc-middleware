# frozen_string_literal: true

require 'zeitwerk'

module JSONRPC
end

loader = Zeitwerk::Loader.for_gem
loader.log! if ENV['DEBUG_ZEITWERK'] == 'true'
loader.enable_reloading
loader.collapse("#{__dir__}/jsonrpc/errors")
loader.inflector.inflect('jsonrpc' => 'JSONRPC')
loader.setup
loader.eager_load
