# frozen_string_literal: true

RSpec.describe JSONRPC::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    context 'when given valid JSON for a single request' do
      it 'returns the parsed request' do
        expect(parser.parse('{"jsonrpc":"2.0","method":"add","id":1}')).to eq(
          JSONRPC::Request.new(method: 'add', id: 1)
        )
      end
    end

    context 'when given valid JSON for a notification' do
      it 'returns the parsed notification' do
        expect(parser.parse('{"jsonrpc":"2.0","method":"update","params":[1,2]}')).to eq(
          JSONRPC::Notification.new(method: 'update', params: [1, 2])
        )
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
      it 'returns the parsed batch request' do
        json = '[{"jsonrpc":"2.0","method":"add","id":1},{"jsonrpc":"2.0","method":"notify"}]'

        expect(parser.parse(json)).to eq(
          JSONRPC::BatchRequest.new(
            [
              JSONRPC::Request.new(method: 'add', id: 1),
              JSONRPC::Notification.new(method: 'notify')
            ]
          )
        )
      end
    end

    context 'when given an empty batch' do
      it 'raises InvalidRequestError' do
        expect { parser.parse('[]') }.to raise_error(JSONRPC::InvalidRequestError)
      end
    end

    context 'when a batch item uses a reserved rpc. method' do
      it 'returns a batch with the invalid item captured as an error' do
        json = '[{"jsonrpc":"2.0","method":"rpc.x"},{"jsonrpc":"2.0","method":"add","id":2}]'

        expect(parser.parse(json)).to eq(
          JSONRPC::BatchRequest.new(
            [
              JSONRPC::InvalidRequestError.new(
                data: { index: 0, details: "Method names starting with 'rpc.' are reserved" }
              ),
              JSONRPC::Request.new(method: 'add', id: 2)
            ]
          )
        )
      end
    end
  end
end
