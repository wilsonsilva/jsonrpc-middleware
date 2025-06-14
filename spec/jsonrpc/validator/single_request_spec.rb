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
    context 'when the method is not found' do
      it 'returns a method not found error' do
        request = JSONRPC::Request.new(method: 'john_cena', id: 'john_cena-1')
        error = validator.validate(request)

        expect(error).to be_a(JSONRPC::MethodNotFoundError)
        expect(error.request_id).to eq('john_cena-1')
        expect(error.data).to eq(method: 'john_cena')
        expect(error.message).to eq('The requested RPC method does not exist or is not supported.')
      end
    end

    describe 'positional arguments' do
      context 'when the positional arguments are missing' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'add', id: 'add-missing-positional-arguments')
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('add-missing-positional-arguments')
          expect(error.data).to eq(method: 'add', params: { addends: ['is missing'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when the positional arguments are nil' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'add', id: 'add-nil-positional-arguments', params: nil)
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('add-nil-positional-arguments')
          expect(error.data).to eq(method: 'add', params: { addends: ['is missing'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when the positional arguments are empty' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'add', id: 'add-empty-positional-arguments', params: [])
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('add-empty-positional-arguments')
          expect(error.data).to eq(method: 'add', params: { addends: ['must contain at least one addend'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when the positional arguments have the wrong value' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'add', id: 'add-value-positional-arguments', params: %w[one two])
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('add-value-positional-arguments')
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

      context 'when the positional arguments have the wrong arity' do
        it 'returns an invalid request params error' do
          pending 'Post-MVP'

          request = JSONRPC::Request.new(method: 'add', id: 'add-arity-positional-arguments', params: [1984])
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('add-arity-positional-arguments')
          expect(error.data).to eq(method: 'add')
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end
    end

    describe 'named arguments' do
      context 'when the named arguments are missing' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'subtract', id: 'subtract-missing-named-arguments')
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('subtract-missing-named-arguments')
          expect(error.data).to eq(method: 'subtract', params: { minuend: ['is missing'], subtrahend: ['is missing'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when the named arguments are nil' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'subtract', id: 'subtract-nil-named-arguments', params: nil)
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('subtract-nil-named-arguments')
          expect(error.data).to eq(method: 'subtract', params: { minuend: ['is missing'], subtrahend: ['is missing'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when the named arguments are empty' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'subtract', id: 'subtract-empty-named-arguments', params: {})
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('subtract-empty-named-arguments')
          expect(error.data).to eq(method: 'subtract', params: { minuend: ['is missing'], subtrahend: ['is missing'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when the named arguments have the wrong arity' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(
            method: 'subtract',
            id: 'subtract-arity-named-arguments',
            params: { minuend: 10 }
          )
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('subtract-arity-named-arguments')
          expect(error.data).to eq(method: 'subtract', params: { subtrahend: ['is missing'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when the named arguments have the wrong value' do
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(
            method: 'subtract',
            id: 'subtract-value-named-arguments',
            params: { minuend: 'ten', subtrahend: 'two' }
          )
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('subtract-value-named-arguments')
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
        it 'returns an invalid request params error' do
          request = JSONRPC::Request.new(method: 'subtract', id: 'subtract-positional-for-named', params: [10, 5])
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('subtract-positional-for-named')
          expect(error.data).to eq(method: 'subtract')
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end
    end

    describe 'successful validation' do
      context 'when positional arguments are valid' do
        it 'returns nil for successful validation' do
          request = JSONRPC::Request.new(method: 'add', id: 'add-valid-positional', params: [1, 2, 3])
          error = validator.validate(request)

          expect(error).to be_nil
        end
      end

      context 'when named arguments are valid' do
        it 'returns nil for successful validation' do
          request = JSONRPC::Request.new(
            method: 'subtract',
            id: 'subtract-valid-named',
            params: { minuend: 10, subtrahend: 5 }
          )
          error = validator.validate(request)

          expect(error).to be_nil
        end
      end

      context 'when procedure allows positional arguments but named are provided' do
        it 'returns nil for successful validation' do
          request = JSONRPC::Request.new(
            method: 'add',
            id: 'add-valid-named',
            params: { addends: [1, 2, 3] }
          )
          error = validator.validate(request)

          expect(error).to be_nil
        end
      end
    end

    describe 'custom validation rules' do
      context 'when custom rule validation fails' do
        it 'returns an invalid request params error for zero divisor' do
          request = JSONRPC::Request.new(
            method: 'divide',
            id: 'divide-zero-divisor',
            params: { dividend: 10, divisor: 0 }
          )
          error = validator.validate(request)

          expect(error).to be_a(JSONRPC::InvalidParamsError)
          expect(error.request_id).to eq('divide-zero-divisor')
          expect(error.data).to eq(method: 'divide', params: { divisor: ['cannot be zero'] })
          expect(error.message).to eq('Invalid method parameter(s).')
        end
      end

      context 'when custom rule validation passes' do
        it 'returns nil for successful validation' do
          request = JSONRPC::Request.new(
            method: 'divide',
            id: 'divide-valid',
            params: { dividend: 10, divisor: 2 }
          )
          error = validator.validate(request)

          expect(error).to be_nil
        end
      end
    end
  end
end
