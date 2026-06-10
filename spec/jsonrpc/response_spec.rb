# frozen_string_literal: true

RSpec.describe JSONRPC::Response do
  describe '#success?' do
    context 'when the response has a result' do
      let(:response) { described_class.new(result: 19, id: 1) }

      specify { expect(response).to be_success }
    end

    context 'when the response has an error' do
      let(:response) { described_class.new(error: JSONRPC::Error.new('Invalid Request', code: -32_600), id: 1) }

      specify { expect(response).not_to be_success }
    end
  end

  describe '#error?' do
    context 'when the response has an error' do
      let(:response) { described_class.new(error: JSONRPC::Error.new('Invalid Request', code: -32_600), id: 1) }

      specify { expect(response).to be_error }
    end

    context 'when the response has a result' do
      let(:response) { described_class.new(result: 19, id: 1) }

      specify { expect(response).not_to be_error }
    end
  end

  describe '#to_h' do
    context 'when the response is successful' do
      let(:response) { described_class.new(result: 19, id: 1) }

      it 'returns a hash with the result' do
        expect(response.to_h).to eq(jsonrpc: '2.0', result: 19, id: 1)
      end
    end

    context 'when the response is an error' do
      let(:response) { described_class.new(error: JSONRPC::Error.new('Invalid Request', code: -32_600), id: 1) }

      it 'returns a hash with the error and no result' do
        expect(response.to_h).to eq(
          jsonrpc: '2.0', id: 1, error: { code: -32_600, message: 'Invalid Request' }
        )
      end
    end
  end

  describe '#to_json' do
    context 'when the response is successful' do
      let(:response) { described_class.new(result: 19, id: 1) }

      it 'returns a valid JSON string' do
        expect(response.to_json).to eq('{"jsonrpc":"2.0","id":1,"result":19}')
      end
    end

    context 'when the response is an error' do
      let(:response) { described_class.new(error: JSONRPC::Error.new('Invalid Request', code: -32_600), id: 1) }

      it 'returns a valid JSON string with the error' do
        expect(response.to_json).to eq(
          '{"jsonrpc":"2.0","id":1,"error":{"code":-32600,"message":"Invalid Request"}}'
        )
      end
    end

    context 'when called with arguments such as pretty' do
      let(:response) { described_class.new(result: 19, id: 1) }

      it 'passes arguments to the underlying JSON serializer' do
        result = response.to_json(pretty: true)

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
