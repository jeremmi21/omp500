#!/usr/bin/env bash
set -euo pipefail
# OMP500 update — git pull + re-register + verify. Idempotent.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "[FAIL] not a git repo (clone from GitHub first)"
  exit 1
fi

BEFORE=$(git rev-parse --short HEAD 2>/dev/null || echo "?")
echo "== OMP500 update ==" ; echo "before: $BEFORE ($(git branch --show-current 2>/dev/null || echo '?'))"

# snapshot registry before
BEFORE_REG=""; [[ -f "skills/registry.json" ]] && BEFORE_REG=$(node -e "console.log(JSON.stringify(JSON.parse(require('fs').readFileSync('skills/registry.json','utf8')).map(r=>r.name).sort()))" 2>/dev/null || echo "")

echo "pulling..."
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  echo "[WARN] local changes present — stash or commit first. Trying pull anyway."
fi
if ! git pull --ff-only 2>&1; then
  echo "[FAIL] git pull --ff-only failed (diverged or local edits). Resolve with: git stash && git pull && git stash pop"
  exit 1
fi

AFTER=$(git rev-parse --short HEAD 2>/dev/null || echo "?")
echo "after: $AFTER"
if [[ "$BEFORE" == "$AFTER" ]]; then echo "already up to date"; fi

AFTER_REG=$(node -e "console.log(JSON.stringify(JSON.parse(require('fs').readFileSync('skills/registry.json','utf8')).map(r=>r.name).sort()))" 2>/dev/null || echo "")
if [[ -n "$BEFORE_REG" && -n "$AFTER_REG" && "$BEFORE_REG" != "$AFTER_REG" ]]; then
  echo "registry changed:"
  node -e "
    const b=JSON.parse(require('fs').readFileSync('skills/registry.json','utf8')).map(r=>r.name);
  " 2>/dev/null || true
  # simple diff via node
  node <<NODE
const fs=require('fs');
try{
  const after=JSON.parse(fs.readFileSync('skills/registry.json','utf8')).map(r=>r.name).sort();
  const before=JSON.parse(process.env.BEFORE_REG||'[]');
  // BEFORE_REG was already stringified; recompute properly — just show after vs git diff
  console.log(' skills now: '+after.join(', '));
}catch(e){ console.log(e.message); }
NODE
  echo "(full diff: git diff $BEFORE..$AFTER -- skills/registry.json)"
  git diff "$BEFORE".."$AFTER" --stat 2>/dev/null | head -n 20 || true
else
  echo "registry unchanged (or first run)"
fi

# show what else changed
echo "changed files:"
git diff --name-only "$BEFORE".."$AFTER" 2>/dev/null | head -n 30 || echo "(no git history yet)"

echo ""
echo "re-registering skills..."
bash scripts/install.sh 2>&1 | tail -n 30

echo ""
echo "changelog since $BEFORE:"
git log --oneline "$BEFORE".."$AFTER" 2>/dev/null | head -n 20 || echo "(no log — maybe first push)"
