# syntax=docker/dockerfile:1
#
# Development image for the jsonrpc-middleware gem.
# ============================================================================
# This image is a *development environment* for AI agents (and humans) who work
# ON the gem — not a *production runtime* that ships the gem to end users.
#
# That single fact inverts most of the usual Docker advice:
#   - We do NOT use a multi-stage build or a distroless final stage. The whole
#     point is to keep the full toolchain available — compilers, git, and every
#     development gem (RSpec, RuboCop, Steep, YARD, bundler-audit, Guard, ...) —
#     so an agent can run the test/lint/type-check/audit suite and rebuild or
#     install native gems on demand. Slimming those away would defeat the image.
#   - Optimising for a tiny final image is therefore a non-goal; optimising for
#     "everything an agent needs is already here and reproducible" is the goal.
# ============================================================================

# Why this exact base:
#   - ruby:4.0.5  -> `.tool-versions` pins Ruby 4.0.5 as the repo's canonical
#     version (CI runs on it too). The gemspec only requires `>= 3.4.0`, but the
#     container must match the pinned version to faithfully reproduce CI results
#     — otherwise an agent could see green/red locally that disagrees with CI.
#   - -slim       -> Debian-slim: small, but still glibc + `apt`. We deliberately
#     avoid Alpine here: Alpine's musl libc forces many native gems to recompile
#     from source (slower builds) and occasionally behaves differently from the
#     glibc CI environment. Debian-slim keeps us byte-for-byte closer to CI while
#     letting us add only the few build packages we actually need.
FROM ruby:4.0.5-slim

# System packages. Each line below earns its place — nothing here is "just in
# case", because every package widens the image and the attack surface:
#   build-essential, pkg-config  Compile native gem extensions when a gem has no
#                                precompiled platform build (or an agent adds one
#                                later). Most deps resolve to precompiled gems,
#                                but the toolchain must be present so `bundle
#                                install` never dead-ends.
#   git                          Required for THREE distinct reasons:
#                                  1. `yard-lint` is sourced from GitHub in the
#                                     Gemfile (`github: 'mensfeld/yard-lint'`),
#                                     so bundler git-clones it during install.
#                                  2. `overcommit --install` (run by bin/setup in
#                                     the devcontainer) writes git hooks.
#                                  3. The gemspec calls `git ls-files` to build
#                                     its file list.
#   libyaml-dev                  Psych (Ruby's YAML) links against libyaml; tools
#                                and configs throughout the stack parse YAML.
#   curl, ca-certificates        TLS roots + a fetch tool for rubygems.org and
#                                the bundler-audit advisory database.
# `--no-install-recommends` skips suggested extras; deleting the apt lists in the
# same layer keeps this layer from carrying ~tens of MB of package indexes.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      libyaml-dev \
      pkg-config \
 && rm -rf /var/lib/apt/lists/*

# Pin bundler to the version recorded in Gemfile.lock's `BUNDLED WITH` (4.0.8).
# Bundler is sensitive to this: a mismatched bundler can re-resolve or warn, which
# undermines the whole point of a locked, reproducible dependency set. Matching it
# keeps installs identical to what a contributor (and CI) get.
RUN gem install bundler -v 4.0.8

# Build/runtime environment:
#   BUNDLE_JOBS=4   Install gems in parallel — meaningfully faster on multi-core
#                   cloud builders.
#   BUNDLE_RETRY=3  Retry a gem fetch up to 3x; absorbs transient network blips
#                   that would otherwise fail an unattended cloud build.
#   LANG=C.UTF-8    Slim images ship with no locale, so Ruby's default external
#                   encoding would be US-ASCII and choke on non-ASCII I/O. Force
#                   UTF-8 to avoid Encoding errors in tooling and specs.
ENV BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    LANG=C.UTF-8

# Conventional, stable workdir. The devcontainer bind-mounts the live repo here
# (see .devcontainer/devcontainer.json -> workspaceFolder/workspaceMount).
WORKDIR /app

# Run as a non-root user (security: containers should not run as root). UID/GID
# 1000 is chosen on purpose — it's the first non-root user on most Linux hosts
# and CI runners, so files created in a bind-mounted workspace get sane, non-root
# ownership on the host instead of being owned by root.
RUN groupadd --gid 1000 dev \
 && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash dev

# --- Dependency layer --------------------------------------------------------
# Copy ONLY the dependency manifests before the source so this (expensive) layer
# is cached and re-runs only when dependencies change — not on every code edit.
#
# Why the gemspec AND lib/jsonrpc/version.rb are needed here: the Gemfile's
# `gemspec` directive evaluates jsonrpc-middleware.gemspec at install time, and
# that file `require_relative`s lib/jsonrpc/version.rb (for `spec.version`). Both
# must be present or `bundle install` fails before it ever reads the lock.
# (The gemspec also runs `git ls-files`; with .git excluded via .dockerignore it
# simply returns an empty file list — harmless, because the *dependencies* come
# from the `add_dependency` lines, not from `spec.files`.)
COPY Gemfile Gemfile.lock jsonrpc-middleware.gemspec ./
COPY lib/jsonrpc/version.rb lib/jsonrpc/version.rb

# Why add Linux platforms: the committed Gemfile.lock was generated on macOS and
# historically listed only `arm64-darwin`. Bundler refuses to install for a
# platform the lock doesn't name, so a Linux build would fail outright. Adding
# x86_64-linux + aarch64-linux makes it resolve on both Intel and ARM Linux
# (cloud runners and Docker on Apple silicon). These platforms are now also
# committed to the repo's lockfile, so in normal builds this command is a no-op
# — it stays here defensively so the image still builds from an older checkout.
#
# Gems install into the base image's GEM_HOME (/usr/local/bundle), which lives
# OUTSIDE /app. That is deliberate and important: the devcontainer bind-mounts
# the host repo over /app at runtime, which would shadow anything installed under
# /app — but gems in /usr/local/bundle survive the mount, so the container is
# ready to run the toolchain the instant it starts.
RUN bundle lock --add-platform x86_64-linux aarch64-linux \
 && bundle install

# --- Source layer ------------------------------------------------------------
# Bake a full copy of the repo so the image is usable standalone (e.g. plain
# `docker run ... bundle exec rspec`). When used as a devcontainer, the live
# bind-mount overlays this copy with the contributor's working tree.
COPY . .

# Hand ownership of both the workspace and the gem cache to the non-root user.
# Chowning /usr/local/bundle is essential, not cosmetic: gems were installed as
# root above, and without this the `dev` user could not install additional gems
# at runtime (e.g. `bundle exec rake examples:bundle_install`) without sudo.
RUN chown -R dev:dev /app /usr/local/bundle
USER dev

# Documentation only — EXPOSE does not publish ports. It records the ports the
# example apps use, so an agent that boots one to manually verify behaviour knows
# where to look: rack/sinatra examples listen on 9292, the Rails example on 3000.
EXPOSE 9292 3000

# Deliberately no HEALTHCHECK: this container runs dev commands, it does not serve
# traffic, so there is no endpoint or process to health-check.

# Default to an interactive shell for ad-hoc development. The devcontainer
# overrides this with its own keep-alive command, so this CMD only matters for
# direct `docker run` usage.
CMD ["bash"]
