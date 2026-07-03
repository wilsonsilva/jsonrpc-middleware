# OpenWiki quickstart

This repository packages a Rack middleware that implements the JSON-RPC 2.0 protocol for Ruby applications. The core library parses JSON-RPC payloads, validates them against configured procedures, and exposes helpers for Rack, Sinatra, and Rails integrations.

## Start here

- Read the top-level [README](../README.md) for installation, a runnable quickstart, and release workflows.
- Read [Architecture notes](architecture.md) for the request lifecycle and the main objects under `lib/jsonrpc/`.
- Read [Testing and operations](testing.md) for the commands used to validate changes and how CI is structured.

## Repository map

- `lib/jsonrpc.rb` boots the gem, wires Zeitwerk, and exposes the configuration DSL.
- `lib/jsonrpc/` contains the protocol types, middleware, parser, validator, helpers, and Rails integration points.
- `spec/` covers the public API, middleware behavior, and support fixtures used by RSpec.
- `examples/` contains working Rack, Sinatra, and Rails example applications.
- `docs/JSON-RPC-2.0-Specification.md` carries a local copy of the upstream specification for reference.
- `.github/workflows/main.yml` runs the primary CI checks for tests, linting, YARD validation, and dependency auditing.
- `.github/workflows/openwiki-update.yml` keeps this OpenWiki documentation fresh through a scheduled/manual workflow that opens a PR with generated updates.

## Change guidance

- Start in `lib/jsonrpc/middleware.rb` when behavior changes affect request routing, Rack env keys, error handling, or batch execution.
- Start in `lib/jsonrpc/parser.rb` for JSON decoding, request-shape validation, and mixed batch parse-error behavior.
- Start in `lib/jsonrpc/validator.rb` and `lib/jsonrpc/configuration.rb` for procedure registration and contract-based parameter validation.
- Review the matching example app under `examples/` when changing framework integration behavior.
- Use the command set in [Testing and operations](testing.md) before merging changes.

## Source references

- `lib/jsonrpc.rb`
- `lib/jsonrpc/middleware.rb`
- `lib/jsonrpc/parser.rb`
- `lib/jsonrpc/validator.rb`
- `.github/workflows/main.yml`
- `.github/workflows/openwiki-update.yml`
