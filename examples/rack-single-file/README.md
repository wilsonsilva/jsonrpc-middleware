# Rack Single File Echo Server

A minimal single-file JSON-RPC echo server using bundler/inline for dependencies.

## Running

```sh
rackup
```

## API

The server implements a single procedure:

- `echo` - Returns the input message

## Features

- Uses `bundler/inline` to define dependencies inline
- Self-contained in a single `config.ru` file
- Supports single requests, notifications, and batch requests

## Example Requests

```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "echo", "params": {"message": "Hello!"}, "id": 1}'

# Batch request
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '[
    {"jsonrpc": "2.0", "method": "echo", "params": {"message": "ping"}, "id": 1},
    {"jsonrpc": "2.0", "method": "echo", "params": {"message": "pong"}}
  ]'
```
