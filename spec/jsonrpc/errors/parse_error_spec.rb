# frozen_string_literal: true

RSpec.describe JSONRPC::ParseError do
  describe '#initialize' do
    context 'with no arguments' do
      let(:error) { described_class.new }

      it 'sets the default message' do
        expect(error.message).to eq(
          'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.'
        )
      end

      it 'sets code to -32700' do
        expect(error.code).to eq(-32_700)
      end

      specify { expect(error.data).to be_nil }
      specify { expect(error.request_id).to be_nil }
    end

    context 'with a custom message' do
      let(:error) { described_class.new('Custom parse error') }

      it 'uses the given message' do
        expect(error.message).to eq('Custom parse error')
      end
    end

    context 'with optional data' do
      let(:error) { described_class.new(data: { 'pos' => 42 }) }

      it 'sets data' do
        expect(error.data).to eq('pos' => 42)
      end
    end
  end

  describe '#to_h' do
    context 'without data' do
      let(:error) { described_class.new }

      it 'returns a hash with code and message' do
        expect(error.to_h).to eq(
          code: -32_700,
          message: 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.'
        )
      end
    end

    context 'with data' do
      let(:error) { described_class.new(data: { 'pos' => 42 }) }

      it 'includes data in the hash' do
        expect(error.to_h).to eq(
          code: -32_700,
          message: 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.',
          data: { 'pos' => 42 }
        )
      end
    end
  end

  describe '#to_json' do
    context 'without data' do
      let(:error) { described_class.new }

      it 'returns a JSON string with code and message' do
        expect(error.to_json).to eq(
          '{"code":-32700,"message":"Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text."}'
        )
      end
    end
  end

  describe '#to_response' do
    let(:error) { described_class.new }

    it 'returns a response hash with nil id' do
      expect(error.to_response).to eq(
        jsonrpc: '2.0',
        error: {
          code: -32_700,
          message: 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.'
        },
        id: nil
      )
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
        message = 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.'

        expect(error).not_to eq(JSONRPC::Error.new(message, code: -32_700))
      end
    end

    context 'when the data differs' do
      it 'returns false' do
        expect(error).not_to eq(described_class.new(data: { 'pos' => 42 }))
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

    context 'when an error and its parent class share to_h' do
      it 'returns different hash codes' do
        message = 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.'

        expect(error.hash).not_to eq(JSONRPC::Error.new(message, code: -32_700).hash)
      end
    end

    it 'returns an Integer' do
      expect(error.hash).to be_an(Integer)
    end
  end
end
