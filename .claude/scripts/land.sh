#!/usr/bin/env bash
# land.sh — merge the rolling PR into main and clean up the branch.
#
#   .claude/scripts/land.sh
#
# Run this ONLY when the user explicitly asks for the rolling PR to be merged.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"
BRANCH=rolling

die()  { printf '\033[1;31mland:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

[ -z "$(git status --porcelain)" ] || die "working tree has uncommitted changes; ship or stash them first"
pr="$(gh pr list --head "$BRANCH" --base main --state open --json number -q '.[0].number')"
[ -n "$pr" ] || die "no open rolling PR"

gh pr merge "$pr" --merge --delete-branch
git checkout -q main
git pull -q --ff-only origin main
git branch -D "$BRANCH" >/dev/null 2>&1 || true
git fetch -q --prune origin
info "merged PR #$pr; main is up to date and $BRANCH is gone"
