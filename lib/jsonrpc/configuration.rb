# frozen_string_literal: true

module JSONRPC
  # Configuration class for JSON-RPC procedure management and validation.
  #
  # @api public
  #
  # This class provides functionality to register, retrieve, and validate JSON-RPC procedures.
  # It acts as a central registry for method definitions and their parameter constraints.
  #
  # @example Registering a procedure
  #   JSONRPC::Configuration.instance.procedure('sum') do
  #     params do
  #       required(:numbers).value(:array, min_size?: 1)
  #     end
  #   end
  #
  class Configuration
    # Represents a registered JSON-RPC procedure with its validation contract and configuration
    #
    # @api public
    #
    # @!method allow_positional_arguments
    #   Indicates if the procedure accepts positional arguments
    #   @api public
    #
    #   @example
    #     procedure.allow_positional_arguments # => true
    #   @return [Boolean] whether the procedure accepts positional arguments
    #
    # @!method contract
    #   The validation contract for procedure parameters
    #   @api public
    #
    #   @example
    #     procedure.contract # => #<Dry::Validation::Contract...>
    #   @return [Dry::Validation::Contract] the validation contract for procedure parameters
    #
    # @!method parameter_name
    #   The name of the first parameter in the contract schema
    #   @api public
    #
    #   @example
    #     procedure.parameter_name # => :numbers
    #   @return [Symbol, nil] the name of the first parameter in the contract schema
    #
    Procedure = Data.define(:allow_positional_arguments, :contract, :parameter_name)

    # Whether procedure signatures are validated
    #
    # @api public
    #
    # @example
    #   config.validate_procedure_signatures # => true
    #
    # @return [Boolean] whether procedure signatures are validated
    #
    attr_reader :validate_procedure_signatures

    # Initializes a new Configuration instance
    #
    # @api public
    #
    # @example
    #   config = JSONRPC::Configuration.new
    #
    # @return [Configuration] a new configuration instance
    #
    def initialize
      @procedures = {}
      @validate_procedure_signatures = true
    end

    # Returns the singleton instance of the Configuration class
    #
    # @api public
    #
    # @example
    #   config = JSONRPC::Configuration.instance
    #
    # @return [Configuration] the singleton instance
    #
    def self.instance
      @instance ||= new
    end

    # Registers a new procedure with the given method name and validation contract
    #
    # @api public
    #
    # @example Register a simple procedure
    #   config.procedure('add') do
    #     params do
    #       required(:a).value(:integer)
    #       required(:b).value(:integer)
    #     end
    #   end
    #
    # @param method_name [String, Symbol] the name of the procedure
    # @param allow_positional_arguments [Boolean] whether the procedure accepts positional arguments
    #
    # @yield A block that defines the validation contract using Dry::Validation DSL
    #
    # @return [Procedure] the registered procedure
    #
    def procedure(method_name, allow_positional_arguments: false, &)
      contract_class = Class.new(Dry::Validation::Contract, &)
      contract_class.class_eval { import_predicates_as_macros }
      contract = contract_class.new

      @procedures[method_name.to_s] = Procedure.new(
        allow_positional_arguments:,
        contract:,
        parameter_name: contract.schema.key_map.keys.first&.name
      )
    end

    # Retrieves a procedure by its method name
    #
    # @api public
    #
    # @example
    #   procedure = config.get_procedure('add')
    #
    # @param method_name [String, Symbol] the name of the procedure to retrieve
    #
    # @return [Procedure, nil] the procedure if found, nil otherwise
    #
    def get_procedure(method_name)
      @procedures[method_name.to_s]
    end

    # Checks if a procedure with the given method name exists
    #
    # @api public
    #
    # @example
    #   config.procedure?('add') # => true
    #
    # @param method_name [String, Symbol] the name of the procedure to check
    #
    # @return [Boolean] true if the procedure exists, false otherwise
    #
    def procedure?(method_name)
      @procedures.key?(method_name.to_s)
    end

    # Clears all registered procedures
    #
    # @api public
    #
    # @example
    #   config.reset!
    #
    # @return [void]
    #
    def reset!
      @procedures.clear
    end
  end
end
