# Ruby

Ruby comes from the devshell:

```nix
devShells.default = pkgs.mkShellNoCC {
  packages = [
    pkgs.ruby_3_3
    pkgs.just
  ];
};
```

## Bundler — vendor gems locally, always

Every Ruby project (plain gems, Puppet modules, Bolt projects — anything with a `Gemfile`) vendors its gems into the project instead of the system/user gem path. This keeps `direnv allow` + `bundle install` fully reproducible and means two projects on the same machine can pin different gem versions without conflict.

Configure this once per project, right after `bundle init` / when the `Gemfile` is created:

```sh
bundle config set --local path '.bundle'
bundle config set --local bin '.bundle/bin'
bundle install --binstubs='.bundle/bin'
```

This writes `.bundle/config` (local, not global) and installs gems under `.bundle/` instead of a shared system location, with executable binstubs in `.bundle/bin`. Add `.bundle/` to `.gitignore` — it's a build artifact, not something to commit; what's committed is the `Gemfile` and `Gemfile.lock`.

Because binaries live in `.bundle/bin`, recipes and hooks should call them directly rather than going through `bundle exec` every time. `rubocop` has no catalogue hook, so define it inline:

```nix
hooks.rubocop = {
  enable = true;
  name = "rubocop";
  entry = ".bundle/bin/rubocop -A";
  types = [ "ruby" ];
};
```

```just
# Repair formatting across the working tree.
fmt:
    pre-commit run --all-files

# Verify without modifying anything.
lint:
    nix flake check

# Run rspec tests.
test:
    .bundle/bin/rspec

# Run lint + test.
ci: lint test
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
