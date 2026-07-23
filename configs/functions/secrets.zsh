# Keychain secret helpers (see references/macos-keychain-secrets.md).
#
# Model: the secret VALUE lives in the macOS Keychain under a service whose name
# IS the env-var name. The LIST of which secrets to auto-load lives in a
# per-machine manifest, $TOOLBELT_SECRETS (one name per line). toolbelt-env.zsh
# reads that manifest at shell startup and exports each. These helpers keep the
# Keychain and the manifest in sync so adding a secret is a single command.
#
#   store-secret NAME "value"   save to Keychain, register for auto-load, export now
#   get-secret   NAME           print a secret's value
#   delete-secret NAME          remove from Keychain + manifest
#   list-secrets                show which secrets are registered

: ${TOOLBELT_SECRETS:=${XDG_CONFIG_HOME:-$HOME/.config}/toolbelt/secrets}

store-secret() {
  local name="$1" value="$2"
  [[ -n "$name" && -n "$value" ]] || { echo "usage: store-secret NAME value" >&2; return 2; }
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
