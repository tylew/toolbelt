# Toolbelt (macOS-native)

Everything I want on a Mac, installed by one script: the zsh config and shell
functions, dotfiles for the terminal stack (iTerm2, tmux, yazi), personal CLI
scripts, Claude Code skills, and the Homebrew packages behind them. Alongside
that: a Tailscale-in-Docker setup and some condensed how-to notes.

## Setup

```sh
git clone https://github.com/tylew/toolbelt && cd toolbelt && ./install.sh
```

Then open a new shell (`exec zsh`). Re-running is safe: every component is
idempotent, and anything the script would overwrite is backed up once as
`.bak`. Later, `tb update` pulls the repo and re-runs `brew bundle`.

## What `install.sh` installs

With no arguments it installs every component below. Nothing already on the
machine is replaced: dotfiles get a small guarded `source` block appended,
configs are symlinked back into this repo (so edits here apply immediately),
and the one thing that is copied (iTerm2 prefs) is backed up first.

| Component | Flag | What it does | Lands at |
|---|---|---|---|
| Dependencies | `--deps` | Installs Homebrew if missing, then every formula, cask, and font in [`Brewfile`](./Brewfile) | Homebrew |
| Shell | `--shell` | Appends a guarded block to `~/.zshenv` (sources `toolbelt-env.zsh`, which loads Keychain secrets) and to `~/.zshrc` (sources `toolbelt.zsh`: PATH, history, completions, aliases, functions, tool init) | `~/.zshenv`, `~/.zshrc` |
| iTerm2 | `--iterm` | Copies the exported preferences plist into place. One-way, repo to machine; quit iTerm2 first | `~/Library/Preferences/com.googlecode.iterm2.plist` |
| tmux | `--tmux` | Symlinks `configs/tmux.conf` | `~/.config/tmux/tmux.conf` |
| yazi | `--yazi` | Symlinks each `configs/yazi/*.toml` individually, so machine-local files like `theme.toml` can coexist | `~/.config/yazi/` |
| Skills | `--skills` | Symlinks each `skills/<name>/` so Claude Code picks it up | `~/.claude/skills/<name>` |
| Scripts | `--bin` | Symlinks each executable in `bin/` | `~/.local/bin/` (put on `PATH` by `toolbelt.zsh`) |

### Dependencies (`--deps`)

Everything in [`Brewfile`](./Brewfile), grouped:

- **Shell tools**: eza (`ls`), bat (`cat`), fd, ripgrep, zoxide (`cd`), yazi, fzf, starship, atuin, tmux, herdr, zsh-autosuggestions, zsh-syntax-highlighting.
- **yazi previews**: poppler (PDF), ffmpeg (video).
- **CLI**: gh, fnm, jq, yq, trash.
- **Apps**: iTerm2, Visual Studio Code, OrbStack.
- **Fonts**: Meslo LG Nerd Font, for terminal and starship glyphs.

### Shell (`--shell`)

The appended block sources the config straight from the repo, after whatever
your dotfiles already define, so the toolbelt layers on top. It gives you:

- **Aliases**: `ls`, `ll`, `lt` (eza), `cat` (bat), `cd` (zoxide).
- **Functions** from [`configs/functions/`](./configs/functions): `c` (Claude Code under `caffeinate`), `fs` (yazi that cd's to where you quit), `tb` (`tb update`, `tb edit`), and the Keychain helpers `store-secret`, `get-secret`, `delete-secret`, `list-secrets`.
- **Tool init**: starship, fzf (fed by fd, with bat and eza previews), zoxide, fnm, atuin.
- **Secrets**: `toolbelt-env.zsh` exports every secret named in a per-machine manifest from the macOS Keychain, in every shell. The script installs no secrets; add each once with `store-secret`.

Details in [`configs/README.md`](./configs/README.md).

### Skills (`--skills`)

Claude Code skills, symlinked so repo edits take effect immediately:

- `herdr`: drive Herdr, the terminal multiplexer for coding agents.
- `managing-secrets`: store, load, and rotate API keys through the Keychain setup above.
- `rich-reply`: answer on a messaging channel with a short message plus a styled HTML page served over Tailscale.

### Scripts (`--bin`)

- `tsvnc`: Screen Sharing to a machine on the personal tailnet from a Mac whose own node is on a different tailnet. Tunnels VNC over SSH through the proxy container's SOCKS port. `tsvnc list`, `tsvnc <host>`, `tsvnc stop <host>`.

### Not installed by the script

- [`tailscale-proxy/`](./tailscale-proxy): run it yourself with `docker compose`.
- [`references/`](./references): notes to read, nothing to install.
- Secret values: never in the repo, see above.

## Parameter reference

```
./install.sh [components...]
```

| Flag | Installs |
|---|---|
| *(none)* | Everything, same as `--all` |
| `--deps` | Homebrew (if missing) and the Brewfile packages, casks, and fonts |
| `--shell` | The guarded `source` blocks in `~/.zshrc` and `~/.zshenv` |
| `--iterm` | iTerm2 preferences plist |
| `--tmux` | `tmux.conf` symlink |
| `--yazi` | yazi config symlinks |
| `--skills` | `~/.claude/skills` symlinks |
| `--bin` | `~/.local/bin` symlinks |
| `--all` | Everything |
| `-h`, `--help` | Usage |

Flags combine (`./install.sh --shell --deps`). Each component skips cleanly if
its source is missing from the repo, reports `ok` if already installed, and
backs up any real file it would replace to `<file>.bak` once. To uninstall the
shell hook, delete the lines between the `# >>> tylew/toolbelt >>>` and
`# <<< tylew/toolbelt <<<` markers; everything else is a symlink you can remove.

```sh
./install.sh                 # full setup
./install.sh --iterm         # just the iTerm2 config
./install.sh --shell --deps  # shell config + Homebrew deps
./install.sh --bin --skills  # just the scripts and Claude skills
```

## Repository map

- [`install.sh`](./install.sh): the bootstrap described above.
- [`Brewfile`](./Brewfile): machine dependencies.
- [`bin/`](./bin): personal CLI scripts, installed by `--bin`.
- [`configs/`](./configs): zsh config, functions, iTerm2, tmux, and yazi dotfiles.
- [`skills/`](./skills): Claude Code skills, installed by `--skills`.
- [`tailscale-proxy/`](./tailscale-proxy): Docker Compose Tailscale node that runs alongside the host's own Tailscale. Forwards everything to one host, or reverse-proxies individual paths with a persisted `serve` config, with optional bridge-port forwarding for the Docker host.
- [`references/`](./references): condensed how-to notes.
  - [`macos-keychain-secrets.md`](./references/macos-keychain-secrets.md): store API keys in the macOS Keychain and load them into your shell.
  - [`hermes-mcp.md`](./references/hermes-mcp.md): expose a Hermes install as an MCP server (`hermes mcp serve`) and wire it into a client.
- [`CLAUDE.md`](./CLAUDE.md) and [`.claude/`](./.claude): how the repo maintains itself, below.

## Maintaining this repo

Claude Code sessions in this repo follow [`CLAUDE.md`](./CLAUDE.md), and `.claude/` holds the tooling:

- **Docs self-heal.** A Stop hook runs `.claude/hooks/doc-drift.sh`. If the working tree has changes and the READMEs no longer name what the repo contains, the session is blocked from finishing until the docs are fixed (the `sync-docs` skill).
- **Rolling PR.** Once a change is verified working and documented, the `ship` skill runs `.claude/scripts/ship.sh`, which commits to the `rolling` branch, pushes, and opens or updates one long-lived PR against `main`.
- **Merge on request only.** The rolling PR is landed with `.claude/scripts/land.sh`, and only when you ask.
