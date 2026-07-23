# macOS Keychain secrets

Store secrets (API keys, tokens) securely in the macOS Keychain instead of plaintext in `~/.zshrc`.

## 1. Store a key (one-time)

```bash
security add-generic-password -s "LINEAR_API_KEY" -a "$USER" -w "your-key-here" -T ""
```

- `-s` — service name (what you search for)
- `-a` — account name (usually your username)
- `-w` — the secret
- `-T ""` — optional; removes app access restrictions

Repeat for any other keys (`OPENAI_API_KEY`, `GITHUB_TOKEN`, …).

## 2. Load it in your shell

Load secrets in **`~/.zshenv`**, not `~/.zshrc`. `~/.zshenv` is sourced for
*every* zsh invocation — login, interactive, and non-interactive/script shells —
so the vars are also available to scripts, `ssh host <cmd>`, and cron. `~/.zshrc`
only runs for interactive shells, so secrets loaded there are invisible to
scripts.

Rather than hardcode the list of secrets, keep a per-machine **manifest** of
env-var names (one per line) and load each from the Keychain under a service of
the same name:

```bash
: ${TOOLBELT_SECRETS:=${XDG_CONFIG_HOME:-$HOME/.config}/toolbelt/secrets}
if command -v security >/dev/null 2>&1 && [ -r "$TOOLBELT_SECRETS" ]; then
  while IFS= read -r name; do
    name="${name%%#*}"; name="${name//[[:space:]]/}"
    [ -z "$name" ] && continue
    val="$(security find-generic-password -s "$name" -w 2>/dev/null)"
    [ -n "$val" ] && export "$name=$val"
  done < "$TOOLBELT_SECRETS"
  unset name val
fi
```

Why a manifest? The list of *which* secrets a machine has is machine-specific,
so it doesn't belong in committed config. The manifest lives outside the repo
(`~/.config/toolbelt/secrets`), stays uncommitted, and is maintained by the
helpers below — so adding a secret never means editing tracked files. See
[`configs/toolbelt-env.zsh`](../configs/toolbelt-env.zsh) for the working
template and [`configs/secrets.example`](../configs/secrets.example) for the
format. After changes, `source ~/.zshenv` (or open a new shell) to reload.

## Helper functions (recommended)

Shipped in [`configs/functions/secrets.zsh`](../configs/functions/secrets.zsh);
each keeps the Keychain and the manifest in sync:

```bash
# Store + register + export (service name == env-var name):
store-secret() {
    local name="$1" value="$2"
    [[ -n "$name" && -n "$value" ]] || { echo "usage: store-secret NAME value" >&2; return 2; }
    security add-generic-password -s "$name" -a "$USER" -w "$value" -U -T "" 2>/dev/null || return 1
    mkdir -p "${TOOLBELT_SECRETS:h}"
    grep -qxF "$name" "$TOOLBELT_SECRETS" 2>/dev/null || echo "$name" >> "$TOOLBELT_SECRETS"
    export "$name=$value"
}

# Retrieve:  get-secret LINEAR_API_KEY
get-secret() { security find-generic-password -s "$1" -w 2>/dev/null; }

# Delete from Keychain + manifest:  delete-secret LINEAR_API_KEY
delete-secret() {
    security delete-generic-password -s "$1" >/dev/null 2>&1
    grep -vxF "$1" "$TOOLBELT_SECRETS" > "$TOOLBELT_SECRETS.tmp" 2>/dev/null && mv "$TOOLBELT_SECRETS.tmp" "$TOOLBELT_SECRETS"
    unset "$1"
}
```

Usage: `store-secret LINEAR_API_KEY "lin_api_12345..."`, then it auto-loads in
every future shell.

## One-liner for a single script

```bash
export LINEAR_API_KEY="$(security find-generic-password -s LINEAR_API_KEY -w 2>/dev/null || echo '')"
```
