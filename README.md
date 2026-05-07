# dotfiles

Personal dotfiles. Designed to drop into [Coder](https://coder.com/) workspaces (via the [workspace dotfiles flow](https://coder.com/docs/user-guides/workspace-dotfiles)) and laptops alike.

## What's in here

| Path | What |
| --- | --- |
| [`git/gitconfig`](git/gitconfig) | Portable git aliases (`cm`, `lol`, `mine`, `weekly`, `recent`, …) and sensible defaults (`fetch.prune`, `pull.ff=only`, `push.autoSetupRemote`, `rerere`, …). Pulled into `~/.gitconfig` via `[include]`, so machine-local config (user.email, URL rewrites, signing) stays untouched. |
| [`git/gitignore_global`](git/gitignore_global) | OS / editor / language clutter (`.DS_Store`, `*.swp`, `__pycache__`, `node_modules`, …). |
| [`vim/vimrc`](vim/vimrc) | Minimal vim config with [vim-plug](https://github.com/junegunn/vim-plug) (replaces the deprecated Vundle). Sensible search defaults, leader=`,`, vim-airline. |
| [`tmux/tmux.conf`](tmux/tmux.conf) | Tmux config: prefix `C-a`, mouse on, `\|` / `_` splits, vi-mode copy, themed status, F12 nested-session toggle. Plugins via [TPM](https://github.com/tmux-plugins/tpm). |
| [`tmux/tmux.remote.conf`](tmux/tmux.remote.conf), [`yank.sh`](tmux/yank.sh), [`renew_env.sh`](tmux/renew_env.sh) | Helper scripts referenced from `tmux.conf`. |
| [`install.sh`](install.sh) | Idempotent installer. Symlinks files into `$HOME`, backs up originals to `~/.dotfiles-backup/<timestamp>/`, bootstraps vim-plug + TPM. Safe to re-run. |

## Quick start

### Coder workspace

The repo is named `dotfiles` and is public, so the default URL works as-is. Enable **Dotfiles Customization** when creating the workspace and Coder will clone + run `install.sh` automatically. On every workspace restart Coder runs `git pull --ff-only` and re-runs the script — `install.sh` is idempotent, so this is safe.

To re-apply without restarting: hit **Refresh Dotfiles** on the workspace page.

### Local machine

```bash
git clone https://github.com/ronakts/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Re-run the installer any time you pull updates:

```bash
cd ~/dotfiles && git pull && ./install.sh
```

## What `install.sh` does

1. **git** — adds `[include] path = …/git/gitconfig` and sets `core.excludesFile = …/git/gitignore_global` on `~/.gitconfig`. Doesn't replace your existing `~/.gitconfig` (so machine-local user.email, URL rewrites, etc. survive).
2. **vim** — symlinks `~/.vimrc` to this repo's `vim/vimrc`, bootstraps [vim-plug](https://github.com/junegunn/vim-plug) into `~/.vim/autoload/`, runs `:PlugInstall`.
3. **tmux** — symlinks `~/.tmux.conf` and the helper files in `~/.tmux/`, bootstraps [TPM](https://github.com/tmux-plugins/tpm) into `~/.tmux/plugins/tpm`, auto-runs `install_plugins`.
4. **backup** — any pre-existing real files (not symlinks) at the link targets get moved to `~/.dotfiles-backup/<timestamp>/<original-path>` before linking. Symlinks already pointing at the right place are left alone.

## Notes

- **Don't put secrets here.** Public repo, plus Coder clones it onto the workspace.
- **Shell config (`~/.zshrc`, `~/.bashrc`) is intentionally not managed.** Other tooling on managed environments often writes to those files; wholesale replacement would clobber them. If I want shell aliases here later, the right pattern is to *append* a single `source ~/dotfiles/shell/aliases.sh` line in `install.sh`, gated by a marker comment so it stays idempotent.
