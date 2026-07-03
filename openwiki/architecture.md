# Architecture notes

## Entry point and configuration

`lib/jsonrpc.rb` loads the gem dependencies, configures Zeitwerk inflections, and exposes `JSONRPC.configure` plus `JSONRPC.configuration`. Procedure definitions are stored in the singleton configuration object, so request validation and downstream helpers all read from the same registry.

## Request lifecycle

1. `JSONRPC::Middleware` intercepts `POST` requests on the configured path and lets everything else fall through to the wrapped Rack app.
2. The middleware reads the request body and hands it to `JSONRPC::Parser`.
3. The parser converts JSON into `Request`, `Notification`, or `BatchRequest` objects and raises structured JSON-RPC errors for malformed input.
4. When signature validation is enabled, `JSONRPC::Validator` resolves the configured procedure and runs its Dry::Validation contract.
5. The middleware stores the parsed object in the Rack env (`jsonrpc.request`, `jsonrpc.notification`, or `jsonrpc.batch`) so application code can respond with the helper layer.
6. If parsing, validation, or execution fails, the middleware maps the failure to JSON-RPC error responses, including mixed batch responses when only part of a batch is invalid.

## Important components

- `lib/jsonrpc/middleware.rb` owns transport-level behavior, error rescue, logging, and batch response assembly.
- `lib/jsonrpc/parser.rb` enforces JSON-RPC 2.0 message shape and preserves per-item errors inside batch requests.
- `lib/jsonrpc/validator.rb` maps procedures to contracts and normalizes positional versus named parameters.
- `lib/jsonrpc/helpers.rb` gives Rack applications a framework-agnostic API for reading parsed requests and building responses.
- `lib/jsonrpc/railtie/` contains the Rails-specific integration points, including routing constraints.
- `lib/jsonrpc/errors/` models the JSON-RPC error hierarchy and numeric codes.

## Extension points and cautions

- Procedure configuration is the main extension point; changes there usually affect parser/validator expectations and example apps together.
- Batch handling is easy to regress because valid and invalid items can coexist; keep parser and middleware behavior aligned when changing batch logic.
- Middleware rescue behavior is configurable, so internal-error changes should be reviewed with both `render_internal_errors` and `rescue_internal_errors` settings in mind.

## Source references

- `lib/jsonrpc.rb`
- `lib/jsonrpc/configuration.rb`
- `lib/jsonrpc/middleware.rb`
- `lib/jsonrpc/parser.rb`
- `lib/jsonrpc/validator.rb`
- `lib/jsonrpc/helpers.rb`
- `lib/jsonrpc/errors/`
