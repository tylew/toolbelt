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

Add to `~/.zshrc`:

```bash
# Load Linear API key from Keychain
if [ -z "$LINEAR_API_KEY" ]; then
    LINEAR_API_KEY="$(security find-generic-password -s LINEAR_API_KEY -w 2>/dev/null)"
    if [ -n "$LINEAR_API_KEY" ]; then
        export LINEAR_API_KEY
        echo "✅ LINEAR_API_KEY loaded from Keychain" >&2
    else
        echo "⚠️  LINEAR_API_KEY not found in Keychain" >&2
    fi
fi
```

Then `source ~/.zshrc` to reload.

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
