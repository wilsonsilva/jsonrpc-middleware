# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-09-17

### Added
- MultiJson support for improved JSON performance and flexibility
  - Configuration option to select JSON adapter (`JSONRPC.configuration.json_adapter`)
  - Enhanced error handling with adapter and input preview details
  - Better performance through optimized JSON parsing
- Enhanced examples
  - Batch JSON-RPC request handling in Rails single-file routing example
  - Smart home control API example using Rails routing DSL
  - Updated documentation with batch request usage examples

### Changed
- Replaced JSON gem with MultiJson throughout the codebase
  - All JSON parsing now uses MultiJson for better adapter support
  - Updated documentation to mention optimized JSON handling
- Refactored Request and Response classes to use dry-struct
  - Simplified class definitions with automatic type checking
  - Reduced code complexity while maintaining functionality
- Enhanced Rails integration
  - Improved example applications with better error handling
  - Updated Gemfile.lock files across all examples

## [0.5.0] - 2025-07-22

### Added
- Rails routing DSL for elegant JSON-RPC method mapping with support for namespaces and batch handling:
  ```ruby
  # In routes.rb
  jsonrpc '/' do
    # Handle batch requests
    batch to: 'batch#handle'

    method 'on', to: 'main#on'
    method 'off', to: 'main#off'

    namespace 'lights' do
      method 'on', to: 'lights#on'    # becomes lights.on
      method 'off', to: 'lights#off'  # becomes lights.off
    end

    namespace 'climate' do
      method 'on', to: 'climate#on'   # becomes climate.on
      method 'off', to: 'climate#off' # becomes climate.off

      namespace 'fan' do
        method 'on', to: 'fan#on'     # becomes climate.fan.on
        method 'off', to: 'fan#off'   # becomes climate.fan.off
      end
    end
  end
  ```
- `JSONRPC::BatchConstraint` for routing JSON-RPC batch requests to dedicated controllers:
  ```ruby
  # Handle batch requests with custom constraint
  post '/api', to: 'api#handle_batch', constraints: JSONRPC::BatchConstraint.new

  # Or use the DSL (recommended)
  jsonrpc '/api' do
    batch to: 'api#handle_batch'
  end
  ```

### Changed
- Procedure registration now supports optional validation blocks (defaults to empty contract):
  ```ruby
  # Before: Always required validation block (even if empty)
  procedure('ping') do
    params do
      # No params needed
    end
  end

  # After: Optional validation block
  procedure('ping')  # Uses empty contract by default

  # Still works with validation when needed
  procedure('add') do
    params do
      required(:a).value(:integer)
      required(:b).value(:integer)
    end
  end
  ```
- Simplified example configurations by removing unnecessary empty validation blocks
- Enhanced Rails integration with automatic DSL registration via Railtie

## [0.4.0] - 2025-07-18

### Added
- `JSONRPC::BatchRequest#process_each` method for simplified batch processing

## [0.3.0] - 2025-07-17

### Added
- Rails routing support with method constraints for JSON-RPC procedures
- Rails single-file routing example application
- Method constraint helper for Rails routing integration

### Changed
- Updated Ruby to v3.4.5 across all environments
- Updated development dependencies (bundler, overcommit, rubocop, rubocop-yard)
- Updated examples dependencies to use latest versions
- Improved documentation for Rails single-file applications

### Fixed
- Standardized Ruby version usage across the project

## [0.2.0] - 2025-07-10

### Added
- Rails support via Railtie for automatic middleware registration
- Configuration options for logging, internal error handling, and error rendering
- Complete YARD documentation for all public APIs
- Rails application examples (single-file and full application)
- Sinatra application examples (classic and modular styles)
- Pure Rack application examples
- AI development guidelines for Claude Code, Copilot, and Cursor

### Changed
- Enhanced helper methods with improved framework-agnostic support
- Improved error handling with configurable logging capabilities
- Updated development dependencies for better compatibility

### Fixed
- Method parameter handling in Rack examples

## [0.1.0] - 2025-06-14

### Added
- Initial release of the JSON-RPC 2.0 middleware for Rack applications
- Complete implementation of the [JSON-RPC 2.0 specification](https://www.jsonrpc.org/specification)
- Core components:
  - `JSONRPC::Middleware` for handling JSON-RPC requests in Rack applications
  - `JSONRPC::Parser` for parsing and validating JSON-RPC requests
  - `JSONRPC::Validator` for validating procedure parameters
  - `JSONRPC::Configuration` for registering and managing procedures
- Support for all JSON-RPC request types:
  - Single requests with responses
  - Notifications (requests without responses)
  - Batch requests (multiple requests/notifications in a single call)
- Parameter validation via Dry::Validation:
  - Support for both positional and named arguments
  - Customizable validation rules and error messages
- Comprehensive error handling:
  - Parse errors
  - Invalid request errors
  - Method not found errors
  - Invalid params errors
  - Internal errors
- Helper methods for request and response processing
- Examples for basic and advanced usage scenarios

[0.6.0]: https://github.com/wilsonsilva/jsonrpc-middleware/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/wilsonsilva/jsonrpc-middleware/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/wilsonsilva/jsonrpc-middleware/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/wilsonsilva/jsonrpc-middleware/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/wilsonsilva/jsonrpc-middleware/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/wilsonsilva/jsonrpc-middleware/compare/745b5a...v0.1.0
