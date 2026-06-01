# frozen_string_literal: true

RSpec.describe JSONRPC::Validator do
  let(:logger) { instance_spy(Logger) }
  let(:validator) { described_class.new(logger:) }

  after do
    JSONRPC.configuration.reset!
    JSONRPC.configuration.log_request_validation_errors = false
  end

  describe '#validate rescue StandardError branch' do
    let(:contract_double) { instance_double(Dry::Validation::Contract) }
    let(:procedure_double) do
      instance_double(
        JSONRPC::Configuration::Procedure,
        allow_positional_arguments: false,
        parameter_name: nil,
        contract: contract_double
      )
    end

    before do
      JSONRPC.configure do
        procedure(:rescue_test) do
          params do
            required(:value).filled(:integer)
          end
        end
      end

      allow(contract_double).to receive(:call).and_raise(StandardError, 'boom')
      allow(JSONRPC.configuration).to receive(:get_procedure).with('rescue_test').and_return(procedure_double)
    end

    context 'when log_request_validation_errors is true' do
      before { JSONRPC.configuration.log_request_validation_errors = true }

      it 'logs the error twice and returns InternalError' do
        request = JSONRPC::Request.new(method: 'rescue_test', params: { value: 1 }, id: 42)
        result = validator.validate(request)

        expect(logger).to have_received(:error).with('Validation error: boom')
        expect(logger).to have_received(:error).exactly(2).times
        expect(result).to be_a(JSONRPC::InternalError)
        expect(result.request_id).to eq(42)
      end
    end

    context 'when log_request_validation_errors is false' do
      it 'does not log and returns InternalError' do
        request = JSONRPC::Request.new(method: 'rescue_test', params: { value: 1 }, id: 43)
        result = validator.validate(request)

        expect(logger).not_to have_received(:error)
        expect(result).to be_a(JSONRPC::InternalError)
        expect(result.request_id).to eq(43)
      end
    end
  end

  describe '#validate handle_positional_arguments else {} branch (L153)' do
    before do
      JSONRPC.configure do
        procedure(:no_param_name_proc, allow_positional_arguments: true)
      end
    end

    context 'when procedure has no parameter_name and params is an Array' do
      it 'returns nil (passes validation with empty hash)' do
        request = JSONRPC::Request.new(method: 'no_param_name_proc', params: [1, 2], id: 1)
        result = validator.validate(request)

        expect(result).to be_nil
      end
    end
  end

  describe '#validate handle_positional_arguments InvalidParamsError branch (L163)' do
    before do
      JSONRPC.configure do
        procedure(:positional_bad_type, allow_positional_arguments: true) do
          params do
            required(:value).filled(:integer)
          end
        end
      end
    end

    context 'when params is not Array, Hash, or nil' do
      it 'returns InvalidParamsError' do
        request = JSONRPC::Request.new(method: 'positional_bad_type', params: [1, 2], id: 99)
        allow(request).to receive(:params).and_return('bad_type')

        result = validator.validate(request)

        expect(result).to be_a(JSONRPC::InvalidParamsError)
        expect(result.request_id).to eq(99)
        expect(result.data).to eq(method: 'positional_bad_type')
      end
    end
  end
end
