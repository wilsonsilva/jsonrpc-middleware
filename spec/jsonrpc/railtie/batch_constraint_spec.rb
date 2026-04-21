# frozen_string_literal: true

RSpec.describe JSONRPC::BatchConstraint do
  describe '#matches?' do
    let(:constraint) { described_class.new }

    context 'when the Rack env contains a jsonrpc.batch entry' do
      let(:batch) { JSONRPC::BatchRequest.new([JSONRPC::Notification.new(method: 'noop', params: {})]) }
      let(:request) { ActionDispatch::Request.new('jsonrpc.batch' => batch) }

      it 'matches the request' do
        expect(constraint.matches?(request)).to be(true)
      end
    end

    context 'when the Rack env does not contain a jsonrpc.batch entry' do
      let(:request) { ActionDispatch::Request.new({}) }

      it 'does not match the request' do
        expect(constraint.matches?(request)).to be(false)
      end
    end
  end
end
