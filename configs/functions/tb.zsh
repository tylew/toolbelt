# tb — manage the toolbelt itself. $TOOLBELT_DIR (set in toolbelt.zsh) points at
# the repo root, so this works wherever the repo was cloned.
#
#   tb update   git pull + brew bundle, then reminds you to reload
#   tb edit     cd into the repo to edit configs
#   tb          show usage
#
# `cat` is aliased to `bat`, so the usage heredoc uses `command cat`.
tb() {
  case "$1" in
    update)
      [[ -n "$TOOLBELT_DIR" && -d "$TOOLBELT_DIR/.git" ]] \
        || { echo "tb: TOOLBELT_DIR not a git repo ($TOOLBELT_DIR)" >&2; return 1; }
      git -C "$TOOLBELT_DIR" pull --ff-only || return
      brew bundle --file="$TOOLBELT_DIR/Brewfile"
      echo "✅ toolbelt updated — run 'exec zsh' to reload your shell"
      ;;
    edit)
      builtin cd "$TOOLBELT_DIR"
      ;;
    ""|-h|--help)
      command cat <<'EOF'
tb — toolbelt manager
  tb update   pull latest + brew bundle (then run: exec zsh)
  tb edit     cd into the toolbelt repo
EOF
      ;;
    *)
      echo "tb: unknown command '$1' (try: tb update | tb edit)" >&2
      return 2
      ;;
  esac
}
