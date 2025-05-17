# frozen_string_literal: true

require 'json'
require 'rack/test'

module JsonRpcHelpers
  def post_jsonrpc_request(payload)
    post '/jsonrpc', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }
  end

  # Sends a raw string as the request body (for invalid JSON tests)
  def post_raw_jsonrpc_request(payload)
    post('/jsonrpc', payload, 'CONTENT_TYPE' => 'application/json')
  end

  def expect_status(status)
    expect(last_response.status).to eq(status)
  end

  def expect_json(expected_json)
    if last_response.body.empty?
      expect(last_response.body).to eq(expected_json)
    else
      parsed_response = JSON.parse(last_response.body, symbolize_names: true)
      expect(parsed_response).to eq(expected_json)
    end
  end

  def expect_empty_response_body
    expect(last_response.body).to be_empty
  end
end

RSpec.configure do |config|
  config.include JsonRpcHelpers
end
