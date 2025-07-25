# frozen_string_literal: true

RSpec.describe JSONRPC::Configuration do
  let(:config) { described_class.new }

  describe '#json_adapter=' do
    let(:original_adapter) { MultiJson.adapter }

    after { MultiJson.use(original_adapter) }

    context 'when setting the JSON adapter to json_gem' do
      it 'sets MultiJson adapter to JsonGem' do
        config.json_adapter = :json_gem
        expect(MultiJson.adapter.name).to include('JsonGem')
      end
    end

    context 'when testing all possible adapters' do
      %i[fast_jsonparser oj yajl json okjson json_gem].each do |adapter|
        it "calls MultiJson.use with #{adapter}" do
          allow(MultiJson).to receive(:use)
          config.json_adapter = adapter
          expect(MultiJson).to have_received(:use).with(adapter)
        end
      end
    end

    context 'when setting an invalid JSON adapter' do
      it 'raises MultiJson::AdapterError' do
        expect { config.json_adapter = :invalid_adapter }.to raise_error(MultiJson::AdapterError)
      end
    end

    context 'when setting the JSON adapter to nil' do
      it 'calls MultiJson.use with nil' do
        allow(MultiJson).to receive(:use)
        config.json_adapter = nil
        expect(MultiJson).to have_received(:use).with(nil)
      end
    end
  end
end
