#!/usr/bin/env bash
# One-shot bootstrap: installs Homebrew (if missing) + the Brewfile deps, then
# hooks the toolbelt shell config into your EXISTING dotfiles without replacing
# them. It appends a small guarded `source` block to ~/.zshrc and ~/.zshenv, so
# whatever the machine already defines (PATH, dep inits, work config) stays put
# and the toolbelt layers on top. Idempotent — re-running is a no-op if the
# block is already present. Uninstall = delete the block between the markers.
#
#   git clone https://github.com/tylew/toolbelt && cd toolbelt && ./install.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO/configs"
BEGIN="# >>> tylew/toolbelt >>>"
END="# <<< tylew/toolbelt <<<"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# hook DEST FRAGMENT — append a guarded `source FRAGMENT` block to DEST, once.
hook() {
  local dest="$1" fragment="$2"
  touch "$dest"
  if grep -qF "$BEGIN" "$dest"; then
    # Refresh the path in case the repo moved; leave everything else untouched.
    if ! grep -qF "source \"$fragment\"" "$dest"; then
      info "updating toolbelt block in $dest"
      # Rewrite just the line between the markers.
      awk -v b="$BEGIN" -v e="$END" -v line="source \"$fragment\"" '
        $0==b {print; print line; skip=1; next}
        $0==e {skip=0}
        skip {next}
        {print}
      ' "$dest" > "$dest.tmp" && mv "$dest.tmp" "$dest"
    else
      info "ok    $dest already hooked"
    fi
    return
  fi
  info "hook  $dest -> $fragment"
  {
    printf '\n%s   (managed by install.sh — edit the repo, not this block)\n' "$BEGIN"
    printf 'source "%s"\n' "$fragment"
    printf '%s\n' "$END"
  } >> "$dest"
}

# ── Homebrew ──
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── Dependencies ──
info "Installing Brewfile dependencies…"
brew bundle --file="$REPO/Brewfile"

# ── Hook the config into existing dotfiles ──
hook "$HOME/.zshenv" "$CONFIGS/toolbelt-env.zsh"   # every shell (secrets)
hook "$HOME/.zshrc"  "$CONFIGS/toolbelt.zsh"       # interactive shells

# ── Install iTerm2 preferences ──
# Copy the repo's plist into the standard prefs location; iTerm2 reads it there
# on launch. One-way (repo -> machine): re-export into the repo to capture GUI
# changes. Existing prefs are backed up once. Quit iTerm2 first so it doesn't
# overwrite the file on exit.
ITERM_PLIST="$CONFIGS/iterm2/com.googlecode.iterm2.plist"
ITERM_DEST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
if [ -f "$ITERM_PLIST" ]; then
  if [ -f "$ITERM_DEST" ] && [ ! -f "$ITERM_DEST.bak" ]; then
    cp "$ITERM_DEST" "$ITERM_DEST.bak"
    info "backup $ITERM_DEST -> $ITERM_DEST.bak"
  fi
  info "Installing iTerm2 preferences -> $ITERM_DEST"
  cp "$ITERM_PLIST" "$ITERM_DEST"
  defaults read com.googlecode.iterm2 >/dev/null 2>&1 || true  # nudge cfprefsd to reload
fi

# ── Install skills globally (~/.claude/skills) ──
# Symlink each skills/<name>/ so edits in the repo take effect immediately. An
# existing real (non-symlink) skill dir of the same name is backed up first.
if [ -d "$REPO/skills" ]; then
  SKILLS_DIR="$HOME/.claude/skills"
  mkdir -p "$SKILLS_DIR"
  for src in "$REPO/skills"/*/; do
    [ -d "$src" ] || continue
    src="${src%/}"
    dest="$SKILLS_DIR/$(basename "$src")"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      info "ok    skill $(basename "$src")"
    else
      if [ -e "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "$dest.bak"
        info "backup $dest -> $dest.bak"
      fi
      ln -s "$src" "$dest"
      info "skill $(basename "$src") -> $dest"
    fi
  done
fi

info "Done. Open a new shell (or run: exec zsh)."
