# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'
require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter,
    SimpleCov::Formatter::Console
  ]
)

unless ENV['COVERAGE'] == 'false'
  SimpleCov.start do
    root 'lib'
    coverage_dir "#{Dir.pwd}/coverage"
  end
end

require 'jsonrpc'
require 'factory_bot'
require 'rack/test'

# Require support files
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Rack::Test::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Define a default app
  def app
    TestApp.new
  end
end
