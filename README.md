# dotfiles

Personal macOS dev environment: **zsh + oh-my-zsh + powerlevel10k**, Ghostty, git.

## What's here

| File | Symlinked to | Purpose |
|------|--------------|---------|
| `zshrc` | `~/.zshrc` | Shell config (oh-my-zsh, plugins, PATH, fzf, history, functions) |
| `p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt theme config |
| `gitconfig` | `~/.gitconfig` | Git aliases, delta, user settings |
| `ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal (sets `MesloLGS NF` font) |
| `zshrc.local.example` | — | Template for **secrets / machine-specific** env (copy to `~/.zshrc.local`) |
| `install.sh` | — | Bootstrap a fresh machine |

## Setup on a new computer

```sh
git clone https://github.com/amuraru/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` is idempotent and will:
1. Install **Homebrew** (if missing) + the CLI tools the config uses:
   `fzf fd ripgrep the_silver_searcher ydiff git git-delta direnv z kubernetes-cli krew coursier`,
   plus the `ghostty`
2. Install **oh-my-zsh** (if missing).
3. Clone the custom theme/plugins: **powerlevel10k**, **zsh-autosuggestions**, **zsh-syntax-highlighting**.
4. Install the **MesloLGS NF** font (macOS).
5. Symlink the dotfiles into `$HOME` (backing up any existing real files to `*.bak`).
6. Seed `~/.zshrc.local` from the template.

(fzf key bindings/completion load automatically via `fzf --zsh` in `zshrc`.)

Optional extras (build libs, `gitstatus`, VS Code) are listed commented-out in
`install.sh` — uncomment what you need.

Then add your secrets and reload:

```sh
$EDITOR ~/.zshrc.local   # fill in Artifactory keys, Vault, work env, etc.
exec zsh
```

## Secrets & machine-specific config

**No credentials live in this repo.** Anything private goes in `~/.zshrc.local`
(git-ignored), which `zshrc` sources last. Use `zshrc.local.example` as the
starting point. Git tokens follow the existing convention (`~/.secrets`,
`.gitconfig.user`) referenced in `gitconfig`.

## Updating

```sh
omzup   # updates oh-my-zsh core + all custom plugins/themes (defined in zshrc)
```

Edit files directly in `~/dotfiles` — the symlinks make changes live immediately.
Commit and push as usual.
