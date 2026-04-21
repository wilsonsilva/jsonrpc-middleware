# frozen_string_literal: true

RSpec.describe JSONRPC::MethodConstraint do
  describe '#matches?' do
    let(:jsonrpc_request) { JSONRPC::Request.new(method: 'subtract', params: {}, id: 1) }

    context 'when the jsonrpc.request method matches' do
      let(:constraint) { described_class.new('subtract') }
      let(:request) { ActionDispatch::Request.new('jsonrpc.request' => jsonrpc_request) }

      it 'matches the request' do
        expect(constraint.matches?(request)).to be(true)
      end
    end

    context 'when the jsonrpc.request method does not match' do
      let(:constraint) { described_class.new('add') }
      let(:request) { ActionDispatch::Request.new('jsonrpc.request' => jsonrpc_request) }

      it 'does not match the request' do
        expect(constraint.matches?(request)).to be(false)
      end
    end

    context 'when the Rack env does not contain a jsonrpc.request entry' do
      let(:constraint) { described_class.new('subtract') }
      let(:request) { ActionDispatch::Request.new({}) }

      it 'does not match the request' do
        expect(constraint.matches?(request)).to be(false)
      end
    end

    context 'when the method name is given as a symbol' do
      let(:constraint) { described_class.new(:subtract) }
      let(:request) { ActionDispatch::Request.new('jsonrpc.request' => jsonrpc_request) }

      it 'still matches a request whose method is the equivalent string' do
        expect(constraint.matches?(request)).to be(true)
      end
    end
  end
end
