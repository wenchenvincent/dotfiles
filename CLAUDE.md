# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal dotfiles repo bootstrapped from [dotfiles_template](https://github.com/anishathalye/dotfiles_template), driven by [Dotbot](https://github.com/anishathalye/dotbot). There is no build system, no application code, and no test suite of our own — the only "code" is declarative config plus the vendored Dotbot submodule.

## Commands

```bash
./install                # apply install.conf.yaml (idempotent; safe to re-run)
./install.ps1            # Windows/PowerShell equivalent
git submodule update --init --remote   # upgrade dotbot to latest upstream
```

`./install` is the single entry point: it syncs/inits the `dotbot` submodule, then runs `dotbot -d <repo> -c install.conf.yaml`. Extra args are passed through to dotbot (e.g. `./install -v`).

Re-run `./install` after editing `install.conf.yaml`. Editing an already-linked file (e.g. `bash/bash_aliases`) needs no re-install — the target is a symlink into this repo, so changes take effect immediately.

## Architecture

`install.conf.yaml` is the source of truth for what gets deployed. Everything is a **symlink from `$HOME` into this repo**, so the repo path is live — never copy files into `$HOME`.

Current mapping:

| Repo path | Linked to |
|---|---|
| `bash/bash_aliases` | `~/.bash_aliases` |
| `git/gitconfig` | `~/.gitconfig` |
| `vim/vimrc` | `~/.vimrc` |
| `vim/vim/` | `~/.vim/` (whole directory) |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` (user-level memory) |
| `claude/commands/` | `~/.claude/commands/` |

The config also runs `clean: ["~"]` (removes dead symlinks in `$HOME`), `create: [~/dockerx]`, and a `shell` block that updates submodules and then bootstraps the private knowledge repo (`~/claude_stuff`): deploy key, clone, claude-mem, sync cron. Every knowledge step is `|| true` — a machine whose deploy key is not registered yet finishes on the next `./install`, so a half-configured host never fails the install.

Adding a new dotfile means: create the file in a topic directory, add a `~/target: path:` entry under `link:`, and re-run `./install`.

### Cross-cutting coupling to be aware of

- **`bash/bash_aliases` mounts the dotfiles into containers.** The `drun` / `ndrun` / `prun` / `drun_nogpu` aliases bind-mount `~/.gitconfig`, `~/.vimrc`, `~/.vim`, and `~/.claude/settings.json` into the container. Because those `$HOME` paths are symlinks into this repo, the mounts resolve through them. When you add a config that should also exist inside containers, add both the `link:` entry *and* a `-v` flag to every alias (they are near-duplicates that must stay in sync — the variants differ only in GPU/runtime flags: `drun` = ROCm devices, `ndrun` = `--gpus all`, `prun` = podman, `drun_nogpu` = no devices).
- **`~/.vim` is a linked directory, so vim writes into the repo.** vim-plug lives at `vim/vim/autoload/plug.vim` (vendored, not a submodule) and anything vim generates at runtime — `.netrwhist`, `plugged/` after `:PlugInstall` — lands in the working tree as untracked noise. Don't commit that churn; only `plug.vim` and `vimrc` are tracked.
- **`git/gitconfig` keeps machine-specific settings out of the repo** via `[include] path = ~/.gitconfig.local`. Git silently ignores an `include.path` that doesn't exist, so the tracked file stays portable: on this laptop `~/.gitconfig.local` sets `http.sslCAInfo = /home/wenchen2/.github-cert.pem` (Zscaler TLS interception); on a machine without that file, git just uses its default CA store. The include is last, so it also wins over anything above it. Anything host-specific belongs there, never in `git/gitconfig`. Note the `*run` aliases mount `~/.gitconfig` but *not* `~/.gitconfig.local` or the cert, so container git falls back to the image's CA store.

### `dotbot/`

Vendored upstream submodule (with its own `lib/pyyaml` sub-submodule). Treat as read-only third-party code — do not edit or "fix" it, and ignore its tests/`setup.py` when reasoning about this repo. Its plugins (`link`, `clean`, `create`, `shell`) define the directives available in `install.conf.yaml`.

### Claude Code settings

`claude/settings.json` is the *deployed user-level* config (no `deny` rules; asks on `rm` and `git push`; enables the `superpowers`, `ponytail`, and `claude-mem` plugins; `remoteControlAtStartup` starts the Remote Control bridge in every session, so sessions are drivable from claude.ai/code without `--rc`). A plugin id is `<plugin>@<marketplace>`, and the marketplace half is the `name` field inside that repo's `.claude-plugin/marketplace.json` — *not* the repo name (`thedotmack/claude-mem` publishes a marketplace named `thedotmack`). Only third-party marketplaces need an `extraKnownMarketplaces` entry; `claude-plugins-official` is known by default, which is why superpowers is sourced from there. Note that ponytail and claude-mem both ship Node lifecycle hooks, and claude-mem's `engines` declares **both** `node >=20.12` (newer than Ubuntu 24.04's apt) *and* `bun >=1.0` — its hooks are `node scripts/bun-runner.js …`, a launcher whose only job is to find a `bun` binary and re-exec the worker under it (Bun has been claude-mem's runtime since v7.1.0, 2025-12-13, which moved it to `bun:sqlite`). So the `SessionStart` hook installs both: Node 22 into `/usr/local` when writable (the container case, running as root) else `~/.local`, then `npm i -g bun` symlinked into that same `bin/`. The Node half guards on **major version < 18**, not on `command -v node` — guarding on presence was a bug: a host whose distro `node` is ancient (v12 on Ubuntu 22.04, say) kept it, so the hook no-opped and claude-mem's MCP server died parsing `??` (`CONNECTION_CLOSED`). Whichever prefix it picks must be ahead of `/usr/bin` on `PATH`, or the install lands but nothing uses it. Each half is skipped when already satisfied, and it exits 0 on every failure path so a bad network can never block session start.

`env.NODE_EXTRA_CA_CERTS` points at the Debian CA bundle because this host sits behind Zscaler TLS interception: the Zscaler root is in the system store but *not* in Node's bundled root list, so without it `npm i -g bun` and claude-mem's own `bun install` both die with `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` (same reason `git/gitconfig` sets `http.sslCAInfo`). Non-Debian hosts just get a warning from Node about the missing file. Those two `ask` rules do **not** prompt under `--dangerously-skip-permissions` — an earlier note here claimed the opposite, and it is wrong for 2.1.322. Retested directly: with `Bash(rm:*)` in `permissions.ask` and the session in bypass mode, a bare `rm` ran unprompted. The binary agrees: the mode resolver maps `bypassPermissions` straight to `allow`, and *"'bypassPermissions' auto-approves every tool call (except explicit deny rules) before the callback is consulted."* So `ask` rules are a guardrail for `default`/`acceptEdits` sessions only. To keep one that survives bypass, use `permissions.deny` or a `PreToolUse` hook — the binary's own advice is *"To gate every tool call, use a PreToolUse hook instead."* `.claude/settings.local.json` is this repo's own project-local override and is a different file with a different purpose — don't conflate them. Validate before committing: `python3 -m json.tool claude/settings.json`.
