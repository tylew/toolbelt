. "$HOME/.local/bin/env"

# ── Paths & Env ──
export PATH="$HOME/.local/bin:$PATH"

# ── History ──
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# ── Completions ──
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ── Aliases ──
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --icons --level=2"
alias cat="bat --paging=never"
alias cd="z"
alias fs=yazi
alias c="claude --dangerously-skip-permissions --chrome"

# ── Keychain secrets (see references/macos-keychain-secrets.md) ──
# Secrets are stored in the macOS Keychain and loaded in ~/.zshenv.
# These helpers manage them. store-secret NAME "value" / get-secret NAME / delete-secret NAME
store-secret()  { security add-generic-password -s "$1" -a "$USER" -w "$2" -T "" 2>/dev/null && echo "✅ Saved $1 to Keychain"; }
get-secret()    { security find-generic-password -s "$1" -w 2>/dev/null; }
delete-secret() { security delete-generic-password -s "$1" 2>/dev/null && echo "🗑️  Deleted $1 from Keychain"; }

# ── SSH: drop into Documents when connecting remotely ──
[[ -n "$SSH_CONNECTION" && "$PWD" == "$HOME" ]] && cd ~/Documents

# ── Tool init ──
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# ── Plugins (must be last) ──
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
