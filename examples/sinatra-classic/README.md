# Sinatra Classic Calculator

A JSON-RPC calculator server using classic Sinatra style.

## Running

```sh
bundle install
bundle exec rackup
```

## API

The server implements a calculator with these procedures:

- `add` - Add numbers (supports both positional and named arguments)
- `subtract` - Subtract two numbers  
- `multiply` - Multiply two numbers
- `divide` - Divide two numbers
- `explode` - Test procedure that throws an error

## Example Requests

```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "add", "params": {"addends": [1, 2, 3]}, "id": 1}'

curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 10, "subtrahend": 3}, "id": 2}'
```