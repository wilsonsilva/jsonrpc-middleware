# Rails Single File Routing

Demonstrates routing JSON-RPC methods to different Rails controller actions.

## Highlights

Uses constraints to route JSON-RPC requests to different Rails controller actions:

```ruby
class App < Rails::Application
  # ...
  routes.append do
    # Handle batch requests
    post '/', to: 'jsonrpc#ping_or_echo', constraints: JSONRPC::BatchConstraint.new

    # Handle individual method requests
    post '/', to: 'jsonrpc#echo', constraints: JSONRPC::MethodConstraint.new('echo')
    post '/', to: 'jsonrpc#ping', constraints: JSONRPC::MethodConstraint.new('ping')
  end
end

class JsonrpcController < ActionController::Base
  # POST /
  def echo
    render jsonrpc: jsonrpc_request.params
  end

  # POST /
  def ping
    render jsonrpc: 'pong'
  end

  # POST /
  def ping_or_echo
    results = jsonrpc_batch.process_each do |request_or_notification|
      case request_or_notification.method
      when 'echo'
        request_or_notification.params
      when 'ping'
        'pong'
      end
    end

    render jsonrpc: results
  end
end
```

## Running

```sh
bundle exec rackup
```

## API

The server implements these procedures:

- `echo` - Returns the input message
- `ping` - Returns `'pong'`

## Example Requests

Echo request:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "echo", "params": {"message": "Hello, World!"}, "id": 1}'
```

Ping request:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "ping", "params": {}, "id": 2}'
```

Batch request with multiple methods:
```sh
# Batch request with multiple methods
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '[
    {"jsonrpc": "2.0", "method": "echo", "params": {"message": "Hello from batch!"}, "id": 1},
    {"jsonrpc": "2.0", "method": "ping", "params": {}, "id": 2},
    {"jsonrpc": "2.0", "method": "echo", "params": {"message": "Another echo"}, "id": 3}
  ]'
```
