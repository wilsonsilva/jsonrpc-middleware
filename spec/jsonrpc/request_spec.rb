# frozen_string_literal: true

RSpec.describe JSONRPC::Request do
  let(:method_name) { 'subtract' }
  let(:array_params) { [42, 23] }
  let(:hash_params) { { minuend: 42, subtrahend: 23 } }
  let(:request) { described_class.new(method: method_name, params: array_params, id: 1) }

  describe '#initialize' do
    context 'when given a method with array params and an id' do
      it 'stores all attributes' do
        expect(request.to_h).to eq(jsonrpc: '2.0', method: method_name, params: array_params, id: 1)
      end
    end

    context 'when given a method with hash params' do
      it 'stores hash params' do
        req = described_class.new(method: method_name, params: hash_params, id: 2)
        expect(req.params).to eq(hash_params)
      end
    end

    context 'when given a method with nil params' do
      specify { expect(described_class.new(method: method_name, id: 3).params).to be_nil }
    end

    context 'when method type is invalid' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: 42, id: 1) }.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when method starts with rpc.' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: 'rpc.discover', id: 1) }.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when params type is invalid' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: method_name, params: 'invalid', id: 1) }.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when id type is invalid' do
      it 'raises Dry::Struct::Error' do
        expect { described_class.new(method: method_name, id: 1.5) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    context 'when request has array params' do
      let(:request) { described_class.new(method: method_name, params: array_params, id: 1) }

      it 'returns a hash with all fields' do
        expect(request.to_h).to eq(jsonrpc: '2.0', method: method_name, params: array_params, id: 1)
      end
    end

    context 'when request has no params' do
      let(:request) { described_class.new(method: method_name, id: 1) }

      it 'omits the params key' do
        expect(request.to_h).to eq(jsonrpc: '2.0', method: method_name, id: 1)
      end
    end

    context 'when request has nil params' do
      let(:request) { described_class.new(method: method_name, params: nil, id: 1) }

      it 'omits the params key' do
        expect(request.to_h).to eq(jsonrpc: '2.0', method: method_name, id: 1)
      end
    end
  end

  describe '#to_json' do
    context 'when request has array params' do
      it 'returns a JSON string with all fields' do
        expect(request.to_json).to eq('{"jsonrpc":"2.0","method":"subtract","id":1,"params":[42,23]}')
      end
    end

    context 'when request has hash params' do
      it 'serializes hash params to JSON' do
        req = described_class.new(method: method_name, params: hash_params, id: 2)
        expect(req.to_json).to eq(
          '{"jsonrpc":"2.0","method":"subtract","id":2,"params":{"minuend":42,"subtrahend":23}}'
        )
      end
    end

    context 'when request has no params' do
      it 'omits the params key' do
        expect(described_class.new(method: method_name, id: 1).to_json).to eq(
          '{"jsonrpc":"2.0","method":"subtract","id":1}'
        )
      end
    end

    context 'when called with arguments' do
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
