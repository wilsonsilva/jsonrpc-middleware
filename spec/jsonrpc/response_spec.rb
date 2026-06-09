# frozen_string_literal: true

RSpec.describe JSONRPC::Response do
  let(:error_obj) { JSONRPC::Error.new('Invalid Request', code: -32_600) }
  let(:success_response) { described_class.new(result: 19, id: 1) }
  let(:error_response) { described_class.new(error: error_obj, id: 1) }

  describe '#success?' do
    context 'when response has a result' do
      specify { expect(success_response).to be_success }
    end

    context 'when response has an error' do
      specify { expect(error_response).not_to be_success }
    end
  end

  describe '#error?' do
    context 'when response has an error' do
      specify { expect(error_response).to be_error }
    end

    context 'when response has a result' do
      specify { expect(success_response).not_to be_error }
    end
  end

  describe '#to_h' do
    context 'when response is successful' do
      it 'returns a hash with result' do
        result = success_response.to_h

        expect(result).to eq(jsonrpc: '2.0', result: 19, id: 1)
      end
    end

    context 'when response is an error' do
      it 'returns a hash with error and no result' do
        result = error_response.to_h

        expect(result).to eq(jsonrpc: '2.0', id: 1, error: { code: -32_600, message: 'Invalid Request' })
      end
    end
  end

  describe '#to_json' do
    context 'when response is successful' do
      it 'returns a valid JSON string' do
        result = success_response.to_json

        expect(result).to eq('{"jsonrpc":"2.0","id":1,"result":19}')
      end
    end

    context 'when response is an error' do
      it 'returns a valid JSON string with error' do
        result = error_response.to_json

        expect(result).to eq('{"jsonrpc":"2.0","id":1,"error":{"code":-32600,"message":"Invalid Request"}}')
      end
    end

    context 'when called with arguments such as `pretty`' do
      it 'passes arguments to the underlying JSON serializer' do
        result = success_response.to_json(pretty: true)

        expect(result).to eq(<<~JSON.chomp)
          {
            "jsonrpc": "2.0",
            "id": 1,
            "result": 19
          }
        JSON
      end
    end
  end
end
