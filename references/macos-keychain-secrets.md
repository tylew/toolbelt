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

Map each env var to its Keychain service name and loop:

```bash
if command -v security >/dev/null 2>&1; then
  typeset -A keychain_secrets=(
    EXAMPLE_API_KEY  example-api-key
    EXAMPLE_TOKEN    example-service-token
  )
  for var svc in ${(kv)keychain_secrets}; do
    val="$(security find-generic-password -s "$svc" -w 2>/dev/null)"
    [ -n "$val" ] && export "$var=$val"
  done
  unset var svc val keychain_secrets
fi
```

See [`configs/.zshenv`](../configs/.zshenv) for the working template. After
editing, `source ~/.zshenv` (or open a new shell) to reload.

## Helper functions (recommended)

Add to `~/.zshrc` for easy management:

```bash
# Store a secret:  store-secret LINEAR_API_KEY "lin_api_12345..."
store-secret() {
    security add-generic-password -s "$1" -a "$USER" -w "$2" -T "" 2>/dev/null && \
        echo "✅ Saved $1 to Keychain"
}

# Retrieve a secret:  get-secret LINEAR_API_KEY
get-secret() {
    security find-generic-password -s "$1" -w 2>/dev/null
}

# Delete a secret:  delete-secret LINEAR_API_KEY
delete-secret() {
    security delete-generic-password -s "$1" 2>/dev/null && \
        echo "🗑️  Deleted $1 from Keychain"
}
```

## One-liner for a single script

```bash
export LINEAR_API_KEY="$(security find-generic-password -s LINEAR_API_KEY -w 2>/dev/null || echo '')"
```
