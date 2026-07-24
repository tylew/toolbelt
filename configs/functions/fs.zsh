# fs — open yazi, and cd into whatever directory you quit from.
#
# A plain `alias fs=yazi` can't do this: yazi runs as a child process and a
# child can never change its parent shell's directory. The trick is yazi's
# --cwd-file: it writes its final directory to that file on exit, and this
# wrapper (which runs IN the shell) reads it and cd's there.
#
# Keybinds inside yazi: `q` quits and reports the cwd (so this cd's you there);
# capital `Q` quits WITHOUT changing directory.
#
# Note: `cat` is aliased to `bat` in toolbelt.zsh, so we use `command cat` to
# read the temp file with the real binary.
fs() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
