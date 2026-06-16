#!/usr/bin/env bash
# =============================================================================
# dotfiles installer — https://github.com/amuraru/dotfiles
#
#   git clone https://github.com/amuraru/dotfiles ~/dotfiles
#   ~/dotfiles/install.sh
#
# Idempotent: safe to re-run. Existing real files are backed up to *.bak
# before being replaced with symlinks into this repo.
# =============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Homebrew + CLI packages the dotfiles depend on
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available for the rest of this script (Apple Silicon path)
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

info "Installing CLI tools referenced by the shell config"
brew install \
  fzf \
  fd \
  ripgrep \
  the_silver_searcher \
  ydiff \
  git \
  git-delta \
  direnv \
  z \
  kubernetes-cli \
  krew \
  coursier

# Optional extras (uncomment as needed):
#   gitstatus is sourced by zshrc but powerlevel10k bundles its own gitstatusd:
# brew install romkatv/gitstatus/gitstatus
#   Build libs referenced in PATH (only if you compile against them):
# brew install make curl openssl@1.1 libpq qt@5

info "Installing GUI apps (casks)"
brew install --cask ghostty
brew install --cask visual-studio-code   # for `code` (git difftool / fzf ctrl-v)

# ---------------------------------------------------------------------------
# 2. oh-my-zsh
# ---------------------------------------------------------------------------
if [ ! -d "$ZSH_DIR" ]; then
  info "Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  info "oh-my-zsh already present"
fi

# ---------------------------------------------------------------------------
# 3. Custom theme + plugins (clone if missing)
# ---------------------------------------------------------------------------
clone_if_missing() {  # $1=repo url  $2=dest dir
  if [ -d "$2/.git" ]; then
    info "$(basename "$2") already cloned"
  else
    info "Cloning $(basename "$2")"
    git clone --depth=1 "$1" "$2"
  fi
}
clone_if_missing https://github.com/romkatv/powerlevel10k.git        "$ZSH_CUSTOM/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ---------------------------------------------------------------------------
# 4. MesloLGS NF font (required for powerlevel10k glyphs) — macOS only
# ---------------------------------------------------------------------------
if [[ "$(uname)" == "Darwin" ]]; then
  FONT_DIR="$HOME/Library/Fonts"
  base="https://github.com/romkatv/powerlevel10k-media/raw/master"
  for f in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" \
           "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
    if [ -f "$FONT_DIR/$f" ]; then
      info "Font present: $f"
    else
      info "Installing font: $f"
      curl -fsSL "$base/${f// /%20}" -o "$FONT_DIR/$f"
    fi
  done
else
  warn "Non-macOS: install MesloLGS NF manually (see powerlevel10k docs)."
fi

# ---------------------------------------------------------------------------
# 5. Symlink dotfiles (back up existing real files first)
# ---------------------------------------------------------------------------
link() {  # $1=source in repo  $2=target in $HOME
  local src="$DOTFILES/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    warn "Backing up existing $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -s "$src" "$dst"
  info "Linked $dst -> $src"
}
link zshrc          "$HOME/.zshrc"
link p10k.zsh       "$HOME/.p10k.zsh"
link gitconfig      "$HOME/.gitconfig"
link ghostty/config "$HOME/.config/ghostty/config"

# ---------------------------------------------------------------------------
# 6. Seed local secrets file (never overwrites an existing one)
# ---------------------------------------------------------------------------
# (fzf key bindings/completion are loaded directly by zshrc via `fzf --zsh` —
#  no generated ~/.fzf.zsh needed.)
if [ ! -f "$HOME/.zshrc.local" ]; then
  cp "$DOTFILES/zshrc.local.example" "$HOME/.zshrc.local"
  chmod 600 "$HOME/.zshrc.local"
  warn "Created ~/.zshrc.local from template — edit it and add your secrets."
else
  info "~/.zshrc.local already exists (left untouched)"
fi

info "Done. Open a new terminal or run: exec zsh"
