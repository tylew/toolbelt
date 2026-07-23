# dotfiles

Personal shell config. Assumes Homebrew on macOS.

## Layout

These are **fragments**, sourced from your real dotfiles — not replacements for them:

- `toolbelt-env.zsh` — sourced from `~/.zshenv` (every shell); loads secrets from the Keychain.
- `toolbelt.zsh` — sourced from `~/.zshrc` (interactive); paths, history, aliases, tool init, plugins.
- `functions/` — shell functions; every `*.zsh` here is sourced by `toolbelt.zsh`.

## Dependencies

Declared in [`../Brewfile`](../Brewfile) and installed by `../install.sh`:
[eza](https://github.com/eza-community/eza) (`ls`),
[bat](https://github.com/sharkdp/bat) (`cat`),
[zoxide](https://github.com/ajeetdsouza/zoxide) (`cd`),
[yazi](https://github.com/sxyazi/yazi) (file manager),
[fzf](https://github.com/junegunn/fzf) (fuzzy finder),
[starship](https://starship.rs) (prompt),
[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions),
[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).

## Install

Run the one-shot bootstrap from the repo root — it installs Homebrew (if
missing) and the Brewfile deps, then appends a small guarded `source` block to
your `~/.zshrc` and `~/.zshenv`:

```sh
../install.sh
```

It **does not replace** your existing dotfiles — whatever the machine already
defines stays, and the toolbelt is sourced *after* it (so it overlays without
erasing anything). The block sources these files straight from the repo, so
edits here take effect immediately. Re-running is idempotent. To uninstall,
delete the lines between the `# >>> tylew/toolbelt >>>` / `# <<< tylew/toolbelt <<<` markers.

## Secrets

Secret *values* live in the macOS Keychain (never in this repo). The *list* of
which to load lives in a per-machine manifest, `$TOOLBELT_SECRETS` (default
`~/.config/toolbelt/secrets`) — also never committed. On shell startup
`toolbelt-env.zsh` reads the manifest and exports each name from the Keychain
(service name == env-var name); it works for scripts and non-interactive shells,
not just terminals.

You don't edit the manifest by hand — the helpers in `functions/secrets.zsh`
keep it in sync:

```sh
store-secret GITHUB_TOKEN ghp_xxx   # → Keychain + manifest + exported now
list-secrets                        # what's registered
delete-secret GITHUB_TOKEN          # remove from both
```

The install script installs **no** secrets — you add each once, and it
auto-loads in every future shell. See
[`secrets.example`](./secrets.example) for the manifest format and
[`../references/macos-keychain-secrets.md`](../references/macos-keychain-secrets.md)
for details.
