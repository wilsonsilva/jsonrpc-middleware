# frozen_string_literal: true

RSpec.describe JSONRPC::Validator do
  let(:validator) { described_class.new }

  before do
    JSONRPC.configure do
      procedure(:add, allow_positional_arguments: true) do
        params do
          required(:addends).filled(:array)
          required(:addends).value(:array).each(type?: Numeric)
        end

        rule(:addends) do
          key.failure('must contain at least one addend') if value.empty?
        end
      end

      procedure(:subtract) do
        params do
          required(:minuend).filled(:integer)
          required(:subtrahend).filled(:integer)
        end
      end

      procedure(:multiply) do
        params do
          required(:multiplicand).filled
          required(:multiplier).filled
        end

        rule(:multiplicand) do
          key.failure('must be a number') unless value.is_a?(Numeric)
        end

        rule(:multiplier) do
          key.failure('must be a number') unless value.is_a?(Numeric)
        end
      end

      procedure(:divide) do
        params do
          required(:dividend).filled(:integer)
          required(:divisor).filled(:integer)
        end

        rule(:divisor) do
          key.failure('cannot be zero') if value.zero?
        end
      end
    end
  end

  after do
    JSONRPC.configuration.reset!
  end

  describe '#validate' do
    context 'when given a single notification' do
      context 'when the method is not found' do
        it 'returns a method not found error without request_id' do
          notification = JSONRPC::Notification.new(method: 'john_cena')
          error = validator.validate(notification)

          expect(error).to be_a(JSONRPC::MethodNotFoundError)
          expect(error.request_id).to be_nil
          expect(error.data).to eq(method: 'john_cena')
          expect(error.message).to eq('The requested RPC method does not exist or is not supported.')
        end
      end

      describe 'positional arguments' do
        context 'when the positional arguments are missing' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'add')
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(method: 'add', params: { addends: ['is missing'] })
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when the positional arguments are nil' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'add', params: nil)
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(method: 'add', params: { addends: ['is missing'] })
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when the positional arguments are empty' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'add', params: [])
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(method: 'add', params: { addends: ['must contain at least one addend'] })
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when the positional arguments have the wrong value' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'add', params: %w[one two])
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(
              method: 'add',
              params: {
                addends: {
                  0 => ['must be Numeric'],
                  1 => ['must be Numeric']
                }
              }
            )
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end
      end

      describe 'named arguments' do
        context 'when the named arguments are missing' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'subtract')
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(
              method: 'subtract',
              params: {
                minuend: ['is missing'],
                subtrahend: ['is missing']
              }
            )
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when the named arguments are nil' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'subtract', params: nil)
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(
              method: 'subtract',
              params: {
                minuend: ['is missing'],
                subtrahend: ['is missing']
              }
            )
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when the named arguments are empty' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'subtract', params: {})
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(
              method: 'subtract',
              params: {
                minuend: ['is missing'],
                subtrahend: ['is missing']
              }
            )
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when the named arguments have the wrong arity' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(
              method: 'subtract',
              params: { minuend: 10 }
            )
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(method: 'subtract', params: { subtrahend: ['is missing'] })
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when the named arguments have the wrong value' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(
              method: 'subtract',
              params: { minuend: 'ten', subtrahend: 'two' }
            )
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(
              method: 'subtract',
              params: {
                minuend: ['must be an integer'],
                subtrahend: ['must be an integer']
              }
            )
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when positional arguments are provided for a named-only procedure' do
          it 'returns an invalid params error without request_id' do
            notification = JSONRPC::Notification.new(method: 'subtract', params: [10, 5])
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(method: 'subtract')
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end
      end

      describe 'successful validation' do
        context 'when positional arguments are valid' do
          it 'returns nil for successful validation' do
            notification = JSONRPC::Notification.new(method: 'add', params: [1, 2, 3])
            error = validator.validate(notification)

            expect(error).to be_nil
          end
        end

        context 'when named arguments are valid' do
          it 'returns nil for successful validation' do
            notification = JSONRPC::Notification.new(
              method: 'subtract',
              params: { minuend: 10, subtrahend: 5 }
            )
            error = validator.validate(notification)

            expect(error).to be_nil
          end
        end

        context 'when procedure allows positional arguments but named are provided' do
          it 'returns nil for successful validation' do
            notification = JSONRPC::Notification.new(
              method: 'add',
              params: { addends: [1, 2, 3] }
            )
            error = validator.validate(notification)

            expect(error).to be_nil
          end
        end
      end

      describe 'custom validation rules' do
        context 'when custom rule validation fails' do
          it 'returns an invalid params error without request_id for zero divisor' do
            notification = JSONRPC::Notification.new(
              method: 'divide',
              params: { dividend: 10, divisor: 0 }
            )
            error = validator.validate(notification)

            expect(error).to be_a(JSONRPC::InvalidParamsError)
            expect(error.request_id).to be_nil
            expect(error.data).to eq(method: 'divide', params: { divisor: ['cannot be zero'] })
            expect(error.message).to eq('Invalid method parameter(s).')
          end
        end

        context 'when custom rule validation passes' do
          it 'returns nil for successful validation' do
            notification = JSONRPC::Notification.new(
              method: 'divide',
              params: { dividend: 10, divisor: 2 }
            )
            error = validator.validate(notification)

            expect(error).to be_nil
          end
        end
      end
    end
  end
end
