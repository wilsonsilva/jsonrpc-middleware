# Rack Echo Server

A simple JSON-RPC echo server using Rack with JSONRPC helpers.

## Running

```sh
bundle install
bundle exec rackup
```

## API

The server implements a single procedure:

- `echo` - Returns the input message

## Example Requests

```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "echo", "params": {"message": "Hello, world!"}, "id": 1}'

# Notification (no response)
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "echo", "params": {"message": "Hello, world!"}}'
```
