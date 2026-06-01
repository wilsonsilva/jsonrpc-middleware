# frozen_string_literal: true

RSpec.describe JSONRPC::Helpers do
  let(:request_id) { 42 }
  let(:jsonrpc_request_obj) { JSONRPC::Request.new(method: 'add', id: request_id) }
  let(:env_with_request) { { 'jsonrpc.request' => jsonrpc_request_obj } }

  let(:test_host_class) do
    Class.new do
      include JSONRPC::Helpers

      def initialize(env_hash)
        @env = env_hash
      end
    end
  end

  let(:host) { test_host_class.new(env_with_request) }

  describe '.included' do
    it 'extends the including class with ClassMethods' do
      expect(test_host_class).to respond_to(:jsonrpc_method)
    end
  end

  describe JSONRPC::Helpers::ClassMethods do
    describe '#jsonrpc_method' do
      it 'delegates to Configuration.instance.procedure' do
        procedure = instance_double(JSONRPC::Configuration::Procedure)
        allow(JSONRPC::Configuration.instance).to receive(:procedure).with('ping').and_return(procedure)

        result = test_host_class.jsonrpc_method('ping')

        expect(JSONRPC::Configuration.instance).to have_received(:procedure).with('ping')
        expect(result).to eq(procedure)
      end
    end
  end

  describe '#jsonrpc_response' do
    it 'returns a 200 Rack tuple with a JSON body' do
      status, headers, body = host.jsonrpc_response(99)

      expect(status).to eq(200)
      expect(headers['content-type']).to eq('application/json')
      expect(JSON.parse(body.first)['result']).to eq(99)
    end
  end

  describe '#jsonrpc_batch_response' do
    context 'when responses are all nil (notifications only)' do
      it 'returns a 204 empty response' do
        status, _headers, body = host.jsonrpc_batch_response([nil, nil])

        expect(status).to eq(204)
        expect(body).to eq([])
      end
    end

    context 'when responses contain at least one non-nil entry' do
      let(:response_obj) { JSONRPC::Response.new(id: 1, result: 5) }

      it 'returns a 200 Rack tuple with a JSON body' do
        status, headers, body = host.jsonrpc_batch_response([response_obj])

        expect(status).to eq(200)
        expect(headers['content-type']).to eq('application/json')
        expect(body.first).to be_a(String)
      end
    end
  end

  describe '#jsonrpc_notification_response' do
    it 'returns a 204 empty Rack tuple' do
      status, headers, body = host.jsonrpc_notification_response

      expect(status).to eq(204)
      expect(headers).to eq({})
      expect(body).to eq([])
    end
  end

  describe '#jsonrpc_params' do
    let(:jsonrpc_request_obj) { JSONRPC::Request.new(method: 'add', params: [1, 2], id: 1) }

    it 'returns the params from the current request' do
      expect(host.jsonrpc_params).to eq([1, 2])
    end
  end

  describe '#jsonrpc_error' do
    let(:error) { JSONRPC::ParseError.new }

    it 'returns a JSON string' do
      result = host.jsonrpc_error(error)

      expect(result).to be_a(String)
    end

    it 'includes the request id in the response' do
      result = JSON.parse(host.jsonrpc_error(error))

      expect(result['id']).to eq(request_id)
    end

    it 'includes the error in the response' do
      result = JSON.parse(host.jsonrpc_error(error))

      expect(result['error']['code']).to eq(-32_700)
    end
  end

  describe '#jsonrpc_parse_error' do
    it 'returns a JSON-formatted parse error response' do
      result = JSON.parse(host.jsonrpc_parse_error)

      expect(result['error']['code']).to eq(-32_700)
    end

    it 'includes optional data when provided' do
      result = JSON.parse(host.jsonrpc_parse_error(data: 'bad input'))

      expect(result['error']['data']).to eq('bad input')
    end
  end

  describe '#jsonrpc_invalid_request_error' do
    it 'returns a JSON-formatted invalid request error response' do
      result = JSON.parse(host.jsonrpc_invalid_request_error)

      expect(result['error']['code']).to eq(-32_600)
    end

    it 'includes optional data when provided' do
      result = JSON.parse(host.jsonrpc_invalid_request_error(data: 'missing field'))

      expect(result['error']['data']).to eq('missing field')
    end
  end

  describe '#jsonrpc_method_not_found_error' do
    it 'returns a JSON-formatted method not found error response' do
      result = JSON.parse(host.jsonrpc_method_not_found_error)

      expect(result['error']['code']).to eq(-32_601)
    end

    it 'includes optional data when provided' do
      result = JSON.parse(host.jsonrpc_method_not_found_error(data: 'unknown_method'))

      expect(result['error']['data']).to eq('unknown_method')
    end
  end

  describe '#jsonrpc_invalid_params_error' do
    it 'returns a JSON-formatted invalid params error response' do
      result = JSON.parse(host.jsonrpc_invalid_params_error)

      expect(result['error']['code']).to eq(-32_602)
    end

    it 'includes optional data when provided' do
      result = JSON.parse(host.jsonrpc_invalid_params_error(data: { 'field' => 'required' }))

      expect(result['error']['data']).to eq({ 'field' => 'required' })
    end
  end

  describe '#jsonrpc_internal_error' do
    it 'returns a JSON-formatted internal error response' do
      result = JSON.parse(host.jsonrpc_internal_error)

      expect(result['error']['code']).to eq(-32_603)
    end

    it 'includes optional data when provided' do
      result = JSON.parse(host.jsonrpc_internal_error(data: 'server crashed'))

      expect(result['error']['data']).to eq('server crashed')
    end
  end
end
