# dotfiles

Personal shell config. Assumes Homebrew on macOS.

## Layout

These are **fragments**, sourced from your real dotfiles — not replacements for them:

- `toolbelt-env.zsh` — sourced from `~/.zshenv` (every shell); loads secrets from the Keychain.
- `toolbelt.zsh` — sourced from `~/.zshrc` (interactive); paths, history, aliases, tool init, plugins.
- `functions/` — shell functions; every `*.zsh` here is sourced by `toolbelt.zsh`:
  - `c.zsh` — `c`: launch Claude Code wrapped in `caffeinate` so the Mac stays awake.
  - `fs.zsh` — `fs`: open yazi and cd into the directory you quit from.
  - `secrets.zsh` — `store-secret` / `get-secret` / `delete-secret` / `list-secrets` (see Secrets below).
  - `tb.zsh` — `tb update` (pull + brew bundle) and `tb edit` (cd into the repo).
- `secrets.example` — example of the per-machine secrets manifest (see Secrets below).
- `iterm2/` — iTerm2 preferences (`com.googlecode.iterm2.plist`). See below.
- `tmux.conf` — tmux config; `install.sh --tmux` symlinks it to `~/.config/tmux/tmux.conf`, so repo edits apply on the next reload (`prefix + r`).
- `yazi/` — yazi config; `install.sh --yazi` symlinks each file into `~/.config/yazi/` (per-file, so machine-local files like `theme.toml` can coexist). `yazi.toml` hides the parent-directory pane (two-column layout); `keymap.toml` binds `o` to open the selection in VS Code. Loaded on yazi startup — restart open sessions to pick up edits.

## iTerm2

The `iterm2/` folder holds the exported preferences plist. `install.sh` copies
it into the standard location (`~/Library/Preferences/com.googlecode.iterm2.plist`),
backing up any existing prefs to `.bak` once. iTerm2 reads it on next launch.
On a fresh machine, `brew bundle` installs the `iterm2` cask and this drops your
config into place.

This is **one-way** (repo → machine). To capture changes you make in iTerm2's
GUI, re-export back into the repo (quit iTerm2 first so its in-memory prefs are
flushed):

```sh
plutil -convert xml1 -o configs/iterm2/com.googlecode.iterm2.plist \
  ~/Library/Preferences/com.googlecode.iterm2.plist
```

(Stored as XML so `git diff` is readable.)

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

With no arguments it installs everything. To install only some parts, pass
component flags (`./install.sh --help` for the full list):

```sh
../install.sh --iterm         # just the iTerm2 config
../install.sh --shell --deps  # shell config + Homebrew deps
```

The full flag list, and what each component installs, is in the
[top-level README](../README.md#parameter-reference).

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
