# ── Paths & Env ──
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"   # uv/rust env, if present

# ── History ──
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# ── Completions ──
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive both ways
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # color the completion menu

# ── Keybinds ──
bindkey "\e[1;3C" forward-word    # Option+Right → jump forward a word
bindkey "\e[1;3D" backward-word   # Option+Left  → jump back a word

# ── Aliases ──
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --icons --level=2"
alias cat="bat --paging=never"
alias cd="z"
# c  → see functions/c.zsh  (function: wraps claude in caffeinate to stay awake)
# fs → see functions/fs.zsh (function, not an alias, so it can cd on quit)

# ── Functions ──
# Source every *.zsh in the sibling functions/ dir, resolved relative to THIS
# file (%x = file of the current line) so it works wherever the repo is cloned.
for _fn in "${${(%):-%x}:A:h}/functions"/*.zsh(N); do
  source "$_fn"
done
unset _fn

# ── SSH: drop into Documents when connecting remotely ──
[[ -n "$SSH_CONNECTION" && "$PWD" == "$HOME" ]] && builtin cd ~/Documents

# ── Tool init ──
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --shell zsh)"  # Node version manager

# ── Plugins (must be last) ──
# Resolve Homebrew's prefix instead of hardcoding it — it's /opt/homebrew on a
# standard Apple-Silicon install but $HOME/homebrew for a user-space one. Guard
# each source so a missing plugin warns rather than erroring the whole rc.
_brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
for _plugin in zsh-autosuggestions/zsh-autosuggestions.zsh \
               zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [ -f "$_brew_prefix/share/$_plugin" ]; then
    source "$_brew_prefix/share/$_plugin"
  else
    print -u2 "toolbelt: plugin not found: $_plugin (brew prefix: ${_brew_prefix:-unset})"
  fi
done
unset _brew_prefix _plugin
