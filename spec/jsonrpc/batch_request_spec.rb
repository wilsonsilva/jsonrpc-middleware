# frozen_string_literal: true

RSpec.describe JSONRPC::BatchRequest do
  let(:add_request) { JSONRPC::Request.new(method: 'add', params: [1, 2], id: 'req1') }
  let(:subtract_request) { JSONRPC::Request.new(method: 'subtract', params: [10, 5], id: 'req2') }
  let(:notify_notification) { JSONRPC::Notification.new(method: 'notify', params: ['hello']) }
  let(:log_notification) { JSONRPC::Notification.new(method: 'log', params: ['info']) }
  let(:parse_error) { JSONRPC::ParseError.new }
  let(:invalid_request_error) { JSONRPC::InvalidRequestError.new }

  describe '#all?' do
    let(:batch) { described_class.new([add_request, notify_notification, subtract_request]) }

    context 'when all items match condition' do
      it 'returns true' do
        result = batch.all? { |item| item.respond_to?(:method) }

        expect(result).to be true
      end
    end

    context 'when not all items match condition' do
      it 'returns false' do
        result = batch.all?(JSONRPC::Request)

        expect(result).to be false
      end
    end
  end

  describe '#any?' do
    let(:batch) { described_class.new([add_request, notify_notification, subtract_request]) }

    context 'when condition matches at least one item' do
      it 'returns true' do
        result = batch.any? { |item| item.method == 'notify' }

        expect(result).to be true
      end
    end

    context 'when condition matches no items' do
      it 'returns false' do
        result = batch.any? { |item| item.method == 'nonexistent' }

        expect(result).to be false
      end
    end
  end

  describe '#count' do
    let(:batch) { described_class.new([add_request, notify_notification, subtract_request]) }

    context 'when counting with condition' do
      it 'returns number of matching items' do
        request_count = batch.count { |item| item.is_a?(JSONRPC::Request) }

        expect(request_count).to eq(2)
      end
    end

    context 'when counting without condition' do
      it 'returns total number of items' do
        total_count = batch.count

        expect(total_count).to eq(3)
      end
    end
  end

  describe '#each' do
    let(:batch) { described_class.new([add_request, notify_notification]) }

    context 'when block is given' do
      it 'yields each request in the batch' do
        yielded_items = batch.map { |item| item }

        expect(yielded_items).to eq([add_request, notify_notification])
      end
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        enumerator = batch.each

        expect(enumerator).to be_a(Enumerator)
        expect(enumerator.to_a).to eq([add_request, notify_notification])
      end
    end
  end

  describe '#find' do
    let(:batch) { described_class.new([add_request, notify_notification, subtract_request]) }

    context 'when item exists' do
      it 'returns the first matching item' do
        found_request = batch.find { |item| item.method == 'add' }

        expect(found_request).to eq(add_request)
      end
    end

    context 'when item does not exist' do
      it 'returns nil' do
        result = batch.find { |item| item.method == 'nonexistent' }

        expect(result).to be_nil
      end
    end
  end

  describe '#initialize' do
    context 'when given requests' do
      it 'creates a batch request with requests' do
        batch = described_class.new([add_request, subtract_request])

        expect(batch.requests).to eq([add_request, subtract_request])
      end
    end

    context 'when given mixed requests and notifications' do
      it 'creates a batch request with requests and notifications' do
        batch = described_class.new([add_request, notify_notification, subtract_request])

        expect(batch.requests).to eq([add_request, notify_notification, subtract_request])
      end
    end

    context 'when requests is not an Array' do
      it 'raises ArgumentError' do
        expect { described_class.new('not an array') }.to raise_error(ArgumentError, 'Requests must be an Array')
      end
    end

    context 'when requests is empty' do
      it 'raises ArgumentError' do
        expect { described_class.new([]) }.to raise_error(ArgumentError, 'Batch request cannot be empty')
      end
    end

    context 'when requests contains invalid objects' do
      it 'raises ArgumentError' do
        expect do
          described_class.new([add_request, 'invalid'])
        end.to raise_error(ArgumentError, /Request at index 1 is not a valid Request, Notification, or Error/)
      end
    end

    context 'when given error objects' do
      it 'creates a batch request with error objects' do
        batch = described_class.new([add_request, parse_error, invalid_request_error])

        expect(batch.requests).to eq([add_request, parse_error, invalid_request_error])
      end
    end

    context 'when given only error objects' do
      it 'creates a batch request with only errors' do
        batch = described_class.new([parse_error, invalid_request_error])

        expect(batch.requests).to eq([parse_error, invalid_request_error])
      end
    end
  end

  describe '#length' do
    it 'returns the number of requests in the batch' do
      batch = described_class.new([add_request, notify_notification, subtract_request])

      expect(batch.length).to eq(3)
    end
  end

  describe '#map' do
    let(:batch) { described_class.new([add_request, notify_notification, subtract_request]) }

    it 'returns array of transformed values' do
      methods = batch.map(&:method)

      expect(methods).to eq(%w[add notify subtract])
    end
  end

  describe '#process_each' do
    context 'with mixed requests and notifications' do
      let(:batch) { described_class.new([add_request, notify_notification, subtract_request, log_notification]) }

      it 'processes each item and returns responses only for requests' do
        responses = batch.process_each do |item|
          case item.method
          when 'add'
            item.params.sum
          when 'subtract'
            item.params.first - item.params.last
          when 'notify', 'log'
            nil # notifications don't need return values
          end
        end

        expect(responses.length).to eq(2)
        expect(responses[0]).to be_a(JSONRPC::Response)
        expect(responses[0].id).to eq('req1')
        expect(responses[0].result).to eq(3)
        expect(responses[1]).to be_a(JSONRPC::Response)
        expect(responses[1].id).to eq('req2')
        expect(responses[1].result).to eq(5)
      end

      it 'preserves the order of requests in responses' do
        batch = described_class.new([notify_notification, add_request, log_notification, subtract_request])

        responses = batch.process_each do |item|
          case item.method
          when 'add'
            item.params.sum
          when 'subtract'
            item.params.first - item.params.last
          end
        end

        expect(responses.length).to eq(2)
        expect(responses[0].id).to eq('req1')
        expect(responses[1].id).to eq('req2')
      end
    end

    context 'with only requests' do
      let(:batch) { described_class.new([add_request, subtract_request]) }

      it 'returns responses for all requests' do
        responses = batch.process_each do |item|
          case item.method
          when 'add'
            item.params.sum
          when 'subtract'
            item.params.first - item.params.last
          end
        end

        expect(responses.length).to eq(2)
        expect(responses.all?(JSONRPC::Response)).to be true
      end
    end

    context 'with only notifications' do
      let(:batch) { described_class.new([notify_notification, log_notification]) }

      it 'returns an empty array' do
        responses = batch.process_each do |item|
          # Process notifications but don't return anything meaningful
          "processed #{item.method}"
        end

        expect(responses).to be_empty
      end
    end

    context 'when block returns nil for requests' do
      let(:batch) { described_class.new([add_request]) }

      it 'creates response with nil result' do
        responses = batch.process_each { |_item| 0 }

        expect(responses.length).to eq(1)
        expect(responses[0].result).to eq(0)
      end
    end

    context 'when no block is given' do
      let(:batch) { described_class.new([add_request]) }

      it 'raises ArgumentError' do
        expect { batch.process_each }.to raise_error(ArgumentError, 'Block required')
      end
    end

    context 'when batch contains error objects' do
      let(:batch) { described_class.new([add_request, parse_error, subtract_request]) }

      it 'processes error objects without creating responses' do
        responses = batch.process_each do |item|
          case item
          when JSONRPC::Request
            case item.method
            when 'add'
              item.params.sum
            when 'subtract'
              item.params.first - item.params.last
            end
          when JSONRPC::Error
            'error processed'
          end
        end

        expect(responses.length).to eq(2)
        expect(responses.all?(JSONRPC::Response)).to be true
        expect(responses[0].result).to eq(3)
        expect(responses[1].result).to eq(5)
      end
    end

    context 'when block raises an exception' do
      let(:batch) { described_class.new([add_request]) }

      it 'allows the exception to propagate' do
        expect do
          batch.process_each { |_item| raise StandardError, 'test error' }
        end.to raise_error(StandardError, 'test error')
      end
    end
  end

  describe '#requests' do
    it 'returns the array of requests' do
      requests = [add_request, notify_notification]
      batch = described_class.new(requests)

      expect(batch.requests).to eq(requests)
      expect(batch.requests).to be_a(Array)
    end
  end

  describe '#select' do
    let(:batch) { described_class.new([add_request, notify_notification, subtract_request]) }

    context 'when filtering with a condition' do
      it 'returns only matching items' do
        requests_only = batch.select { |item| item.is_a?(JSONRPC::Request) }

        expect(requests_only).to eq([add_request, subtract_request])
      end
    end

    context 'when no items match' do
      it 'returns empty array' do
        result = batch.select { |item| item.method == 'nonexistent' }

        expect(result).to eq([])
      end
    end
  end

  describe '#size' do
    it 'returns the number of requests in the batch' do
      batch = described_class.new([add_request, notify_notification, subtract_request])

      expect(batch.size).to eq(3)
    end
  end

  describe '#to_h' do
    context 'when batch contains requests and notifications' do
      it 'converts batch to array of hashes' do
        batch = described_class.new([add_request, notify_notification])
        result = batch.to_h

        expect(result).to be_an(Array)
        expect(result[0]).to eq(add_request.to_h)
        expect(result[1]).to eq(notify_notification.to_h)
      end
    end

    context 'when batch contains error objects' do
      it 'includes error objects that respond to to_h' do
        batch = described_class.new([add_request, parse_error])
        result = batch.to_h

        expect(result).to be_an(Array)
        expect(result[0]).to eq(add_request.to_h)
        expect(result[1]).to eq(parse_error.to_h)
      end
    end
  end

  describe '#to_json' do
    context 'when batch contains requests' do
      it 'converts batch to JSON string' do
        batch = described_class.new([add_request])
        result = batch.to_json

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq([add_request.to_h.transform_keys(&:to_s)])
      end
    end

    context 'when called with arguments' do
      it 'passes arguments to underlying to_json call' do
        batch = described_class.new([add_request])
        result = batch.to_json(indent: '  ')

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq([add_request.to_h.transform_keys(&:to_s)])
      end
    end
  end
end
