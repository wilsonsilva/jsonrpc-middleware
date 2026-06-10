# frozen_string_literal: true

RSpec.describe JSONRPC::MethodNotFoundError do
  describe '#initialize' do
    context 'with no arguments' do
      let(:error) { described_class.new }

      it 'sets the default message' do
        expect(error.message).to eq(
          'The requested RPC method does not exist or is not supported.'
        )
      end

      it 'sets code to -32601' do
        expect(error.code).to eq(-32_601)
      end

      specify { expect(error.data).to be_nil }
      specify { expect(error.request_id).to be_nil }
    end

    context 'with a custom message' do
      let(:error) { described_class.new('Custom method not found error') }

      it 'uses the given message' do
        expect(error.message).to eq('Custom method not found error')
      end
    end

    context 'with optional data' do
      let(:error) { described_class.new(data: { 'method' => 'unknown_method' }) }

      it 'sets data' do
        expect(error.data).to eq('method' => 'unknown_method')
      end
    end

    context 'with optional request_id' do
      let(:error) { described_class.new(request_id: '42') }

      it 'sets request_id' do
        expect(error.request_id).to eq('42')
      end
    end
  end

  describe '#to_h' do
    context 'without data' do
      let(:error) { described_class.new }

      it 'returns a hash with code and message' do
        expect(error.to_h).to eq(
          code: -32_601,
          message: 'The requested RPC method does not exist or is not supported.'
        )
      end
    end

    context 'with data' do
      let(:error) { described_class.new(data: { 'method' => 'unknown_method' }) }

      it 'includes data in the hash' do
        expect(error.to_h).to eq(
          code: -32_601,
          message: 'The requested RPC method does not exist or is not supported.',
          data: { 'method' => 'unknown_method' }
        )
      end
    end
  end

  describe '#to_json' do
    context 'without data' do
      let(:error) { described_class.new }

      it 'returns a JSON string with code and message' do
        expect(error.to_json).to eq(
          '{"code":-32601,"message":"The requested RPC method does not exist or is not supported."}'
        )
      end
    end
  end

  describe '#to_response' do
    context 'without request_id' do
      let(:error) { described_class.new }

      it 'returns a response hash with nil id' do
        expect(error.to_response).to eq(
          jsonrpc: '2.0',
          error: {
            code: -32_601,
            message: 'The requested RPC method does not exist or is not supported.'
          },
          id: nil
        )
      end
    end

    context 'with request_id' do
      let(:error) { described_class.new(request_id: '1') }

      it 'includes request_id as the response id' do
        expect(error.to_response[:id]).to eq('1')
      end
    end
  end

  describe '#==' do
    let(:error) { described_class.new }

    context 'when the other error has the same attributes' do
      it 'returns true' do
        expect(error).to eq(described_class.new)
      end
    end

    context 'when the other object is a base Error with the same code and message' do
      it 'returns false' do
        message = 'The requested RPC method does not exist or is not supported.'

        expect(error).not_to eq(JSONRPC::Error.new(message, code: -32_601))
      end
    end

    context 'when the data differs' do
      it 'returns false' do
        expect(error).not_to eq(described_class.new(data: { 'method' => 'unknown_method' }))
      end
    end

    context 'when the request_id differs' do
      it 'returns false' do
        expect(described_class.new(request_id: '1')).not_to eq(described_class.new(request_id: '2'))
      end
    end

    context 'when the request_ids are equal strings with different identities' do
      it 'returns true' do
        first = described_class.new(request_id: +'abc')
        second = described_class.new(request_id: +'abc')

        expect(first).to eq(second)
      end
    end

    context 'when the other object is not an error' do
      it 'returns false' do
        expect(error).not_to eq('not an error')
      end
    end
  end

  describe '#eql?' do
    let(:error) { described_class.new }

    context 'when the other error has the same attributes' do
      it 'returns true' do
        expect(error.eql?(described_class.new)).to be(true)
      end
    end

    context 'when the other error differs' do
      it 'returns false' do
        expect(error.eql?(described_class.new('custom message'))).to be(false)
      end
    end
  end

  describe '#hash' do
    let(:error) { described_class.new }

    context 'when two errors are equal' do
      it 'returns the same hash code' do
        expect(error.hash).to eq(described_class.new.hash)
      end
    end

    context 'when two errors differ by message' do
      it 'returns different hash codes' do
        expect(error.hash).not_to eq(described_class.new('custom message').hash)
      end
    end

    context 'when two errors differ only by request_id' do
      it 'returns different hash codes' do
        expect(described_class.new(request_id: '1').hash).not_to eq(described_class.new(request_id: '2').hash)
      end
    end

    context 'when an error and its parent class share to_h' do
      it 'returns different hash codes' do
        message = 'The requested RPC method does not exist or is not supported.'

        expect(error.hash).not_to eq(JSONRPC::Error.new(message, code: -32_601).hash)
      end
    end

    it 'returns an Integer' do
      expect(error.hash).to be_an(Integer)
    end
  end
end
