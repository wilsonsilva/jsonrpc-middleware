# frozen_string_literal: true

RSpec.describe JSONRPC::Notification do
  describe '#initialize' do
    context 'when given a method and array params' do
      let(:notification) { described_class.new(method: 'files/changed', params: %w[app.rb lib/foo.rb]) }

      it 'stores all attributes' do
        expect(notification.to_h).to eq(jsonrpc: '2.0', method: 'files/changed', params: %w[app.rb lib/foo.rb])
      end
    end

    context 'when given a method and hash params' do
      let(:notification) { described_class.new(method: 'log', params: { level: 'info', message: 'Hello' }) }

      it 'stores hash params' do
        expect(notification.params).to eq(level: 'info', message: 'Hello')
      end
    end

    context 'when given a method without params' do
      let(:notification) { described_class.new(method: 'update') }

      specify { expect(notification.params).to be_nil }
    end

    context 'when method is not a String' do
      let(:notification) { described_class.new(method: 42) }

      it 'raises ArgumentError' do
        expect { notification }.to raise_error(ArgumentError, 'Method must be a String')
      end
    end

    context 'when method starts with rpc.' do
      let(:notification) { described_class.new(method: 'rpc.discover') }

      it 'raises ArgumentError' do
        expect { notification }.to raise_error(ArgumentError, "Method names starting with 'rpc.' are reserved")
      end
    end

    context 'when params is an integer' do
      let(:notification) { described_class.new(method: 'update', params: 42) }

      it 'raises ArgumentError' do
        expect { notification }.to raise_error(ArgumentError, 'Params must be an Object, Array, or omitted')
      end
    end

    context 'when params is a string' do
      let(:notification) { described_class.new(method: 'update', params: 'invalid') }

      it 'raises ArgumentError' do
        expect { notification }.to raise_error(ArgumentError, 'Params must be an Object, Array, or omitted')
      end
    end
  end

  describe '#to_h' do
    context 'when notification has array params' do
      let(:notification) { described_class.new(method: 'files/changed', params: %w[app.rb lib/foo.rb]) }

      it 'returns a hash with all fields' do
        expect(notification.to_h).to eq(jsonrpc: '2.0', method: 'files/changed', params: %w[app.rb lib/foo.rb])
      end
    end

    context 'when notification has no params' do
      let(:notification) { described_class.new(method: 'update') }

      it 'omits the params key' do
        expect(notification.to_h).to eq(jsonrpc: '2.0', method: 'update')
      end
    end
  end

  describe '#to_json' do
    context 'when notification has params' do
      let(:notification) { described_class.new(method: 'files/changed', params: %w[app.rb lib/foo.rb]) }

      it 'returns a JSON string with all fields' do
        expect(notification.to_json).to eq(
          '{"jsonrpc":"2.0","method":"files/changed","params":["app.rb","lib/foo.rb"]}'
        )
      end
    end

    context 'when called with arguments' do
      let(:notification) { described_class.new(method: 'files/changed', params: %w[app.rb lib/foo.rb]) }

      it 'passes arguments to the underlying JSON serializer' do
        expect(notification.to_json(pretty: true)).to eq(<<~JSON.chomp)
          {
            "jsonrpc": "2.0",
            "method": "files/changed",
            "params": [
              "app.rb",
              "lib/foo.rb"
            ]
          }
        JSON
      end
    end

    context 'when notification has no params' do
      let(:notification) { described_class.new(method: 'update') }

      it 'omits the params key' do
        expect(notification.to_json).to eq('{"jsonrpc":"2.0","method":"update"}')
      end
    end
  end
end
