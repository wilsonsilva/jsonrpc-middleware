# JSONRPC::Middleware - Ruby JSON-RPC Implementation

[![Gem Version](https://badge.fury.io/rb/jsonrpc-middleware.svg)](https://badge.fury.io/rb/jsonrpc-middleware)
![Build](https://github.com/wilsonsilva/jsonrpc-middleware/actions/workflows/main.yml/badge.svg)
[![Maintainability](https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/maintainability.svg)](https://qlty.sh/gh/wilsonsilva/projects/jsonrpc-middleware)
[![Code Coverage](https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/test_coverage.svg)](https://qlty.sh/gh/wilsonsilva/projects/jsonrpc-middleware)

A Ruby implementation of the JSON-RPC protocol, enabling standardized communication between systems via remote procedure calls encoded in JSON.

## Table of contents

- [Key features](#-key-features)
- [Installation](#-installation)
- [Quickstart](#-quickstart)
- [Documentation](#-documentation)
- [Development](#-development)
  * [Type checking](#type-checking)
- [Contributing](#-contributing)
- [License](#-license)
- [Code of Conduct](#-code-of-conduct)

## 🔑 Key features

-

## 📦 Installation

Install the gem by executing:

    $ gem install jsonrpc-middleware

## ⚡️ Quickstart

```ruby
```

## 📚 Documentation

- [YARD documentation](https://rubydoc.info/gems/jsonrpc-middleware)

## 🔨 Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

The health and maintainability of the codebase is ensured through a set of
Rake tasks to test, lint and audit the gem for security vulnerabilities and documentation:

```
rake build                    # Build jsonrpc-middleware.gem into the pkg directory
rake build:checksum           # Generate SHA512 checksum if jsonrpc-middleware.gem into the checksums directory
rake bundle:audit:check       # Checks the Gemfile.lock for insecure dependencies
rake bundle:audit:update      # Updates the bundler-audit vulnerability database
rake clean                    # Remove any temporary products
rake clobber                  # Remove any generated files
rake coverage                 # Run spec with coverage
rake install                  # Build and install jsonrpc-middleware.gem into system gems
rake install:local            # Build and install jsonrpc-middleware.gem into system gems without network access
rake qa                       # Test, lint and perform security and documentation audits
rake release[remote]          # Create a tag, build and push jsonrpc-middleware.gem to rubygems.org
rake rubocop                  # Run RuboCop
rake rubocop:autocorrect      # Autocorrect RuboCop offenses (only when it's safe)
rake rubocop:autocorrect_all  # Autocorrect RuboCop offenses (safe and unsafe)
rake spec                     # Run RSpec code examples
rake verify_measurements      # Verify that yardstick coverage is at least 100%
rake yard                     # Generate YARD Documentation
rake yard:junk                # Check the junk in your YARD Documentation
rake yardstick_measure        # Measure docs in lib/**/*.rb with yardstick
```

### Type checking

This gem leverages [RBS](https://github.com/ruby/rbs), a language to describe the structure of Ruby programs. It is
used to provide type checking and autocompletion in your editor. Run `bundle exec typeprof FILENAME` to generate
an RBS definition for the given Ruby file. And validate all definitions using [Steep](https://github.com/soutaro/steep)
with the command `bundle exec steep check`.

## 🐞 Issues & Bugs

If you find any issues or bugs, please report them [here](https://github.com/wilsonsilva/jsonrpc-middleware/issues), I will be happy
to have a look at them and fix them as soon as possible.

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wilsonsilva/jsonrpc-middleware.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere
to the [code of conduct](https://github.com/wilsonsilva/jsonrpc-middleware/blob/main/CODE_OF_CONDUCT.md).

## 📜 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 👔 Code of Conduct

Everyone interacting in the JSONRPC::Middleware Ruby project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/wilsonsilva/jsonrpc-middleware/blob/main/CODE_OF_CONDUCT.md).
