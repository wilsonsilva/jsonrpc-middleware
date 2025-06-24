# frozen_string_literal: true

RSpec.describe JSONRPC::Middleware do
  # Valid Single Requests
  context 'when processing a valid JSON-RPC request with positional parameters' do
    it 'returns HTTP 200 OK with the correct JSON-RPC response' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'add',
        params: [1, 2, 3, 4],
        id: 'req-valid-positional-arguments'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        result: 10,
        id: 'req-valid-positional-arguments'
      )
    end
  end

  context 'when processing a valid JSON-RPC request with named parameters' do
    it 'returns HTTP 200 OK with the correct JSON-RPC response' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'divide',
        params: { dividend: 10, divisor: 2 },
        id: 'req-valid-named-parameters'
      )

      expect_json(
        jsonrpc: '2.0',
        result: 5,
        id: 'req-valid-named-parameters'
      )
      expect_status(200)
    end
  end

  context 'when processing a JSON-RPC request with a null id' do
    it 'returns HTTP 200 OK and preserves the null id' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'add',
        params: [1, 2, 3, 4],
        id: nil
      )

      expect_json(
        jsonrpc: '2.0',
        result: 10,
        id: nil
      )
      expect_status(200)
    end
  end

  # Notifications
  context 'when processing a JSON-RPC notification (request without id)' do
    it 'returns HTTP 204 No Content with no response body' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'add',
        params: [1, 2, 3, 4]
      )

      expect_status(204)
      expect_empty_response_body
    end
  end

  # Parameter Type Errors
  context 'when processing a JSON-RPC request with named parameters for a method expecting positional parameters' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid params error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'add',
        params: { a: 1, b: 2, c: 3, d: 4 }, # Named params for a method that normally takes positional params
        id: 'req-named-for-positioned'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_602,
          message: 'Invalid method parameter(s).',
          data: {
            method: 'add',
            params: {
              addends: ['is missing']
            }
          }
        },
        id: 'req-named-for-positioned'
      )
    end
  end

  context 'when processing a JSON-RPC request with positional parameters for a method expecting named parameters' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid params error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'divide',
        params: [10, 2], # Positional params for a method that normally takes named params
        id: 'req-positional-for-named'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_602,
          message: 'Invalid method parameter(s).',
          data: { method: 'divide' }
        },
        id: 'req-positional-for-named'
      )
    end
  end

  context 'when processing a JSON-RPC request with incorrect parameter types' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid params error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'divide',
        params: { dividend: 'ten', divisor: 2 },
        id: 'req-invalid-params-type'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_602,
          message: 'Invalid method parameter(s).',
          data: {
            method: 'divide',
            params: {
              dividend: ['must be an integer']
            }
          }
        },
        id: 'req-invalid-params-type'
      )
    end
  end

  context 'when processing a JSON-RPC request with an invalid parameter structure' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid request error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'divide',
        params: 'not an array or object',
        id: 'req-invalid-params-structure'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_600,
          data: { details: 'Params must be an object, array, or omitted' },
          message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'
        },
        id: 'req-invalid-params-structure'
      )
    end
  end

  # Missing Parameters
  context 'when processing a JSON-RPC request with missing parameters' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid params error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'divide',
        id: 'req-missing-params'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_602,
          message: 'Invalid method parameter(s).',
          data: {
            method: 'divide',
            params: {
              dividend: ['is missing'],
              divisor: ['is missing']
            }
          }
        },
        id: 'req-missing-params'
      )
    end
  end

  # Invalid Request Format
  context 'when processing an HTTP request with an empty body' do
    it 'returns HTTP 200 OK with a JSON-RPC parse error' do
      post_raw_jsonrpc_request(nil)

      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_700,
          data: {
            details: 'unexpected end of input at line 1 column 1'
          },
          message: 'Invalid JSON was received by the server. ' \
                   'An error occurred on the server while parsing the JSON text.'
        },
        id: nil
      )
      expect_status(200)
    end
  end

  context 'when processing an HTTP request with invalid JSON' do
    it 'returns HTTP 200 OK with a JSON-RPC parse error' do
      post_raw_jsonrpc_request('Taxation is theft.')

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_700,
          data: {
            details: "unexpected character: 'Taxation' at line 1 column 1"
          },
          message: 'Invalid JSON was received by the server. ' \
                   'An error occurred on the server while parsing the JSON text.'
        },
        id: nil
      )
    end
  end

  context 'when processing a JSON-RPC request with an invalid method attribute' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid request error', :aggregate_failures do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 1, # Method should be a string
        params: { dividend: 10, divisor: 2 },
        id: 'req-valid-parse-error'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_600,
          data: {
            details: 'Method must be a string'
          },
          message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'
        },
        id: 'req-valid-parse-error'
      )
    end
  end

  context 'when processing a JSON-RPC request without the jsonrpc attribute' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid request error' do
      post_jsonrpc_request(
        method: 'divide',
        params: { dividend: 10, divisor: 2 },
        id: 'req-missing-jsonrpc-attribute'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_600,
          data: {
            details: "Missing 'jsonrpc' property"
          },
          message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'
        },
        id: 'req-missing-jsonrpc-attribute'
      )
    end
  end

  context 'when processing a JSON-RPC request with an invalid jsonrpc version' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid request error' do
      post_jsonrpc_request(
        jsonrpc: nil,
        method: 'divide',
        params: { dividend: 10, divisor: 2 },
        id: 'req-invalid-jsonrpc-attribute'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_600,
          data: {
            details: "Missing 'jsonrpc' property"
          },
          message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'
        },
        id: 'req-invalid-jsonrpc-attribute'
      )
    end
  end

  context 'when processing a JSON-RPC request without the method attribute' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid request error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        params: { dividend: 10, divisor: 2 },
        id: 'req-missing-method-attribute'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_600,
          data: {
            details: "Missing 'method' property"
          },
          message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'
        },
        id: 'req-missing-method-attribute'
      )
    end
  end

  # Method Not Found
  context 'when processing a JSON-RPC request for a non-existent method' do
    it 'returns HTTP 200 OK with a JSON-RPC method not found error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'spoon', # This method doesn't exist
        id: 'req-method-not-found'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_601,
          data: {
            method: 'spoon'
          },
          message: 'The requested RPC method does not exist or is not supported.'
        },
        id: 'req-method-not-found'
      )
    end
  end

  # Application Errors
  context 'when processing a JSON-RPC request that triggers an application-specific error' do
    it 'returns HTTP 200 OK with an application-specific error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'divide',
        params: { dividend: 10, divisor: 0 },
        id: 'req-division-by-zero'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_602,
          message: 'Invalid method parameter(s).',
          data: {
            method: 'divide',
            params: {
              divisor: ["can't be 0"]
            }
          }
        },
        id: 'req-division-by-zero'
      )
    end
  end

  context 'when processing a JSON-RPC request that causes an unexpected exception' do
    it 'returns HTTP 200 OK with a JSON-RPC internal error' do
      post_jsonrpc_request(
        jsonrpc: '2.0',
        method: 'explode',
        id: 'req-internal-error'
      )

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_603,
          message: 'Internal JSON-RPC error.'
        },
        id: 'req-internal-error'
      )
    end
  end

  # Batch Requests
  context 'when processing a valid JSON-RPC batch request' do
    it 'returns HTTP 200 OK with an array of JSON-RPC responses' do
      post_jsonrpc_request(
        [
          {
            jsonrpc: '2.0',
            method: 'add',
            params: [1, 2, 3, 4],
            id: 'batch-req-1'
          },
          {
            jsonrpc: '2.0',
            method: 'divide',
            params: { dividend: 10, divisor: 2 },
            id: 'batch-req-2'
          }
        ]
      )

      expect_status(200)
      expect_json(
        [
          {
            jsonrpc: '2.0',
            result: 10,
            id: 'batch-req-1'
          },
          {
            jsonrpc: '2.0',
            result: 5,
            id: 'batch-req-2'
          }
        ]
      )
    end
  end

  context 'when processing a batch request with mixed success and error responses' do
    it 'returns HTTP 200 OK with an array of JSON-RPC responses' do
      post_jsonrpc_request(
        [
          {
            jsonrpc: '2.0',
            method: 'add',
            params: [1, 2, 3, 4],
            id: 'batch-mixed-1'
          },
          {
            jsonrpc: '2.0',
            method: 'divide',
            params: { dividend: 10, divisor: 0 },
            id: 'batch-mixed-2'
          },
          {
            jsonrpc: '2.0',
            method: 'unknown_method',
            params: [],
            id: 'batch-mixed-3'
          }
        ]
      )

      expect_status(200)
      expect_json(
        [
          {
            jsonrpc: '2.0',
            result: 10,
            id: 'batch-mixed-1'
          },
          {
            jsonrpc: '2.0',
            error: {
              code: -32_602,
              message: 'Invalid method parameter(s).',
              data: {
                method: 'divide',
                params: {
                  divisor: ["can't be 0"]
                }
              }
            },
            id: 'batch-mixed-2'
          },
          {
            jsonrpc: '2.0',
            error: {
              code: -32_601,
              message: 'The requested RPC method does not exist or is not supported.',
              data: {
                method: 'unknown_method'
              }
            },
            id: 'batch-mixed-3'
          }
        ]
      )
    end
  end

  context 'when processing a batch request with only notifications' do
    it 'returns HTTP 204 No Content with no response body' do
      post_jsonrpc_request(
        [
          {
            jsonrpc: '2.0',
            method: 'add',
            params: [1, 2, 3, 4]
            # No id - notification
          },
          {
            jsonrpc: '2.0',
            method: 'divide',
            params: { dividend: 10, divisor: 2 }
            # No id - notification
          }
        ]
      )

      expect_status(204)
      expect_empty_response_body
    end
  end

  context 'when processing an empty batch request' do
    it 'returns HTTP 200 OK with a JSON-RPC invalid request error' do
      post_jsonrpc_request([])

      expect_status(200)
      expect_json(
        jsonrpc: '2.0',
        error: {
          code: -32_600,
          data: {
            details: 'Batch request cannot be empty'
          },
          message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'
        },
        id: nil
      )
    end
  end

  context 'when processing an invalid batch request format' do
    it 'returns HTTP 200 OK with JSON-RPC invalid request errors', :aggregate_failures do
      post_jsonrpc_request([1, 2, 3])

      expect_status(200)
      expect_json(
        [
          {
            jsonrpc: '2.0',
            id: nil,
            error: {
              code: -32_600,
              message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.',
              data: {
                index: 0,
                details: 'Request must be an object'
              }
            }
          },
          {
            jsonrpc: '2.0',
            id: nil,
            error: {
              code: -32_600,
              message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.',
              data: {
                index: 1,
                details: 'Request must be an object'
              }
            }
          },
          {
            jsonrpc: '2.0',
            id: nil,
            error: {
              code: -32_600,
              message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.',
              data: {
                index: 2,
                details: 'Request must be an object'
              }
            }
          }
        ]
      )
    end
  end

  context 'when processing a batch request containing an invalid JSON-RPC request' do
    it 'returns HTTP 200 OK with appropriate responses for each request' do
      post_jsonrpc_request(
        [
          {
            jsonrpc: '2.0',
            method: 'add',
            params: [1, 2, 3, 4],
            id: 'batch-partial-1'
          },
          {
            # Invalid - missing jsonrpc version
            method: 'divide',
            params: { dividend: 10, divisor: 2 },
            id: 'batch-partial-2'
          }
        ]
      )

      expect_status(200)
      expect_json(
        [
          {
            jsonrpc: '2.0',
            error: {
              code: -32_600,
              data: {
                details: "Missing 'jsonrpc' property",
                index: 1
              },
              message: 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'
            },
            id: 'batch-partial-2'
          },
          {
            jsonrpc: '2.0',
            result: 10,
            id: 'batch-partial-1'
          }
        ]
      )
    end
  end
end
