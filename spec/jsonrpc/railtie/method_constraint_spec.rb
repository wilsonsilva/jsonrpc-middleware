# frozen_string_literal: true

RSpec.describe JSONRPC::MethodConstraint do
  describe '#matches?' do
    context 'when the JSON-RPC request method name matches the constraint method name' do
      let(:jsonrpc_request) { JSONRPC::Request.new(method: 'subtract', params: { minuend: 42, subtrahend: 23 }, id: 1) }
      let(:matching_constraint) { described_class.new('subtract') }
      let(:rack_request) { ActionDispatch::Request.new('jsonrpc.request' => jsonrpc_request) }

      it 'returns true because the JSON-RPC method name equals the constraint method name' do
        expect(matching_constraint.matches?(rack_request)).to be(true)
      end
    end

    context 'when the JSON-RPC request method name does not match the constraint method name' do
      let(:jsonrpc_request) { JSONRPC::Request.new(method: 'subtract', params: { minuend: 42, subtrahend: 23 }, id: 1) }
      let(:non_matching_constraint) { described_class.new('add') }
      let(:rack_request) { ActionDispatch::Request.new('jsonrpc.request' => jsonrpc_request) }

      it 'returns false because the JSON-RPC method name differs from the constraint method name' do
        expect(non_matching_constraint.matches?(rack_request)).to be(false)
      end
    end

    context 'when the Rack env does not contain a jsonrpc.request key' do
      let(:constraint_for_missing_env) { described_class.new('subtract') }
      let(:rack_request) { ActionDispatch::Request.new({}) }

      it 'returns false because there is no JSON-RPC request in the Rack env to evaluate' do
        expect(constraint_for_missing_env.matches?(rack_request)).to be(false)
      end
    end

    context 'when the constraint is initialized with a symbol method name' do
      let(:jsonrpc_request) { JSONRPC::Request.new(method: 'subtract', params: { minuend: 42, subtrahend: 23 }, id: 1) }
      let(:symbol_method_constraint) { described_class.new(:subtract) }
      let(:rack_request) { ActionDispatch::Request.new('jsonrpc.request' => jsonrpc_request) }

      it 'returns true because the constraint coerces the symbol method name to a string before comparing' do
        expect(symbol_method_constraint.matches?(rack_request)).to be(true)
      end
    end
  end

  describe '#to_s' do
    let(:constraint) { described_class.new('subtract') }

    it 'returns a string representation including the method name' do
      expect(constraint.to_s).to eq('#<JSONRPC::MethodConstraint method="subtract">')
    end
  end
end
