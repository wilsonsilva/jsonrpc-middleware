# Examples

This directory contains example implementations of JSON-RPC servers using the jsonrpc-middleware gem with different Ruby web frameworks.

## Examples

- [**rack-echo**](./rack-echo/) - Echo server using Rack with helpers
- [**rack-single-file**](./rack-single-file/) - Minimal single-file example with bundler/inline
- [**rack**](./rack/) - Calculator server using pure Rack
- [**rails**](./rails/) - Calculator server using Rails
- [**rails-single-file**](./rails-single-file/) - Echo server using Rails with bundler/inline
- [**rails-single-file-routing**](./rails-single-file-routing/) - Echo server using Rails with method-specific routing
- [**rails-routing-dsl**](./rails-routing-dsl/) - Smart home control server showcasing Rails JSON-RPC routing DSL
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

The rails-routing-dsl example implements a smart home control API:

- `on` / `off` - Control main home automation system
- `lights.on` / `lights.off` - Control lights
- `climate.on` / `climate.off` - Control climate system
- `climate.fan.on` / `climate.fan.off` - Control climate fan
- Batch request support for multiple operations

## Running Examples

Each example directory contains its own README with specific instructions. Generally:

```sh
cd <example-directory>
bundle install  # if Gemfile present
bundle exec rackup  # or ruby app.rb for Sinatra classic
```
