# c — launch Claude Code, keeping the Mac awake for the whole session.
#
# Wraps `claude` in `caffeinate` so a long agent run doesn't get suspended when
# the display sleeps (-d display, -i idle, -s system-on-AC). caffeinate is a
# macOS-native binary (/usr/bin/caffeinate) — nothing to install — but we guard
# on it so the function still runs Claude if it's somehow absent.
#
# The trap guarantees caffeinate is killed even if you Ctrl-C out of Claude, so
# we never leave a stray keep-awake process holding the machine on.
c() {
  if command -v caffeinate >/dev/null 2>&1; then
    caffeinate -dis &
    local caf_pid=$!
    trap 'kill "$caf_pid" 2>/dev/null' EXIT INT TERM
  fi
  claude --dangerously-skip-permissions --chrome "$@"
}
