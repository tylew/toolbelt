# Toolbelt (MacOS-Native)

A collection of random tools and stuff.

## Setup

Mount the shell config on a new (or current) machine in one shot — installs
Homebrew and deps, then hooks the config into your existing `~/.zshrc` /
`~/.zshenv` without replacing them (idempotent):

```sh
git clone https://github.com/tylew/toolbelt && cd toolbelt && ./install.sh
```

## Contents

- [`install.sh`](./install.sh) — one-shot bootstrap: Homebrew + [`Brewfile`](./Brewfile) deps + hooks the shell config into your existing dotfiles.
- [`tailscale-proxy/`](./tailscale-proxy) — Docker Compose setup that registers a machine on Tailscale as its own node, forwarding all traffic to the host. Useful for running alongside an existing host Tailscale instance (e.g. to expose a named node for SSH access).
- [`configs/`](./configs) — Personal shell config (zsh). Assumes Homebrew on macOS.
- [`references/`](./references) — Condensed how-to notes.
  - [`macos-keychain-secrets.md`](./references/macos-keychain-secrets.md) — Store API keys/tokens in the macOS Keychain and load them into your shell.
