# Puppet & Puppet Bolt

Puppet tooling (`pdk`, `bolt`, `r10k`, `puppet-lint`) is Ruby underneath, so read `references/ruby.md` first — the same mise-pinned Ruby version and local-vendored-bundler pattern (`.bundle/`, binstubs in `.bundle/bin`) applies here too. Prefer installing the CLIs themselves through mise where a plugin/backend exists (e.g. `"gem:bolt"`, `"gem:r10k"`, `"gem:puppet-lint"` as mise tool entries) so version pinning stays in `mise.toml` like everything else; fall back to the vendored Gemfile/bundler path for anything mise can't manage directly (this is common for `pdk`, which many teams still install as a native OS package because of its bundled toolchain).

```toml
# mise.toml — Puppet control repo or module
[tools]
ruby = "3.2"
"gem:r10k" = "4.1.0"
"gem:puppet-lint" = "2.5.2"
"gem:bolt" = "3.28.0"

[tasks.fmt]
run = ".bundle/bin/puppet-lint --fix manifests/ site-modules/"
description = "Auto-fix Puppet style"

[tasks.lint]
run = ".bundle/bin/puppet-lint manifests/ site-modules/ && .bundle/bin/puppet parser validate manifests/ site-modules/"
description = "Lint + syntax-validate Puppet code"

[tasks.test]
run = ".bundle/bin/rspec"
description = "Run rspec-puppet unit tests"

[tasks.build]
run = "r10k puppetfile check"
description = "Validate Puppetfile module pins"

[tasks.ci]
run = ["mise run fmt", "mise run lint", "mise run test", "mise run build"]
description = "Run fmt + lint + test + build"
```

## Control repo — roles & profiles

The control repo is the top of the Puppet code hierarchy: it pulls in modules via a `Puppetfile` (deployed with `r10k` or Code Manager) and holds the site-specific roles/profiles layer plus Hiera data. Structure:

```
control-repo/
├── Puppetfile              # r10k-managed module dependencies, pinned versions/refs
├── environment.conf
├── hiera.yaml              # hierarchy definition
├── data/
│   ├── common.yaml
│   └── nodes/
│       └── <fqdn>.yaml
├── manifests/
│   └── site.pp             # node classification, usually just `include role::...`
└── site-modules/
    ├── role/
    │   └── manifests/
    │       └── <role>.pp   # one role per node type; composes profiles, no resources directly
    └── profile/
        └── manifests/
            └── <profile>.pp  # wires together component modules + Hiera data for one concern
```

The rule that keeps this pattern useful over time: roles only include profiles (never resources or component-module classes directly), and profiles are the only layer that references Hiera data and component modules. If you catch yourself putting a `package`/`file`/`service` resource straight into a role or into `site.pp`, it belongs in a profile instead.

## Reusable modules — PDK

A standalone module (the kind published or shared across control repos) is scaffolded and validated with PDK rather than by hand:

```sh
pdk new module my_module
cd my_module
pdk new class my_module::config      # manifests/config.pp + matching spec
pdk validate                          # metadata, syntax, style
pdk test unit                         # rspec-puppet
```

Resulting layout:

```
my_module/
├── manifests/
│   └── init.pp
├── files/
├── templates/
├── spec/
│   ├── classes/
│   │   └── init_spec.rb
│   └── spec_helper.rb
├── metadata.json
├── Gemfile
├── Rakefile
├── .fixtures.yml            # spec dependencies on other modules
├── .rubocop.yml
└── .puppet-lint.rc
```

Every class, defined type, and function gets an rspec-puppet spec under `spec/`. `.fixtures.yml` declares any modules the specs depend on (pulled into `spec/fixtures/modules/` via `pdk test unit`, which handles this automatically).

## Puppet Bolt projects

A Bolt project is its own thing — not necessarily inside the control repo — used for orchestration: ad hoc commands, multi-step plans, and (via `apply`) actually running Puppet code against targets without a Puppet server.

```
bolt-project/
├── bolt-project.yaml        # project name, module path, plugin config
├── inventory.yaml           # targets, groups, connection config
├── Puppetfile               # only needed if plans use apply_prep/apply against modules
├── plans/
│   └── deploy_app/
│       └── init.pp          # orchestration logic — bolt plan run deploy_app
├── tasks/
│   └── restart_service/
│       ├── init.sh
│       └── init.json        # task metadata: parameters, input method
└── files/                   # static files a plan/task can reference
```

Conventions:

- Plans go in `plans/<plan_name>/init.pp` (or `<name>.pp` for a flat single plan); write orchestration logic in the Puppet plan language rather than YAML plans once there's any branching or error handling — YAML plans are fine for a straight-line sequence of task calls only.
- Tasks pair an executable (`init.sh`, `init.rb`, `init.py`, whatever fits) with `init.json` describing its parameters — never ship a task without the metadata file, since that's what makes `bolt task show` and parameter validation work.
- When a plan needs to apply actual Puppet code to a target instead of running discrete tasks, call `apply_prep($targets)` first (installs the Puppet agent package and syncs facts), then wrap the resources or class includes in an `apply($targets) { ... }` block. This is the bridge between Bolt-style push orchestration and normal Puppet catalog application — reach for it when the end state is more naturally expressed as Puppet resources than as a sequence of imperative tasks.
- Run plans with `bolt plan run <module>::<plan> --inventoryfile inventory.yaml`, individual tasks with `bolt task run`, and validate a plan's structure with `bolt plan show`.

## Testing expectations

Puppet and Bolt code follows the same rule as the rest of Ruby: a manifest, defined type, function, or task isn't finished until there's a spec for it.

- Control repo profiles/roles and module classes → `rspec-puppet` (`describe 'profile::foo' do ... end`, asserting on `contain_class`/`contain_package`/etc.)
- Bolt plans → `bolt_spec/plans` (ships with the `puppetlabs-bolt_spec` module) for asserting on the sequence of task/command calls a plan makes
- Ruby-backed custom types/providers/functions → plain `rspec`, same as any other Ruby code

`mise run test` should run the full rspec suite; don't add a plan or profile in one commit and its spec in the next.
