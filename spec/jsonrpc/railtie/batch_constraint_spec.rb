# frozen_string_literal: true

RSpec.describe JSONRPC::BatchConstraint do
  describe '#matches?' do
    let(:constraint) { described_class.new }
    let(:request) { ActionDispatch::Request.new(env) }

    context 'when the Rack env contains a jsonrpc.batch entry' do
      let(:batch) do
        JSONRPC::BatchRequest.new([JSONRPC::Notification.new(method: 'noop', params: {})])
      end
      let(:env) { { 'jsonrpc.batch' => batch } }

      it 'matches the request' do
        expect(constraint.matches?(request)).to be(true)
      end
    end

    context 'when the Rack env does not contain a jsonrpc.batch entry' do
      let(:env) { {} }

      it 'does not match the request' do
        expect(constraint.matches?(request)).to be(false)
      end
    end
  end
end
