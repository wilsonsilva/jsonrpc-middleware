# frozen_string_literal: true

module JSONRPC
  # @api private
  class Railtie < ::Rails::Railtie
    # Rails routing constraint for matching JSON-RPC method names
    initializer 'jsonrpc.middleware' do |app|
      app.middleware.use JSONRPC::Middleware
    end

    initializer 'jsonrpc.renderer' do
      ActiveSupport.on_load(:action_controller) do
        Mime::Type.register 'application/json', :jsonrpc

        ActionController::Renderers.add :jsonrpc do |result_data, _options|
          self.content_type ||= Mime[:jsonrpc]

          # Handle different types of JSON-RPC responses
          if jsonrpc_request?
            # Single request - create response with ID and result
            self.status = 200
            self.response_body = JSONRPC::Response.new(id: jsonrpc_request.id, result: result_data).to_json
          elsif jsonrpc_batch?
            # Batch request - result_data should be an array of responses
            if result_data.compact.empty?
              # Batch contained only notifications
              self.status = 204
              self.response_body = ''
              ''
            else
              result_data.to_json
            end
          elsif jsonrpc_notification?
            # Notification - no response body
            self.status = 204
            self.response_body = ''
            ''
          else
            # Fallback - treat as regular JSON-RPC response
            result_data.to_json
          end
        end
      end
    end

    # Hook into the controller loading process
    initializer 'jsonrpc.include_controller_extensions', after: 'action_controller.set_configs' do
      ActiveSupport.on_load(:action_controller_base) do
        include JSONRPC::Helpers
      end

      # Also include in API controllers if you're using Rails API mode
      ActiveSupport.on_load(:action_controller_api) do
        include JSONRPC::Helpers
      end
    end
  end
end
