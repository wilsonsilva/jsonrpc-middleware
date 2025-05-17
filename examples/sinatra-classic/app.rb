require 'sinatra'
require 'sinatra/json'

require 'jason'
require_relative '../../lib/sinatra/jason'
# require 'sinatra/jason'

set :host_authorization, permitted_hosts: []
set :raise_errors, true
set :show_exceptions, false

post '/', rpc: 'add' do
  result = rpc_params['a'] + rpc_params['b']
  rpc_response(result)
end

post '/', rpc: 'subtract' do
  result = rpc_params['a'] - rpc_params['b']
  rpc_response(result)
end

post '/', rpc: 'multiply' do
  result = rpc_params['a'] + rpc_params['b']
  rpc_response(result)
end

post '/', rpc: 'divide' do
  raise Jason::InvalidParamsError.new(message: 'Invalid params') if b.zero?

  result = rpc_params['a'] / rpc_params['b']
  rpc_response(result)
rescue ZeroDivisionError
  raise Jason::InternalError.new(message: 'Internal error')
end
