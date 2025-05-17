require 'json'
require 'jsonrpc'

class App
  def call(env)
    # Store env for helper methods
    @env = env
    request = env['jason.request']

    result = case request.method
    when 'add'
      1 + 1
    when 'subtract'
      1 - 1
    when 'multiply'
      1 * 1
    when 'divide'
      1/1
    else
      [400, { 'Content-Type' => 'application/json' }, [result]]
    end
  end
end
