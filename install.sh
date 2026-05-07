#!/usr/bin/env bash
# install.sh — idempotent installer for personal dotfiles.
#
# Re-run safely. Symlinks files into $HOME, backing up any pre-existing
# regular files to ~/.dotfiles-backup/<timestamp>/. Adds [include] entries
# to ~/.gitconfig instead of overwriting it (machine-local config like
# user.email and URL rewrites stays put).
#
# When used with [Coder](https://coder.com/) workspaces, this runs once per
# workspace start (and on Refresh Dotfiles), so every step here MUST be safe
# to repeat. See: https://coder.com/docs/user-guides/workspace-dotfiles

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[36m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[dotfiles]\033[0m %s\n' "$*" >&2; }

# link $1 -> $2, backing up $2 if it's a real file.
link() {
    local src="$1" dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"
    mkdir -p "$dst_dir"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        return 0  # already linked correctly
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR$(dirname "$dst")"
        mv "$dst" "$BACKUP_DIR$dst"
        log "backed up $dst -> $BACKUP_DIR$dst"
    fi

    ln -s "$src" "$dst"
    log "linked $dst -> $src"
}

# add an [include]/path entry to ~/.gitconfig if not already present.
git_include() {
    local path="$1"
    if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$path"; then
        return 0
    fi
    git config --global --add include.path "$path"
    log "added [include]path=$path to ~/.gitconfig"
}

# set a global git config key (idempotent).
git_set() {
    local key="$1" value="$2"
    if [ "$(git config --global --get "$key" 2>/dev/null || true)" = "$value" ]; then
        return 0
    fi
    git config --global "$key" "$value"
    log "set git --global $key=$value"
}

# ---- git ----
log "configuring git"
git_include "$DOTFILES_DIR/git/gitconfig"
git_set core.excludesFile "$DOTFILES_DIR/git/gitignore_global"

# ---- vim ----
log "configuring vim"
link "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"

# bootstrap vim-plug if missing
VIM_PLUG="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$VIM_PLUG" ]; then
    log "installing vim-plug"
    curl -fLo "$VIM_PLUG" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# install vim plugins (silent + quit-if-no-error)
if command -v vim >/dev/null 2>&1; then
    vim +PlugInstall +qall >/dev/null 2>&1 || warn "vim +PlugInstall returned non-zero (run manually if needed)"
fi

# ---- tmux ----
log "configuring tmux"
link "$DOTFILES_DIR/tmux/tmux.conf"        "$HOME/.tmux.conf"
link "$DOTFILES_DIR/tmux/tmux.remote.conf" "$HOME/.tmux/tmux.remote.conf"
link "$DOTFILES_DIR/tmux/yank.sh"          "$HOME/.tmux/yank.sh"
link "$DOTFILES_DIR/tmux/renew_env.sh"     "$HOME/.tmux/renew_env.sh"

# bootstrap tmux plugin manager (TPM)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    log "installing tpm"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# auto-install tmux plugins if a tmux server is running
if command -v tmux >/dev/null 2>&1 && [ -x "$TPM_DIR/bin/install_plugins" ]; then
    "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || warn "tpm install_plugins returned non-zero (run prefix+I inside tmux to retry)"
fi

if [ -d "$BACKUP_DIR" ]; then
    log "originals backed up at $BACKUP_DIR"
fi

log "done"
