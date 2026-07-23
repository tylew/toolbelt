---
name: managing-secrets
description: Use when storing, retrieving, rotating, or loading an API key / token / secret on this machine — e.g. a config or .mcp.json references a ${VAR} that isn't set, an MCP server or CLI fails to authenticate for lack of an env var, or the user wants to save/list/delete a secret. This machine loads secrets from the macOS Keychain via the toolbelt.
---

# Managing secrets

Secret **values** live in the macOS Keychain (service name == env-var name); the **list** to auto-load lives in `~/.config/toolbelt/secrets`. `~/.zshenv` exports each on every shell (incl. the ones that spawn MCP servers). These helpers keep both in sync — never hand-edit `~/.zshenv` or the manifest.

## Commands

| Task | Command |
|---|---|
| Save / rotate + register + export | `store-secret NAME` (prompts for value) |
| Print a value | `get-secret NAME` |
| Remove (Keychain + manifest) | `delete-secret NAME` |
| List registered names | `list-secrets` |

`store-secret NAME` with **no value** prompts securely — a macOS popup when local, a hidden terminal read over SSH (`--gui`/`--tty` force either) — so the secret never lands in shell history or `argv`. A positional `store-secret NAME value` still works for scripts.

To satisfy a config's `${SOME_KEY}`: `store-secret SOME_KEY`, open a new shell, then **fully restart** the client (MCP servers read env at launch). Keep `${VAR}` in the config — never inline the secret.

## Security

- The value must not pass through you. **Give the user the command to run themselves** — never execute `store-secret` with a real value or ask them to paste it into chat.
- Prefer the no-value form so nothing is captured anywhere: in Claude Code, `! store-secret SOME_KEY` runs in-session and prompts them for the value.
- `get-secret` / `list-secrets` are read-only and fine to run.
