## General
- Always write the code
- Don't apologize for errors, fix them
- When adding new rules, update both `.cursor/rules/{rule}.mdc` and `.github/copilot-instructions.md` to keep them synchronized

## Dependency Management
- Always use the latest version of Ruby and the gems

## Testing
- Use the latest version of RSpec
- Execute RSpec via `bundle exec rspec`
- Ensure 100% test coverage
- Limit `context` nesting to 2 levels and do your best to use just 1
- Follow the Arrange Act Assert pattern
- Use `@example.com` for emails in tests
- Use `example.com`, [`example.org`](http://example.org), and [`example.net`](http://example.net) as custom domains or request hosts in tests.
- Avoid `to_not have_enqueued_sidekiq_job` or `not_to have_enqueued_sidekiq_job` because they're prone to false positives. Make assertions on `SidekiqWorkerName.jobs.size` instead. See [comment in #20580 for details](https://github.com/gumroad/web/pull/20580#discussion_r716199137).

## Changelog

## Releasing

## Logging

## Monitoring

## Type Checking

## Documentation
