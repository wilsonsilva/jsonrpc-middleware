require 'sinatra/base'
require 'sinatra/json'

require 'jason'
require_relative '../../lib/sinatra/jason'
# require 'sinatra/jason'

class App < Sinatra::Base
  set :host_authorization, permitted_hosts: []
  set :raise_errors, true
  set :show_exceptions, false

  register Sinatra::Jason

  post '/', rpc: 'add' do
    rpc_params['addend_one'] + rpc_params['addend_two']
  end

  post '/', rpc: 'subtract' do
    rpc_params['minuend'] - rpc_params['subtrahend']
  end

  post '/', rpc: 'multiply' do
    rpc_params['factor_one'] * rpc_params['factor_two']  # Fixed multiplication operator
  end

  post '/', rpc: 'divide' do
    if rpc_params['dividend'].zero? || rpc_params['divisor'].zero?
      raise Jason::InvalidParamsError.new(message: 'Invalid params')
    end

    rpc_params['dividend'] / rpc_params['divisor']
  rescue ZeroDivisionError
    raise Jason::InternalError.new(message: 'Internal error')
  end
end
