# frozen_string_literal: true

RSpec.describe JSONRPC::Railtie do
  # Overrides the default Rack app (see spec_helper.rb) so every request is
  # exercised against the full Rails dummy app in spec/support/routing_app.rb.
  def app
    RoutingApp::Application
  end

  def post_json(path, payload)
    post(path, payload.to_json, { 'CONTENT_TYPE' => 'application/json' })
  end

  describe 'middleware installation' do
    context 'when an unknown method is called' do
      before do
        post_json('/', { jsonrpc: '2.0', method: 'unknown', id: 'u1' })
      end

      it 'responds with the JSON-RPC method-not-found error' do
        parsed = JSON.parse(last_response.body, symbolize_names: true)
        expect(parsed.dig(:error, :code)).to eq(-32_601)
      end
    end
  end

  describe 'the :jsonrpc renderer' do
    context 'when rendering a response to a single JSON-RPC request' do
      before do
        post_json('/', { jsonrpc: '2.0', method: 'add', params: { addends: [1, 2, 3] }, id: 'req-1' })
      end

      it 'returns HTTP 200' do
        expect_status(200)
      end

      it 'wraps the result in a JSON-RPC response envelope' do
        expect_json(jsonrpc: '2.0', result: 6, id: 'req-1')
      end
    end

    context 'when rendering a response to a notification' do
      before do
        post_json('/', { jsonrpc: '2.0', method: 'subtract', params: { minuend: 10, subtrahend: 3 } })
      end

      it 'returns HTTP 204' do
        expect_status(204)
      end

      it 'returns an empty body' do
        expect_empty_response_body
      end
    end

    context 'when rendering a batch response that contains request results' do
      let(:payload) do
        [
          { jsonrpc: '2.0', method: 'add', params: { addends: [1, 2] }, id: 'sum' },
          { jsonrpc: '2.0', method: 'subtract', params: { minuend: 5, subtrahend: 2 } }
        ]
      end

      before { post_json('/', payload) }

      it 'returns HTTP 200' do
        expect_status(200)
      end

      it 'includes only responses for requests (notifications omitted)' do
        parsed = JSON.parse(last_response.body, symbolize_names: true)
        expect(parsed.pluck(:id)).to eq(['sum'])
      end

      it 'includes the request result' do
        parsed = JSON.parse(last_response.body, symbolize_names: true)
        expect(parsed.first[:result]).to eq(3)
      end
    end

    context 'when rendering a batch response that contains only notifications' do
      let(:payload) do
        [
          { jsonrpc: '2.0', method: 'subtract', params: { minuend: 1, subtrahend: 2 } },
          { jsonrpc: '2.0', method: 'subtract', params: { minuend: 3, subtrahend: 4 } }
        ]
      end

      before { post_json('/', payload) }

      it 'returns HTTP 204' do
        expect_status(204)
      end

      it 'returns an empty body' do
        expect_empty_response_body
      end
    end

    context 'when rendering outside of any JSON-RPC context' do
      before { get '/plain' }

      it 'returns HTTP 200' do
        expect_status(200)
      end

      it 'serializes the payload as plain JSON' do
        expect_json(status: 'ok')
      end
    end
  end

  describe 'the routing DSL' do
    context 'when a method is declared inside a namespace' do
      before do
        post_json('/', {
                    jsonrpc: '2.0',
                    method: 'math.multiply',
                    params: { multiplicand: 3, multiplier: 4 },
                    id: 'm1'
                  })
      end

      it 'reaches the controller action declared in the namespace block' do
        expect_json(jsonrpc: '2.0', result: 12, id: 'm1')
      end
    end

    context 'when a method is declared inside a nested namespace' do
      before do
        post_json('/', {
                    jsonrpc: '2.0',
                    method: 'math.advanced.divide',
                    params: { dividend: 20, divisor: 5 },
                    id: 'd1'
                  })
      end

      it 'reaches the controller action declared in the innermost namespace' do
        expect_json(jsonrpc: '2.0', result: 4, id: 'd1')
      end
    end
  end

  describe 'controller helper inclusion' do
    context 'when a JSON-RPC request routes to an ActionController::API controller' do
      before do
        post_json('/', { jsonrpc: '2.0', method: 'ping', id: 'p1' })
      end

      it 'has JSONRPC::Helpers available on the API controller' do
        parsed = JSON.parse(last_response.body, symbolize_names: true)
        expect(parsed[:result]).to be(true)
      end
    end
  end
end
