# frozen_string_literal: true

RSpec.describe JSONRPC::RoutesDsl do
  # Minimal PORO that records every `post` call the DSL makes on the mapper.
  # Avoids coupling unit tests to ActionDispatch internals.
  let(:mapper) do
    Class.new do
      attr_reader :calls

      def initialize
        @calls = []
      end

      def post(*args, **kwargs)
        @calls << { args: args, kwargs: kwargs }
      end
    end.new
  end

  def fake_request_for(method_name)
    Struct.new(:env).new({ 'jsonrpc.request' => JSONRPC::Request.new(method: method_name, params: {}, id: 1) })
  end

  def fake_batch_request
    notification = JSONRPC::Notification.new(method: 'noop', params: {})
    batch = JSONRPC::BatchRequest.new([notification])
    Struct.new(:env).new({ 'jsonrpc.batch' => batch })
  end

  describe '#method' do
    context 'when declared at the root path' do
      before do
        described_class.new(mapper, '/rpc').instance_eval { method :add, to: 'math#add' }
      end

      let(:call) { mapper.calls.first }
      let(:path) { call[:args].first }
      let(:options) { call[:args].last }

      it 'registers a POST route at the given path' do
        expect(path).to eq('/rpc')
      end

      it 'routes to the given controller action' do
        expect(options[:to]).to eq('math#add')
      end

      it 'uses a MethodConstraint that matches the bare method name' do
        constraint = options[:constraints]
        expect(constraint).to be_a(JSONRPC::MethodConstraint)
        expect(constraint.matches?(fake_request_for('add'))).to be(true)
      end
    end

    context 'when declared inside a single namespace' do
      before do
        described_class.new(mapper, '/').instance_eval do
          namespace 'users' do
            method :create, to: 'users#create'
          end
        end
      end

      let(:constraint) { mapper.calls.first[:args].last[:constraints] }

      it 'prefixes the method name with the namespace' do
        expect(constraint.matches?(fake_request_for('users.create'))).to be(true)
      end

      it 'does not match the bare method name' do
        expect(constraint.matches?(fake_request_for('create'))).to be(false)
      end
    end

    context 'when declared inside nested namespaces' do
      before do
        described_class.new(mapper, '/').instance_eval do
          namespace 'climate' do
            namespace 'fan' do
              method :on, to: 'fan#on'
            end
          end
        end
      end

      it 'prefixes the method name with every namespace' do
        constraint = mapper.calls.first[:args].last[:constraints]
        expect(constraint.matches?(fake_request_for('climate.fan.on'))).to be(true)
      end
    end

    context 'when declared after a namespace block returns' do
      before do
        described_class.new(mapper, '/').instance_eval do
          namespace 'math' do
            method :multiply, to: 'math#multiply'
          end

          method :add, to: 'math#add'
        end
      end

      it 'leaves the root-level method unprefixed' do
        constraint = mapper.calls.last[:args].last[:constraints]
        expect(constraint.matches?(fake_request_for('add'))).to be(true)
      end
    end
  end

  describe '#batch' do
    before do
      described_class.new(mapper, '/').instance_eval { batch to: 'batches#handle' }
    end

    let(:call) { mapper.calls.first }
    let(:path) { call[:args].first }
    let(:options) { call[:args].last }

    it 'registers a POST route at the given path' do
      expect(path).to eq('/')
    end

    it 'routes to the given controller action' do
      expect(options[:to]).to eq('batches#handle')
    end

    it 'uses a BatchConstraint that matches batch requests' do
      constraint = options[:constraints]
      expect(constraint).to be_a(JSONRPC::BatchConstraint)
      expect(constraint.matches?(fake_batch_request)).to be(true)
    end
  end
end
