# frozen_string_literal: true

RSpec.describe JSONRPC::Notification do
  let(:method_name) { 'update' }
  let(:array_params) { [1, 2, 3, 4, 5] }
  let(:hash_params) { { level: 'info', message: 'Hello' } }
  let(:notification) { described_class.new(method: method_name, params: array_params) }

  describe '#initialize' do
    context 'when given a method and array params' do
      it 'creates a notification with the correct attributes' do
        result = described_class.new(method: method_name, params: array_params)

        expect(result.jsonrpc).to eq('2.0')
        expect(result.method).to eq(method_name)
        expect(result.params).to eq(array_params)
      end
    end

    context 'when given a method and hash params' do
      it 'creates a notification with hash params' do
        result = described_class.new(method: method_name, params: hash_params)

        expect(result.params).to eq(hash_params)
      end
    end

    context 'when given a method without params' do
      it 'creates a notification with nil params' do
        result = described_class.new(method: method_name)

        expect(result.jsonrpc).to eq('2.0')
        expect(result.method).to eq(method_name)
        expect(result.params).to be_nil
      end
    end

    context 'when method is not a String' do
      it 'raises ArgumentError' do
        expect { described_class.new(method: 42) }.to raise_error(ArgumentError, 'Method must be a String')
      end
    end

    context 'when method starts with rpc.' do
      it 'raises ArgumentError' do
        expect do
          described_class.new(method: 'rpc.discover')
        end.to raise_error(ArgumentError, "Method names starting with 'rpc.' are reserved")
      end
    end

    context 'when params is an invalid type' do
      it 'raises ArgumentError for an integer' do
        expect do
          described_class.new(method: method_name, params: 42)
        end.to raise_error(ArgumentError, 'Params must be an Object, Array, or omitted')
      end

      it 'raises ArgumentError for a string' do
        expect do
          described_class.new(method: method_name, params: 'invalid')
        end.to raise_error(ArgumentError, 'Params must be an Object, Array, or omitted')
      end
    end
  end

  describe '#to_h' do
    context 'when notification has array params' do
      it 'returns a hash with all fields' do
        result = notification.to_h

        expect(result).to eq({ jsonrpc: '2.0', method: method_name, params: array_params })
      end
    end

    context 'when notification has no params' do
      it 'returns a hash without the params key' do
        result = described_class.new(method: method_name).to_h

        expect(result).to eq({ jsonrpc: '2.0', method: method_name })
        expect(result).not_to have_key(:params)
      end
    end
  end

  describe '#to_json' do
    context 'when notification has params' do
      it 'returns a JSON string' do
        result = notification.to_json

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq({ 'jsonrpc' => '2.0', 'method' => method_name, 'params' => array_params })
      end
    end

    context 'when called with arguments' do
      it 'passes arguments to the underlying JSON serializer' do
        result = notification.to_json(indent: '  ')

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq({ 'jsonrpc' => '2.0', 'method' => method_name, 'params' => array_params })
      end
    end

    context 'when notification has no params' do
      it 'returns a JSON string without params key' do
        result = described_class.new(method: method_name).to_json

        expect(result).to be_a(String)
        parsed = JSON.parse(result)
        expect(parsed).to eq({ 'jsonrpc' => '2.0', 'method' => method_name })
        expect(parsed).not_to have_key('params')
      end
    end
  end
end
