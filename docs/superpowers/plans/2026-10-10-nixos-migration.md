# NixOS Migration (p15v) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A NixOS + Sway configuration for the ThinkPad P15v Gen 1 in this repo's flake, proven in a VM (interactive VM, automated NixOS test, full install rehearsal) before the laptop is wiped.

**Architecture:** One flake: `nixosConfigurations.{vm,p15v,p15v-rehearsal,iso,iso-rehearsal}` compose shared modules from `nixos/`; the user environment is `home/` (split out of today's `home.nix`) and is used both by NixOS (home-manager module) and by the standalone Ubuntu `homeConfigurations.jantrojak`. Dotfiles stay in `stow/` and are linked out-of-store by home-manager. `nix flake check` runs lint, path-portability, list-parity, a headless desktop test and builds of the real host.

**Tech Stack:** Nix flakes, nixos-unstable (26.11pre), home-manager, disko, sops-nix + age, stylix, nixos-hardware, QEMU/KVM + OVMF, `pkgs.testers.runNixOSTest`, mise tasks, lefthook.

**Spec:** `docs/superpowers/specs/2026-10-10-nixos-migration-design.md`

## Global Constraints

- Single nixpkgs: `github:NixOS/nixpkgs/nixos-unstable` (the one `home.nix` already uses); every new input sets `inputs.nixpkgs.follows = "nixpkgs"` where it has a nixpkgs input.
- One `pkgs` instance (`import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }`) is shared by home-manager, every NixOS host (`nixpkgs.pkgs = pkgs`) and the NixOS test. Modules under `nixos/` and `hosts/` must never set `nixpkgs.config` or `nixpkgs.hostPlatform`.
- NixOS `system.stateVersion = "26.11"`; home-manager `home.stateVersion` stays `"24.11"`.
- User `jantrojak`, `uid = 1001` (same as the Ubuntu host, so 9p-shared and restored files keep their owner).
- NVIDIA Quadro P620 is Pascal: driver `nvidiaPackages.legacy_580`, `hardware.nvidia.open = false`. `stable` (595) does not support it.
- Console/initrd keymap `us` (LUKS passphrase is typed before any layout switching exists).
- Task runner is mise (`mise.toml`), git hooks are lefthook (`lefthook.yml`) — this repo's convention. No justfile.
- Every edited file conforms to `.editorconfig` (2-space indent, LF, final newline, no trailing whitespace).
- Nothing under `stow/` may change in a way that breaks the current Ubuntu machine; Ubuntu keeps working until the wipe.
- No plaintext real secret is ever committed. Only the throwaway VM/rehearsal keys under `secrets/vm-test.agekey` and `secrets/rehearsal/` are committed unencrypted, on purpose.
- Commits: Conventional Commits, subject ≤ 72 chars, body explains why, trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never include a model identifier anywhere else.
- `nix flake check` must pass at the end of every task from Task 3 on.
- **The working tree holds the user's own uncommitted work** (e.g. `stow/zsh/.zshrc`, sway/systemd configs, `CLAUDE.md`, `doc/`, `installer/config.py`, `.gitignore`). Stage only the exact paths a task changes (`git add <path>`); never `git add -A`/`-u`/`.` at the repo root. Before editing a file, run `git diff --quiet -- <file>`; if it already has user changes, stage only your own hunks with `git add -p <file>`, and never revert or reformat the user's hunks. New files under `home/`, `nixos/`, `hosts/`, `checks/`, `tests/`, `keys/`, `secrets/` must be `git add`ed before any `nix` command (flakes only see tracked files).

## Review Focus

1. **Ubuntu regression** — after the split and the portability edits, the standalone `homeConfigurations.jantrojak` and the stowed configs must behave exactly as before on Ubuntu. Pinned by: Task 1 drvPath equality; Task 2 runs `sway -C` and `systemd-analyze --user verify` on the Ubuntu host; Task 4 asserts the standalone config still has no dotfile links.
2. **Runtime-written files landing in the repo** — foot `theme-mode.ini`, k9s `config.yaml`, lazygit `state.yml`, Claude sessions, the gnupg keyring must be written to real directories in `~`, not into `stow/`. Pinned by: Task 4 test writes those files in the VM and asserts they are not symlinks into the dotfiles root.
3. **Interactive shell errors on NixOS** — a missing oh-my-zsh plugin or a stale `/usr/...` path makes every terminal print errors. Pinned by: Task 5 test asserts `zsh -ic 'echo ok'` prints exactly `ok`.
4. **`swaymsg reload` / re-login** — `exec_always` lines re-run on reload and restart `sway-session.target`; the bar and session units must survive it. Pinned by: Task 6 test runs `swaymsg reload` and re-asserts waybar/kanshi.
5. **Locked out after install** — undecryptable secrets mean no user password; private flake input unreachable from the ISO means no install. Pinned by: Task 3 test logs in with the sops password; Task 10 rehearsal checks `/run/secrets-for-users/user-password` after a real install and runs `nix flake metadata --offline` on the ISO.

---

## File map

| Path | Responsibility | Task |
|---|---|---|
| `home/default.nix` | user identity, imports | 1 |
| `home/packages.nix` | `home.packages` (moved from `home.nix`) | 1 |
| `home/args.nix` | `extraSpecialArgs` (custom derivations + inputs) | 1 |
| `home/generic-linux.nix` | Ubuntu-only `targets.genericLinux` | 1 |
| `home/dotfiles-packages.nix` | folded / no-folding stow package lists | 4 |
| `home/dotfiles.nix` | `dotfiles.{enable,root}` options, out-of-store links | 4 |
| `scripts/check-portable-paths` | forbid distro-specific absolute paths in stow | 2 |
| `scripts/check-dotfiles-parity` | installer vs. nix stow lists | 4 |
| `flake.nix` | inputs, `mkHost`, hosts, checks, formatter | 3 (+9, 10) |
| `checks/default.nix` | all flake checks | 3 (+4, 9) |
| `tests/desktop.nix` | headless NixOS test | 3 (+4, 5, 6) |
| `nixos/default.nix` | imports of all shared system modules | 3 (+4, 5, 6) |
| `nixos/base.nix` | nix, locale, tz, network, sshd, stateVersion | 3 |
| `nixos/users.nix` | user, password from sops | 3 |
| `nixos/secrets.nix` | sops-nix module import | 3 |
| `nixos/home.nix` | home-manager as NixOS module | 4 |
| `nixos/shell.nix` | zsh + oh-my-zsh from nixpkgs, direnv | 5 |
| `nixos/desktop-sway.nix` | sway, portals, pipewire, desktop binaries | 6 |
| `nixos/greetd.nix`, `logind.nix`, `fonts.nix`, `security.nix`, `theme.nix` | one former ansible role each | 6 |
| `hosts/vm/default.nix` | VM hardware + VM secrets | 3 |
| `hosts/vm/interactive.nix` | GL display, shared `~/.dot`, disk image location | 7 |
| `hosts/p15v/{default,common,hardware,disko,nvidia,wifi,snapper}.nix` | the laptop | 9 |
| `hosts/p15v-rehearsal.nix` | p15v minus hardware, on QEMU | 10 |
| `hosts/iso/{default,rehearsal}.nix` | installer ISO | 10 |
| `keys/jantrojak.pub` | public SSH keys (ISO root + user) | 3 |
| `.sops.yaml`, `secrets/*` | sops recipients and encrypted files | 3, 8, 10 |
| `scripts/vm-rehearsal` | install rehearsal driver | 10 |
| `scripts/migration-preflight` | read-only pre-wipe report | 11 |
| `ansible/playbook-user.yml`, `scripts/bootstrap-user` | post-install user setup via existing roles | 11 |
| `doc/nixos.md`, `doc/nixos-migration.md` | how it works / runbook + hardware checklist | 7, 11 |
| `mise.toml`, `lefthook.yml`, `.gitignore` | tasks, hooks, ignores | 3, 7, 10 |

---

### Task 0: Preconditions

**Files:** none.

- [ ] **Step 1: Make sure the user's in-progress Nix edits are committed**

Run: `git -C ~/.dot diff --quiet -- flake.nix flake.lock home.nix && echo CLEAN || echo DIRTY`
Expected: `CLEAN`. If `DIRTY`, STOP and ask the user to commit their own changes to these three files first (they contain unrelated work: `nixpkgs-bazel`, `logcli-zsh-completion`, new packages). Do not commit them on the user's behalf and do not stash them.

- [ ] **Step 2: Confirm KVM and the flake evaluate**

Run: `test -w /dev/kvm && nix eval --raw ~/.dot#homeConfigurations.jantrojak.activationPackage.drvPath`
Expected: a `/nix/store/...-home-manager-generation.drv` path. Save it: `nix eval --raw ~/.dot#homeConfigurations.jantrojak.activationPackage.drvPath > /tmp/hm-drv-before`.

---

### Task 1: Split `home.nix` into `home/` without changing the result

**Files:**
- Create: `home/default.nix`, `home/packages.nix`, `home/args.nix`, `home/generic-linux.nix`
- Delete: `home.nix`
- Modify: `flake.nix` (the `homeConfigurations` block only)

**Interfaces:**
- Produces: `home/args.nix` is a function `{ pkgs, inputs }: { inputs, ccstatusline, jira-cli, claude-desktop }` used as home-manager `extraSpecialArgs` (Task 3 and 4 reuse it as `homeArgs`). `home/default.nix` is the user module both NixOS and Ubuntu import. `home/generic-linux.nix` is imported only by the standalone Ubuntu config.

- [ ] **Step 1: The test — derivation must stay identical**

The test is drvPath equality against `/tmp/hm-drv-before` from Task 0. A pure move of Nix code must not change a single derivation.

- [ ] **Step 2: Create `home/args.nix`**

```nix
# extraSpecialArgs for the user environment, shared by the standalone
# (Ubuntu) homeConfigurations and the NixOS home-manager module.
{ pkgs, inputs }:
{
  inherit inputs;
  ccstatusline = pkgs.callPackage ../nix/ccstatusline.nix { };
  jira-cli = pkgs.callPackage ../nix/jira-cli.nix { };
  claude-desktop = pkgs.callPackage ../nix/claude-desktop.nix { };
}
```

- [ ] **Step 3: Create `home/packages.nix`**

Move, verbatim, from `home.nix`: the function header, the whole `let … in` block (`mkClaudeDesktop`, `claude-desktop-personal`, `claude-desktop-work`, all comments, `logcli-zsh-completion`, `vscode-fixed`) and the `home.packages = with pkgs; [ … ];` list with all its comments. The file body becomes:

```nix
{
  config,
  pkgs,
  inputs,
  ccstatusline,
  jira-cli,
  claude-desktop,
  ...
}:

let
  # (the entire let-block from home.nix, unchanged; fix the import path:)
  mkClaudeDesktop = import ../nix/claude-desktop-profile.nix {
    inherit (pkgs) lib runCommand makeWrapper;
    inherit claude-desktop;
  };
  # … claude-desktop-personal, claude-desktop-work, logcli-zsh-completion,
  # vscode-fixed exactly as in home.nix …
in
{
  # 1:1 with stow/mise/.config/mise/config.toml. (comment block from home.nix)
  home.packages = with pkgs; [
    # … the full list from home.nix, unchanged …
  ];
}
```

The only textual change inside the moved code is `./nix/claude-desktop-profile.nix` → `../nix/claude-desktop-profile.nix`. Copy with an editor or `sed -n`, not by retyping.

- [ ] **Step 4: Create `home/default.nix`**

```nix
# The user environment. Imported by NixOS (nixos/home.nix) and by the
# standalone Ubuntu homeConfigurations (flake.nix, together with
# ./generic-linux.nix).
_:
{
  imports = [ ./packages.nix ];

  home.username = "jantrojak";
  home.homeDirectory = "/home/jantrojak";

  # Bumping this after the initial setup is not required/recommended;
  # it pins the home-manager config format, not package versions.
  home.stateVersion = "24.11";

  home.sessionVariables = {
    GOPRIVATE = "github.com/zezav-cz/*";
  };

  programs.home-manager.enable = true;
}
```

- [ ] **Step 5: Create `home/generic-linux.nix`**

```nix
# Ubuntu only: recommended for non-NixOS Linux (NIX_PATH, TERMINFO_DIRS,
# XDG data dirs). NixOS must not import this.
{
  targets.genericLinux.enable = true;
}
```

- [ ] **Step 6: Point the flake at the new modules, delete `home.nix`**

In `flake.nix` replace the `homeConfigurations."jantrojak"` value with:

```nix
      homeConfigurations."jantrojak" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = import ./home/args.nix { inherit pkgs inputs; };
        modules = [
          ./home
          ./home/generic-linux.nix
        ];
      };
```

Run: `git rm -q home.nix && git add home/`  (new files must be tracked or the flake can't see them)

- [ ] **Step 7: Verify the derivation is unchanged**

Run: `nix eval --raw ~/.dot#homeConfigurations.jantrojak.activationPackage.drvPath | diff - /tmp/hm-drv-before && echo SAME`
Expected: `SAME`. If it differs, diff the two with `nix-diff` (`nix run nixpkgs#nix-diff -- $(cat /tmp/hm-drv-before) $(nix eval --raw ~/.dot#homeConfigurations.jantrojak.activationPackage.drvPath)`) and fix the move until it is `SAME`.

- [ ] **Step 8: Update docs that name `home.nix`**

Run: `grep -rn 'home\.nix' --include=*.md --include=*.py --include=*.nix --include=*.yml . | grep -v '^./docs/superpowers'`
Replace each mention with `home/packages.nix` (package lists) or `home/default.nix` (identity/settings) as appropriate. Do not touch `docs/superpowers/`.

- [ ] **Step 9: Commit**

```bash
git add home/ flake.nix && git rm -q --cached home.nix 2>/dev/null || true
git add -p CLAUDE.md doc/ installer/   # only the home.nix → home/ mentions from Step 8
git commit -m "refactor(nix): split home.nix into home/ modules

NixOS will import the same user environment as the standalone Ubuntu
config, so the Ubuntu-only genericLinux target and the shared package
list must live in separate modules. The activation derivation is
unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Make stowed configs distro-portable

**Files:**
- Create: `scripts/check-portable-paths`
- Modify: `stow/systemd/.config/systemd/user/{kanshi,ssh-agent,claude-rc@,git-autopush-vnotes,obsidian-remotely-save,openclaw-gateway}.service`, `stow/systemd/.config/environment.d/global-vars.conf`, `stow/sway/.config/sway/config.d/95-xdg-user-dirs.conf`, `stow/sway/.config/waybar/scripts/{colorscheme,gammastep}.sh`, `stow/k9s/.config/k9s/skins/k9s-theme-watcher.sh`, `stow/zsh/.zshrc`, `stow/my-scripts/.local/bin/{ssh-askpass-portable,ssh-askpass-with-audit}`
- Delete: `stow/systemd/.config/systemd/user/timers.target.wants/snap.firmware-updater.firmware-notifier.timer`

**Interfaces:**
- Produces: `scripts/check-portable-paths [STOW_DIR]` — exit 0 and prints `portable-paths: OK`, or exit 1 and lists offending `file:line:content`. Task 3 wires it into `nix flake check` as `checks.portable-paths`.

- [ ] **Step 1: Write the checker (the failing test)**

`scripts/check-portable-paths`:

```bash
#!/usr/bin/env bash
# Fail if stowed desktop/session configs call binaries through distro-specific
# absolute paths (/usr/bin/x, /usr/libexec/x, /bin/bash, ...). They do not exist
# on NixOS. `/usr/bin/env <cmd>` and `/bin/sh` exist on every distro and are fine.
set -euo pipefail

root="${1:-stow}"
dirs=(sway systemd zsh ssh-agent xdg-portals foot k9s my-scripts rofi tmux git)
scan=()
for d in "${dirs[@]}"; do [[ -d "$root/$d" ]] && scan+=("$root/$d"); done

# Lines that probe several distro paths on purpose (guarded with -x/-e).
allow=(
  '/sway/\.config/sway/config:[0-9]+:include .*layered-include'
  '/my-scripts/\.local/bin/ssh-askpass-(portable|with-audit):[0-9]+:[[:space:]]*/usr/'
)

pattern='(^|[^[:alnum:]_./-])/(usr/(local/)?(s?bin|lib|libexec)|bin)/[[:alnum:]_.-]+'
hits=$(grep -rnEI "$pattern" "${scan[@]}" \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(#([^!]|$)|//|--)' \
  | grep -vE '/usr/bin/env([[:space:]]|$)|/bin/sh([[:space:]]|$|")' || true)
for a in "${allow[@]}"; do
  hits=$(grep -vE "$a" <<<"$hits" || true)
done

if [[ -n "$hits" ]]; then
  echo "Distro-specific absolute paths (use '/usr/bin/env <cmd>' or a bare command):" >&2
  echo "$hits" >&2
  exit 1
fi
echo "portable-paths: OK"
```

Run: `chmod +x scripts/check-portable-paths && nix run nixpkgs#shellcheck -- scripts/check-portable-paths`
Expected: no shellcheck output.

- [ ] **Step 2: Run it to see it fail**

Run: `scripts/check-portable-paths stow`
Expected: exit 1, listing (at least) `kanshi.service:13`, `ssh-agent.service:13`, `ssh-agent.service:15`, `claude-rc@.service:14,15`, `git-autopush-vnotes.service:9`, `obsidian-remotely-save.service:8`, `openclaw-gateway.service:7`, `global-vars.conf:1`, `95-xdg-user-dirs.conf:13`, `colorscheme.sh:1`, `gammastep.sh:1`, `k9s-theme-watcher.sh:1`, `.zshrc:176`.

- [ ] **Step 3: Fix each hit**

Exact replacements (keep surrounding comments; update a comment if it now lies):

| File | Old | New |
|---|---|---|
| `kanshi.service` | `ExecStart=/usr/bin/kanshi` | `ExecStart=/usr/bin/env kanshi` |
| `ssh-agent.service` | `ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK` | `ExecStart=/usr/bin/env ssh-agent -D -a $SSH_AUTH_SOCK` |
| `ssh-agent.service` | `ExecStartPost=/bin/bash -c '…'` | `ExecStartPost=/usr/bin/env bash -c '…'` (same quoted body) |
| `ssh-agent.service` | `ExecStop=kill $MAINPID` | delete the line (systemd's default stop already SIGTERMs the main PID; a bare `kill` is not resolvable on NixOS) |
| `claude-rc@.service` | `/usr/bin/tmux` (2×) | `/usr/bin/env tmux` |
| `git-autopush-vnotes.service` | `ExecStart=/usr/bin/bash -c` | `ExecStart=/usr/bin/env bash -c` |
| `obsidian-remotely-save.service` | `ExecStart=/usr/local/bin/obsidian command` | `ExecStart=/usr/bin/env obsidian command` |
| `openclaw-gateway.service` | `ExecStart=/bin/bash -c` | `ExecStart=/usr/bin/env bash -c` |
| `environment.d/global-vars.conf` | `EDITOR=/usr/bin/nvim` | `EDITOR=nvim` |
| `95-xdg-user-dirs.conf` | `exec /usr/bin/xdg-user-dirs-update` | `exec xdg-user-dirs-update` (fix the comment above it that claims the path is portable) |
| `colorscheme.sh`, `gammastep.sh`, `k9s-theme-watcher.sh` | `#!/bin/bash` | `#!/usr/bin/env bash` |
| `.zshrc:1` | `export ZSH="$HOME/.oh-my-zsh"` | `export ZSH="${ZSH:-$HOME/.oh-my-zsh}"` |
| `.zshrc:176` | `alias ccat='/usr/bin/cat'` | `alias ccat='command cat'` |

`obsidian-remotely-save.service`: on Ubuntu `obsidian` lives in `/usr/local/bin`, which is on the systemd user manager's default PATH, so `/usr/bin/env obsidian` still resolves there.

For both askpass scripts, prepend a NixOS candidate to the probe list (first line of the `for p in \` list):

```sh
for p in \
  /run/current-system/sw/bin/lxqt-openssh-askpass \
  /usr/libexec/openssh/gnome-ssh-askpass \
```

and extend the comment above the loop with: `NixOS: lxqt-openssh-askpass from the system profile (nixos/desktop-sway.nix).`

Delete the Ubuntu-only snap timer link:
`git rm stow/systemd/.config/systemd/user/timers.target.wants/snap.firmware-updater.firmware-notifier.timer`

- [ ] **Step 4: Run the checker until it passes**

Run: `scripts/check-portable-paths stow`
Expected: `portable-paths: OK`

- [ ] **Step 5: Prove Ubuntu still works (Review Focus 1)**

Run:
```bash
systemctl --user daemon-reload
systemd-analyze --user verify ~/.config/systemd/user/{kanshi,ssh-agent,claude-rc@x,git-autopush-vnotes}.service 2>&1 | grep -v 'Unknown key\|is not executable' || true
sway -C -c ~/.config/sway/config && echo SWAY-OK
zsh -ic 'echo ok' 2>&1 | tail -1
systemctl --user restart kanshi.service ssh-agent.service && systemctl --user is-active kanshi.service ssh-agent.service
```
Expected: no `Command … is not executable` / `not found` errors from verify, `SWAY-OK`, `ok`, `active` ×2.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-portable-paths
git add -p stow/   # only the hunks from Step 3; user WIP in the same files stays unstaged
git commit -m "fix(stow): call binaries via PATH instead of distro paths

/usr/bin/kanshi, /bin/bash and friends do not exist on NixOS. Going
through /usr/bin/env keeps the same units and sway config working on
Ubuntu and NixOS. The checker keeps new hardcoded paths out.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Flake skeleton, VM host, secrets, lint, first NixOS test

**Files:**
- Modify: `flake.nix`, `flake.lock`, `lefthook.yml`, `mise.toml`, `.gitignore`
- Create: `nixos/{default,base,users,secrets}.nix`, `hosts/vm/default.nix`, `checks/default.nix`, `tests/desktop.nix`, `keys/jantrojak.pub`, `.sops.yaml`, `secrets/vm-test.agekey`, `secrets/vm.yaml`

**Interfaces:**
- Consumes: `home/args.nix` (Task 1), `scripts/check-portable-paths` (Task 2).
- Produces:
  - `mkHost :: [module] -> nixosSystem` in `flake.nix`, `specialArgs = { inputs, self, homeArgs }`.
  - `nixosConfigurations.vm`.
  - sops secret name `user-password` (yescrypt hash) — every host's sops file must contain it.
  - `checks.x86_64-linux.{nix-lint,portable-paths,desktop}`.
  - `tests/desktop.nix`: `{ pkgs, self, inputs, homeArgs }: <test derivation>`; its `testScript` is a Nix string later tasks append to.
  - `keys/jantrojak.pub`: the user's public SSH keys.

- [ ] **Step 1: Add inputs and restructure `flake.nix`**

Replace `flake.nix` with (keep the existing `nixpkgs-bazel` comment and `vn` block exactly as they are in the file at this point):

```nix
{
  description = "p15v: NixOS system and home-manager user environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # (existing nixpkgs-bazel comment + url, unchanged)
    nixpkgs-bazel.url = "github:NixOS/nixpkgs/01fbdeef22b76df85ea168fbfe1bfd9e63681b30";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # private repo, has its own flake.nix (packages.default via buildGoModule)
    vn = {
      url = "git+ssh://git@github.com/zezav-cz/vn.git?ref=refs/tags/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      inherit (nixpkgs) lib;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # slack, obsidian, nvidia, etc.
      };
      homeArgs = import ./home/args.nix { inherit pkgs inputs; };
      # Every host shares nixos/ and the one pkgs instance above.
      mkHost =
        modules:
        lib.nixosSystem {
          specialArgs = { inherit inputs self homeArgs; };
          modules = [
            { nixpkgs.pkgs = pkgs; }
            ./nixos
          ] ++ modules;
        };
    in
    {
      homeConfigurations."jantrojak" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = homeArgs;
        modules = [
          ./home
          ./home/generic-linux.nix
        ];
      };

      nixosConfigurations = {
        vm = mkHost [ ./hosts/vm ];
      };

      checks.${system} = import ./checks { inherit pkgs self inputs homeArgs; };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
```

Run: `nix flake lock` (adds the four inputs to `flake.lock`, leaves existing pins alone).
Expected: `flake.lock` gains `disko`, `sops-nix`, `stylix`, `nixos-hardware`; `git diff flake.lock | grep -c '"nixpkgs"'` shows the root nixpkgs rev unchanged.

- [ ] **Step 2: Public keys and VM secrets**

```bash
mkdir -p keys secrets
ssh-add -L > keys/jantrojak.pub          # public halves only; agent is the YubiKey/ssh-agent
test -s keys/jantrojak.pub
nix shell --inputs-from . nixpkgs#age -c age-keygen -o secrets/vm-test.agekey
VM_PUB=$(nix shell --inputs-from . nixpkgs#age -c age-keygen -y secrets/vm-test.agekey)
cat > .sops.yaml <<EOF
# Recipients per secrets file. vm_test is a throwaway key committed on purpose
# (secrets/vm-test.agekey): vm.yaml holds nothing real.
keys:
  - &vm_test $VM_PUB
creation_rules:
  - path_regex: secrets/vm\.yaml$
    key_groups:
      - age:
          - *vm_test
EOF
HASH=$(nix shell --inputs-from . nixpkgs#mkpasswd -c mkpasswd -m yescrypt vm)
printf 'user-password: %s\n' "$HASH" > secrets/vm.yaml
SOPS_AGE_KEY_FILE=secrets/vm-test.agekey nix shell --inputs-from . nixpkgs#sops -c sops -e -i secrets/vm.yaml
grep -q '^sops:' secrets/vm.yaml && ! grep -q '\$y\$' secrets/vm.yaml && echo ENCRYPTED
```
Expected: `ENCRYPTED`. The VM password is `vm`.

- [ ] **Step 3: `nixos/` base modules**

`nixos/default.nix`:
```nix
# Shared by every machine (vm, p15v, p15v-rehearsal). Host differences live
# in hosts/. One module per former ansible role.
{
  imports = [
    ./base.nix
    ./secrets.nix
    ./users.nix
  ];
}
```

`nixos/base.nix`:
```nix
{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  # The LUKS passphrase is typed in the initrd, before sway's us,cz switching
  # exists: keep the console on plain us so the passphrase means the same keys.
  console.keyMap = "us";

  networking.networkmanager.enable = true;

  # sops-nix derives the host age key from the ed25519 host key, so sshd must
  # exist; it stays unreachable unless a host opens the firewall.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    pciutils
    usbutils
  ];

  system.stateVersion = "26.11";
}
```

`nixos/secrets.nix`:
```nix
# sops-nix. Each host sets sops.defaultSopsFile; every sops file must contain
# `user-password`.
{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];
}
```

`nixos/users.nix`:
```nix
{ config, pkgs, ... }:
{
  users.mutableUsers = false;
  sops.secrets.user-password.neededForUsers = true;

  programs.zsh.enable = true;

  users.users.jantrojak = {
    isNormalUser = true;
    uid = 1001; # same as on Ubuntu: restored files and 9p shares keep their owner
    description = "Jan Trojak";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.user-password.path;
    openssh.authorizedKeys.keyFiles = [ ../keys/jantrojak.pub ];
  };
}
```

- [ ] **Step 4: VM host**

`hosts/vm/default.nix`:
```nix
# QEMU guest used by `mise run vm` and the NixOS test. No bootloader or disko:
# qemu-vm.nix boots the kernel directly.
{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  networking.hostName = "vm";

  virtualisation = {
    memorySize = 8192;
    cores = 4;
    diskSize = 20480;
  };

  # Throwaway key, world-readable in the store on purpose: vm.yaml holds only
  # the VM test password.
  sops = {
    defaultSopsFile = ../../secrets/vm.yaml;
    age.keyFile = "${../../secrets/vm-test.agekey}";
    age.sshKeyPaths = [ ];
    age.generateKey = false;
  };
}
```

- [ ] **Step 5: Write the failing test**

`tests/desktop.nix`:
```nix
# Headless NixOS test of the desktop, run by `nix flake check`.
{
  pkgs,
  self,
  inputs,
  homeArgs,
}:
pkgs.testers.runNixOSTest {
  name = "desktop";
  node.specialArgs = { inherit inputs self homeArgs; };
  nodes.machine = {
    imports = [
      ../nixos
      ../hosts/vm
    ];
  };
  testScript = ''
    start_all()

    with subtest("base system and sops password"):
        machine.wait_for_unit("multi-user.target")
        machine.succeed("test -s /run/secrets-for-users/user-password")
        machine.succeed("test \"$(id -u jantrojak)\" = 1001")
        machine.succeed("getent passwd jantrojak | grep -q /zsh$")

    with subtest("login with the sops password on tty1"):
        machine.wait_until_tty_matches("1", "login: ")
        machine.send_chars("jantrojak\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars("vm\n")
        machine.wait_until_succeeds("pgrep -u jantrojak zsh")
  '';
}
```

`checks/default.nix`:
```nix
{
  pkgs,
  self,
  inputs,
  homeArgs,
}:
{
  nix-lint =
    pkgs.runCommand "nix-lint"
      {
        nativeBuildInputs = [
          pkgs.nixfmt
          pkgs.statix
          pkgs.deadnix
          pkgs.findutils
        ];
      }
      ''
        cd ${self}
        find . -name '*.nix' -not -path './stow/*' -print0 | xargs -0 nixfmt --check
        statix check .
        deadnix --fail --no-lambda-pattern-names .
        touch $out
      '';

  portable-paths = pkgs.runCommand "portable-paths" { nativeBuildInputs = [ pkgs.bash ]; } ''
    bash ${self}/scripts/check-portable-paths ${self}/stow
    touch $out
  '';

  desktop = import ../tests/desktop.nix {
    inherit
      pkgs
      self
      inputs
      homeArgs
      ;
  };
}
```

Run: `git add flake.nix flake.lock nixos hosts checks tests keys secrets .sops.yaml && nix build -L .#checks.x86_64-linux.desktop`
Expected: it builds and the test PASSES only if everything above is right. To see the test actually guard something, temporarily change `send_chars("vm\n")` to `send_chars("wrong\n")`, run again → FAIL at `pgrep -u jantrojak zsh` (timeout), then revert.

- [ ] **Step 6: Format and lint the whole repo's Nix**

Run: `nix fmt && nix build -L .#checks.x86_64-linux.nix-lint`
Expected: `nix fmt` may reformat `nix/*.nix`, `home/*.nix`. If `statix`/`deadnix` report findings, run `nix run --inputs-from . nixpkgs#statix -- fix .` and `nix run --inputs-from . nixpkgs#deadnix -- --edit --no-lambda-pattern-names .`, review the diff, rebuild until the check passes. Then verify Task 1's invariant still holds for real changes only: `nix build .#homeConfigurations.jantrojak.activationPackage` succeeds.

- [ ] **Step 7: Lefthook + mise hooks for Nix**

Append to `lefthook.yml` under `pre-commit.commands`:
```yaml
    nixfmt:
      run: nix run --inputs-from . nixpkgs#nixfmt -- --check {staged_files}
      glob: "*.nix"
```
Append to `mise.toml`:
```toml
[tasks."nix:check"]
run = "nix flake check -L"
description = "All Nix checks: lint, portable paths, list parity, VM desktop test, p15v build"

[tasks."nix:fmt"]
run = "nix fmt"
description = "Format all Nix files"
```
Append to `.gitignore`:
```
# QEMU disk images and rehearsal state (mise run vm, vm:rehearsal)
/.vm/
/result*
```

- [ ] **Step 8: Run all checks**

Run: `nix flake check -L`
Expected: all checks pass (first run downloads a lot; later runs are cached).

- [ ] **Step 9: Commit**

```bash
git add flake.nix flake.lock nixos hosts checks tests keys secrets .sops.yaml lefthook.yml mise.toml nix home
git add -p .gitignore
git commit -m "feat(nixos): add flake hosts, VM, sops secrets and NixOS test

Starts the NixOS configuration with a QEMU host and a headless test so
every later piece is proven in a VM before it reaches the laptop.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: home-manager on NixOS and out-of-store dotfile links

**Files:**
- Create: `nixos/home.nix`, `home/dotfiles.nix`, `home/dotfiles-packages.nix`, `scripts/check-dotfiles-parity`
- Modify: `nixos/default.nix`, `home/default.nix`, `checks/default.nix`, `tests/desktop.nix`

**Interfaces:**
- Consumes: `homeArgs`, `self` specialArgs (Task 3).
- Produces:
  - Options `dotfiles.enable :: bool` (default `false`) and `dotfiles.root :: str` (default `"${config.home.homeDirectory}/.dot"`) in home-manager.
  - `home/dotfiles-packages.nix :: { folded :: [str]; noFolding :: [str]; }`.
  - `checks.dotfiles-parity`.
  - Systemd unit `home-manager-jantrojak.service` on NixOS hosts.

- [ ] **Step 1: Extend the test first**

Append to `testScript` in `tests/desktop.nix` (before the closing `''`):
```python
    with subtest("home-manager links dotfiles out of store"):
        machine.wait_for_unit("home-manager-jantrojak.service")
        root = machine.succeed("cat /etc/dotfiles-root").strip()
        # folded package: the whole directory is one link into the repo
        machine.succeed(f"test \"$(readlink -f /home/jantrojak/.config/sway)\" = {root}/stow/sway/.config/sway")
        machine.succeed(f"test \"$(readlink -f /home/jantrojak/.zshrc)\" = {root}/stow/zsh/.zshrc")
        # no-folding package: real directory, per-file links
        machine.succeed("test -d /home/jantrojak/.config/foot -a ! -L /home/jantrojak/.config/foot")
        machine.succeed(f"test \"$(readlink -f /home/jantrojak/.config/foot/foot.ini)\" = {root}/stow/foot/.config/foot/foot.ini")
        machine.succeed("test \"$(stat -c %a /home/jantrojak/.gnupg)\" = 700")

    with subtest("runtime-written files stay out of the repo"):
        for f in [".config/foot/theme-mode.ini", ".config/k9s/config.yaml", ".config/lazygit/state.yml", ".gnupg/pubring.kbx"]:
            machine.succeed(f"su jantrojak -c 'echo x > /home/jantrojak/{f}'")
            machine.succeed(f"test ! -L /home/jantrojak/{f}")
            machine.succeed(f"case \"$(readlink -f /home/jantrojak/{f})\" in {root}/*) exit 1;; esac")
```
And turn `nodes.machine` into a function so it can use `lib`, adding two lines so the test resolves links without a host checkout:
```nix
  nodes.machine =
    { lib, ... }:
    {
      imports = [
        ../nixos
        ../hosts/vm
      ];
      home-manager.users.jantrojak.dotfiles.root = lib.mkForce "${self}";
      environment.etc."dotfiles-root".text = "${self}";
    };
```
Note: `k9s/config.yaml` is written by `k9s-theme-watcher.sh` at runtime; if `stow/k9s/.config/k9s/config.yaml` is tracked in the repo, the test's write would hit a per-file link. Check `git ls-files stow/k9s` first; if `config.yaml` is tracked, drop it from that list (the stow comment in `installer/config.py` says it must stay outside the repo, so it should not be tracked).

Run: `nix build -L .#checks.x86_64-linux.desktop`
Expected: FAIL — `home-manager-jantrojak.service` does not exist / option `home-manager` unknown.

- [ ] **Step 2: Stow package lists, shared with the parity check**

`home/dotfiles-packages.nix`:
```nix
# Mirrors STOW_PACKAGES / STOW_NO_FOLDING in installer/config.py (checked by
# checks.dotfiles-parity until the Ubuntu installer is removed).
{
  # Linked as whole directories (stow "folding"): editing or adding files
  # under them needs no rebuild.
  folded = [
    "ccstatusline"
    "git"
    "mise"
    "nvim"
    "rofi"
    "ssh-agent"
    "sway"
    "systemd"
    "tmux"
    "zsh"
    "nwg-displays"
    "xdg-portals"
  ];
  # Linked per file: the target directory also holds runtime state that must
  # stay outside the repo (see the comments on STOW_NO_FOLDING).
  noFolding = [
    "claude"
    "claude-personal"
    "gnupg"
    "my-scripts"
    "pgcli"
    "vscode"
    "foot"
    "k9s"
    "lazygit"
    "lnav"
    "pandoc"
  ];
}
```

- [ ] **Step 3: The dotfiles module**

`home/dotfiles.nix`:
```nix
# Links stow/ packages into ~ like GNU stow does, but via home-manager:
# mkOutOfStoreSymlink points at the working copy (dotfiles.root), so edits
# apply without a rebuild. Off by default: on Ubuntu stow still owns ~.
{ config, lib, ... }:
let
  cfg = config.dotfiles;
  lists = import ./dotfiles-packages.nix;
  stowDir = ../stow;

  # Directories home-manager itself writes into; link their files, not them.
  perFileDirs = [ "systemd/.config/environment.d" ];

  filesOf =
    pkg:
    map (p: lib.removePrefix "${toString stowDir}/${pkg}/" (toString p)) (
      lib.filesystem.listFilesRecursive (stowDir + "/${pkg}")
    );

  # stow-style folding: ~/.config/<x> and other top-level entries become one
  # link each; files directly in ~/.config stay files.
  foldedUnit =
    pkg: f:
    let
      parts = lib.splitString "/" f;
      top = builtins.head parts;
      second = builtins.elemAt parts 1;
    in
    if top == ".config" && builtins.length parts > 2 then
      (if lib.elem "${pkg}/.config/${second}" perFileDirs then f else ".config/${second}")
    else if top != ".config" && builtins.length parts > 1 then
      top
    else
      f;

  unitsOf =
    pkg:
    if lib.elem pkg lists.noFolding then filesOf pkg else lib.unique (map (foldedUnit pkg) (filesOf pkg));

  linksOf =
    pkg:
    lib.listToAttrs (
      map (u: {
        name = u;
        value.source = config.lib.file.mkOutOfStoreSymlink "${cfg.root}/stow/${pkg}/${u}";
      }) (unitsOf pkg)
    );
in
{
  options.dotfiles = {
    enable = lib.mkEnableOption "linking stow/ packages into ~ with home-manager";
    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.dot";
      description = "Working copy of this repo the links point into.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge (map linksOf (lists.folded ++ lists.noFolding));

    # gpg refuses a group/world-readable ~/.gnupg; per-file links leave the
    # directory itself to home-manager, which creates it 0755.
    home.activation.gnupgPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run chmod 700 "$HOME/.gnupg"
    '';
  };
}
```

Add `./dotfiles.nix` to `imports` in `home/default.nix`.

- [ ] **Step 4: home-manager as a NixOS module**

`nixos/home.nix`:
```nix
{ inputs, homeArgs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    # false: packages go to ~/.nix-profile exactly like on Ubuntu, which
    # .zshrc's fpath and plantuml-server.service (%h/.nix-profile/bin) expect.
    useUserPackages = false;
    extraSpecialArgs = homeArgs;
    backupFileExtension = "hm-backup";
    users.jantrojak = {
      imports = [ ../home ];
      dotfiles.enable = true;
    };
  };
}
```

Add `./home.nix` to `nixos/default.nix` imports.

- [ ] **Step 5: Run the test**

Run: `git add home nixos && nix build -L .#checks.x86_64-linux.desktop`
Expected: PASS. If home-manager reports a collision (`Existing file … is in the way`), it is a package whose directory HM also writes into — add `"<pkg>/.config/<dir>"` to `perFileDirs` with a comment naming the HM file, and re-run.

- [ ] **Step 6: Ubuntu still gets no links (Review Focus 1)**

Run: `nix eval --json .#homeConfigurations.jantrojak.config.home.file --apply 'f: builtins.filter (n: builtins.match ".*(sway|zshrc|foot).*" n != null) (builtins.attrNames f)'`
Expected: `[]`

- [ ] **Step 7: Parity checker (failing test first)**

`scripts/check-dotfiles-parity`:
```python
#!/usr/bin/env python3
"""Fail if installer/config.py and home/dotfiles-packages.nix list different
stow packages. Usage: check-dotfiles-parity CONFIG_PY NIX_LISTS_JSON"""

import ast
import json
import sys


def python_lists(path: str) -> dict[str, set[str]]:
    found: dict[str, set[str]] = {}
    for node in ast.parse(open(path, encoding="utf-8").read()).body:
        if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name):
            name = node.targets[0].id
            if name in ("STOW_PACKAGES", "STOW_NO_FOLDING"):
                found[name] = set(ast.literal_eval(node.value))
    return found


def main() -> int:
    py = python_lists(sys.argv[1])
    nix = json.load(open(sys.argv[2], encoding="utf-8"))
    pairs = [("STOW_PACKAGES", "folded"), ("STOW_NO_FOLDING", "noFolding")]
    ok = True
    for py_name, nix_name in pairs:
        a, b = py.get(py_name, set()), set(nix[nix_name])
        if a != b:
            ok = False
            print(f"{py_name} vs {nix_name}: only in installer {sorted(a - b)}, only in nix {sorted(b - a)}")
    print("dotfiles-parity: OK" if ok else "dotfiles-parity: MISMATCH")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
```

Add to `checks/default.nix`:
```nix
  dotfiles-parity =
    pkgs.runCommand "dotfiles-parity" { nativeBuildInputs = [ pkgs.python3 ]; }
      ''
        python3 ${self}/scripts/check-dotfiles-parity ${self}/installer/config.py \
          ${pkgs.writeText "lists.json" (builtins.toJSON (import ../home/dotfiles-packages.nix))}
        touch $out
      '';
```

Run: `chmod +x scripts/check-dotfiles-parity && nix run --inputs-from . nixpkgs#ruff -- check scripts/check-dotfiles-parity && sed -i 's/"pandoc"/"pandocX"/' home/dotfiles-packages.nix && git add home scripts/check-dotfiles-parity checks && nix build -L .#checks.x86_64-linux.dotfiles-parity`
Expected: FAIL with `only in installer ['pandoc'], only in nix ['pandocX']`.
Then: `sed -i 's/"pandocX"/"pandoc"/' home/dotfiles-packages.nix && nix build -L .#checks.x86_64-linux.dotfiles-parity` → PASS.

- [ ] **Step 8: Full check + commit**

Run: `nix flake check -L` → all pass.
```bash
git add home nixos checks tests scripts/check-dotfiles-parity
git commit -m "feat(nixos): link stow packages into ~ through home-manager

Out-of-store links keep the edit-without-rebuild workflow; no-folding
packages are linked per file so runtime state stays out of the repo.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: zsh with oh-my-zsh from nixpkgs

**Files:**
- Create: `nixos/shell.nix`
- Modify: `nixos/default.nix`, `tests/desktop.nix`

**Interfaces:**
- Consumes: `.zshrc` honouring a preset `$ZSH` (Task 2).
- Produces: system env vars `ZSH`, `ZSH_CUSTOM`, `ZSH_CACHE_DIR`, `DISABLE_AUTO_UPDATE`.

- [ ] **Step 1: Failing test (Review Focus 3)**

Append to `testScript`:
```python
    with subtest("interactive zsh starts clean"):
        out = machine.succeed("su - jantrojak -c \"zsh -ic 'echo ok' 2>&1\"").strip()
        assert out == "ok", f"zsh printed extra output:\n{out}"
        machine.succeed("su - jantrojak -c \"zsh -ic 'type _zsh_autosuggest_start && (( \\${+functions[_zsh_highlight]} ))'\"")
```

Run: `nix build -L .#checks.x86_64-linux.desktop`
Expected: FAIL — `.zshrc` sources `$HOME/.oh-my-zsh/oh-my-zsh.sh`, which does not exist.

- [ ] **Step 2: Implement**

`nixos/shell.nix`:
```nix
# Replaces ansible/roles/shell (git clones of oh-my-zsh + plugins). The stowed
# .zshrc reads $ZSH/$ZSH_CUSTOM when set and falls back to ~/.oh-my-zsh on
# Ubuntu.
{ pkgs, ... }:
let
  omzCustom = pkgs.runCommand "oh-my-zsh-custom" { } ''
    mkdir -p $out/plugins/zsh-autosuggestions $out/plugins/zsh-syntax-highlighting $out/plugins/zsh-completions
    echo "source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
      > $out/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    echo "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
      > $out/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
    ln -s ${pkgs.zsh-completions}/share/zsh/site-functions $out/plugins/zsh-completions/src
  '';
in
{
  programs.zsh = {
    enable = true;
    # .zshrc runs compinit itself; a second global one only slows startup.
    enableGlobalCompInit = false;
  };

  environment.variables = {
    ZSH = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
    ZSH_CUSTOM = "${omzCustom}";
    # $ZSH is read-only in the store
    ZSH_CACHE_DIR = "$HOME/.cache/oh-my-zsh";
    DISABLE_AUTO_UPDATE = "true";
  };

  # Replaces installer/steps/s10_direnv.py (~/.config/direnv/direnvrc).
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  environment.systemPackages = with pkgs; [
    fzf
    tmux
  ];
}
```

Verify the plugin file paths before trusting them:
Run: `for p in zsh-autosuggestions/zsh-autosuggestions.zsh zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do ls $(nix build --no-link --print-out-paths --inputs-from . nixpkgs#${p%%/*})/share/$p; done; ls $(nix build --no-link --print-out-paths --inputs-from . nixpkgs#zsh-completions)/share/zsh/site-functions | head -2; ls $(nix build --no-link --print-out-paths --inputs-from . nixpkgs#oh-my-zsh)/share/oh-my-zsh/oh-my-zsh.sh`
Expected: every path exists. If one differs, fix it in `omzCustom`.

Add `./shell.nix` to `nixos/default.nix`.

- [ ] **Step 3: Run the test**

Run: `git add nixos && nix build -L .#checks.x86_64-linux.desktop`
Expected: PASS. If `out` contains errors, they name the failing line of `.zshrc` — fix it in `stow/zsh/.zshrc` in a way that also works on Ubuntu (guard with `[[ -r … ]]` / `command -v`), re-run `scripts/check-portable-paths stow`, and re-test. Also re-run on the Ubuntu host: `zsh -ic 'echo ok'` → `ok`.

- [ ] **Step 4: Commit**

```bash
git add nixos tests
git add -p stow/zsh   # only if Step 3 needed a .zshrc fix
git commit -m "feat(nixos): provide oh-my-zsh and plugins from nixpkgs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Sway desktop (greetd, sway, portals, audio, fonts, logind, YubiKey, theme)

**Files:**
- Create: `nixos/{desktop-sway,greetd,logind,fonts,security,theme}.nix`
- Modify: `nixos/default.nix`, `tests/desktop.nix`

**Interfaces:**
- Consumes: stowed sway/waybar/systemd configs (Tasks 2, 4).
- Produces: greetd on tty1 launching `${config.programs.sway.package}/bin/sway`; user units `waybar.service`, `swaync.service` from packages; `/run/current-system/sw/bin/lxqt-openssh-askpass` (used by Task 2's askpass scripts); option `programs.sway.extraOptions` (Task 9 appends `--unsupported-gpu`).

- [ ] **Step 1: Failing test**

In `tests/desktop.nix`, replace the `"login with the sops password on tty1"` subtest (greetd replaces getty on tty1) with a greetd login, and add the desktop subtests. Also add to the `nodes.machine` body:
```nix
    # No GPU in the test VM: software rendering.
    virtualisation.qemu.options = [
      "-vga none"
      "-device virtio-gpu-pci"
    ];
    environment.sessionVariables = {
      WLR_RENDERER = "pixman";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
```
New/updated `testScript` subtests:
```python
    def user(cmd):
        return ("runuser -u jantrojak -- env XDG_RUNTIME_DIR=/run/user/1001 "
                "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus "
                f"sh -c 'SWAYSOCK=$(ls /run/user/1001/sway-ipc.*.sock 2>/dev/null | head -1); export SWAYSOCK; {cmd}'")

    with subtest("greetd login starts sway"):
        machine.wait_for_unit("greetd.service")
        machine.wait_until_tty_matches("1", "Username")
        machine.send_chars("jantrojak\n")
        machine.wait_until_tty_matches("1", "Password")
        machine.send_chars("vm\n")
        machine.wait_until_succeeds("ls /run/user/1001/sway-ipc.*.sock", timeout=120)
        machine.succeed(user("swaymsg -t get_tree >/dev/null"))
        machine.succeed(user("sway -C -c ~/.config/sway/config"))

    with subtest("session units"):
        for unit in ["sway-session.target", "waybar.service", "swaync.service", "kanshi.service", "ssh-agent.service"]:
            machine.wait_until_succeeds(user(f"systemctl --user is-active {unit}"), timeout=60)
        machine.succeed(user("systemctl --user is-active timers.target"))
        machine.succeed(user("systemctl --user list-timers --all | grep -q battery-notify"))
        machine.wait_until_succeeds(user("systemctl --user is-active xdg-desktop-portal.service"), timeout=60)
        machine.succeed("test -e /etc/pam.d/swaylock")

    with subtest("every binary the sway config calls exists"):
        machine.succeed(user(
            "for c in waybar swaync swaylock swayidle kanshi rofi foot grim slurp grimshot swappy "
            "wl-copy wl-paste cliphist gammastep brightnessctl playerctl pactl notify-send "
            "xdg-user-dirs-update nwg-bar gsettings lxqt-openssh-askpass; do "
            "command -v $c >/dev/null || { echo missing $c; exit 1; }; done"))

    with subtest("swaymsg reload keeps the session (Review Focus 4)"):
        machine.succeed(user("swaymsg reload"))
        machine.sleep(5)
        for unit in ["sway-session.target", "waybar.service", "kanshi.service"]:
            machine.wait_until_succeeds(user(f"systemctl --user is-active {unit}"), timeout=60)
        machine.screenshot("desktop")
```

Run: `nix build -L .#checks.x86_64-linux.desktop`
Expected: FAIL at `greetd.service` (unit missing).

- [ ] **Step 2: Implement the modules**

`nixos/desktop-sway.nix`:
```nix
# Replaces ansible roles packages-base, sway-minimal and sway-portability.
# The sway/waybar/kanshi configs themselves stay in stow/ (home/dotfiles.nix).
{ pkgs, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    # Everything stow/sway calls by name; also lands in systemPackages.
    extraPackages = with pkgs; [
      swaylock
      swayidle
      foot
      waybar
      swaynotificationcenter
      kanshi
      rofi
      grim
      slurp
      sway-contrib.grimshot
      swappy
      wl-clipboard
      cliphist
      gammastep
      brightnessctl
      playerctl
      pulseaudio # pactl
      libnotify # notify-send
      xdg-user-dirs
      nwg-bar
      nwg-displays
      glib # gsettings
      lxqt.lxqt-openssh-askpass # stow/my-scripts/.local/bin/ssh-askpass-portable
      lxsession # lxpolkit, as on Ubuntu (packages-base)
    ];
  };

  # sway-session.target (stow/systemd) Wants= these; on Ubuntu the distro
  # packages ship the units, here the packages do.
  systemd.packages = with pkgs; [
    waybar
    swaynotificationcenter
  ];
  services.dbus.packages = [ pkgs.swaynotificationcenter ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway.default = [
      "wlr"
      "gtk"
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true;
  security.polkit.enable = true;

  # gsettings calls in stow/sway/.config/sway/config and the waybar
  # colour-scheme toggle
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra # Adwaita-dark for GTK3
  ];

  services.tailscale.enable = true; # `tailscale systray` in the sway config
  hardware.bluetooth.enable = true;
}
```

`nixos/greetd.nix`:
```nix
# Replaces ansible/roles/greetd.
{ config, pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd ${config.programs.sway.package}/bin/sway";
      user = "greeter";
    };
  };
}
```

`nixos/logind.nix`:
```nix
# Replaces ansible/roles/logind: keep running with the lid closed on AC
# (docked), suspend on battery as usual.
{
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
}
```

`nixos/fonts.nix`:
```nix
# Replaces ansible/roles/fonts (Meslo Nerd Font + Font Awesome 6 downloads).
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg # "MesloLGS Nerd Font Mono" in foot.ini
    font-awesome_6
    noto-fonts
    noto-fonts-color-emoji # "Noto Color Emoji" in foot.ini
  ];
}
```

`nixos/security.nix`:
```nix
# YubiKey: PIV/OATH via pcscd (ykman), OpenPGP card for gpg, udev access.
{ pkgs, ... }:
{
  services.pcscd.enable = true;
  hardware.gpgSmartcards.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
}
```

`nixos/theme.nix`:
```nix
# stylix only where nothing in stow/ already themes at runtime: the Linux
# console and fontconfig defaults. GTK/Qt, foot, nvim, k9s, waybar follow the
# color-scheme toggle in stow/sway/.config/waybar/scripts/colorscheme.sh, and
# stylix must not fight it.
{ inputs, pkgs, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  stylix = {
    enable = true;
    autoEnable = false;
    homeManagerIntegration.autoImport = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    polarity = "dark";
    fonts.monospace = {
      package = pkgs.nerd-fonts.meslo-lg;
      name = "MesloLGS Nerd Font Mono";
    };
    targets = {
      console.enable = true;
      fontconfig.enable = true;
    };
  };
}
```

Verify the stylix option names against the locked input before building:
Run: `nix eval --json .#nixosConfigurations.vm.options.stylix --apply 'o: { a = o ? autoEnable; b = o ? homeManagerIntegration; c = o.targets ? console; d = o.targets ? fontconfig; }'` (after adding the import below)
Expected: all `true`. If `homeManagerIntegration.autoImport` or a target name changed upstream, use the name the locked stylix exposes.

Update `nixos/default.nix` imports to:
```nix
  imports = [
    ./base.nix
    ./secrets.nix
    ./users.nix
    ./home.nix
    ./shell.nix
    ./desktop-sway.nix
    ./greetd.nix
    ./logind.nix
    ./fonts.nix
    ./security.nix
    ./theme.nix
  ];
```

- [ ] **Step 3: Run the test**

Run: `git add nixos tests && nix build -L .#checks.x86_64-linux.desktop`
Expected: PASS; `result/desktop.png` shows sway with waybar. Look at it with the Read tool. A unit that is not active: `journalctl --user -u <unit>` in an interactive test (`nix run .#checks.x86_64-linux.desktop.driverInteractive`) — fix the root cause in the NixOS module or, if it is a config bug, in `stow/` keeping Ubuntu working, then re-run.

- [ ] **Step 4: Full check + commit**

Run: `nix flake check -L` → all pass.
```bash
git add nixos tests
git commit -m "feat(nixos): add the sway desktop, greetd, portals and fonts

Replaces the ansible system roles one module each; the NixOS test logs
in through greetd and checks the session units and sway reload.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Interactive VM (`mise run vm`)

**Files:**
- Create: `hosts/vm/interactive.nix`, `doc/nixos.md`
- Modify: `flake.nix` (`nixosConfigurations.vm`), `mise.toml`, `doc/README.md`

**Interfaces:**
- Produces: mise tasks `vm`, `vm:reset`, `vm:test`. The interactive VM mounts the host's `~/.dot` at `/mnt/dot` and links `~/.dot` → `/mnt/dot`.

- [ ] **Step 1: Interactive-only VM settings**

`hosts/vm/interactive.nix`:
```nix
# Only for `mise run vm` (not the NixOS test): GL display and the live repo.
{ pkgs, ... }:
{
  virtualisation = {
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
    # Relative to the repo root, where `mise run vm` starts QEMU.
    diskImage = "./.vm/vm.qcow2";
    # The host working copy: edit on the host, `swaymsg reload` in the guest.
    sharedDirectories.dot = {
      source = "/home/jantrojak/.dot";
      target = "/mnt/dot";
    };
  };

  home-manager.users.jantrojak =
    { config, ... }:
    {
      dotfiles.root = "/mnt/dot";
      home.file.".dot".source = config.lib.file.mkOutOfStoreSymlink "/mnt/dot";
    };

  # If sway shows a black screen (host without virgl), log in on tty2 and
  # set this to "pixman" in hosts/vm/interactive.nix.
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  environment.systemPackages = [ pkgs.foot ];
}
```

In `flake.nix`: `vm = mkHost [ ./hosts/vm ./hosts/vm/interactive.nix ];`

- [ ] **Step 2: mise tasks**

Append to `mise.toml`:
```toml
[tasks.vm]
run = "mkdir -p .vm && nix build -L .#nixosConfigurations.vm.config.system.build.vm -o .vm/result && .vm/result/bin/run-vm-vm"
description = "Boot the NixOS desktop in QEMU (user jantrojak, password vm)"

[tasks."vm:reset"]
run = "rm -f .vm/vm.qcow2"
description = "Delete the VM disk image (next `mise run vm` starts fresh)"

[tasks."vm:test"]
run = "nix build -L .#checks.x86_64-linux.desktop -o .vm/test && echo screenshot: .vm/test/desktop.png"
description = "Headless NixOS test of the desktop"
```

- [ ] **Step 3: Verify by hand**

Run: `mise run vm`
Expected, in the QEMU window: tuigreet → log in as `jantrojak` / `vm` → sway with waybar. In foot inside the VM:
```sh
readlink -f ~/.config/sway   # /mnt/dot/stow/sway/.config/sway
ls -ld ~ ~/.dot              # ~ owned by jantrojak, ~/.dot -> /mnt/dot
```
On the host, change the bar height in `stow/sway/.config/waybar/config*`, run `swaymsg reload` in the VM → the change is visible. Revert the host change. Close the VM.

Run: `mise run vm:test` → passes, prints the screenshot path.

- [ ] **Step 4: Docs**

`doc/nixos.md` — sections (prose as single long lines, no hard wrap): **Layout** (the file map from this plan, short), **How dotfiles are linked** (folded vs. per-file, `dotfiles.root`, why `useUserPackages = false`), **VM** (`mise run vm`, `vm:reset`, `vm:test`, password `vm`, the pixman fallback), **Checks** (each `checks.*` and what it guards), **Secrets** (recipients, how to edit: `SOPS_AGE_KEY_FILE=secrets/vm-test.agekey sops secrets/vm.yaml`). Add a line linking it from `doc/README.md`.

- [ ] **Step 5: Commit**

```bash
git add hosts flake.nix mise.toml doc/nixos.md
git add -p doc/README.md
git commit -m "feat(nixos): add an interactive VM with the live repo mounted

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: USER — real secrets for p15v

**This task needs the user's YubiKey and their real passwords. The agent prepares and explains; the user runs the marked commands.**

**Files:**
- Modify: `.sops.yaml`
- Create: `secrets/p15v.yaml`, `secrets/p15v-ssh-host-key.enc`, `secrets/p15v-ssh-host-key.pub`

**Interfaces:**
- Produces: `secrets/p15v.yaml` with keys `user-password` and `wifi-env` (`HOME_SSID=…`, `HOME_PSK=…`), decryptable by the personal YubiKey identity, the offline backup key and the p15v host key. `secrets/p15v-ssh-host-key.enc` — the host's private ed25519 key, sops-encrypted for personal keys only (binary format).

- [ ] **Step 1 (USER): Personal age identities**

```bash
nix shell --inputs-from ~/.dot nixpkgs#age-plugin-yubikey nixpkgs#age -c age-plugin-yubikey --generate --slot 1 --touch-policy cached --pin-policy once > ~/.config/sops/age/yubikey-identity.txt
grep -o 'age1yubikey1[0-9a-z]*' ~/.config/sops/age/yubikey-identity.txt          # personal recipient
nix shell --inputs-from ~/.dot nixpkgs#age -c age-keygen -o /tmp/backup.agekey   # offline backup
nix shell --inputs-from ~/.dot nixpkgs#age -c age-keygen -y /tmp/backup.agekey    # backup recipient
```
Store `/tmp/backup.agekey` in Bitwarden (secure note) and on paper, then `shred -u /tmp/backup.agekey`. Make `~/.config/sops/age/keys.txt` point at the YubiKey identity: `cat ~/.config/sops/age/yubikey-identity.txt >> ~/.config/sops/age/keys.txt`.

- [ ] **Step 2 (USER): p15v host key**

```bash
mkdir -p /tmp/p15v && ssh-keygen -t ed25519 -N "" -C root@p15v -f /tmp/p15v/ssh_host_ed25519_key
cp /tmp/p15v/ssh_host_ed25519_key.pub ~/.dot/secrets/p15v-ssh-host-key.pub
nix shell --inputs-from ~/.dot nixpkgs#ssh-to-age -c ssh-to-age < /tmp/p15v/ssh_host_ed25519_key.pub   # host recipient
```

- [ ] **Step 3 (agent, with the three recipients from the user): `.sops.yaml`**

```yaml
keys:
  - &vm_test age1…            # unchanged
  - &personal age1yubikey1…   # Step 1
  - &backup age1…             # Step 1
  - &p15v age1…               # Step 2
creation_rules:
  - path_regex: secrets/vm\.yaml$
    key_groups:
      - age:
          - *vm_test
  - path_regex: secrets/p15v\.yaml$
    key_groups:
      - age:
          - *personal
          - *backup
          - *p15v
  - path_regex: secrets/p15v-ssh-host-key\.enc$
    key_groups:
      - age:
          - *personal
          - *backup
```

- [ ] **Step 4 (USER): Encrypt**

```bash
cd ~/.dot
HASH=$(nix shell --inputs-from . nixpkgs#mkpasswd -c mkpasswd -m yescrypt)   # prompts for the real login password
printf 'user-password: %s\nwifi-env: |\n    HOME_SSID=<your ssid>\n    HOME_PSK=<your wifi password>\n' "$HASH" > secrets/p15v.yaml
nix shell --inputs-from . nixpkgs#sops -c sops -e -i secrets/p15v.yaml
nix shell --inputs-from . nixpkgs#sops -c sops -e --input-type binary --output-type binary /tmp/p15v/ssh_host_ed25519_key > secrets/p15v-ssh-host-key.enc
shred -u /tmp/p15v/ssh_host_ed25519_key
grep -q '^sops:' secrets/p15v.yaml && echo ENCRYPTED
nix shell --inputs-from . nixpkgs#sops -c sops -d secrets/p15v.yaml | grep -c user-password   # touch the YubiKey → 1
```
Expected: `ENCRYPTED`, then `1`.

- [ ] **Step 5 (agent): Commit**

```bash
git add .sops.yaml secrets/p15v.yaml secrets/p15v-ssh-host-key.enc secrets/p15v-ssh-host-key.pub
git commit -m "chore(secrets): add encrypted p15v secrets and host key

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: The p15v host (disko, NVIDIA, Wi-Fi, snapper)

**Files:**
- Create: `hosts/p15v/{default,common,hardware,disko,nvidia,wifi,snapper}.nix`
- Modify: `flake.nix`, `checks/default.nix`

**Interfaces:**
- Consumes: `secrets/p15v.yaml` (Task 8), `programs.sway.extraOptions` (Task 6).
- Produces: `nixosConfigurations.p15v`; `hosts/p15v/common.nix` (everything except real hardware — Task 10 reuses it); option `p15v.disk :: str` (default `/dev/nvme0n1`); LUKS mapping `cryptroot`; disko reads the passphrase from `/tmp/secret.key` at format time only; `checks.{p15v-layout,p15v-toplevel}`.

- [ ] **Step 1: Failing check**

Add to `checks/default.nix`:
```nix
  # Facts about the laptop config that must hold before it ever boots.
  p15v-layout =
    let
      c = self.nixosConfigurations.p15v.config;
      inherit (pkgs) lib;
    in
    assert lib.elem "subvol=@home" c.fileSystems."/home".options;
    assert lib.elem "subvol=@nix" c.fileSystems."/nix".options;
    assert c.fileSystems ? "/home/.snapshots";
    assert c.boot.initrd.luks.devices ? cryptroot;
    assert c.boot.initrd.luks.devices.cryptroot.allowDiscards;
    assert c.console.keyMap == "us";
    assert !c.hardware.nvidia.open;
    assert lib.elem "--unsupported-gpu" c.programs.sway.extraOptions;
    assert c.services.snapper.configs ? home;
    pkgs.runCommand "p15v-layout" { } "touch $out";

  p15v-toplevel = self.nixosConfigurations.p15v.config.system.build.toplevel;
```
Run: `nix build .#checks.x86_64-linux.p15v-layout`
Expected: FAIL — `nixosConfigurations.p15v` missing.

- [ ] **Step 2: Hardware config from the real machine**

Run on the laptop (Ubuntu):
```bash
nix shell --inputs-from ~/.dot nixpkgs#nixos-install-tools -c sh -c 'sudo env PATH="$PATH" nixos-generate-config --show-hardware-config --no-filesystems' > ~/.dot/hosts/p15v/hardware.nix
```
Then edit `hosts/p15v/hardware.nix`: delete the `nixpkgs.hostPlatform` line (the flake sets `nixpkgs.pkgs`) and any `networking.useDHCP` lines (NetworkManager owns networking). Add a header comment: `# Generated by nixos-generate-config --no-filesystems on p15v (Ubuntu), 2026-10-10. Filesystems come from disko.nix.`

- [ ] **Step 3: Host modules**

`hosts/p15v/disko.nix`:
```nix
# GPT: ESP + LUKS2 -> btrfs subvolumes. The LUKS passphrase is read from
# /tmp/secret.key only while formatting (doc/nixos-migration.md).
{ config, lib, ... }:
let
  btrfsOpts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  options.p15v.disk = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1";
    description = "Whole disk disko partitions (wiped!).";
  };

  config.disko.devices.disk.main = {
    type = "disk";
    device = config.p15v.disk;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/secret.key";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = btrfsOpts;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOpts;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOpts;
                };
                # snapper's config for /home expects /home/.snapshots
                "@home-snapshots" = {
                  mountpoint = "/home/.snapshots";
                  mountOptions = btrfsOpts;
                };
                "@swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "16G";
                };
              };
            };
          };
        };
      };
    };
  };
}
```

`hosts/p15v/snapper.nix`:
```nix
# Hourly /home snapshots; system rollback is NixOS generations instead.
{
  services.snapper.configs.home = {
    SUBVOLUME = "/home";
    ALLOW_USERS = [ "jantrojak" ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = "24";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "4";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";
  };
}
```

`hosts/p15v/common.nix`:
```nix
# Everything about p15v except its real hardware; shared with the install
# rehearsal (hosts/p15v-rehearsal.nix).
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./snapper.nix
  ];

  networking.hostName = "p15v";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  sops.defaultSopsFile = ../../secrets/p15v.yaml;
}
```

`hosts/p15v/nvidia.nix`:
```nix
# Quadro P620 (Pascal) + Intel UHD. Sway renders on the iGPU; the dGPU is for
# `nvidia-offload <app>`. Pascal is dropped by the 590+ drivers and by the
# open kernel module, hence legacy_580 + open = false.
{ config, inputs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.common-gpu-nvidia ];

  services.xserver.videoDrivers = [ "nvidia" ]; # loads the driver, no X needed
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;
    modesetting.enable = true;
    powerManagement.finegrained = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0"; # lspci 00:02.0
      nvidiaBusId = "PCI:1:0:0"; # lspci 01:00.0
    };
  };

  # wlroots splits WLR_DRM_DEVICES on ':', so PCI by-path names can't be used.
  services.udev.extraRules = ''
    KERNEL=="card*", SUBSYSTEM=="drm", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
  '';
  environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/igpu";
  # sway refuses to start while the proprietary module is loaded at all.
  programs.sway.extraOptions = [ "--unsupported-gpu" ];
}
```

`hosts/p15v/wifi.nix`:
```nix
# Wi-Fi profiles with passwords from sops (secrets/p15v.yaml, key wifi-env:
# KEY=value lines). Add a network: a profile here + its variables there.
{ config, ... }:
{
  sops.secrets.wifi-env = { };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets.wifi-env.path ];
    profiles.home = {
      connection = {
        id = "home";
        type = "wifi";
      };
      wifi = {
        ssid = "$HOME_SSID";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$HOME_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };
}
```

`hosts/p15v/default.nix`:
```nix
# ThinkPad P15v Gen 1. nixos-hardware has no profile for it; compose the
# common ones.
{ inputs, ... }:
{
  imports = [
    ./common.nix
    ./hardware.nix
    ./nvidia.nix
    ./wifi.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
}
```

In `flake.nix` `nixosConfigurations`: add `p15v = mkHost [ ./hosts/p15v ];`

- [ ] **Step 4: Run the checks**

Run: `git add hosts flake.nix checks && nix build -L .#checks.x86_64-linux.p15v-layout .#checks.x86_64-linux.p15v-toplevel`
Expected: both PASS. `p15v-toplevel` compiles the NVIDIA module locally (unfree, not cached) — several minutes. If `legacy_580` fails to build against the default kernel, set `boot.kernelPackages = pkgs.linuxPackages_6_12;` (LTS) in `nvidia.nix` with a comment and re-run.

- [ ] **Step 5: Full check + commit**

Run: `nix flake check -L` → all pass.
```bash
git add hosts flake.nix checks
git commit -m "feat(nixos): add the p15v host with disko, NVIDIA and Wi-Fi

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Installer ISO and the install rehearsal

**Files:**
- Create: `hosts/iso/default.nix`, `hosts/iso/rehearsal.nix`, `hosts/p15v-rehearsal.nix`, `scripts/vm-rehearsal`, `secrets/rehearsal/{id_ed25519,id_ed25519.pub,ssh_host_ed25519_key,ssh_host_ed25519_key.pub}`
- Modify: `flake.nix`, `.sops.yaml`, `secrets/vm.yaml` (re-keyed), `mise.toml`

**Interfaces:**
- Consumes: `hosts/p15v/common.nix`, `p15v.disk` (Task 9).
- Produces: `nixosConfigurations.{iso,iso-rehearsal,p15v-rehearsal}`; the ISO has the flake at `/etc/dot` and every flake input source in its store; `mise run vm:rehearsal` exits 0 only after a full install + LUKS unlock + post-boot checks.

- [ ] **Step 1: Throwaway rehearsal keys**

```bash
mkdir -p secrets/rehearsal
ssh-keygen -t ed25519 -N "" -C rehearsal-client -f secrets/rehearsal/id_ed25519
ssh-keygen -t ed25519 -N "" -C root@p15v-rehearsal -f secrets/rehearsal/ssh_host_ed25519_key
REH=$(nix shell --inputs-from . nixpkgs#ssh-to-age -c ssh-to-age < secrets/rehearsal/ssh_host_ed25519_key.pub)
```
In `.sops.yaml` add `  - &rehearsal $REH` under `keys:` (with a comment: throwaway, private half committed in secrets/rehearsal/) and add `- *rehearsal` to the `vm.yaml` rule. Then:
`SOPS_AGE_KEY_FILE=secrets/vm-test.agekey nix shell --inputs-from . nixpkgs#sops -c sops updatekeys -y secrets/vm.yaml`

- [ ] **Step 2: ISO**

`hosts/iso/default.nix`:
```nix
# Installer USB for p15v (and, via rehearsal.nix, the rehearsal VM). Carries
# the flake at /etc/dot and every input's source, so evaluating it needs no
# GitHub access (the private `vn` input included).
{
  lib,
  modulesPath,
  pkgs,
  inputs,
  self,
  ...
}:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../keys/jantrojak.pub ];

  environment.etc."dot".source = self;
  # Sources of every node in flake.lock (inputs of inputs too), so
  # `nix flake metadata --offline /etc/dot` works.
  isoImage.storeContents =
    let
      sources = i: [ i.outPath ] ++ lib.concatMap sources (lib.attrValues (i.inputs or { }));
    in
    lib.unique ([ self.outPath ] ++ lib.concatMap sources (lib.attrValues (removeAttrs inputs [ "self" ])));

  services.pcscd.enable = true; # age-plugin-yubikey to decrypt the host key
  environment.systemPackages = [
    inputs.disko.packages.${pkgs.system}.disko
    pkgs.git
    pkgs.sops
    pkgs.age
    pkgs.age-plugin-yubikey
    pkgs.ssh-to-age
  ];
}
```

`hosts/iso/rehearsal.nix`:
```nix
# Rehearsal-only ISO additions; never on the real USB stick.
{
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../secrets/rehearsal/id_ed25519.pub ];
  boot.kernelParams = [ "console=ttyS0,115200" ];
}
```

`hosts/p15v-rehearsal.nix`:
```nix
# p15v as installed into the rehearsal VM: same disko layout, bootloader,
# initrd, sops mechanism (host key -> age) and modules; minus the real
# hardware, Wi-Fi and secrets. Its sops file is vm.yaml, re-keyed for the
# throwaway rehearsal host key in secrets/rehearsal/.
{ lib, modulesPath, ... }:
{
  imports = [
    ./p15v/common.nix
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  p15v.disk = "/dev/vda";
  sops.defaultSopsFile = lib.mkForce ../secrets/vm.yaml;

  # LUKS prompt and logs on the serial port the rehearsal script talks to.
  boot.kernelParams = [ "console=ttyS0,115200" ];

  services.openssh.openFirewall = lib.mkForce true;
  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../secrets/rehearsal/id_ed25519.pub ];
}
```

In `flake.nix` add a second builder and the hosts:
```nix
      mkIso =
        modules:
        lib.nixosSystem {
          specialArgs = { inherit inputs self; };
          modules = [ { nixpkgs.pkgs = pkgs; } ./hosts/iso ] ++ modules;
        };
```
(in the `let`), and in `nixosConfigurations`:
```nix
        p15v-rehearsal = mkHost [ ./hosts/p15v-rehearsal.nix ];
        iso = mkIso [ ];
        iso-rehearsal = mkIso [ ./hosts/iso/rehearsal.nix ];
```

Run: `git add hosts flake.nix .sops.yaml secrets && nix build -L .#nixosConfigurations.iso-rehearsal.config.system.build.isoImage -o .vm/iso-rehearsal && ls .vm/iso-rehearsal/iso/*.iso`
Expected: one `.iso` file. Also: `nix eval .#nixosConfigurations.iso.config.users.users.root.openssh.authorizedKeys.keyFiles` must NOT mention `rehearsal`.

- [ ] **Step 3: The rehearsal driver**

`scripts/vm-rehearsal`:
```python
#!/usr/bin/env python3
"""Install rehearsal for p15v, end to end, in QEMU.

Boots the rehearsal ISO on an empty disk, runs the same disko + nixos-install
commands doc/nixos-migration.md prescribes for the laptop (against
#p15v-rehearsal), reboots from disk, types the LUKS passphrase on the serial
console and checks the installed system. Exit 0 only if every check passes.
Takes long: the system is built inside the VM, as on the real install.
"""

import shutil
import socket
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
WORK = REPO / ".vm" / "rehearsal"
DISK = WORK / "disk.qcow2"
VARS = WORK / "OVMF_VARS.fd"
SERIAL = WORK / "serial.sock"
CLIENT_KEY = REPO / "secrets/rehearsal/id_ed25519"
HOST_KEY = REPO / "secrets/rehearsal/ssh_host_ed25519_key"
PASSPHRASE = "rehearsal"  # throwaway LUKS passphrase
PORT = "2222"
FLAKE_ON_ISO = "/etc/dot#p15v-rehearsal"


def run(*cmd: str, capture: bool = False) -> str:
    print("+", " ".join(cmd), flush=True)
    res = subprocess.run(cmd, check=True, text=True, capture_output=capture)
    return res.stdout.strip() if capture else ""


def build(installable: str) -> Path:
    return Path(
        run("nix", "build", "--no-link", "--print-out-paths", "--inputs-from", str(REPO), installable, capture=True)
        .splitlines()[0]
    )


def ssh_args() -> list[str]:
    return [
        "ssh", "-p", PORT, "-i", str(CLIENT_KEY),
        "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-o", "LogLevel=ERROR",
        "root@localhost",
    ]


def remote(cmd: str, capture: bool = False) -> str:
    return run(*ssh_args(), cmd, capture=capture)


def poweroff() -> None:
    # the connection drops mid-command; a non-zero ssh exit is expected here
    subprocess.run([*ssh_args(), "poweroff"], capture_output=True)


def wait_ssh(timeout: int) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if subprocess.run([*ssh_args(), "true"], capture_output=True).returncode == 0:
            return
        time.sleep(5)
    sys.exit(f"ssh on port {PORT} not up after {timeout}s")


def qemu(qemu_bin: Path, ovmf: Path, iso: Path | None) -> subprocess.Popen[bytes]:
    args = [
        str(qemu_bin / "bin/qemu-system-x86_64"), "-enable-kvm", "-machine", "q35",
        "-m", "8192", "-smp", "8",
        "-drive", f"if=pflash,format=raw,readonly=on,file={ovmf / 'FV/OVMF_CODE.fd'}",
        "-drive", f"if=pflash,format=raw,file={VARS}",
        "-drive", f"file={DISK},if=virtio,format=qcow2",
        "-nic", f"user,model=virtio-net-pci,hostfwd=tcp::{PORT}-:22",
        "-serial", f"unix:{SERIAL},server,nowait",
        "-display", "none",
    ]
    if iso:
        args += ["-cdrom", str(iso)]
    print("+ qemu", "(with ISO)" if iso else "(from disk)", flush=True)
    return subprocess.Popen(args)


def unlock_luks(timeout: int) -> None:
    deadline = time.time() + timeout
    while True:
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(str(SERIAL))
            break
        except OSError:
            if time.time() > deadline:
                sys.exit("serial console never came up")
            time.sleep(1)
    sock.settimeout(5)
    seen = b""
    while time.time() < deadline:
        try:
            chunk = sock.recv(4096)
        except TimeoutError:
            continue
        seen = (seen + chunk)[-4096:]
        if b"passphrase" in seen.lower():
            time.sleep(1)
            sock.sendall(PASSPHRASE.encode() + b"\n")
            print("LUKS passphrase sent", flush=True)
            sock.close()
            return
    sys.exit("no LUKS passphrase prompt on the serial console")


def main() -> int:
    shutil.rmtree(WORK, ignore_errors=True)
    WORK.mkdir(parents=True)
    qemu_bin = build("nixpkgs#qemu_kvm")
    ovmf = build("nixpkgs#OVMF.fd")
    iso_dir = build(f"{REPO}#nixosConfigurations.iso-rehearsal.config.system.build.isoImage")
    iso = next((iso_dir / "iso").glob("*.iso"))
    shutil.copy(ovmf / "FV/OVMF_VARS.fd", VARS)
    VARS.chmod(0o644)
    run(str(qemu_bin / "bin/qemu-img"), "create", "-f", "qcow2", str(DISK), "64G")

    vm = qemu(qemu_bin, ovmf, iso)
    try:
        wait_ssh(300)
        # Review Focus 5: the ISO must evaluate the flake without GitHub.
        remote("nix flake metadata --offline /etc/dot >/dev/null")
        # --- the same steps as doc/nixos-migration.md, Phase 1 ---
        remote(f"printf %s {PASSPHRASE} > /tmp/secret.key")
        remote(f"disko --mode destroy,format,mount --yes-wipe-all-disks --flake {FLAKE_ON_ISO}")
        remote("install -d -m 755 /mnt/etc/ssh")
        run("scp", "-P", PORT, "-i", str(CLIENT_KEY), "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null", "-o", "LogLevel=ERROR",
            str(HOST_KEY), f"{HOST_KEY}.pub", "root@localhost:/mnt/etc/ssh/")
        remote("chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key")
        remote(f"nixos-install --no-root-passwd --flake {FLAKE_ON_ISO}")
        poweroff()
        vm.wait(timeout=120)
    finally:
        if vm.poll() is None:
            vm.kill()

    vm = qemu(qemu_bin, ovmf, None)
    try:
        unlock_luks(600)
        wait_ssh(600)
        checks = {
            "greetd running": "systemctl is-active greetd.service",
            "sops password decrypted": "test -s /run/secrets-for-users/user-password",
            "/home on @home": "findmnt -no OPTIONS /home | grep -q 'subvol=/@home'",
            "LUKS mapping active": "cryptsetup status cryptroot | grep -q 'is active'",
            "swapfile on": "swapon --show=NAME --noheadings | grep -q /.swapvol/swapfile",
            "snapper timer": "systemctl is-active snapper-timeline.timer",
            "home-manager": "systemctl is-active home-manager-jantrojak.service",
        }
        failed = []
        for name, cmd in checks.items():
            ok = subprocess.run([*ssh_args(), cmd], capture_output=True).returncode == 0
            print(f"{'PASS' if ok else 'FAIL'}  {name}", flush=True)
            if not ok:
                failed.append(name)
        poweroff()
        return 1 if failed else 0
    finally:
        try:
            vm.wait(timeout=60)
        except subprocess.TimeoutExpired:
            vm.kill()


if __name__ == "__main__":
    sys.exit(main())
```

Run: `chmod +x scripts/vm-rehearsal && nix run --inputs-from . nixpkgs#ruff -- check scripts/vm-rehearsal && nix run --inputs-from . nixpkgs#ruff -- format --check scripts/vm-rehearsal`
Expected: clean (run `ruff format scripts/vm-rehearsal` if the format check complains).

Append to `mise.toml`:
```toml
[tasks."vm:rehearsal"]
run = "scripts/vm-rehearsal"
description = "Full p15v install rehearsal in QEMU: ISO -> disko -> nixos-install -> LUKS boot -> checks (slow)"
```

- [ ] **Step 4: Run the rehearsal**

Run: `mise run vm:rehearsal` (run in background; it can take 30–90 min because the system builds inside the VM)
Expected: seven `PASS` lines, exit 0. On a FAIL, reproduce interactively: boot `.vm/rehearsal/disk.qcow2` with the same QEMU command minus `-display none`, look at `journalctl -b`, fix the module, re-run. If the serial prompt never appears, check that `console=ttyS0,115200` is the *last* `console=` in `/proc/cmdline` of the installed system.

- [ ] **Step 5: Commit**

```bash
git add hosts flake.nix .sops.yaml secrets mise.toml scripts/vm-rehearsal
git commit -m "feat(nixos): add the installer ISO and a scripted install rehearsal

The rehearsal runs the exact disko + nixos-install steps of the
migration runbook in QEMU, including LUKS unlock and sops on first boot,
so the wipe of the laptop is not the first time they run.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Migration tooling and runbook

**Files:**
- Create: `scripts/migration-preflight`, `scripts/bootstrap-user`, `ansible/playbook-user.yml`, `doc/nixos-migration.md`
- Modify: `CLAUDE.md`, `doc/README.md`, `doc/architecture.md`, `mise.toml`

**Interfaces:**
- Consumes: ansible roles `vnotes`, `dev-repos`, `mcp` (unchanged, user-level only).
- Produces: `scripts/migration-preflight [DEV_ROOT]` (read-only, exit 0); `scripts/bootstrap-user` (idempotent).

- [ ] **Step 1: Preflight report**

`scripts/migration-preflight`:
```bash
#!/usr/bin/env bash
# Read-only report of everything that must be saved before p15v is wiped.
# Changes nothing. Usage: migration-preflight [DEV_ROOT]   (default ~/dev)
set -euo pipefail

dev_root="${1:-$HOME/dev}"

report_repo() {
  local repo="$1" dirty unpushed stashes
  dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l)
  unpushed=$(git -C "$repo" log --branches --not --remotes --oneline 2>/dev/null | wc -l)
  stashes=$(git -C "$repo" stash list 2>/dev/null | wc -l)
  if (( dirty + unpushed + stashes > 0 )); then
    printf '%-70s dirty=%-4s unpushed=%-4s stashes=%s\n' "$repo" "$dirty" "$unpushed" "$stashes"
  fi
}

echo "== Git repos with uncommitted, unpushed or stashed work"
report_repo "$HOME/.dot"
report_repo "$HOME/ops/vnotes"
while IFS= read -r gitdir; do
  report_repo "${gitdir%/.git}"
done < <(find "$dev_root" -maxdepth 5 -name .git \( -type d -o -type f \) -prune -print 2>/dev/null)

echo
echo "== Data outside the repo (back these up)"
for p in .ssh .gnupg .aws .kube .config/gcloud .config/Claude-personal .config/Claude-work \
          .claude .claude-personal snap/firefox ops/vnotes .config/Bitwarden .local/share/TelegramDesktop \
          .config/Signal .config/Slack .config/obsidian; do
  if [[ -e "$HOME/$p" ]]; then du -sh "$HOME/$p" 2>/dev/null; fi
done

echo
echo "== Total size of \$HOME"
du -sh "$HOME" 2>/dev/null || true
```

Run: `chmod +x scripts/migration-preflight && nix run nixpkgs#shellcheck -- scripts/migration-preflight && scripts/migration-preflight | head -40`
Expected: no shellcheck findings; a report (content depends on the machine); `git -C ~/.dot status` unchanged by the run.

- [ ] **Step 2: Post-install user setup through the existing roles**

`ansible/playbook-user.yml`:
```yaml
---
# User-level setup only (git clones, MCP servers) — safe on NixOS, where the
# system roles are replaced by nixos/. Run via scripts/bootstrap-user.
- name: User data (repos, vnotes, MCP)
  hosts: [all, localhost]
  become: false
  roles:
    - role: vnotes
      tags: [vnotes]
    - role: dev-repos
      tags: [dev-repos]
    - mcp
```

`scripts/bootstrap-user`:
```bash
#!/usr/bin/env bash
# First login on NixOS: clone repos and register MCP servers with the same
# ansible roles Ubuntu uses. Idempotent; re-run any time.
set -euo pipefail
cd "$(dirname "$0")/../ansible"
exec nix shell --inputs-from .. nixpkgs#ansible -c \
  ansible-playbook -i localhost, -c local playbook-user.yml "$@"
```

Run: `chmod +x scripts/bootstrap-user && nix run nixpkgs#shellcheck -- scripts/bootstrap-user && scripts/bootstrap-user --check`
Expected: ansible runs in check mode on the Ubuntu host and reports `ok`/`changed` counts without failures (it changes nothing in `--check`).

Add to `mise.toml`:
```toml
[tasks."migration:preflight"]
run = "scripts/migration-preflight"
description = "Read-only report of unpushed work and data to back up before the wipe"
```

- [ ] **Step 3: Runbook — `doc/nixos-migration.md`**

Prose as single long lines. Required content, in this order:

1. **Gate** — all must be true: `nix flake check -L` green; `mise run vm:rehearsal` exit 0 on the current commit; `mise run migration:preflight` shows nothing unexpected; restic backup done and a sample restore verified; the backup age key from Task 8 is retrievable from Bitwarden.
2. **Phase 0 — backup** —
    ```bash
    nix shell nixpkgs#restic -c restic -r /run/media/$USER/<disk>/p15v init
    nix shell nixpkgs#restic -c restic -r /run/media/$USER/<disk>/p15v backup ~ --exclude ~/.cache --exclude ~/.local/share/Trash --exclude ~/snap/*/common/.cache
    nix shell nixpkgs#restic -c restic -r /run/media/$USER/<disk>/p15v restore latest --target /tmp/restore-test --include ~/.ssh   # then diff -r ~/.ssh /tmp/restore-test$HOME/.ssh
    nix build ~/.dot#nixosConfigurations.iso.config.system.build.isoImage -o /tmp/iso
    sudo dd if=$(ls /tmp/iso/iso/*.iso) of=/dev/sdX bs=4M status=progress conv=fsync
    ```
3. **Phase 1 — install (same commands as `scripts/vm-rehearsal`)** — boot the USB (F12), `nmcli device wifi connect <ssid> --ask`, then:
    ```bash
    sudo -i
    nix flake metadata --offline /etc/dot          # must succeed
    read -rs PASS; printf %s "$PASS" > /tmp/secret.key   # LUKS passphrase: ASCII letters/digits only (us keymap in initrd)
    disko --mode destroy,format,mount --yes-wipe-all-disks --flake /etc/dot#p15v
    install -d -m 755 /mnt/etc/ssh
    sops -d --input-type binary --output-type binary /etc/dot/secrets/p15v-ssh-host-key.enc > /mnt/etc/ssh/ssh_host_ed25519_key   # YubiKey touch
    cp /etc/dot/secrets/p15v-ssh-host-key.pub /mnt/etc/ssh/ssh_host_ed25519_key.pub
    chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
    nixos-install --no-root-passwd --flake /etc/dot#p15v
    reboot
    ```
    Note: `sops` on the ISO needs the YubiKey identity: `age-plugin-yubikey --identity > /tmp/id.txt; export SOPS_AGE_KEY_FILE=/tmp/id.txt`.
4. **Phase 2 — hardware checklist** (checkbox list; each with the command that proves it): sway on iGPU (`cat /proc/$(pgrep -x sway)/environ | tr '\0' '\n' | grep WLR_DRM`), `nvidia-offload glxinfo | grep NVIDIA`, external monitor on DP-1 (if black: the port is wired to the dGPU → `WLR_DRM_DEVICES=/dev/dri/igpu:/dev/dri/card1` in `hosts/p15v/nvidia.nix`), Wi-Fi (`nmcli c`), Bluetooth (`bluetoothctl show`), audio (`wpctl status`), brightness and media keys, suspend on lid close on battery and none on AC, kanshi `docked`/`laptop` switch, YubiKey (`ykman info`, `ssh -T git@github.com`, `gpg --card-status`), `fwupdmgr get-devices`, snapper (`snapper -c home list` after an hour).
5. **Phase 3 — restore** — clone `~/.dot` (`git clone git@github.com:zezav-cz/.dot.git ~/.dot`), `sudo nixos-rebuild switch --flake ~/.dot#p15v` (now links point at the real checkout), restic restore of the listed directories, `~/.dot/scripts/bootstrap-user`, Firefox profile from `~/snap/firefox/common/.mozilla` → `~/.mozilla`.
6. **Rollback** — config regression: pick the previous generation in systemd-boot; broken install: Ubuntu ISO + restic restore.
7. **Afterwards (separate task)** — remove `ansible/`, `installer/`, `install.py`, `homeConfigurations`, `home/generic-linux.nix`, `checks.dotfiles-parity`.

- [ ] **Step 4: Repo docs**

- `CLAUDE.md`: in "What This Is" add one sentence that the repo also defines the NixOS system for p15v (`flake.nix`, `nixos/`, `hosts/`, `home/`), pointing to `doc/nixos.md`; in "Dev tooling" add the `nix:check`, `nix:fmt`, `vm`, `vm:reset`, `vm:test`, `vm:rehearsal`, `migration:preflight` rows to the mise table; in "Architecture notes" add: stow lists are mirrored in `home/dotfiles-packages.nix` (checked by `checks.dotfiles-parity`), and stowed configs must not use distro-specific absolute paths (`checks.portable-paths`).
- `doc/README.md`: link `doc/nixos.md` and `doc/nixos-migration.md`.
- `doc/architecture.md`: add a short "NixOS" section pointing to `doc/nixos.md`.

- [ ] **Step 5: Final verification**

Run: `nix flake check -L && mise run check && scripts/check-portable-paths stow`
Expected: all green.

- [ ] **Step 6: Commit and push**

```bash
git add scripts/migration-preflight scripts/bootstrap-user ansible/playbook-user.yml doc/nixos-migration.md mise.toml
git add -p CLAUDE.md doc/README.md doc/architecture.md
git commit -m "docs(nixos): add the migration runbook, preflight and bootstrap

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push -u origin ubuntu
```

---

## Deviations from the spec (decided while planning, reflected in the spec)

- `/home` snapshots need `/home/.snapshots`, so the subvolume is `@home-snapshots` → `/home/.snapshots` instead of `@snapshots` → `/.snapshots`.
- stylix themes only the console and fontconfig: the existing light/dark toggle owns GTK/Qt/foot/nvim/k9s, and stylix on those would fight it.
- The rehearsal runs the runbook's own `disko` + `nixos-install` commands from the ISO instead of nixos-anywhere, so rehearsal and real install are the same procedure (the laptop has no second machine to run nixos-anywhere from).
- The interactive VM mounts the repo at `/mnt/dot` and links `~/.dot` to it (a 9p mount inside `~` would create `~` root-owned before the user exists).
- `ZSH`/`ZSH_CUSTOM` are set by NixOS (`nixos/shell.nix`), not home-manager: the stowed `.zshrc` does not source home-manager's session variables.
- home-manager runs with `useUserPackages = false` so packages stay in `~/.nix-profile` as on Ubuntu.
- sway needs `--unsupported-gpu` while the NVIDIA module is loaded; the iGPU is selected with a udev symlink because wlroots splits `WLR_DRM_DEVICES` on `:`.
- The ISO carries every flake input's source so the private `vn` input never has to be fetched during install.
