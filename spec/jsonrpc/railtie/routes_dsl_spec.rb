# frozen_string_literal: true

RSpec.describe JSONRPC::RoutesDsl do
  # Create a lightweight fake mapper that records route definitions.
  # This avoids loading the entire ActionDispatch stack while still
  # accurately testing the DSL's behavior.
  let(:fake_mapper_class) do
    Class.new do
      attr_reader :routes

      def initialize
        @routes = []
      end

      # Stub for ActionDispatch::Routing::Mapper#post
      def post(path, to:, constraints:)
        @routes << { path: path, to: to, constraints: constraints }
      end
    end
  end

  let(:mapper) { fake_mapper_class.new }

  # Build a Rack request carrying a JSON-RPC request for the given method name.
  # Constraints are verified through their public #matches? rather than by
  # inspecting internals, keeping these tests black box.
  def request_for(method_name)
    jsonrpc_request = JSONRPC::Request.new(method: method_name, id: 1)
    ActionDispatch::Request.new('jsonrpc.request' => jsonrpc_request)
  end

  describe '#method' do
    context 'with the default path' do
      let(:dsl) { described_class.new(mapper) }

      it 'maps a JSON-RPC method to the root path' do
        dsl.method(:ping, to: 'system#ping')

        expect(mapper.routes.size).to eq(1)
        expect(mapper.routes.first[:path]).to eq('/')
      end

      it 'routes to the correct controller action' do
        dsl.method(:ping, to: 'system#ping')

        expect(mapper.routes.first[:to]).to eq('system#ping')
      end

      it 'applies a MethodConstraint' do
        dsl.method(:ping, to: 'system#ping')

        expect(mapper.routes.first[:constraints]).to be_a(JSONRPC::MethodConstraint)
      end

      it 'uses the bare method name when not namespaced' do
        dsl.method(:ping, to: 'system#ping')

        constraint = mapper.routes.first[:constraints]
        expect(constraint.matches?(request_for('ping'))).to be(true)
      end
    end

    context 'with a custom path prefix' do
      let(:dsl) { described_class.new(mapper, '/api/v1') }

      it 'maps the method to the custom path' do
        dsl.method(:status, to: 'system#status')

        expect(mapper.routes.first[:path]).to eq('/api/v1')
        expect(mapper.routes.first[:to]).to eq('system#status')
      end
    end

    context 'with a missing :to keyword argument' do
      let(:dsl) { described_class.new(mapper) }

      it 'raises an ArgumentError' do
        expect { dsl.method(:ping) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#batch' do
    context 'with the default path' do
      let(:dsl) { described_class.new(mapper) }

      it 'maps the batch route to the root path' do
        dsl.batch(to: 'batch#handle')

        expect(mapper.routes.size).to eq(1)
        expect(mapper.routes.first[:path]).to eq('/')
      end

      it 'routes to the correct batch controller action' do
        dsl.batch(to: 'batch#handle')

        expect(mapper.routes.first[:to]).to eq('batch#handle')
      end

      it 'applies a BatchConstraint' do
        dsl.batch(to: 'batch#handle')

        expect(mapper.routes.first[:constraints]).to be_a(JSONRPC::BatchConstraint)
      end
    end

    context 'with a custom path prefix' do
      let(:dsl) { described_class.new(mapper, '/api/v1') }

      it 'maps the batch route to the custom path' do
        dsl.batch(to: 'batch#handle')

        expect(mapper.routes.first[:path]).to eq('/api/v1')
      end
    end

    context 'with a missing :to keyword argument' do
      let(:dsl) { described_class.new(mapper) }

      it 'raises an ArgumentError' do
        expect { dsl.batch }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#namespace' do
    context 'with a single-level namespace' do
      let(:dsl) { described_class.new(mapper) }

      it 'maps all methods in the namespace' do
        dsl.namespace 'users' do
          method :create, to: 'users#create'
          method :list, to: 'users#index'
        end

        expect(mapper.routes.size).to eq(2)
      end

      it 'prefixes the method names with the namespace' do
        dsl.namespace 'users' do
          method :create, to: 'users#create'
          method :list, to: 'users#index'
        end

        create_route = mapper.routes.find { |r| r[:to] == 'users#create' }
        list_route = mapper.routes.find { |r| r[:to] == 'users#index' }

        # Verify the full method name via the constraint's public matching behavior
        expect(create_route[:constraints].matches?(request_for('users.create'))).to be(true)
        expect(list_route[:constraints].matches?(request_for('users.list'))).to be(true)
      end
    end

    context 'with nested namespaces' do
      let(:dsl) { described_class.new(mapper, '/api') }

      it 'creates dot-separated method names for deep nesting' do
        dsl.namespace 'climate' do
          method :status, to: 'climate#status'

          namespace 'fan' do
            method :on, to: 'fan#on'
          end
        end

        status_route = mapper.routes.find { |r| r[:to] == 'climate#status' }
        expect(status_route[:constraints].matches?(request_for('climate.status'))).to be(true)

        fan_on_route = mapper.routes.find { |r| r[:to] == 'fan#on' }
        expect(fan_on_route[:constraints].matches?(request_for('climate.fan.on'))).to be(true)
      end

      it 'uses the correct base path for all nested routes' do
        dsl.namespace 'climate' do
          method :status, to: 'climate#status'

          namespace 'fan' do
            method :on, to: 'fan#on'
          end
        end

        expect(mapper.routes).to all(include(path: '/api'))
      end
    end

    context 'when a method follows an inner namespace in the same block' do
      let(:dsl) { described_class.new(mapper) }

      it 'prefixes with the outer namespace, not the inner one' do
        dsl.namespace 'climate' do
          namespace 'fan' do
            method :on, to: 'fan#on'
          end

          method :status, to: 'climate#status'
        end

        status_route = mapper.routes.find { |r| r[:to] == 'climate#status' }
        expect(status_route[:constraints].matches?(request_for('climate.status'))).to be(true)
        expect(status_route[:constraints].matches?(request_for('fan.status'))).to be(false)
      end
    end

    context 'when the namespace stack is unwound after the block' do
      let(:dsl) { described_class.new(mapper) }

      it 'does not prefix methods defined after the namespace block' do
        dsl.namespace 'users' do
          method :create, to: 'users#create'
        end

        dsl.method(:ping, to: 'system#ping')

        ping_route = mapper.routes.find { |r| r[:to] == 'system#ping' }
        expect(ping_route[:constraints].matches?(request_for('ping'))).to be(true)
        expect(ping_route[:constraints].matches?(request_for('users.ping'))).to be(false)
      end
    end
  end
end
