---
name: update-ruby
description: Update the Ruby and Bundler versions across the jsonrpc-middleware project. Use when explicitly asked to "upgrade ruby version", "update ruby version", "bump ruby version", "upgrade bundler version", "update bundler version", or "bump bundler version".
---

# Update Ruby and Bundler Versions

## Procedure

### 1. Determine target versions

Ask the user for the target Ruby version and Bundler version if not provided. To find the latest Bundler version, run `gem search bundler --exact` or check https://rubygems.org/gems/bundler.

### 2. Update mise config

Update `.tool-versions` with the new Ruby version:

```
ruby <version>
```

### 3. Install the target Bundler version

```sh
gem install bundler -v <version>
```

This ensures `bundle install` stamps the correct version in `BUNDLED WITH` across all lock files.

### 4. Update RuboCop target

In `.rubocop.yml`, update `AllCops.TargetRubyVersion` to match the new major.minor (e.g. `4.0`).

### 5. Regenerate root lock file

```sh
bundle install
```

Verify the `BUNDLED WITH` line at the bottom of `Gemfile.lock` reflects the new Bundler version.

### 6. Regenerate example lock files

```sh
bundle exec rake examples:bundle_install
```

Verify each `examples/*/Gemfile.lock` also reflects the new `BUNDLED WITH` version.

### 7. Validate

```sh
bundle exec rspec
bundle exec rubocop
bundle exec steep check
```

### 8. Update CHANGELOG.md

Add an entry under the next unreleased version noting the Ruby and Bundler version update.

## Constraints
- Do not update the required Ruby version in `json-rpc-middleware.gemspec`.
- Do not attempt to install a Ruby version
