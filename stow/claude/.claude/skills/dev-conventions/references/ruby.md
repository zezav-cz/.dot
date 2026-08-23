# Ruby

Pin the Ruby version in `mise.toml`:

```toml
[tools]
ruby = "3.3"
```

## Bundler — vendor gems locally, always

Every Ruby project (plain gems, Puppet modules, Bolt projects — anything with a `Gemfile`) vendors its gems into the project instead of the system/user gem path. This keeps `mise install` + `bundle install` fully reproducible and means two projects on the same machine can pin different gem versions without conflict.

Configure this once per project, right after `bundle init` / when the `Gemfile` is created:

```sh
bundle config set --local path '.bundle'
bundle config set --local bin '.bundle/bin'
bundle install --binstubs='.bundle/bin'
```

This writes `.bundle/config` (local, not global) and installs gems under `.bundle/` instead of a shared system location, with executable binstubs in `.bundle/bin`. Add `.bundle/` to `.gitignore` — it's a build artifact, not something to commit; what's committed is the `Gemfile` and `Gemfile.lock`.

Because binaries live in `.bundle/bin`, tasks should call them directly rather than going through `bundle exec` every time:

```toml
[tasks.fmt]
run = ".bundle/bin/rubocop -A"
description = "Auto-fix Ruby style with rubocop"

[tasks.lint]
run = ".bundle/bin/rubocop"
description = "Run rubocop"

[tasks.test]
run = ".bundle/bin/rspec"
description = "Run rspec tests"

[tasks.ci]
run = ["mise run fmt", "mise run lint", "mise run test"]
description = "Run fmt + lint + test"
```

## Style and testing

- Lint and format with `rubocop`; keep its config in `.rubocop.yml` at the project root.
- Test with `rspec`, specs live under `spec/` mirroring the `lib/` (or module-specific) structure being tested.
- Don't treat tests as optional scaffolding — a Ruby change (a gem, a Puppet module's Ruby-backed functions/providers/types, a Bolt task written in Ruby) isn't done until it has a spec covering the behavior that changed. This matters more in Ruby than some languages because so much of the ecosystem (Puppet included) leans on rspec conventions for correctness.

## Gemfile

```ruby
# Gemfile
source "https://rubygems.org"

gem "rake"

group :development, :test do
  gem "rubocop", require: false
  gem "rspec", require: false
end
```
