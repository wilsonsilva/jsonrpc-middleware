# frozen_string_literal: true

RSpec.describe JSONRPC::MapperExtension do
  # A minimal Mapper substitute that includes the extension and records `post` calls.
  let(:mapper) do
    fake_mapper_class = Class.new do
      include JSONRPC::MapperExtension

      attr_reader :calls

      def initialize
        @calls = []
      end

      def post(*args, **kwargs)
        @calls << { args: args, kwargs: kwargs }
      end
    end
    fake_mapper_class.new
  end

  describe '#jsonrpc' do
    context 'when given a block that declares a method' do
      before do
        mapper.jsonrpc('/api') do
          method :ping, to: 'system#ping'
        end
      end

      it 'registers a POST route at the given path' do
        expect(mapper.calls.first[:args].first).to eq('/api')
      end

      it 'routes to the controller action declared in the block' do
        expect(mapper.calls.first[:args].last[:to]).to eq('system#ping')
      end

      it 'attaches a MethodConstraint built from the declared method name' do
        constraint = mapper.calls.first[:args].last[:constraints]
        request = Struct.new(:env).new({ 'jsonrpc.request' => JSONRPC::Request.new(method: 'ping', params: {}, id: 1) })
        expect(constraint).to be_a(JSONRPC::MethodConstraint)
        expect(constraint.matches?(request)).to be(true)
      end
    end

    context 'when called without a path argument' do
      before do
        mapper.jsonrpc do
          method :ping, to: 'system#ping'
        end
      end

      it 'defaults the path to the root' do
        expect(mapper.calls.first[:args].first).to eq('/')
      end
    end
  end
end
