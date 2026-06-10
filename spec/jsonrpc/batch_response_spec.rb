# frozen_string_literal: true

RSpec.describe JSONRPC::BatchResponse do
  let(:success_response) { JSONRPC::Response.new(result: 42, id: 1) }
  let(:other_response) { JSONRPC::Response.new(result: 'hello', id: 2) }
  let(:error_response) do
    JSONRPC::Response.new(error: JSONRPC::Error.new(code: -32_600, message: 'Invalid Request'), id: nil)
  end

  describe '#initialize' do
    context 'when given valid responses' do
      it 'creates a batch response with responses' do
        batch = described_class.new([success_response, other_response])

        expect(batch.responses).to eq([success_response, other_response])
      end
    end

    context 'when responses is not an Array' do
      it 'raises ArgumentError' do
        expect { described_class.new('not an array') }.to raise_error(ArgumentError, 'Responses must be an Array')
      end
    end

    context 'when responses is empty' do
      it 'raises ArgumentError' do
        expect { described_class.new([]) }.to raise_error(ArgumentError, 'Batch response cannot be empty')
      end
    end

    context 'when responses contains a non-Response object' do
      it 'raises ArgumentError' do
        expect do
          described_class.new([success_response, 'invalid'])
        end.to raise_error(ArgumentError, 'Response at index 1 is not a valid Response')
      end
    end
  end

  describe '#to_h' do
    it 'returns an array of hashes for all responses' do
      batch = described_class.new([success_response, other_response])
      result = batch.to_h

      expect(result).to be_an(Array)
      expect(result[0]).to eq(success_response.to_h)
      expect(result[1]).to eq(other_response.to_h)
    end
  end

  describe '#to_json' do
    context 'when batch contains responses' do
      it 'returns a JSON string with all fields' do
        batch = described_class.new([success_response])
        expect(batch.to_json).to eq('[{"jsonrpc":"2.0","id":1,"result":42}]')
      end
    end

    context 'when called with arguments' do
      it 'passes arguments to the underlying serializer' do
        batch = described_class.new([success_response])
        expect(batch.to_json(pretty: true)).to eq(<<~JSON.chomp)
          [
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": 42
            }
          ]
        JSON
      end
    end
  end

  describe '#to_response' do
    it 'returns an array of response hashes for all responses' do
      batch = described_class.new([success_response, other_response])
      result = batch.to_response

      expect(result).to eq([success_response.to_h, other_response.to_h])
    end
  end

  describe '#each' do
    let(:batch) { described_class.new([success_response, other_response]) }

    context 'when block is given' do
      it 'yields each response in the batch' do
        yielded_items = []
        result = batch.each { |item| yielded_items << item }

        expect(yielded_items).to eq([success_response, other_response])
        expect(result).to be(batch)
      end
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        enumerator = batch.each

        expect(enumerator).to be_a(Enumerator)
        expect(enumerator.to_a).to eq([success_response, other_response])
      end
    end
  end
end
