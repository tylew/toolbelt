# ~/.zshenv — sourced for EVERY zsh invocation: login, interactive, AND
# non-interactive/script shells. Anything exported here is therefore visible to
# scripts, `ssh host <cmd>`, and cron — not just interactive terminals. That is
# why secret loading lives here rather than in ~/.zshrc (which only runs for
# interactive shells).
#
# Secrets are stored in the macOS Keychain, never in this file.
# See references/macos-keychain-secrets.md for how to store/retrieve them.

# ── Load secrets from the macOS Keychain ──
# Map each env var to the Keychain service name (-s) it's stored under.
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

# ── Non-secret identity/config (safe to keep in the file) ──
# export PATH="${HOME}/.local/bin:${PATH}"
# export EMAIL_ADDRESS="you@example.com"
# export EMAIL_IMAP_HOST="imap.gmail.com"
# export EMAIL_IMAP_PORT="993"
