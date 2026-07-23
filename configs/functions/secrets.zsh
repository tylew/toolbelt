# Keychain secret helpers (see references/macos-keychain-secrets.md).
#
# Model: the secret VALUE lives in the macOS Keychain under a service whose name
# IS the env-var name. The LIST of which secrets to auto-load lives in a
# per-machine manifest, $TOOLBELT_SECRETS (one name per line). toolbelt-env.zsh
# reads that manifest at shell startup and exports each. These helpers keep the
# Keychain and the manifest in sync so adding a secret is a single command.
#
#   store-secret [--gui|--tty] NAME [value]   save + register + export
#   get-secret   NAME                         print a secret's value
#   delete-secret NAME                        remove from Keychain + manifest
#   list-secrets                              show which secrets are registered
#
# Prefer `store-secret NAME` with NO value: it prompts without the secret ever
# landing in shell history or the process argv (where `ps` could read it). When
# local it prompts via a macOS popup; over SSH ($SSH_CONNECTION set) or without
# a GUI it falls back to a hidden terminal read. Force either with --gui/--tty.

: ${TOOLBELT_SECRETS:=${XDG_CONFIG_HOME:-$HOME/.config}/toolbelt/secrets}

# _toolbelt-read-secret NAME MODE — echo a secret value to stdout, no terminal echo.
# MODE: gui | tty | auto (gui if local + GUI available, else tty).
_toolbelt-read-secret() {
  local name="$1" mode="${2:-auto}"
  if [[ "$mode" == auto ]]; then
    if [[ -z "$SSH_CONNECTION" ]] && command -v osascript >/dev/null 2>&1; then
      mode=gui
    else
      mode=tty
    fi
  fi
  if [[ "$mode" == gui ]]; then
    # NAME is validated to [A-Za-z0-9_] by the caller, so it's safe to inline.
    osascript 2>/dev/null <<APPLESCRIPT
text returned of (display dialog "Enter value for $name" with title "store-secret" default answer "" with hidden answer buttons {"Cancel", "Save"} default button "Save")
APPLESCRIPT
  else
    local v
    printf 'Value for %s (hidden): ' "$name" >&2
    read -rs v
    printf '\n' >&2
    printf '%s' "$v"
  fi
}

store-secret() {
  local mode=auto
  while [[ "$1" == -* ]]; do
    case "$1" in
      --gui)          mode=gui ;;
      --tty|--terminal) mode=tty ;;
      -h|--help)      echo "usage: store-secret [--gui|--tty] NAME [value]"; return 0 ;;
      --)             shift; break ;;
      *)              echo "store-secret: unknown option $1" >&2; return 2 ;;
    esac
    shift
  done
  local name="$1" value="$2"
  [[ -n "$name" ]] || { echo "usage: store-secret [--gui|--tty] NAME [value]" >&2; return 2; }
  [[ "$name" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] \
    || { echo "store-secret: NAME must be a valid env-var name (got: $name)" >&2; return 2; }
  if [[ -z "$value" ]]; then
    value="$(_toolbelt-read-secret "$name" "$mode")" \
      || { echo "store-secret: cancelled, nothing saved" >&2; return 1; }
  fi
  [[ -n "$value" ]] || { echo "store-secret: empty value, nothing saved" >&2; return 2; }
  security add-generic-password -s "$name" -a "$USER" -w "$value" -U -T "" 2>/dev/null \
    || { echo "❌ failed to store $name in Keychain" >&2; return 1; }
  mkdir -p "${TOOLBELT_SECRETS:h}"
  grep -qxF "$name" "$TOOLBELT_SECRETS" 2>/dev/null || echo "$name" >> "$TOOLBELT_SECRETS"
  export "$name=$value"
  echo "✅ Saved $name (Keychain + ${TOOLBELT_SECRETS/#$HOME/~})"
}

get-secret() { security find-generic-password -s "$1" -w 2>/dev/null; }

delete-secret() {
  local name="$1"
  [[ -n "$name" ]] || { echo "usage: delete-secret NAME" >&2; return 2; }
  security delete-generic-password -s "$name" >/dev/null 2>&1
  if [[ -f "$TOOLBELT_SECRETS" ]]; then
    grep -vxF "$name" "$TOOLBELT_SECRETS" > "$TOOLBELT_SECRETS.tmp" 2>/dev/null \
      && mv "$TOOLBELT_SECRETS.tmp" "$TOOLBELT_SECRETS"
  fi
  unset "$name"
  echo "🗑️  Deleted $name (Keychain + manifest)"
}

list-secrets() { [[ -r "$TOOLBELT_SECRETS" ]] && cat "$TOOLBELT_SECRETS" || echo "(no secrets registered)"; }
