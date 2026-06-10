# frozen_string_literal: true

RSpec.describe JSONRPC::Notification do
  let(:method_name) { 'update' }
  let(:array_params) { [1, 2, 3, 4, 5] }
  let(:hash_params) { { level: 'info', message: 'Hello' } }
  let(:notification) { described_class.new(method: method_name, params: array_params) }

  describe '#initialize' do
    context 'when given a method and array params' do
      it 'stores all attributes' do
        expect(notification.to_h).to eq(jsonrpc: '2.0', method: method_name, params: array_params)
      end
    end

    context 'when given a method and hash params' do
      let(:notification) { described_class.new(method: method_name, params: hash_params) }

      it 'stores hash params' do
        expect(notification.params).to eq(hash_params)
      end
    end

    context 'when given a method without params' do
      specify { expect(described_class.new(method: method_name).params).to be_nil }
    end

    context 'when method is not a String' do
      it 'raises ArgumentError' do
        expect { described_class.new(method: 42) }.to raise_error(ArgumentError, 'Method must be a String')
      end
    end

    context 'when method starts with rpc.' do
      it 'raises ArgumentError' do
        expect { described_class.new(method: 'rpc.discover') }.to raise_error(
          ArgumentError, "Method names starting with 'rpc.' are reserved"
        )
      end
    end

    context 'when params is an invalid type' do
      it 'raises ArgumentError for an integer' do
        expect { described_class.new(method: method_name, params: 42) }.to raise_error(
          ArgumentError, 'Params must be an Object, Array, or omitted'
        )
      end

      it 'raises ArgumentError for a string' do
        expect { described_class.new(method: method_name, params: 'invalid') }.to raise_error(
          ArgumentError, 'Params must be an Object, Array, or omitted'
        )
      end
    end
  end

  describe '#to_h' do
    context 'when notification has array params' do
      it 'returns a hash with all fields' do
        expect(notification.to_h).to eq(jsonrpc: '2.0', method: method_name, params: array_params)
      end
    end

    context 'when notification has no params' do
      it 'omits the params key' do
        expect(described_class.new(method: method_name).to_h).to eq(jsonrpc: '2.0', method: method_name)
      end
    end
  end

  describe '#to_json' do
    context 'when notification has params' do
      it 'returns a JSON string with all fields' do
        expect(notification.to_json).to eq('{"jsonrpc":"2.0","method":"update","params":[1,2,3,4,5]}')
      end
    end

    context 'when called with arguments' do
      it 'passes arguments to the underlying JSON serializer' do
        expect(notification.to_json(pretty: true)).to eq(<<~JSON.chomp)
          {
            "jsonrpc": "2.0",
            "method": "update",
            "params": [
              1,
              2,
              3,
              4,
              5
            ]
          }
        JSON
      end
    end

    context 'when notification has no params' do
      it 'omits the params key' do
        expect(described_class.new(method: method_name).to_json).to eq('{"jsonrpc":"2.0","method":"update"}')
      end
    end
  end
end
