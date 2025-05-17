# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.enable_reloading
loader.inflector.inflect('jsonrpc' => 'JSONRPC')
loader.setup
loader.eager_load
