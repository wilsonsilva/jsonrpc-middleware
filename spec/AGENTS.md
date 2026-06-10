# AGENTS.md

## Testing Best Practices

Use `JsonRpcHelpers`. This provides a more consistent and readable way to assert on response status and body content:
- Prefer `post_jsonrpc_request` over `post` when sending JSON-RPC requests, as it automatically sets the correct headers and formats the request body
- Prefer `post_raw_request` over `post` when you need to send a raw JSON string, as it avoids unnecessary parsing and re-encoding
- Prefer `expect_status` over `expect(last_response.status)`
- Prefer `expect_json` over `expect(last_response.body)`
- Prefer `expect_empty_response_body` over `expect(last_response.body).to be_empty`

## Antipatterns

- Do not use `allow_any_instance_of`
