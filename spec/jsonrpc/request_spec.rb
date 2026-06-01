# frozen_string_literal: true

RSpec.describe JSONRPC::Request do
  let(:method_name) { 'subtract' }
  let(:array_params) { [42, 23] }
  let(:hash_params) { { minuend: 42, subtrahend: 23 } }
  let(:request) { described_class.new(method: method_name, params: array_params, id: 1) }

  describe '#initialize' do
    context 'when given a method with array params and an id' do
      it 'creates a request with the correct attributes' do
        result = described_class.new(method: method_name, params: array_params, id: 1)

        expect(result.jsonrpc).to eq('2.0')
        expect(result.method).to eq(method_name)
        expect(result.params).to eq(array_params)
        expect(result.id).to eq(1)
      end
    end

    context 'when given a method with hash params' do
      it 'creates a request with hash params' do
        result = described_class.new(method: method_name, params: hash_params, id: 2)

        expect(result.params).to eq(hash_params)
      end
    end

    context 'when given a method with nil params' do
      it 'creates a request with nil params' do
        result = described_class.new(method: method_name, id: 3)

        expect(result.params).to be_nil
      end
    end

    context 'when method type is invalid' do
      it 'raises Dry::Struct::Error' do
        expect do
          described_class.new(method: 42, id: 1)
        end.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when method starts with rpc.' do
      it 'raises Dry::Struct::Error' do
        expect do
          described_class.new(method: 'rpc.discover', id: 1)
        end.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when params type is invalid' do
      it 'raises Dry::Struct::Error for a String' do
        expect do
          described_class.new(method: method_name, params: 'invalid', id: 1)
        end.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when id type is invalid' do
      it 'raises Dry::Struct::Error for a Float' do
        expect do
          described_class.new(method: method_name, id: 1.5)
        end.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    context 'when request has array params' do
      it 'returns a hash with all fields' do
        result = request.to_h

        expect(result).to eq({ jsonrpc: '2.0', method: method_name, params: array_params, id: 1 })
      end
    end

    context 'when request has no params' do
      it 'returns a hash without the params key' do
        result = described_class.new(method: method_name, id: 1).to_h

        expect(result).to eq({ jsonrpc: '2.0', method: method_name, id: 1 })
        expect(result).not_to have_key(:params)
      end
    end
  end

  describe '#to_json' do
    context 'when request has array params' do
      it 'returns a valid JSON string' do
        result = request.to_json

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq(request.to_h.transform_keys(&:to_s))
      end
    end

    context 'when request has hash params' do
      it 'returns a valid JSON string that round-trips' do
        req = described_class.new(method: method_name, params: hash_params, id: 2)
        result = req.to_json

        expect(result).to be_a(String)
        parsed = JSON.parse(result)
        expect(parsed['jsonrpc']).to eq('2.0')
        expect(parsed['method']).to eq(method_name)
        expect(parsed['id']).to eq(2)
      end
    end

    context 'when request has no params' do
      it 'returns a JSON string without params key' do
        req = described_class.new(method: method_name, id: 1)
        result = req.to_json

        expect(result).to be_a(String)
        parsed = JSON.parse(result)
        expect(parsed).not_to have_key('params')
      end
    end

    context 'when called with arguments' do
      it 'passes arguments to the underlying JSON serializer' do
        result = request.to_json(indent: '  ')

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq(request.to_h.transform_keys(&:to_s))
      end
    end
  end
end
