#!/usr/bin/env bash
# One-shot bootstrap: installs Homebrew (if missing) + the Brewfile deps, then
# hooks the toolbelt shell config into your EXISTING dotfiles without replacing
# them. It appends a small guarded `source` block to ~/.zshrc and ~/.zshenv, so
# whatever the machine already defines (PATH, dep inits, work config) stays put
# and the toolbelt layers on top. Idempotent — re-running is a no-op if the
# block is already present. Uninstall = delete the block between the markers.
#
#   git clone https://github.com/tylew/toolbelt && cd toolbelt && ./install.sh
#
# By default it installs everything. Pass component flags to install only some
# parts — e.g. `./install.sh --iterm` for just the iTerm2 config. See --help.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO/configs"
BEGIN="# >>> tylew/toolbelt >>>"
END="# <<< tylew/toolbelt <<<"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [components...]

With no arguments, installs everything. Pass one or more component flags to
install only those parts:

  --deps      Homebrew (if missing) + Brewfile packages/casks
  --shell     hook the zsh config into ~/.zshrc and ~/.zshenv
  --iterm     copy iTerm2 preferences into ~/Library/Preferences
  --skills    symlink skills into ~/.claude/skills
  --all       everything (the default)
  -h, --help  show this help

Examples:
  ./install.sh                 # full setup
  ./install.sh --iterm         # just the iTerm2 config
  ./install.sh --shell --deps  # shell config + Homebrew deps
EOF
}

# ── Parse args: enable selected components (default = all) ──
do_deps=false do_shell=false do_iterm=false do_skills=false
if [ "$#" -eq 0 ]; then
  do_deps=true do_shell=true do_iterm=true do_skills=true
else
  for arg in "$@"; do
    case "$arg" in
      --deps)   do_deps=true ;;
      --shell)  do_shell=true ;;
      --iterm)  do_iterm=true ;;
      --skills) do_skills=true ;;
      --all)    do_deps=true do_shell=true do_iterm=true do_skills=true ;;
      -h|--help) usage; exit 0 ;;
      *) printf 'Unknown option: %s\n\n' "$arg" >&2; usage >&2; exit 2 ;;
    esac
  done
fi

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

# ── Dependencies: Homebrew + Brewfile ──
install_deps() {
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  info "Installing Brewfile dependencies…"
  brew bundle --file="$REPO/Brewfile"
}

# ── Shell: hook the config into existing dotfiles ──
install_shell() {
  hook "$HOME/.zshenv" "$CONFIGS/toolbelt-env.zsh"   # every shell (secrets)
  hook "$HOME/.zshrc"  "$CONFIGS/toolbelt.zsh"       # interactive shells
}

# ── iTerm2: copy the repo's plist into the standard prefs location ──
# iTerm2 reads it there on launch. One-way (repo -> machine): re-export into the
# repo to capture GUI changes. Existing prefs are backed up once. Quit iTerm2
# first so it doesn't overwrite the file on exit.
install_iterm() {
  local plist="$CONFIGS/iterm2/com.googlecode.iterm2.plist"
  local dest="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
  [ -f "$plist" ] || { info "skip  no iTerm2 plist in repo"; return; }
  if [ -f "$dest" ] && [ ! -f "$dest.bak" ]; then
    cp "$dest" "$dest.bak"
    info "backup $dest -> $dest.bak"
  fi
  info "Installing iTerm2 preferences -> $dest"
  cp "$plist" "$dest"
  defaults read com.googlecode.iterm2 >/dev/null 2>&1 || true  # nudge cfprefsd to reload
}

# ── Skills: symlink each skills/<name>/ into ~/.claude/skills ──
# Edits in the repo then take effect immediately. An existing real (non-symlink)
# skill dir of the same name is backed up first.
install_skills() {
  [ -d "$REPO/skills" ] || { info "skip  no skills/ in repo"; return; }
  local skills_dir="$HOME/.claude/skills"
  mkdir -p "$skills_dir"
  for src in "$REPO/skills"/*/; do
    [ -d "$src" ] || continue
    src="${src%/}"
    local dest="$skills_dir/$(basename "$src")"
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
}

$do_deps   && install_deps
$do_shell  && install_shell
$do_iterm  && install_iterm
$do_skills && install_skills

info "Done. Open a new shell (or run: exec zsh)."
