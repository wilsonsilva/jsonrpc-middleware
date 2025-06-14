# frozen_string_literal: true

module JSONRPC
  # Validates JSON-RPC 2.0 requests and notifications.
  class Validator
    # Validates a single request, notification or a batch of requests and/or notifications.
    #
    # @param [JSONRPC::BatchRequest, JSONRPC::Request, JSONRPC::Notification] batch_or_request
    #
    # @example Validate a single request
    #   validator = JSONRPC::Validator.new
    #   error = validator.validate(request)
    #
    # @example Validate a batch of requests
    #   validator = JSONRPC::Validator.new
    #   errors = validator.validate(batch)
    #
    # @return [JSONRPC::Error, Array<JSONRPC::Error>, nil]
    #
    def validate(batch_or_request)
      case batch_or_request
      when BatchRequest
        validate_batch_params(batch_or_request)
      when Request, Notification
        validate_request_params(batch_or_request)
      end
    end

    private

    def validate_batch_params(batch)
      errors = batch.map { |req| validate_request_params(req) }

      # Return the array of errors (with nil for successful validations)
      # If all validations passed, return nil
      errors.any? ? errors : nil
    end

    # @param [Request, Notification] request_or_notification
    def validate_request_params(request_or_notification)
      config = JSONRPC.configuration

      unless config.procedure?(request_or_notification.method)
        return MethodNotFoundError.new(
          request_id: extract_request_id(request_or_notification),
          data: {
            method: request_or_notification.method
          }
        )
      end

      procedure = config.get_procedure(request_or_notification.method)

      # Determine params to validate based on procedure configuration
      params_to_validate = prepare_params_for_validation(request_or_notification, procedure)

      # If params preparation failed, return error
      return params_to_validate if params_to_validate.is_a?(InvalidParamsError)

      # Validate the parameters
      validation_result = procedure.contract.call(params_to_validate)

      unless validation_result.success?
        return InvalidParamsError.new(
          request_id: extract_request_id(request_or_notification),
          data: {
            method: request_or_notification.method,
            params: validation_result.errors.to_h
          }
        )
      end

      nil
    rescue StandardError => e
      if ENV['DEBUG_RACK'] == 'true'
        puts "Validation error: #{e.message}"
        puts e.backtrace.join("\n")
      end

      InternalError.new(request_id: extract_request_id(request_or_notification))
    end

    def prepare_params_for_validation(request, procedure)
      if procedure.allow_positional_arguments
        handle_positional_arguments(request, procedure)
      else
        handle_named_arguments(request)
      end
    end

    def handle_positional_arguments(request_or_notification, procedure)
      case request_or_notification.params
      when Array
        # Convert positional to named parameters if procedure has a parameter name
        if procedure.parameter_name
          { procedure.parameter_name => request_or_notification.params }
        else
          {}
        end
      when Hash
        # Named parameters are also allowed when positional arguments are enabled
        request_or_notification.params
      when nil
        # Missing params - let the contract validation handle it
        {}
      else
        # Invalid params type (not Array, Hash, or nil)
        InvalidParamsError.new(
          request_id: extract_request_id(request_or_notification),
          data: { method: request_or_notification.method }
        )
      end
    end

    def handle_named_arguments(request_or_notification)
      case request_or_notification.params
      when Hash
        request_or_notification.params
      when nil
        # Missing params - let the contract validation handle it
        {}
      else
        # Invalid params type and positional arguments aren't allowed for this procedure
        InvalidParamsError.new(
          request_id: extract_request_id(request_or_notification),
          data: { method: request_or_notification.method }
        )
      end
    end

    def extract_request_id(request_or_notification)
      case request_or_notification
      when Request
        request_or_notification.id
      when Notification
        nil
      end
    end
  end
end
