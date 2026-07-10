# toolbelt

A collection of random tools and stuff.

## Contents

- [`tailscale-proxy/`](./tailscale-proxy) — Docker Compose setup that registers a machine on Tailscale as its own node, forwarding all traffic to the host. Useful for running alongside an existing host Tailscale instance (e.g. to expose a named node for SSH access).
- [`configs/`](./configs) — Personal shell config (zsh). Assumes Homebrew on macOS.
- [`references/`](./references) — Condensed how-to notes.
  - [`macos-keychain-secrets.md`](./references/macos-keychain-secrets.md) — Store API keys/tokens in the macOS Keychain and load them into your shell.
