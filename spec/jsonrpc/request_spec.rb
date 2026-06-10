# frozen_string_literal: true

RSpec.describe JSONRPC::Request do
  describe '#initialize' do
    context 'when given array params and an id' do
      let(:request) { described_class.new(method: 'subtract', params: [42, 23], id: 1) }

      it 'stores the method' do
        expect(request.method).to eq('subtract')
      end

      it 'stores the params' do
        expect(request.params).to eq([42, 23])
      end

      it 'stores the id' do
        expect(request.id).to eq(1)
      end
    end

    context 'when given hash params' do
      let(:request) { described_class.new(method: 'subtract', params: { minuend: 42, subtrahend: 23 }, id: 2) }

      it 'stores the params' do
        expect(request.params).to eq(minuend: 42, subtrahend: 23)
      end
    end

    context 'when given no params' do
      specify { expect(described_class.new(method: 'subtract', id: 3).params).to be_nil }
    end

    context 'when the method is not a string' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: 42, id: 1) }.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when the method starts with rpc.' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: 'rpc.discover', id: 1) }.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when the params are neither a hash nor an array' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: 'subtract', params: 'invalid', id: 1) }.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when the id is neither a string nor an integer' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: 'subtract', id: 1.5) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    context 'when the request has array params' do
      let(:request) { described_class.new(method: 'subtract', params: [42, 23], id: 1) }

      it 'returns a hash with all fields' do
        expect(request.to_h).to eq(jsonrpc: '2.0', method: 'subtract', params: [42, 23], id: 1)
      end
    end

    context 'when the request has no params' do
      let(:request) { described_class.new(method: 'subtract', id: 1) }

      it 'omits the params key' do
        expect(request.to_h).to eq(jsonrpc: '2.0', method: 'subtract', id: 1)
      end
    end

    context 'when the request has nil params' do
      let(:request) { described_class.new(method: 'subtract', params: nil, id: 1) }

      it 'omits the params key' do
        expect(request.to_h).to eq(jsonrpc: '2.0', method: 'subtract', id: 1)
      end
    end
  end

  describe '#to_json' do
    context 'when the request has array params' do
      let(:request) { described_class.new(method: 'subtract', params: [42, 23], id: 1) }

      it 'returns a JSON string with all fields' do
        expect(request.to_json).to eq('{"jsonrpc":"2.0","method":"subtract","id":1,"params":[42,23]}')
      end
    end

    context 'when the request has hash params' do
      let(:request) { described_class.new(method: 'subtract', params: { minuend: 42, subtrahend: 23 }, id: 2) }

      it 'serializes hash params to JSON' do
        expect(request.to_json).to eq(
          '{"jsonrpc":"2.0","method":"subtract","id":2,"params":{"minuend":42,"subtrahend":23}}'
        )
      end
    end

    context 'when the request has no params' do
      let(:request) { described_class.new(method: 'subtract', id: 1) }

      it 'omits the params key' do
        expect(request.to_json).to eq('{"jsonrpc":"2.0","method":"subtract","id":1}')
      end
    end

    context 'when called with arguments' do
      let(:request) { described_class.new(method: 'subtract', params: [42, 23], id: 1) }

      it 'passes arguments to the underlying JSON serializer' do
        result = request.to_json(pretty: true)

        expect(result).to eq(<<~JSON.chomp)
          {
            "jsonrpc": "2.0",
            "method": "subtract",
            "id": 1,
            "params": [
              42,
              23
            ]
          }
        JSON
      end
    end
  end
end
