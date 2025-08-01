# frozen_string_literal: true

# Simplest usage of json-middleware in a Rack application with helpers
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
    batch.process_each { |request_or_notification| handle_single(request_or_notification) }
  end
end

JSONRPC.configure do
  procedure(:echo) do
    params do
      required(:message).filled(:string)
    end
  end
end
