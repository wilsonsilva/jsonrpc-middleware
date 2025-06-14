# JSONRPC::Middleware - Ruby JSON-RPC Implementation

[![Gem Version](https://badge.fury.io/rb/jsonrpc-middleware.svg)](https://badge.fury.io/rb/jsonrpc-middleware)
![Build](https://github.com/wilsonsilva/jsonrpc-middleware/actions/workflows/main.yml/badge.svg)
[![Maintainability](https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/maintainability.svg)](https://qlty.sh/gh/wilsonsilva/projects/jsonrpc-middleware)
[![Code Coverage](https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/test_coverage.svg)](https://qlty.sh/gh/wilsonsilva/projects/jsonrpc-middleware)

A Ruby implementation of the JSON-RPC protocol, enabling standardized communication between systems via remote procedure
calls encoded in JSON.

## Table of contents

- [Key features](#-key-features)
- [Installation](#-installation)
- [Quickstart](#-quickstart)
- [Documentation](#-documentation)
- [Development](#-development)
  * [Type checking](#type-checking)
- [Contributing](#-contributing)
- [License](#-license)
- [Code of Conduct](#-code-of-conduct)

## 🔑 Key features

- **Complete JSON-RPC 2.0 Implementation**: Fully implements the [JSON-RPC 2.0 specification](https://www.jsonrpc.org/specification)
- **Rack Middleware integration**: Seamlessly integrates with Rack applications
- **Advanced request validation**: Define request parameter specifications and validations using `Dry::Validation`
- **Support for all request types**: Handles single requests, notifications, and batch requests
- **Parameter validation**: Supports both positional and named arguments with customizable validation rules
- **Error handling**: Comprehensive error handling with standard JSON-RPC error responses
- **Helper methods**: Convenient helper methods to simplify request and response processing
- **Type checking**: Ruby type checking support via RBS definitions

## 📦 Installation

Install the gem by executing:

    $ gem install jsonrpc-middleware

## ⚡️ Quickstart

### Basic Setup with Rack

```ruby
# Gemfile
source 'https://rubygems.org'
gem 'jsonrpc-middleware'
gem 'rack'
```

```ruby
# config.ru
require 'jsonrpc'
require_relative 'app'

# Use the middleware
use JSONRPC::Middleware

# Your application
run App.new
```

### Define Your JSON-RPC Procedures

Define your available procedures with validation rules:

```ruby
# procedures.rb
require 'jsonrpc'

JSONRPC.configure do
  # Define a procedure that accepts both positional and named arguments
  procedure(:add, allow_positional_arguments: true) do
    params do
      required(:addends).filled(:array)
      required(:addends).value(:array).each(type?: Numeric)
    end

    rule(:addends) do
      key.failure('must contain at least one addend') if value.empty?
    end
  end

  # Define a procedure with named arguments only
  procedure(:subtract) do
    params do
      required(:minuend).filled(:integer)
      required(:subtrahend).filled(:integer)
    end
  end
end
```

### Create Your Application

```ruby
# app.rb
class App
  include JSONRPC::Helpers

  def call(env)
    @env = env # Set the env instance variable to use JSONRPC helpers

    if jsonrpc_request?
      # Handle a standard JSON-RPC request
      result = handle_single(jsonrpc_request)
      jsonrpc_response(result)
    elsif jsonrpc_notification?
      # Handle a notification (no response needed)
      handle_single(jsonrpc_notification)
      jsonrpc_notification_response
    else
      # Handle batch requests
      responses = handle_batch(jsonrpc_batch)
      jsonrpc_batch_response(responses)
    end
  end

  private

  def handle_single(request_or_notification)
    params = request_or_notification.params

    case request_or_notification.method
    when 'add'
      # Handle both positional and named arguments
      addends = params.is_a?(Array) ? params : params['addends']
      addends.sum
    when 'subtract'
      params['minuend'] - params['subtrahend']
    end
  end

  def handle_batch(batch)
    batch.flat_map do |request_or_notification|
      result = handle_single(request_or_notification)
      # Only create responses for requests, not notifications
      JSONRPC::Response.new(id: request_or_notification.id, result: result) if request_or_notification.is_a?(JSONRPC::Request)
    end.compact
  end
end
```

### Example Requests

Here are example JSON-RPC requests you can make to your application:

```json
// Standard request with named params
{
  "jsonrpc": "2.0",
  "method": "subtract",
  "params": {
    "minuend": 42,
    "subtrahend": 23
  },
  "id": 1
}

// Request with positional params (if allowed)
{
  "jsonrpc": "2.0",
  "method": "add",
  "params": [1, 2, 3, 4, 5],
  "id": 2
}

// Notification (no response)
{
  "jsonrpc": "2.0",
  "method": "add",
  "params": {"addends": [1, 2, 3]}
}

// Batch request
[
  {"jsonrpc": "2.0", "method": "add", "params": {"addends": [1, 2]}, "id": 1},
  {"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 10, "subtrahend": 5}, "id": 2}
]
```

## 📚 Documentation

- [YARD documentation](https://rubydoc.info/gems/jsonrpc-middleware)

## 🔨 Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

The health and maintainability of the codebase is ensured through a set of
Rake tasks to test, lint and audit the gem for security vulnerabilities and documentation:

```
rake build                    # Build jsonrpc-middleware.gem into the pkg directory
rake build:checksum           # Generate SHA512 checksum if jsonrpc-middleware.gem into the checksums directory
rake bundle:audit:check       # Checks the Gemfile.lock for insecure dependencies
rake bundle:audit:update      # Updates the bundler-audit vulnerability database
rake clean                    # Remove any temporary products
rake clobber                  # Remove any generated files
rake coverage                 # Run spec with coverage
rake install                  # Build and install jsonrpc-middleware.gem into system gems
rake install:local            # Build and install jsonrpc-middleware.gem into system gems without network access
rake qa                       # Test, lint and perform security and documentation audits
rake release[remote]          # Create a tag, build and push jsonrpc-middleware.gem to rubygems.org
rake rubocop                  # Run RuboCop
rake rubocop:autocorrect      # Autocorrect RuboCop offenses (only when it's safe)
rake rubocop:autocorrect_all  # Autocorrect RuboCop offenses (safe and unsafe)
rake spec                     # Run RSpec code examples
rake verify_measurements      # Verify that yardstick coverage is at least 100%
rake yard                     # Generate YARD Documentation
rake yard:junk                # Check the junk in your YARD Documentation
rake yardstick_measure        # Measure docs in lib/**/*.rb with yardstick
```

### Type checking

This gem leverages [RBS](https://github.com/ruby/rbs), a language to describe the structure of Ruby programs. It is
used to provide type checking and autocompletion in your editor. Run `bundle exec typeprof FILENAME` to generate
an RBS definition for the given Ruby file. And validate all definitions using [Steep](https://github.com/soutaro/steep)
with the command `bundle exec steep check`.

## 🐞 Issues & Bugs

If you find any issues or bugs, please report them [here](https://github.com/wilsonsilva/jsonrpc-middleware/issues), I will be happy
to have a look at them and fix them as soon as possible.

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wilsonsilva/jsonrpc-middleware.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere
to the [code of conduct](https://github.com/wilsonsilva/jsonrpc-middleware/blob/main/CODE_OF_CONDUCT.md).

## 📜 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 👔 Code of Conduct

Everyone interacting in the JSONRPC::Middleware Ruby project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/wilsonsilva/jsonrpc-middleware/blob/main/CODE_OF_CONDUCT.md).
