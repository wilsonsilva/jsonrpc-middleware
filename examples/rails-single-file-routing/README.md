# Rails Single File Routing

Demonstrates routing JSON-RPC methods to different Rails controller actions.

## Highlights

Uses constraints to route JSON-RPC requests to different Rails controller actions:

```ruby
class App < Rails::Application
  # ...
  routes.append do
    post '/', to: 'jsonrpc#echo', constraints: JSONRPC::MethodConstraint.new('echo')
    post '/', to: 'jsonrpc#ping', constraints: JSONRPC::MethodConstraint.new('ping')
  end
end

class JsonrpcController < ActionController::Base
  # POST /
  def echoc
    render jsonrpc: jsonrpc_request.params
  end

  # POST /
  def ping
    render jsonrpc: 'pong'
  end
end
```

## Running

```sh
bundle exec rackup
```

## API

The server implements an echo API with these procedures:

- `echo` - Returns the input message
- `ping` - Returns "pong"

## Example Requests

```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "echo", "params": {"message": "Hello, World!"}, "id": 1}'
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0""method": "ping", "params": {}, "id": 2}'
```
