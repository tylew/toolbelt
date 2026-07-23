# toolbelt-env.zsh — sourced from ~/.zshenv, which runs for EVERY zsh
# invocation: login, interactive, AND non-interactive/script shells. Anything
# exported here is therefore visible to scripts, `ssh host <cmd>`, and cron —
# not just interactive terminals. That is why secret loading lives here rather
# than in the interactive config (which only runs for interactive shells).
#
# Secrets are stored in the macOS Keychain, never in this file.
# See references/macos-keychain-secrets.md for how to store/retrieve them.

# Silence zoxide's doctor false positive. With `alias cd=z` (toolbelt.zsh),
# zoxide's doctor warns in non-interactive shells (ssh <cmd>, scripts, agent
# harnesses) where its chpwd hook isn't wired up — even though `zoxide init` is
# already last in toolbelt.zsh. Setting this here (env, every shell) covers them.
export _ZO_DOCTOR=0

# ── Load secrets from the macOS Keychain ──
# The list of secrets to load lives in a PER-MACHINE manifest, not in this repo:
#   $TOOLBELT_SECRETS   (default ~/.config/toolbelt/secrets)
# one env-var name per line. Each name is looked up in the Keychain under a
# service of the SAME name and exported. Manage the list with store-secret /
# delete-secret (functions/secrets.zsh) — nothing here is committed, and the
# install script installs no secrets. Format example: configs/secrets.example.
: ${TOOLBELT_SECRETS:=${XDG_CONFIG_HOME:-$HOME/.config}/toolbelt/secrets}
if command -v security >/dev/null 2>&1 && [ -r "$TOOLBELT_SECRETS" ]; then
  while IFS= read -r name; do
    name="${name%%#*}"          # strip trailing comments
    name="${name//[[:space:]]/}" # strip whitespace
    [ -z "$name" ] && continue
    val="$(security find-generic-password -s "$name" -w 2>/dev/null)"
    [ -n "$val" ] && export "$name=$val"
  done < "$TOOLBELT_SECRETS"
  unset name val
fi

# ── Non-secret identity/config (safe to keep in the file) ──
# export PATH="${HOME}/.local/bin:${PATH}"
# export EMAIL_ADDRESS="you@example.com"
# export EMAIL_IMAP_HOST="imap.gmail.com"
# export EMAIL_IMAP_PORT="993"
