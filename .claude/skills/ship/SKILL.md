---
name: ship
description: Submit completed, verified toolbelt work to the rolling PR (branch `rolling`, never merged automatically). Use when a change is done and working and the user says ship, push, submit, or PR it, or at the end of any change per CLAUDE.md. Do not use to merge; merging happens only on an explicit user request via land.sh.
---

# Ship to the rolling PR

## Preconditions

1. **The change works.** Verify it the way CLAUDE.md describes for that kind of
   file (syntax check plus a real run). Do not ship half-done work; leave it
   uncommitted and tell the user what is left.
2. **The docs describe it.** Run the `sync-docs` skill. `ship.sh` refuses to
   run while `.claude/hooks/doc-drift.sh` reports drift.

## Ship

```sh
.claude/scripts/ship.sh "<area>: <what changed>"
```

The script switches to `rolling` (creating it from `main` if needed), commits
the whole working tree, pushes, and opens the PR or refreshes its body with the
commit list. It prints the PR URL; give that to the user.

Commit message style matches the log: `install: add --yazi component`,
`bin: add tsvnc`, `tailscale-proxy: document TS_BRIDGE_PORTS`.

## Merging

Never merge on your own, and never suggest it as the next step. When the user
explicitly asks for the rolling PR to be merged or landed:

```sh
.claude/scripts/land.sh
```
