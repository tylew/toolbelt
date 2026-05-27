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

# ── SSH: drop into Documents when connecting remotely ──
[[ -n "$SSH_CONNECTION" && "$PWD" == "$HOME" ]] && cd ~/Documents

# ── Tool init ──
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# ── Plugins (must be last) ──
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'
source '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'
