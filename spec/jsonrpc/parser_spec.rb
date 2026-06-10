# frozen_string_literal: true

RSpec.describe JSONRPC::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    context 'when given valid JSON for a single request' do
      let(:result) { parser.parse('{"jsonrpc":"2.0","method":"add","id":1}') }

      it 'returns a Request' do
        expect(result).to be_a(JSONRPC::Request)
      end

      it 'sets the method' do
        expect(result.method).to eq('add')
      end

      it 'sets the id' do
        expect(result.id).to eq(1)
      end
    end

    context 'when given valid JSON for a notification' do
      let(:result) { parser.parse('{"jsonrpc":"2.0","method":"update","params":[1,2]}') }

      it 'returns a Notification' do
        expect(result).to be_a(JSONRPC::Notification)
      end

      it 'sets the method' do
        expect(result.method).to eq('update')
      end
    end

    context 'when given invalid JSON' do
      it 'raises ParseError' do
        expect { parser.parse('{not valid json') }.to raise_error(JSONRPC::ParseError)
      end
    end

    context 'when the jsonrpc version is missing' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('{"method":"add","id":1}') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when the jsonrpc version is not 2.0' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('{"jsonrpc":"1.0","method":"add","id":1}') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when the method key is missing' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('{"jsonrpc":"2.0","id":1}') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when the method is not a string' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('{"jsonrpc":"2.0","method":42,"id":1}') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when the id is an invalid type' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('{"jsonrpc":"2.0","method":"add","id":{}}') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when a notification uses a reserved rpc. method' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('{"jsonrpc":"2.0","method":"rpc.list"}') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when given a batch request' do
      let(:result) do
        parser.parse('[{"jsonrpc":"2.0","method":"add","id":1},{"jsonrpc":"2.0","method":"notify"}]')
      end

      it 'returns a BatchRequest' do
        expect(result).to be_a(JSONRPC::BatchRequest)
      end

      it 'parses every item' do
        expect(result.requests.length).to eq(2)
      end

      it 'parses an item with an id as a Request' do
        expect(result.requests[0]).to be_a(JSONRPC::Request)
      end

      it 'parses an item without an id as a Notification' do
        expect(result.requests[1]).to be_a(JSONRPC::Notification)
      end
    end

    context 'when given an empty batch' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('[]') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when a batch item uses a reserved rpc. method' do
      let(:result) do
        parser.parse('[{"jsonrpc":"2.0","method":"rpc.x"},{"jsonrpc":"2.0","method":"add","id":2}]')
      end

      it 'captures the invalid item as an InvalidRequestError' do
        expect(result.requests[0]).to be_a(JSONRPC::InvalidRequestError)
      end

      it 'parses the valid item as a Request' do
        expect(result.requests[1]).to be_a(JSONRPC::Request)
      end
    end
  end
end
