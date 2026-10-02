---
name: sync-docs
description: Heal this repo's READMEs so they describe what the toolbelt actually installs and contains. Use after adding or changing a component, install flag, bin script, skill, config, shell function, or reference note; when the doc-drift Stop hook reports drift; or when the user asks to sync, refresh, or fix the docs.
---

# Sync docs

The docs are the install script's contract. Every time something in the repo
changes shape, the docs change with it, in the same commit.

## 1. Mechanical check

```sh
.claude/hooks/doc-drift.sh
```

It reports anything that exists in the repo but is not named where it should
be, and any documented install flag that no longer exists. Fix every line it
prints. This is a presence check only; passing it does not mean the prose is right.

## 2. Prose check

For the thing that changed, open its source and compare against its doc entry.
Describe what it does now, where it lands on the machine, and the mechanism
(symlink, copy, appended block). Remove claims that are no longer true.

| Changed | Update |
|---|---|
| `install.sh` flag or component | `README.md` component table, its subsection, and the parameter reference; `usage()` in the script itself |
| `Brewfile` | `README.md` dependencies subsection; `configs/README.md` dependencies list if it is a shell tool |
| `configs/*` or `configs/functions/*.zsh` | `configs/README.md` layout list; `README.md` shell subsection if user-facing |
| `bin/*` | `README.md` scripts subsection |
| `skills/*` | `README.md` skills subsection (one line, matching the skill's own description) |
| `references/*.md` | `README.md` repository map |
| `tailscale-proxy/*` | `tailscale-proxy/README.md`; the one-line summary in `README.md` |
| `.claude/*` or `CLAUDE.md` | `CLAUDE.md` and the maintenance section of `README.md` |

## 3. Re-run until clean

Repeat step 1 until it prints `docs in sync`. Do not ship from here; the
`ship` skill does that once the change itself is verified.
