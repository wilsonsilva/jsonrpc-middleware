# frozen_string_literal: true

RSpec.describe JSONRPC::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    context 'when given valid JSON for a single request' do
      it 'returns a Request object' do
        result = parser.parse('{"jsonrpc":"2.0","method":"add","id":1}')

        expect(result).to be_a(JSONRPC::Request)
        expect(result.method).to eq('add')
        expect(result.id).to eq(1)
      end
    end

    context 'when given valid JSON for a notification (no id)' do
      it 'returns a Notification object' do
        result = parser.parse('{"jsonrpc":"2.0","method":"update","params":[1,2]}')

        expect(result).to be_a(JSONRPC::Notification)
        expect(result.method).to eq('update')
      end
    end

    context 'when given invalid JSON' do
      it 'raises ParseError' do
        expect { parser.parse('{not valid json') }.to raise_error(JSONRPC::ParseError)
      end
    end

    context 'when jsonrpc version is missing' do
      it 'raises InvalidRequestError' do
        expect do
          parser.parse('{"method":"add","id":1}')
        end.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when jsonrpc version is not 2.0' do
      it 'raises InvalidRequestError' do
        expect do
          parser.parse('{"jsonrpc":"1.0","method":"add","id":1}')
        end.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when method key is missing' do
      it 'raises InvalidRequestError' do
        expect do
          parser.parse('{"jsonrpc":"2.0","id":1}')
        end.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when method is not a string' do
      it 'raises InvalidRequestError' do
        expect do
          parser.parse('{"jsonrpc":"2.0","method":42,"id":1}')
        end.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when id is an invalid type (Hash)' do
      it 'raises InvalidRequestError' do
        expect do
          parser.parse('{"jsonrpc":"2.0","method":"add","id":{}}')
        end.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when method starts with rpc. in a single notification (no id)' do
      it 'raises InvalidRequestError' do
        expect do
          parser.parse('{"jsonrpc":"2.0","method":"rpc.list"}')
        end.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when given a batch request' do
      it 'returns a BatchRequest with mixed requests and notifications' do
        json = '[{"jsonrpc":"2.0","method":"add","id":1},{"jsonrpc":"2.0","method":"notify"}]'
        result = parser.parse(json)

        expect(result).to be_a(JSONRPC::BatchRequest)
        expect(result.requests.length).to eq(2)
        expect(result.requests[0]).to be_a(JSONRPC::Request)
        expect(result.requests[1]).to be_a(JSONRPC::Notification)
      end
    end

    context 'when given an empty batch' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('[]') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when a batch item has a reserved rpc. method (notification, no id)' do
      it 'returns a BatchRequest where the invalid item is an InvalidRequestError' do
        json = '[{"jsonrpc":"2.0","method":"rpc.x"},{"jsonrpc":"2.0","method":"add","id":2}]'
        result = parser.parse(json)

        expect(result).to be_a(JSONRPC::BatchRequest)
        expect(result.requests[0]).to be_a(JSONRPC::InvalidRequestError)
        expect(result.requests[1]).to be_a(JSONRPC::Request)
      end
    end
  end
end
