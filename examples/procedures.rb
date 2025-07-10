# frozen_string_literal: true

JSONRPC.configure do |config|
  config.log_internal_errors = true           # Log internal error backtraces (default: true)
  config.log_request_validation_errors = true # Log JSON-RPC request validation errors (default: false)
  config.render_internal_errors = true        # Render detailed internal error information in responses (default: true)
  config.rescue_internal_errors = true        # Handle and serialize internal errors (default: true)

  # Allow positional and named arguments
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

  # Used only to test internal server errors
  procedure(:explode) do
    params do
      # No params
    end
  end
end
