# frozen_string_literal: true

RSpec.describe JSONRPC::BatchConstraint do
  describe '#matches?' do
    context 'when the Rack env contains a jsonrpc.batch entry' do
      let(:jsonrpc_request) { JSONRPC::Request.new(id: 1, method: 'noop', params: { addends: [2, 3] }) }
      let(:jsonrpc_batch) { JSONRPC::BatchRequest.new([jsonrpc_request]) }
      let(:request) { ActionDispatch::Request.new('jsonrpc.batch' => jsonrpc_batch) }
      let(:constraint) { described_class.new }

      it 'matches the request' do
        expect(constraint.matches?(request)).to be(true)
      end
    end

    context 'when the Rack env does not contain a jsonrpc.batch entry' do
      let(:request) { ActionDispatch::Request.new({}) }
      let(:constraint) { described_class.new }

      it 'does not match the request' do
        expect(constraint.matches?(request)).to be(false)
      end
    end
  end
end
