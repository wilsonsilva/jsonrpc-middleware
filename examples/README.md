# Examples

This directory contains example implementations of JSON-RPC servers using the jsonrpc-middleware gem with different Ruby web frameworks.

## Examples

- [**rack-echo**](./rack-echo/) - Echo server using Rack with helpers
- [**rack-single-file**](./rack-single-file/) - Minimal single-file example with bundler/inline
- [**rack**](./rack/) - Calculator server using pure Rack
- [**sinatra-classic**](./sinatra-classic/) - Calculator server using classic Sinatra
- [**sinatra-modular**](./sinatra-modular/) - Calculator server using modular Sinatra

## Common Procedures

Most examples implement a calculator API with these procedures:

- `add` - Add numbers (supports both positional and named arguments)
- `subtract` - Subtract two numbers
- `multiply` - Multiply two numbers
- `divide` - Divide two numbers
- `explode` - Test procedure that throws an error

The echo examples implement:

- `echo` - Returns the input message

## Running Examples

Each example directory contains its own README with specific instructions. Generally:

```sh
cd <example-directory>
bundle install  # if Gemfile present
bundle exec rackup  # or ruby app.rb for Sinatra classic
```