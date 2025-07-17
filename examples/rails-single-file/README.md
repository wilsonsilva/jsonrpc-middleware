# Rails Single File

An echo server using Rails with bundler/inline in a single file.

## Running

```sh
bundle exec rackup
```

## API

The server implements an echo API with this procedure:

- `echo` - Returns the input message

## Example Requests

```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "echo", "params": {"message": "Hello, World!"}, "id": 1}'
```
