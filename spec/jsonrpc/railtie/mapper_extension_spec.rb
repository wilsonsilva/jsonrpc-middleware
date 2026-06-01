# frozen_string_literal: true

RSpec.describe JSONRPC::MapperExtension do
  # Create a lightweight fake mapper that records route definitions.
  # This avoids loading the entire ActionDispatch stack while still
  # accurately testing the DSL's behavior.
  let(:fake_mapper_class) do
    Class.new do
      include JSONRPC::MapperExtension

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

  describe '#jsonrpc' do
    context 'with an empty block' do
      it 'does not add any routes' do
        mapper.jsonrpc {} # rubocop:disable Lint/EmptyBlock
        expect(mapper.routes).to be_empty
      end
    end

    context 'with the default path' do
      before do
        mapper.jsonrpc do
          method :ping, to: 'system#ping'
        end
      end

      it 'maps a JSON-RPC method to the root path' do
        expect(mapper.routes.size).to eq(1)
        expect(mapper.routes.first[:path]).to eq('/')
      end

      it 'routes to the correct controller action' do
        expect(mapper.routes.first[:to]).to eq('system#ping')
      end

      it 'applies a MethodConstraint' do
        expect(mapper.routes.first[:constraints]).to be_a(JSONRPC::MethodConstraint)
      end
    end

    context 'with a custom path prefix' do
      before do
        mapper.jsonrpc '/api/v1' do
          method :status, to: 'system#status'
        end
      end

      it 'maps the method to the custom path' do
        expect(mapper.routes.first[:path]).to eq('/api/v1')
        expect(mapper.routes.first[:to]).to eq('system#status')
      end
    end

    context 'with a batch route' do
      before do
        mapper.jsonrpc do
          batch to: 'batch#handle'
        end
      end

      it 'routes to the correct batch controller action' do
        expect(mapper.routes.first[:to]).to eq('batch#handle')
      end

      it 'applies a BatchConstraint' do
        expect(mapper.routes.first[:constraints]).to be_a(JSONRPC::BatchConstraint)
      end
    end

    context 'with namespaces' do
      context 'with a single-level namespace' do
        before do
          mapper.jsonrpc do
            namespace 'users' do
              method :create, to: 'users#create'
              method :list, to: 'users#index'
            end
          end
        end

        it 'maps all methods in the namespace' do
          expect(mapper.routes.size).to eq(2)
        end

        it 'prefixes the method names with the namespace' do
          create_route = mapper.routes.find { |r| r[:to] == 'users#create' }
          list_route = mapper.routes.find { |r| r[:to] == 'users#index' }

          # Verify the full method name via the constraint's public matching behavior
          expect(create_route[:constraints].matches?(request_for('users.create'))).to be(true)
          expect(list_route[:constraints].matches?(request_for('users.list'))).to be(true)
        end
      end

      context 'with nested namespaces' do
        before do
          mapper.jsonrpc '/api' do
            namespace 'climate' do
              method :status, to: 'climate#status'

              namespace 'fan' do
                method :on, to: 'fan#on'
              end
            end
          end
        end

        it 'creates dot-separated method names for deep nesting' do
          status_route = mapper.routes.find { |r| r[:to] == 'climate#status' }
          expect(status_route[:constraints].matches?(request_for('climate.status'))).to be(true)

          fan_on_route = mapper.routes.find { |r| r[:to] == 'fan#on' }
          expect(fan_on_route[:constraints].matches?(request_for('climate.fan.on'))).to be(true)
        end

        it 'uses the correct base path for all nested routes' do
          expect(mapper.routes).to all(include(path: '/api'))
        end
      end
    end

    context 'with missing keyword arguments' do
      it 'raises an ArgumentError when :to is missing for method' do
        expect do
          mapper.jsonrpc do
            method :ping
          end
        end.to raise_error(ArgumentError)
      end

      it 'raises an ArgumentError when :to is missing for batch' do
        expect do
          mapper.jsonrpc do
            batch
          end
        end.to raise_error(ArgumentError)
      end
    end
  end
end
