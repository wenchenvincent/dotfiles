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

The config also runs `clean: ["~"]` (removes dead symlinks in `$HOME`), `create: [~/dockerx]`, and a `shell` step that recursively updates submodules.

Adding a new dotfile means: create the file in a topic directory, add a `~/target: path:` entry under `link:`, and re-run `./install`.

### Cross-cutting coupling to be aware of

- **`bash/bash_aliases` mounts the dotfiles into containers.** The `drun` / `ndrun` / `prun` / `drun_nogpu` aliases bind-mount `~/.gitconfig`, `~/.vimrc`, `~/.vim`, and `~/.claude/settings.json` into the container. Because those `$HOME` paths are symlinks into this repo, the mounts resolve through them. When you add a config that should also exist inside containers, add both the `link:` entry *and* a `-v` flag to every alias (they are near-duplicates that must stay in sync — the variants differ only in GPU/runtime flags: `drun` = ROCm devices, `ndrun` = `--gpus all`, `prun` = podman, `drun_nogpu` = no devices).
- **`~/.vim` is a linked directory, so vim writes into the repo.** vim-plug lives at `vim/vim/autoload/plug.vim` (vendored, not a submodule) and anything vim generates at runtime — `.netrwhist`, `plugged/` after `:PlugInstall` — lands in the working tree as untracked noise. Don't commit that churn; only `plug.vim` and `vimrc` are tracked.
- **`git/gitconfig` contains machine-specific absolute paths** (`http.sslCAInfo` points at `/home/wenchen2/.github-cert.pem`). It is not portable; changes here affect the host and every container using the `*run` aliases.

### `dotbot/`

Vendored upstream submodule (with its own `lib/pyyaml` sub-submodule). Treat as read-only third-party code — do not edit or "fix" it, and ignore its tests/`setup.py` when reasoning about this repo. Its plugins (`link`, `clean`, `create`, `shell`) define the directives available in `install.conf.yaml`.

### Claude Code settings

`claude/settings.json` is the *deployed user-level* config (denies `curl`/`wget`/`rm -rf`/`WebFetch` and secret-file reads; asks on `git push`, `docker`, `kubectl`; enables the `superpowers`, `ponytail`, and `claude-mem` plugins). A plugin id is `<plugin>@<marketplace>`, and the marketplace half is the `name` field inside that repo's `.claude-plugin/marketplace.json` — *not* the repo name (`thedotmack/claude-mem` publishes a marketplace named `thedotmack`). Only third-party marketplaces need an `extraKnownMarketplaces` entry; `claude-plugins-official` is known by default, which is why superpowers is sourced from there. Note that ponytail and claude-mem both ship Node lifecycle hooks and this host has no `node` on PATH, so they load but stay inert. `.claude/settings.local.json` is this repo's own project-local override and is a different file with a different purpose — don't conflate them. Validate before committing: `python3 -m json.tool claude/settings.json`.
