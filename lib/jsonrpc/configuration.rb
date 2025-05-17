module JSONRPC
  class Configuration
    Procedure = Data.define(:allow_positional_arguments,  :contract, :parameter_name)

    attr_reader :validate_procedure_signatures

    def initialize
      @procedures = {}
      @validate_procedure_signatures = true
    end

    def self.instance
      @instance ||= new
    end

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

    def get_procedure(method_name)
      @procedures[method_name.to_s]
    end

    def has_procedure?(method_name)
      @procedures.key?(method_name.to_s)
    end

    def reset!
      @procedures.clear
    end
  end
end
