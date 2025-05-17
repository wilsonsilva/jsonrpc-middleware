class App
  include JSONRPC::Helpers

  def call(env)
    @env = env # Set the @env instance variable to use the JSONRPC helpers below

    if jsonrpc_request?
      result = handle_single(jsonrpc_request)
      jsonrpc_response(result)
    elsif jsonrpc_notification?
      handle_single(jsonrpc_notification)
      jsonrpc_notification_response
    else
      responses = handle_batch(jsonrpc_batch)
      jsonrpc_batch_response(responses)
    end
  end

  private

  def handle_single(request_or_notification)
    params = request_or_notification.params
    params['message']
  end

  def handle_batch(batch)
    batch.flat_map do |request_or_notification|
      puts "Handling ##{request_or_notification.id} - #{request_or_notification.method}(#{request_or_notification.params})"
      result = handle_single(request_or_notification)
      JSONRPC::Response.new(id: request_or_notification.id, result:) if request_or_notification.is_a?(JSONRPC::Request)
    end
  end
end

JSONRPC.configure do
  procedure(:echo) do
    params do
      required(:addends).filled(:string)
    end
  end
end

