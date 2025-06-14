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

      procedure(:notify) do
        params do
          optional(:message).filled(:string)
        end
      end
    end
  end

  after do
    JSONRPC.configuration.reset!
  end

  describe '#validate' do
    context 'when given a batch' do
      context 'when all requests are successful' do
        it 'returns nil for successful batch validation' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Request.new(method: 'add', params: [1, 2, 3], id: 'req1'),
              JSONRPC::Request.new(method: 'subtract', params: { minuend: 10, subtrahend: 5 }, id: 'req2'),
              JSONRPC::Request.new(method: 'multiply', params: { multiplicand: 3, multiplier: 4 }, id: 'req3')
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_nil
        end
      end

      context 'when all requests are erroneous' do
        it 'returns an array of errors for all failed validations' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Request.new(method: 'unknown_method', params: [], id: 'req1'),
              JSONRPC::Request.new(method: 'add', params: [], id: 'req2'),
              JSONRPC::Request.new(method: 'subtract', params: { minuend: 'invalid' }, id: 'req3')
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_an(Array)
          expect(result.length).to eq(3)

          expect(result[0]).to be_a(JSONRPC::MethodNotFoundError)
          expect(result[0].request_id).to eq('req1')
          expect(result[0].data).to eq(method: 'unknown_method')

          expect(result[1]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[1].request_id).to eq('req2')
          expect(result[1].data).to eq(method: 'add', params: { addends: ['must contain at least one addend'] })

          expect(result[2]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[2].request_id).to eq('req3')
          expect(result[2].data).to eq(
            method: 'subtract',
            params: {
              minuend: ['must be an integer'],
              subtrahend: ['is missing']
            }
          )
        end
      end

      context 'when some requests are successful and some are erroneous' do
        it 'returns an array with nils for successful validations and errors for failed ones' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Request.new(method: 'add', params: [1, 2, 3], id: 'req1'),
              JSONRPC::Request.new(method: 'unknown_method', params: [], id: 'req2'),
              JSONRPC::Request.new(method: 'subtract', params: { minuend: 10, subtrahend: 5 }, id: 'req3'),
              JSONRPC::Request.new(method: 'add', params: [], id: 'req4')
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_an(Array)
          expect(result.length).to eq(4)

          expect(result[0]).to be_nil

          expect(result[1]).to be_a(JSONRPC::MethodNotFoundError)
          expect(result[1].request_id).to eq('req2')

          expect(result[2]).to be_nil

          expect(result[3]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[3].request_id).to eq('req4')
        end
      end

      context 'when all notifications are successful' do
        it 'returns nil for successful batch validation' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Notification.new(method: 'notify'),
              JSONRPC::Notification.new(method: 'notify', params: { message: 'hello' }),
              JSONRPC::Notification.new(method: 'add', params: [1, 2, 3])
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_nil
        end
      end

      context 'when all notifications are erroneous' do
        it 'returns an array of errors for all failed validations' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Notification.new(method: 'unknown_method'),
              JSONRPC::Notification.new(method: 'add', params: []),
              JSONRPC::Notification.new(method: 'subtract', params: { minuend: 'invalid' })
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_an(Array)
          expect(result.length).to eq(3)

          expect(result[0]).to be_a(JSONRPC::MethodNotFoundError)
          expect(result[0].request_id).to be_nil
          expect(result[0].data).to eq(method: 'unknown_method')

          expect(result[1]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[1].request_id).to be_nil
          expect(result[1].data).to eq(method: 'add', params: { addends: ['must contain at least one addend'] })

          expect(result[2]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[2].request_id).to be_nil
          expect(result[2].data).to eq(
            method: 'subtract',
            params: {
              minuend: ['must be an integer'],
              subtrahend: ['is missing']
            }
          )
        end
      end

      context 'when some notifications are successful and some are erroneous' do
        it 'returns an array with nils for successful validations and errors for failed ones' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Notification.new(method: 'notify'),
              JSONRPC::Notification.new(method: 'unknown_method'),
              JSONRPC::Notification.new(method: 'add', params: [1, 2, 3]),
              JSONRPC::Notification.new(method: 'subtract', params: { minuend: 'invalid' })
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_an(Array)
          expect(result.length).to eq(4)

          expect(result[0]).to be_nil

          expect(result[1]).to be_a(JSONRPC::MethodNotFoundError)
          expect(result[1].request_id).to be_nil

          expect(result[2]).to be_nil

          expect(result[3]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[3].request_id).to be_nil
        end
      end

      context 'when all requests and notifications are successful' do
        it 'returns nil for successful batch validation' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Request.new(method: 'add', params: [1, 2, 3], id: 'req1'),
              JSONRPC::Notification.new(method: 'notify'),
              JSONRPC::Request.new(method: 'subtract', params: { minuend: 10, subtrahend: 5 }, id: 'req2'),
              JSONRPC::Notification.new(method: 'add', params: [4, 5, 6])
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_nil
        end
      end

      context 'when all requests and notifications are erroneous' do
        it 'returns an array of errors for all failed validations' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Request.new(method: 'unknown_method', params: [], id: 'req1'),
              JSONRPC::Notification.new(method: 'unknown_method2'),
              JSONRPC::Request.new(method: 'add', params: [], id: 'req2'),
              JSONRPC::Notification.new(method: 'subtract', params: { minuend: 'invalid' })
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_an(Array)
          expect(result.length).to eq(4)

          expect(result[0]).to be_a(JSONRPC::MethodNotFoundError)
          expect(result[0].request_id).to eq('req1')

          expect(result[1]).to be_a(JSONRPC::MethodNotFoundError)
          expect(result[1].request_id).to be_nil

          expect(result[2]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[2].request_id).to eq('req2')

          expect(result[3]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[3].request_id).to be_nil
        end
      end

      context 'when some requests and notifications are successful and some are erroneous' do
        it 'returns an array with nils for successful validations and errors for failed ones' do
          batch = JSONRPC::BatchRequest.new(
            [
              JSONRPC::Request.new(method: 'add', params: [1, 2, 3], id: 'req1'),
              JSONRPC::Notification.new(method: 'unknown_method'),
              JSONRPC::Request.new(method: 'subtract', params: { minuend: 10, subtrahend: 5 }, id: 'req2'),
              JSONRPC::Notification.new(method: 'add', params: []),
              JSONRPC::Request.new(method: 'multiply', params: { multiplicand: 3, multiplier: 4 }, id: 'req3'),
              JSONRPC::Notification.new(method: 'notify', params: { message: 'success' })
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_an(Array)
          expect(result.length).to eq(6)

          expect(result[0]).to be_nil

          expect(result[1]).to be_a(JSONRPC::MethodNotFoundError)
          expect(result[1].request_id).to be_nil

          expect(result[2]).to be_nil

          expect(result[3]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[3].request_id).to be_nil

          expect(result[4]).to be_nil

          expect(result[5]).to be_nil
        end
      end

      context 'when batch contains mixed valid and invalid parameter types' do
        it 'correctly validates each item individually' do
          batch = JSONRPC::BatchRequest.new(
            [
              # valid named params for a positional procedure
              JSONRPC::Request.new(method: 'add', params: { addends: [1, 2, 3] }, id: 'req1'),
              # invalid positional params for named procedure
              JSONRPC::Notification.new(method: 'subtract', params: [10, 5]),
              # invalid param types
              JSONRPC::Request.new(method: 'multiply', params: { multiplicand: 'invalid', multiplier: 4 }, id: 'req2')
            ]
          )

          result = validator.validate(batch)
          expect(result).to be_an(Array)
          expect(result.length).to eq(3)

          expect(result[0]).to be_nil

          expect(result[1]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[1].request_id).to be_nil
          expect(result[1].data).to eq(method: 'subtract')

          expect(result[2]).to be_a(JSONRPC::InvalidParamsError)
          expect(result[2].request_id).to eq('req2')
          expect(result[2].data).to eq(method: 'multiply', params: { multiplicand: ['must be a number'] })
        end
      end
    end
  end
end
