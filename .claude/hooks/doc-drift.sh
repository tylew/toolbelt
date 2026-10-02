#!/usr/bin/env bash
# doc-drift.sh — mechanical check that the READMEs (and CLAUDE.md) still name
# everything the repo actually contains. It checks PRESENCE, not prose
# accuracy; the prose is Claude's job (see CLAUDE.md and the sync-docs skill).
#
#   .claude/hooks/doc-drift.sh          print a drift report; exit 1 on drift
#   .claude/hooks/doc-drift.sh --hook   Claude Code Stop hook: when the working
#                                       tree has uncommitted changes AND drift
#                                       exists, block the stop so Claude heals
#                                       the docs before finishing
#
# ship.sh runs the plain form as a gate and refuses to ship on drift.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"

issues=()
need() {  # need FILE LITERAL MESSAGE — record an issue if LITERAL is absent from FILE
  grep -qF -- "$2" "$1" 2>/dev/null || issues+=("$1: $3")
}

# 1. install.sh flags <-> README "Parameter reference" (both directions).
script_flags=$(grep -oE '(^[[:space:]]+|\|)--[a-z]+\)' install.sh | grep -oE -- '--[a-z]+' | sort -u)
for f in $script_flags; do
  need README.md "\`$f\`" "install flag $f exists in install.sh but is not documented"
done
ref_section=$(sed -n '/^## Parameter reference/,/^## [^P]/p' README.md)
for f in $(printf '%s\n' "$ref_section" | grep -oE '`--[a-z]+`' | tr -d '`' | sort -u); do
  grep -qE "(^[[:space:]]+|\|)$f\)" install.sh \
    || issues+=("README.md: parameter reference lists $f but install.sh has no such flag")
done

# 2. Every top-level directory is linked from README.md.
for d in */; do
  d="${d%/}"
  need README.md "](./$d)" "top-level directory $d/ is not linked"
done

# 3. Every bin/ executable, skill, and reference note is named in README.md.
for f in bin/*; do
  [ -f "$f" ] && [ -x "$f" ] || continue
  need README.md "\`$(basename "$f")\`" "bin script $(basename "$f") is not listed"
done
for s in skills/*/; do
  s="${s%/}"
  need README.md "\`$(basename "$s")\`" "skill $(basename "$s") is not listed"
done
for r in references/*.md; do
  need README.md "](./$r)" "reference note $(basename "$r") is not linked"
done

# 4. configs/README.md names every entry in configs/ and every shell function file.
for e in configs/*; do
  n="$(basename "$e")"
  [ "$n" = "README.md" ] && continue
  if [ -d "$e" ]; then need configs/README.md "\`$n/\`" "configs entry $n/ is not described"
  else                 need configs/README.md "\`$n\`"  "configs entry $n is not described"
  fi
done
for fn in configs/functions/*.zsh; do
  need configs/README.md "$(basename "$fn")" "shell function file $(basename "$fn") is not listed"
done

# 5. CLAUDE.md names every project skill, script, and hook under .claude/.
for s in .claude/skills/*/; do
  s="${s%/}"
  need CLAUDE.md "$(basename "$s")" "project skill $(basename "$s") is not mentioned"
done
for f in .claude/scripts/* .claude/hooks/*; do
  [ -f "$f" ] || continue
  need CLAUDE.md "$(basename "$f")" "$(basename "$f") is not mentioned"
done

# ── Report ──
if [ "${1:-}" = "--hook" ]; then
  input="$(cat 2>/dev/null || true)"
  # Already continued once from this hook: never loop.
  printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0
  # Clean tree: nothing in flight, don't nag.
  [ -n "$(git status --porcelain 2>/dev/null)" ] || exit 0
  [ "${#issues[@]}" -eq 0 ] && exit 0
  REASON="$(printf '%s\n' "${issues[@]}")" python3 - <<'PY'
import json, os
reason = ("The repo's docs no longer describe what it contains. Heal them before "
          "finishing (see CLAUDE.md / the sync-docs skill), then re-run "
          ".claude/hooks/doc-drift.sh until it is clean:\n" + os.environ["REASON"])
print(json.dumps({"decision": "block", "reason": reason}))
PY
  exit 0
fi

if [ "${#issues[@]}" -eq 0 ]; then
  echo "docs in sync"
  exit 0
fi
echo "doc drift:"
printf '  - %s\n' "${issues[@]}"
exit 1
