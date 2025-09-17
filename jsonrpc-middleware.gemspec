# frozen_string_literal: true

require_relative 'lib/jsonrpc/version'

Gem::Specification.new do |spec|
  spec.name = 'jsonrpc-middleware'
  spec.version = JSONRPC::VERSION
  spec.authors = ['Wilson Silva']
  spec.email = ['wilson.dsigns@gmail.com']

  spec.summary = 'Rack middleware implementing the JSON-RPC 2.0 protocol.'
  spec.description = 'A Rack middleware implementing the JSON-RPC 2.0 protocol that integrates easily with all Rack-based applications (Rails, Sinatra, Hanami, etc).'
  spec.homepage = 'https://github.com/wilsonsilva/jsonrpc-middleware'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/wilsonsilva/jsonrpc-middleware'
  spec.metadata['changelog_uri'] = 'https://github.com/wilsonsilva/jsonrpc-middleware/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ spec/ .git .github Gemfile])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-struct', '~> 1.8'
  spec.add_dependency 'dry-validation', '~> 1.11'
  spec.add_dependency 'multi_json', '~> 1.17'
  spec.add_dependency 'zeitwerk', '~> 2.7'
end
