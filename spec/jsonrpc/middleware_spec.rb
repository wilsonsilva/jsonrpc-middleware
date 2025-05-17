# frozen_string_literal: true

RSpec.describe JSONRPC::Middleware do
  it 'has a version number' do
    expect(JSONRPC::Middleware::VERSION).not_to be_nil
  end
end
