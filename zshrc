# =============================================================================
# ZSH CONFIGURATION FILE
# Managed in https://github.com/amuraru/dotfiles
#
# Machine-specific config and ALL secrets live in ~/.zshrc.local (git-ignored).
# Copy zshrc.local.example -> ~/.zshrc.local and fill it in. See README.md.
# =============================================================================

# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("$HOME/.oh-my-zsh/custom/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

# =============================================================================
# OH-MY-ZSH CONFIGURATION
# =============================================================================

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# NOTE: zsh-syntax-highlighting MUST be last (it wraps all ZLE widgets).
plugins=(
  git
  kube-ps1
  zsh-autosuggestions
  kubectl
  zsh-syntax-highlighting
)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh
PROMPT='$(kube_ps1) '$PROMPT

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Language and locale
export LANG=en_US.UTF-8

# Java
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home/
export PATH=$JAVA_HOME/bin:$PATH

# Go
export PATH=$HOME/go/bin:$PATH
command -v go >/dev/null 2>&1 && export GOROOT=$(go env GOROOT)
export GO111MODULE=on
export GOPATH=$HOME/go

# Python/Conda
export PATH="$HOME/miniconda/bin:$PATH"

# Node.js/Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"

# =============================================================================
# PATH CONFIGURATION
# =============================================================================

# Core system paths
export PATH=$HOME/bin:$PATH
export PATH=${KREW_ROOT:-$HOME/.krew}/bin:$PATH

# Homebrew paths (guarded; only prepend dirs that exist)
for _p in \
  "/opt/homebrew/opt/curl/bin" \
  "/opt/homebrew/opt/libpq/bin" \
  "/usr/local/opt/curl/bin" \
  "/usr/local/opt/openssl@1.1/bin" \
  "/usr/local/opt/qt@5/bin" \
  "/usr/local/bin"; do
  [ -d "$_p" ] && export PATH="$_p:$PATH"
done
unset _p
command -v brew >/dev/null 2>&1 && export PATH="$(brew --prefix)/opt/make/libexec/gnubin:$PATH"

# Development tools
export PATH="$HOME/.crc/bin/oc:$PATH"
export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"

# =============================================================================
# DEVELOPMENT ENVIRONMENT
# =============================================================================

# Kubernetes (override with a specific kubeconfig in ~/.zshrc.local if needed)
export KUBECONFIG=~/.kube/config

# Maven
export MVN_REPO_HOME=~/.m2/repository

# =============================================================================
# FZF CONFIGURATION
# =============================================================================

# FZF default options
export FZF_DEFAULT_OPTS="
--layout=reverse
--info=inline
--height=80%
--multi
--preview-window=:hidden
--color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
--prompt='∼ ' --pointer='▶' --marker='✓'
--bind '?:toggle-preview'
--bind 'ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
--bind 'ctrl-e:execute(vim {} < /dev/tty > /dev/tty)'
--bind 'ctrl-v:execute(code {+})'
"

# FZF commands
export FZF_DEFAULT_COMMAND="fd"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d"

# =============================================================================
# HISTORY CONFIGURATION
# =============================================================================

# History settings
unsetopt share_history
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# History file configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

# =============================================================================
# FUNCTIONS
# =============================================================================

# Directory diff function
function dirdiff() {
  diff -ur $1 $2 | ydiff -s --wrap
}

# Find in file function
fif() {
  if [ ! "$#" -gt 0 ]; then
    echo "Need a string to search for!";
    return 1;
  fi
  rg --files-with-matches --no-messages "$1" | fzf $FZF_PREVIEW_WINDOW --preview "rg --ignore-case --pretty --context 10 '$1' {}"
}

# Ag replace function
function agr {
  ag -0 -l "$1" | xargs -0 perl -pi.bak -e "s/$1/$2/g";
}

# Paste performance fix
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}

# Update oh-my-zsh core AND all custom (git-cloned) plugins/themes
omzup() {
  omz update --unattended
  local CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  for d in "$CUSTOM"/plugins/*/ "$CUSTOM"/themes/*/; do
    [ -d "$d/.git" ] && { echo "==> ${d:t}"; git -C "$d" pull --ff-only; }
  done
}

# =============================================================================
# ALIASES
# =============================================================================

# General aliases
alias find='noglob find'
[ -d "/Applications/Meld.app" ] && alias meld=/Applications/Meld.app/Contents/MacOS/Meld
alias excel='open -a /Applications/Microsoft\ Excel.app'
alias helm2='docker run -e KUBECONFIG="/root/.kube/kind" -ti --rm -v $(pwd):/apps -v ~/.kube:/root/.kube -v ~/.helm2:/root/.helm alpine/helm:2.16.9'

# Kubernetes utility: show resource allocation per node
alias kutil='kubectl get nodes | grep node | awk '\''{print $1}'\'' | xargs -I {} sh -c '\''echo {} ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo '\'''

# =============================================================================
# COMPLETION CONFIGURATION
# =============================================================================

# Ensure completion is on
autoload -Uz compinit
compinit

# FZF completion functions
_fzf_compgen_path() {
    fd . "$1"
}
_fzf_compgen_dir() {
    fd --type d . "$1"
}

# Completion for: env VAR=... → complete filenames after '='
_env_files() {
  if compset -P '*='; then
    _files
  else
    _values 'environment variable' INPUT_FILE OTHER_VAR
  fi
}
compdef _env_files env

# =============================================================================
# EXTERNAL TOOL INITIALIZATION (all guarded so missing tools don't error)
# =============================================================================

# Gitstatus
[ -f /opt/homebrew/opt/gitstatus/gitstatus.prompt.zsh ] && source /opt/homebrew/opt/gitstatus/gitstatus.prompt.zsh

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Jabba (Java version manager)
[ -s "$HOME/.jabba/jabba.sh" ] && source "$HOME/.jabba/jabba.sh"

# Travis CI
[ -f "$HOME/.travis/travis.sh" ] && source "$HOME/.travis/travis.sh"

# Direnv
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# SDKMAN (must be at the end)
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Conda initialization
if [ -x "$HOME/miniconda/bin/conda" ]; then
  __conda_setup="$("$HOME/miniconda/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  elif [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
      . "$HOME/miniconda/etc/profile.d/conda.sh"
  else
      export PATH="$HOME/miniconda/bin:$PATH"
  fi
  unset __conda_setup
fi

# Z (directory jumping)
[ -f /opt/homebrew/etc/profile.d/z.sh ] && source /opt/homebrew/etc/profile.d/z.sh

# Docker CLI completions
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

# =============================================================================
# PROMPT CONFIGURATION
# =============================================================================

# Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# =============================================================================
# ZSH SETTINGS
# =============================================================================

# Paste performance fix
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Additional completion paths
[ -d /usr/local/share/zsh/site-functions ] && fpath+=/usr/local/share/zsh/site-functions
[ -d /opt/homebrew/share/zsh/site-functions ] && fpath+=/opt/homebrew/share/zsh/site-functions
autoload -Uz compinit && compinit

# pipx
export PATH="$PATH:$HOME/.local/bin"

# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# fabro
export PATH="$HOME/.fabro/bin:$PATH"

# =============================================================================
# LOCAL / MACHINE-SPECIFIC OVERRIDES & SECRETS (git-ignored)
# Put Artifactory/Vault/work env, tokens, and anything private here.
# =============================================================================
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
