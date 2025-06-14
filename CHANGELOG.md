# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/wilsonsilva/jsonrpc-middleware/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/wilsonsilva/jsonrpc-middleware/releases/tag/v0.1.0
