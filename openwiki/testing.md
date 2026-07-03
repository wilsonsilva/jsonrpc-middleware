# Testing and operations

## Local validation commands

- `bundle exec rspec` runs the full test suite.
- `bundle exec rspec spec/path/to/spec.rb` runs a focused spec file.
- `bundle exec rake qa` runs the broader quality gate (tests, RuboCop, YARD lint, and dependency audit tasks).
- `bundle exec rubocop` runs the Ruby linter.
- `bundle exec steep check` validates the RBS type signatures.
- `bundle exec rake coverage` produces coverage output and an LLM-friendly report in `coverage/report.md`.
- `bundle exec mutant run` runs mutation testing across the configured JSONRPC subjects.

## CI workflows

### Main workflow

`.github/workflows/main.yml` runs on pushes to `main` and on pull requests. It splits the checks into four jobs:

- RSpec
- RuboCop
- YARD lint
- Bundler audit

### OpenWiki workflow

`.github/workflows/openwiki-update.yml` runs on manual dispatch and on a weekly schedule. It installs the OpenWiki CLI, refreshes the `openwiki/` docs, and opens a PR with the generated changes.

Required repository secrets:

- `OPENROUTER_API_KEY` for the OpenWiki model provider
- `LANGSMITH_API_KEY` if tracing to LangSmith is desired

## When changing the repo

- Update the OpenWiki pages when architecture, workflows, or validation commands change.
- Review the example apps when altering middleware integration behavior because they serve as executable documentation.
- Keep AGENTS/CLAUDE guidance aligned with the `openwiki/quickstart.md` entrypoint.

## Source references

- `AGENTS.md`
- `CLAUDE.md`
- `.github/workflows/main.yml`
- `.github/workflows/openwiki-update.yml`
- `Rakefile`
