# frozen_string_literal: true

RSpec.describe JSONRPC::Error do
  describe '#initialize' do
    context 'with valid arguments' do
      it 'sets the message' do
        error = described_class.new('Invalid Request', code: -32_600)

        expect(error.message).to eq('Invalid Request')
      end

      it 'sets the code' do
        error = described_class.new('Invalid Request', code: -32_600)

        expect(error.code).to eq(-32_600)
      end

      it 'sets data to nil by default' do
        error = described_class.new('Invalid Request', code: -32_600)

        expect(error.data).to be_nil
      end

      it 'sets request_id to nil by default' do
        error = described_class.new('Invalid Request', code: -32_600)

        expect(error.request_id).to be_nil
      end
    end

    context 'with optional data' do
      it 'sets data' do
        error = described_class.new('Invalid params', code: -32_602, data: { 'field' => 'missing' })

        expect(error.data).to eq({ 'field' => 'missing' })
      end
    end

    context 'with optional request_id' do
      it 'sets request_id' do
        error = described_class.new('Invalid Request', code: -32_600, request_id: '42')

        expect(error.request_id).to eq('42')
      end
    end

    context 'when code is not an Integer' do
      it 'raises ArgumentError' do
        expect do
          described_class.new('Invalid Request', code: '-32600')
        end.to raise_error(ArgumentError, 'Error code must be an Integer')
      end
    end

    context 'when message is not a String' do
      it 'raises ArgumentError' do
        expect do
          described_class.new(123, code: -32_600)
        end.to raise_error(ArgumentError, 'Error message must be a String')
      end
    end
  end

  describe '#to_h' do
    context 'without data' do
      it 'returns hash with code and message' do
        error = described_class.new('Invalid Request', code: -32_600)

        expect(error.to_h).to eq({ code: -32_600, message: 'Invalid Request' })
      end
    end

    context 'with data' do
      it 'includes data in the hash' do
        error = described_class.new('Invalid params', code: -32_602, data: { 'field' => 'missing' })

        expect(error.to_h).to eq({ code: -32_602, message: 'Invalid params', data: { 'field' => 'missing' } })
      end
    end
  end

  describe '#to_json' do
    context 'without data' do
      it 'returns a JSON string with code and message' do
        error = described_class.new('Invalid Request', code: -32_600)

        result = error.to_json

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq({ 'code' => -32_600, 'message' => 'Invalid Request' })
      end
    end

    context 'with data' do
      it 'includes data in the JSON output' do
        error = described_class.new('Invalid params', code: -32_602, data: { 'field' => 'missing' })

        result = error.to_json

        expect(JSON.parse(result)).to eq({
                                           'code' => -32_602,
                                           'message' => 'Invalid params',
                                           'data' => { 'field' => 'missing' }
                                         })
      end
    end
  end

  describe '#to_response' do
    context 'without request_id' do
      it 'returns a JSON-RPC response hash with nil id' do
        error = described_class.new('Invalid Request', code: -32_600)

        result = error.to_response

        expect(result).to eq({
                               jsonrpc: '2.0',
                               error: { code: -32_600, message: 'Invalid Request' },
                               id: nil
                             })
      end
    end

    context 'with request_id' do
      it 'includes request_id as the response id' do
        error = described_class.new('Invalid Request', code: -32_600, request_id: '1')

        result = error.to_response

        expect(result[:id]).to eq('1')
      end
    end
  end
end
