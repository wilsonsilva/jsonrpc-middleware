# frozen_string_literal: true

RSpec.describe JSONRPC do
  describe '.configure' do
    context 'when given a block with a procedure definition' do
      it 'registers the procedure on the configuration instance' do
        described_class.configure do
          procedure('greet') do
            params { required(:name).value(:string) }
          end
        end

        expect(described_class.configuration.procedure?('greet')).to be(true)
      end
    end
  end

  describe '.configuration' do
    it 'returns the singleton Configuration instance' do
      expect(described_class.configuration).to be_a(JSONRPC::Configuration)
    end

    it 'returns the same instance on repeated calls' do
      first = described_class.configuration
      expect(first).to be(described_class.configuration)
    end
  end
end
