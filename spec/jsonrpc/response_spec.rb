# frozen_string_literal: true

RSpec.describe JSONRPC::Response do
  let(:error_obj) { JSONRPC::Error.new('Invalid Request', code: -32_600) }
  let(:success_response) { described_class.new(result: 19, id: 1) }
  let(:error_response) { described_class.new(error: error_obj, id: 1) }

  describe '#success?' do
    context 'when response has a result' do
      it 'returns true' do
        expect(success_response.success?).to be(true)
      end
    end

    context 'when response has an error' do
      it 'returns false' do
        expect(error_response.success?).to be(false)
      end
    end
  end

  describe '#error?' do
    context 'when response has an error' do
      it 'returns true' do
        response = described_class.new(error: JSONRPC::Error.new('x', code: -32_600), id: 1)

        expect(response.error?).to be(true)
      end
    end

    context 'when response has a result' do
      it 'returns false' do
        expect(success_response.error?).to be(false)
      end
    end
  end

  describe '#to_h' do
    context 'when response is successful' do
      it 'returns a hash with result' do
        result = success_response.to_h

        expect(result).to eq({ jsonrpc: '2.0', result: 19, id: 1 })
        expect(result).not_to have_key(:error)
      end
    end

    context 'when response is an error' do
      it 'returns a hash with error and no result' do
        result = error_response.to_h

        expect(result[:jsonrpc]).to eq('2.0')
        expect(result[:id]).to eq(1)
        expect(result[:error]).to eq(error_obj.to_h)
        expect(result).not_to have_key(:result)
      end
    end
  end

  describe '#to_json' do
    context 'when response is successful' do
      it 'returns a valid JSON string' do
        result = success_response.to_json

        expect(result).to be_a(String)
        parsed = JSON.parse(result)
        expect(parsed['jsonrpc']).to eq('2.0')
        expect(parsed['result']).to eq(19)
        expect(parsed['id']).to eq(1)
        expect(parsed).not_to have_key('error')
      end
    end

    context 'when response is an error' do
      it 'returns a valid JSON string with error' do
        result = error_response.to_json

        expect(result).to be_a(String)
        parsed = JSON.parse(result)
        expect(parsed['jsonrpc']).to eq('2.0')
        expect(parsed['id']).to eq(1)
        expect(parsed['error']).to eq({ 'code' => -32_600, 'message' => 'Invalid Request' })
        expect(parsed).not_to have_key('result')
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
