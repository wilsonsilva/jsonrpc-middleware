# frozen_string_literal: true

RSpec.describe JSONRPC::Error do
  describe '#initialize' do
    context 'with valid arguments' do
      let(:error) { described_class.new('Invalid Request', code: -32_600) }

      it 'sets the message' do
        expect(error.message).to eq('Invalid Request')
      end

      it 'sets the code' do
        expect(error.code).to eq(-32_600)
      end

      specify { expect(error.data).to be_nil }

      specify { expect(error.request_id).to be_nil }
    end

    context 'with optional data' do
      let(:error) { described_class.new('Invalid params', code: -32_602, data: { 'field' => 'missing' }) }

      it 'sets data' do
        expect(error.data).to eq('field' => 'missing')
      end
    end

    context 'with optional request_id' do
      let(:error) { described_class.new('Invalid Request', code: -32_600, request_id: '42') }

      it 'sets request_id' do
        expect(error.request_id).to eq('42')
      end
    end

    context 'when code is not an Integer' do
      let(:error) { described_class.new('Invalid Request', code: '-32600') }

      it 'raises ArgumentError' do
        expect { error }.to raise_error(ArgumentError, 'Error code must be an Integer')
      end
    end

    context 'when message is not a String' do
      let(:error) { described_class.new(123, code: -32_600) }

      it 'raises ArgumentError' do
        expect { error }.to raise_error(ArgumentError, 'Error message must be a String')
      end
    end
  end

  describe '#to_h' do
    context 'without data' do
      let(:error) { described_class.new('Invalid Request', code: -32_600) }

      it 'returns a hash with code and message' do
        expect(error.to_h).to eq(code: -32_600, message: 'Invalid Request')
      end
    end

    context 'with data' do
      let(:error) { described_class.new('Invalid params', code: -32_602, data: { 'field' => 'missing' }) }

      it 'includes data in the hash' do
        expect(error.to_h).to eq(code: -32_602, message: 'Invalid params', data: { 'field' => 'missing' })
      end
    end
  end

  describe '#to_json' do
    context 'without data' do
      let(:error) { described_class.new('Invalid Request', code: -32_600) }

      it 'returns a JSON string with code and message' do
        expect(error.to_json).to eq('{"code":-32600,"message":"Invalid Request"}')
      end
    end

    context 'with data' do
      let(:error) { described_class.new('Invalid params', code: -32_602, data: { 'field' => 'missing' }) }

      it 'includes data in the JSON output' do
        expect(error.to_json).to eq('{"code":-32602,"message":"Invalid params","data":{"field":"missing"}}')
      end
    end
  end

  describe '#to_response' do
    context 'without request_id' do
      let(:error) { described_class.new('Invalid Request', code: -32_600) }

      it 'returns a response hash with nil id' do
        expect(error.to_response).to eq(
          jsonrpc: '2.0',
          error: { code: -32_600, message: 'Invalid Request' },
          id: nil
        )
      end
    end

    context 'with request_id' do
      let(:error) { described_class.new('Invalid Request', code: -32_600, request_id: '1') }

      it 'includes request_id as the response id' do
        expect(error.to_response[:id]).to eq('1')
      end
    end
  end
end
