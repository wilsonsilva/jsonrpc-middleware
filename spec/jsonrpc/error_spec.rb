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

    context 'when called with arguments' do
      let(:error) { described_class.new('Invalid Request', code: -32_600) }

      it 'passes arguments to the underlying serializer' do
        expect(error.to_json(pretty: true)).to eq(<<~JSON.chomp)
          {
            "code": -32600,
            "message": "Invalid Request"
          }
        JSON
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

  describe '#==' do
    let(:error) { described_class.new('Invalid params', code: -32_602, data: { 'field' => 'x' }, request_id: '1') }

    context 'when the other error has the same attributes' do
      it 'returns true' do
        expect(error).to eq(
          described_class.new('Invalid params', code: -32_602, data: { 'field' => 'x' }, request_id: '1')
        )
      end
    end

    context 'when the code differs' do
      it 'returns false' do
        expect(error).not_to eq(
          described_class.new('Invalid params', code: -32_600, data: { 'field' => 'x' }, request_id: '1')
        )
      end
    end

    context 'when the message differs' do
      it 'returns false' do
        expect(error).not_to eq(
          described_class.new('Other message', code: -32_602, data: { 'field' => 'x' }, request_id: '1')
        )
      end
    end

    context 'when the data differs' do
      it 'returns false' do
        expect(error).not_to eq(
          described_class.new('Invalid params', code: -32_602, data: { 'field' => 'y' }, request_id: '1')
        )
      end
    end

    context 'when the request_id differs' do
      it 'returns false' do
        expect(error).not_to eq(
          described_class.new('Invalid params', code: -32_602, data: { 'field' => 'x' }, request_id: '2')
        )
      end
    end

    context 'when the request_ids are equal strings with different identities' do
      it 'returns true' do
        first = described_class.new('Invalid params', code: -32_602, request_id: +'abc')
        second = described_class.new('Invalid params', code: -32_602, request_id: +'abc')

        expect(first).to eq(second)
      end
    end

    context 'when the other object is a subclass with the same attributes' do
      it 'returns false' do
        message = 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'

        expect(described_class.new(message, code: -32_600)).not_to eq(JSONRPC::InvalidRequestError.new)
      end
    end

    context 'when the other object is not an error' do
      it 'returns false' do
        expect(error).not_to eq('not an error')
      end
    end
  end

  describe '#eql?' do
    let(:error) { described_class.new('Invalid Request', code: -32_600) }

    context 'when the other error has the same attributes' do
      it 'returns true' do
        expect(error.eql?(described_class.new('Invalid Request', code: -32_600))).to be(true)
      end
    end

    context 'when the other error differs' do
      it 'returns false' do
        expect(error.eql?(described_class.new('Invalid Request', code: -32_601))).to be(false)
      end
    end
  end

  describe '#hash' do
    let(:error) { described_class.new('Invalid Request', code: -32_600) }

    context 'when two errors are equal' do
      it 'returns the same hash code' do
        expect(error.hash).to eq(described_class.new('Invalid Request', code: -32_600).hash)
      end
    end

    context 'when two errors differ by an attribute in to_h' do
      it 'returns different hash codes' do
        expect(error.hash).not_to eq(described_class.new('Invalid Request', code: -32_601).hash)
      end
    end

    context 'when two errors differ only by request_id' do
      it 'returns different hash codes' do
        expect(described_class.new('Invalid Request', code: -32_600, request_id: '1').hash).not_to eq(
          described_class.new('Invalid Request', code: -32_600, request_id: '2').hash
        )
      end
    end

    context 'when an error and a subclass share to_h and request_id' do
      it 'returns different hash codes' do
        message = 'The JSON payload was valid JSON, but not a valid JSON-RPC Request object.'

        expect(described_class.new(message, code: -32_600).hash).not_to eq(JSONRPC::InvalidRequestError.new.hash)
      end
    end

    it 'returns an Integer' do
      expect(error.hash).to be_an(Integer)
    end
  end
end
