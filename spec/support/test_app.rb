# frozen_string_literal: true

require 'rack'
require 'jsonrpc'

class TestApp
  def self.methods_list
    [
      {
        name: 'divide',
        block: proc { |params|
          raise JSONRPC::InvalidParamsError unless params.is_a?(Hash)
          raise JSONRPC::InvalidParamsError if !params['dividend'].is_a?(Numeric) || !params['divisor'].is_a?(Numeric)

          params['dividend'] / params['divisor']
        }
      },
      {
        name: 'sum',
        block: proc { |params|
          raise JSONRPC::InvalidParamsError unless params.is_a?(Array)

          params.sum
        }
      }
    ]
  end

  def initialize
    @app = JSONRPC::Middleware.new(
      ->(env) { [404, { 'content-type' => 'text/plain' }, ['Not Found']] },
      methods: self.class.methods_list,
      path: '/jsonrpc'
    )
  end

  def call(env)
    @app.call(env)
  end
end
