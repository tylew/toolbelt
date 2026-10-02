#!/usr/bin/env bash
# ship.sh — submit the working tree to the rolling PR.
#
#   .claude/scripts/ship.sh "commit message"
#
# 1. Gate: .claude/hooks/doc-drift.sh must be clean (docs describe the repo).
# 2. Get onto the `rolling` branch (created from main if it doesn't exist).
# 3. Commit everything, push, and open the PR if there isn't one — otherwise
#    refresh the open PR's body with the current commit list.
#
# It NEVER merges. Merging is land.sh, run only when the user asks for it.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"
BRANCH=rolling

die()  { printf '\033[1;31mship:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

msg="${1:-}"
[ -n "$msg" ] || die 'usage: ship.sh "commit message"'
command -v gh >/dev/null || die "gh is required (brew install gh)"

info "checking docs"
"$REPO/.claude/hooks/doc-drift.sh" || die "docs are out of sync with the repo (above). Fix them, then ship again."

[ -n "$(git status --porcelain)" ] || die "nothing to ship: working tree is clean"

cur="$(git rev-parse --abbrev-ref HEAD)"
case "$cur" in
  "$BRANCH") ;;
  main)
    git fetch -q origin
    if git show-ref -q --verify "refs/heads/$BRANCH"; then
      git checkout -q "$BRANCH"
    elif git show-ref -q --verify "refs/remotes/origin/$BRANCH"; then
      git checkout -q -b "$BRANCH" "origin/$BRANCH"
    else
      git checkout -q -b "$BRANCH"
    fi
    info "on branch $BRANCH" ;;
  *) die "on branch '$cur'; ship.sh only runs from main or $BRANCH" ;;
esac

git add -A
# Commits are authored solely by the repo owner: no signing, no co-author trailers.
git -c commit.gpgsign=false commit -q -m "$msg"
info "committed: $msg"
git push -q -u origin "$BRANCH"
info "pushed $BRANCH"

body() {
  cat <<B
Rolling PR for completed, verified toolbelt changes. Each entry below was shipped by \`.claude/scripts/ship.sh\` after the docs were synced. **Merged only on request** (\`.claude/scripts/land.sh\`).

## Commits

$(git log --reverse --format='- %s' "origin/main..$BRANCH")
B
}

pr="$(gh pr list --head "$BRANCH" --base main --state open --json number -q '.[0].number')"
if [ -n "$pr" ]; then
  gh pr edit "$pr" --body "$(body)" >/dev/null
  info "updated PR #$pr"
else
  gh pr create --base main --head "$BRANCH" --title "Rolling toolbelt updates" --body "$(body)" >/dev/null
  info "opened rolling PR"
fi
gh pr view "$BRANCH" --json url -q .url
