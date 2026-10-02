# Toolbelt

Personal macOS setup repo. `install.sh` installs a set of independent components
(deps, shell, iTerm2, tmux, yazi, skills, bin) onto a machine; everything else
in the repo is what those components install, plus `tailscale-proxy/` and
`references/`. `README.md` is the contract for what the script does. See
`.claude/` for the tooling that keeps that contract true.

## Working rules

- **Docs track the repo, in the same change.** Any change to what the repo
  contains or what `install.sh` does is not finished until `README.md` (and the
  component README it touches) says so. A Stop hook runs
  `.claude/hooks/doc-drift.sh --hook`: if the working tree is dirty and the docs
  no longer name what the repo contains, it blocks the stop and lists what is
  missing. Heal the docs (the `sync-docs` skill) rather than working around it.
- **Completed work goes to the rolling PR, not to main.** When a change is
  verified working and the docs are synced, run the `ship` skill, which calls
  `.claude/scripts/ship.sh "<message>"`: commits to the `rolling` branch, pushes,
  and opens or refreshes the PR. Work that is not done stays uncommitted.
- **Never merge unless the user explicitly asks.** Then, and only then, run
  `.claude/scripts/land.sh`. Do not propose merging as a next step.
- **Commits are authored solely by the repo owner.** No commit signing, no
  co-author trailers, no generated-by footers in commits or PR bodies.
  `ship.sh` enforces the signing part; keep the rest out of any message you write.
- **Nothing on the user's machine is replaced.** Components append guarded
  blocks, symlink into the repo, or copy once with a `.bak`. Keep that property
  when adding a component, and keep every component idempotent.
- **No secrets in the repo.** Secret values live in the Keychain
  (`configs/functions/secrets.zsh`); `.env` files are gitignored.

## Verifying a change is functional

Verify before shipping, with a real run, not just a syntax check.

| Kind | Check |
|---|---|
| `install.sh` | `bash -n install.sh && ./install.sh --help`, then run the touched component flag (safe: idempotent, backs up) and confirm the result on disk |
| `configs/*.zsh`, `configs/functions/*.zsh` | `zsh -n <file>`, then `zsh -ic 'source configs/toolbelt.zsh; <fn> --help'` or exercise the function |
| `bin/*` | `bash -n bin/<x> && bin/<x> --help`, then the real subcommand where it can be run locally |
| `Brewfile` | `brew bundle check --file=Brewfile` (or `brew bundle` to install) |
| `skills/*`, `.claude/skills/*` | frontmatter has `name` and `description`; the body's commands actually run |
| `tailscale-proxy/` | `docker compose -f tailscale-proxy/docker-compose.yml config -q`; `sh -n tailscale-proxy/entrypoint.sh` |
| `.claude/hooks/*`, `.claude/scripts/*` | `bash -n`, then run the plain (non-hook) form |

## Adding a component to `install.sh`

1. Add a `do_<name>` flag, its `case` arm, the `--all` set, and the `usage()` line.
2. Write `install_<name>()`: skip cleanly if the source is absent, symlink per
   file where machine-local files might coexist, back up a real file once.
3. Document it in the `README.md` component table, a subsection, and the
   parameter reference. `configs/README.md` points at that reference rather than
   duplicating it.

## Layout of `.claude/`

- `settings.json` — the Stop hook wiring.
- `hooks/doc-drift.sh` — presence check of docs vs repo; `--hook` form blocks a stop on drift.
- `scripts/ship.sh` — gate on drift, commit to `rolling`, push, open or refresh the PR.
- `scripts/land.sh` — merge the rolling PR; user request only.
- `skills/sync-docs` — the prose-level doc audit, with a map of what to update where.
- `skills/ship` — the ship procedure and its preconditions.
