# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `bundle exec rspec` - Run all tests
- `bundle exec rspec spec/path/to/spec.rb` - Run specific test file
- `rake coverage` - Run tests with coverage report (opens in browser)

### Code Quality
- `bundle exec rake qa` - Complete quality check (tests, linting, security, docs)
- `bundle exec rubocop` - Run Ruby linter
- `bundle exec rubocop --autocorrect` - Auto-fix safe Ruby style issues  
- `bundle exec rubocop --autocorrect-all` - Auto-fix all Ruby style issues
- `bundle exec steep check` - Run type checking with Steep/RBS

### Security & Dependencies
- `bundle exec rake bundle:audit:check` - Check for vulnerable dependencies
- `bundle exec rake bundle:audit:update` - Update vulnerability database

### Documentation
- `bundle exec rake yard` - Generate YARD documentation
- `bundle exec rake yard:format` - Format YARD comments in code
- `bundle exec rake verify_measurements` - Verify 100% documentation coverage

### Build & Release
- `bundle exec rake build` - Build gem package
- `bundle exec rake install` - Install gem locally
- `bin/console` - Interactive console with gem loaded

## Architecture Overview

### Core Components

**JSONRPC Module** (`lib/jsonrpc.rb`)
- Main entry point with configuration DSL
- Uses Zeitwerk for autoloading with specific inflection rules
- Singleton Configuration pattern for procedure definitions

**Middleware** (`lib/jsonrpc/middleware.rb`)
- Rack middleware implementing JSON-RPC 2.0 specification
- Handles parsing, validation, and error responses
- Supports single requests, notifications, and batch operations
- Complex batch processing with mixed error/success handling

**Parser** (`lib/jsonrpc/parser.rb`)
- Converts JSON strings into Request/Notification/BatchRequest objects
- Handles malformed JSON and invalid request structures

**Validator** (`lib/jsonrpc/validator.rb`)
- Validates requests against procedure definitions using dry-validation
- Supports both positional and named parameters
- Handles method existence and parameter validation

**Helpers** (`lib/jsonrpc/helpers.rb`)
- Framework-agnostic helper methods for apps
- Provides convenience methods for checking request types
- Response generation helpers for different scenarios

### Request/Response Objects
- `Request` - Standard JSON-RPC request with id
- `Notification` - Request without id (no response expected)
- `BatchRequest` - Collection of requests/notifications
- `Response` - JSON-RPC response with result or error
- `BatchResponse` - Collection of responses

### Error System
Structured error hierarchy in `lib/jsonrpc/errors/`:
- `ParseError` (-32700) - Invalid JSON
- `InvalidRequestError` (-32600) - Invalid request object
- `MethodNotFoundError` (-32601) - Method not found
- `InvalidParamsError` (-32602) - Invalid parameters
- `InternalError` (-32603) - Server error

### Configuration DSL
```ruby
JSONRPC.configure do
  procedure('method_name') do
    params do
      required(:param).value(:type)
    end
    
    rule(:param) do
      # Custom validation rules
    end
  end
end
```

## Type System

The project uses RBS (Ruby Type Signatures) with Steep for type checking:
- Type definitions in `sig/` directory
- Run `bundle exec steep check` for type validation
- Generate types with `bundle exec typeprof FILENAME`

## Examples

Comprehensive examples in `examples/` directory showing integration with:
- Pure Rack applications
- Sinatra (classic and modular)
- Single-file applications with bundler/inline

Each example implements calculator operations (add, subtract, multiply, divide) demonstrating different usage patterns.

## Testing Strategy

- RSpec with comprehensive test coverage
- Factory Bot for test data generation
- Rack::Test for middleware testing
- SimpleCov for coverage reporting with multiple formatters
- Examples include both unit and integration tests