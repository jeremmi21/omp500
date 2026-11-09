#!/usr/bin/env bash
set -uo pipefail
# OMP500 verify — read-only checks. Exits 0 if all PASS, 1 if any FAIL.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0
pass(){ echo "[PASS] $*"; }
fail(){ echo "[FAIL] $*"; FAIL=1; }
warn(){ echo "[WARN] $*"; }
# Windows Git Bash: bare `node` may not resolve (space in "Program Files").
# Find node once; use $NODE_BIN everywhere below.
find_node(){
  if command -v node >/dev/null 2>&1; then command -v node; return 0; fi
  for p in "/c/Program Files/nodejs/node.exe" "/c/Program Files/nodejs/node" "/c/Users/zhy3o/AppData/Local/pi-node/current/node.exe" "/c/Users/zhy3o/AppData/Local/pi-node/current/node" "/mnt/c/Program Files/nodejs/node.exe"; do
    if [[ -x "$p" ]]; then echo "$p"; return 0; fi
  done
  echo "node"
}
NODE_BIN="$(find_node)"

echo "== OMP500 verify =="
echo "node: $NODE_BIN ($("$NODE_BIN" --version 2>&1 || echo 'not found'))"

# 1) config
if [[ -f "settings/config.yaml" ]]; then
  if grep -q "expected_skill_count" settings/config.yaml; then pass "settings/config.yaml present"; else fail "settings/config.yaml missing expected_skill_count"; fi
else fail "settings/config.yaml missing"; fi

# 2) secrets template must not contain real keys
if [[ -f "settings/secrets.example.env" ]]; then
  if grep -Eiq "sk-(proj-|[A-Za-z0-9]{20,})" settings/secrets.example.env 2>/dev/null; then fail "settings/secrets.example.env appears to contain a real key"; else pass "settings/secrets.example.env has no real keys"; fi
else warn "settings/secrets.example.env missing"; fi
if [[ -f ".env" ]] && grep -Eq "OPENAI_API_KEY=.+[^placeholder]" .env 2>/dev/null; then warn ".env present (not committed) — ok"; fi

# 2b) no real key anywhere in a tracked file (a key belongs in .env, which is gitignored)
if git rev-parse --git-dir >/dev/null 2>&1; then
  LEAKED="$(git grep -lEI '(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|oc_sk_[A-Za-z0-9]{20,})' -- . ':!*.lock' 2>/dev/null | head -5)"
  if [[ -n "$LEAKED" ]]; then fail "real key in tracked file(s): $(echo "$LEAKED" | tr '\n' ' ')"; else pass "no real keys in tracked files"; fi
else warn "not a git checkout — skipped the tracked-file key scan"; fi

# 3) registry + expected count + per-skill folders
"$NODE_BIN" <<'NODE'
const fs=require('fs'), path=require('path');
let fail=0;
const regPath='skills/registry.json';
let reg;
try{ reg=JSON.parse(fs.readFileSync(regPath,'utf8')); }catch(e){ console.error('[FAIL] registry.json invalid: '+e.message); process.exit(1); }
console.log(`[PASS] registry.json valid (${reg.length} entries)`);
let expected=null;
try{
  const cfg=fs.readFileSync('settings/config.yaml','utf8');
  const m=cfg.match(/expected_skill_count:\s*(\d+)/);
  if(m) expected=parseInt(m[1],10);
}catch{}
if(expected!==null){
  if(reg.length===expected) console.log(`[PASS] skill count ${reg.length} matches expected ${expected}`);
  else { console.error(`[FAIL] skill count ${reg.length} != expected ${expected} (settings/config.yaml)`); fail=1; }
}
let missing=[];
for(const e of reg){
  const dir=path.join('skills',e.name);
  const mf=path.join(dir,'manifest.yaml');
  const pr=path.join(dir,'prompt.md');
  if(!fs.existsSync(dir)) missing.push(e.name+' (no dir)');
  else {
    if(!fs.existsSync(mf)) missing.push(e.name+'/manifest.yaml');
    if(!fs.existsSync(pr)) missing.push(e.name+'/prompt.md');
    if(e.name!==path.basename(dir)) missing.push(e.name+' folder mismatch');
  }
}
const dirs=fs.readdirSync('skills').filter(d=>d!=='_template' && fs.statSync(path.join('skills',d)).isDirectory());
const names=new Set(reg.map(r=>r.name));
for(const d of dirs) if(!names.has(d)) console.log(`[WARN] orphan dir skills/${d} not in registry.json`);
if(missing.length) { console.error('[FAIL] missing: '+missing.join(', ')); fail=1; }
else console.log('[PASS] each skill folder present (manifest.yaml + prompt.md)');
process.exit(fail);
NODE
if [[ $? -ne 0 ]]; then FAIL=1; fi

# 4) VERSION
if [[ -f "VERSION" ]]; then
  VER=$(tr -d '\r\n ' < VERSION)
  if [[ -n "$VER" ]]; then
    pass "VERSION $VER"
    if git rev-parse --git-dir >/dev/null 2>&1; then
      if git tag --list | grep -qx "v$VER"; then pass "tag v$VER exists";
      else warn "tag v$VER not found (run: git tag v$VER)"; fi
      echo "commit: $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
    fi
  else fail "VERSION empty"; fi
else warn "VERSION missing"; fi

# 5) BAML
if command -v baml >/dev/null 2>&1; then
  if baml check 2>&1 | head -n 30; then pass "BAML check"; else fail "BAML check failed"; fi
else
  if [[ -f "baml/config.baml" ]]; then warn "baml CLI not installed — baml check skipped"; else pass "no baml pipeline — skipped"; fi
fi

if [[ $FAIL -eq 0 ]]; then echo "== all PASS =="; else echo "== FAIL — fix above =="; fi
exit $FAIL
