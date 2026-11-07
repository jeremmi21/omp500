#!/usr/bin/env bash
set -euo pipefail
# OMP500 install — idempotent. Run from repo root or scripts/.
# UX: one command. AX: agent runs this after cloning.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

pass(){ echo "[PASS] $*"; }
warn(){ echo "[WARN] $*"; }
fail(){ echo "[FAIL] $*"; exit 1; }
find_node(){
  if command -v node >/dev/null 2>&1; then command -v node; return 0; fi
  for p in "/c/Program Files/nodejs/node.exe" "/c/Program Files/nodejs/node" "/c/Users/zhy3o/AppData/Local/pi-node/current/node.exe" "/c/Users/zhy3o/AppData/Local/pi-node/current/node" "/mnt/c/Program Files/nodejs/node.exe"; do
    if [[ -x "$p" ]]; then echo "$p"; return 0; fi
  done
  echo "node"
}
NODE_BIN="$(find_node)"

echo "== OMP500 install ==" ; echo "root: $ROOT"
echo "node: $NODE_BIN ($("$NODE_BIN" --version 2>&1 || echo 'not found'))"

# 0) prereqs
command -v git >/dev/null 2>&1 || fail "git not found"
"$NODE_BIN" --version >/dev/null 2>&1 || warn "node not found — npx skills + verify will be limited"
if ! command -v bash >/dev/null 2>&1; then warn "bash not found"; fi

# 1) config + registry must be valid JSON/YAML (light check via node)
"$NODE_BIN" -e "
const fs=require('fs');
try{ JSON.parse(fs.readFileSync('skills/registry.json','utf8')); console.log('[PASS] registry.json valid JSON'); }catch(e){ console.error('[FAIL] registry.json invalid: '+e.message); process.exit(1); }
try{
  const t=fs.readFileSync('settings/config.yaml','utf8');
  if(!t.includes('expected_skill_count')) throw new Error('missing expected_skill_count');
  console.log('[PASS] settings/config.yaml present');
}catch(e){ console.error('[FAIL] config.yaml: '+e.message); process.exit(1); }
"

# 2) .env from template if missing
if [[ ! -f ".env" ]]; then
  if [[ -f "settings/secrets.example.env" ]]; then
    cp "settings/secrets.example.env" ".env"
    warn "created .env from settings/secrets.example.env — fill in real keys before using LLM calls"
  else
    warn "no settings/secrets.example.env and no .env — LLM calls will fail until you create .env"
  fi
else
  pass ".env exists"
fi

# 3) BAML client — best-effort
if command -v baml >/dev/null 2>&1; then
  echo "baml CLI found: $(baml --version 2>&1 | head -n1)"
  if [[ -f "baml/config.baml" ]]; then
    baml generate 2>&1 | head -n 20 || warn "baml generate failed — check baml/config.baml"
  fi
elif [[ -f "baml/config.baml" ]]; then
  warn "baml CLI not installed — skipping baml generate (install with: pip install baml-py or see baml-agents/README.md)"
fi

# 4) register skills from registry.json -> ~/.agents/skills/<name>/SKILL.md
#    AX: the agent discovers from registry; this step makes them usable locally too.
SKILLS_DIR="${HOME}/.agents/skills"
mkdir -p "$SKILLS_DIR"

"$NODE_BIN" <<'NODE'
const fs=require('fs'), path=require('path');
const ROOT=process.cwd();
const reg=JSON.parse(fs.readFileSync(path.join(ROOT,'skills/registry.json'),'utf8'));
const outBase = path.join(process.env.HOME||process.env.USERPROFILE||'.', '.agents','skills');
let ok=0, stub=0;
for(const e of reg){
  const srcPrompt = path.join(ROOT, e.prompt_file);
  const dstDir = path.join(outBase, e.name);
  const dstSkill = path.join(dstDir, 'SKILL.md');
  if(!fs.existsSync(srcPrompt)){ console.log(`[WARN] missing prompt for ${e.name}: ${e.prompt_file}`); continue; }
  const content = fs.readFileSync(srcPrompt,'utf8');
  const isStub = content.includes('Stub — SKILL.md not present');
  if(isStub){ stub++; console.log(`[WARN] stub ${e.name} — install source: ${e.source||'unknown'} (npx skills add ...)`); continue; }
  fs.mkdirSync(dstDir,{recursive:true});
  fs.writeFileSync(dstSkill, content);
  ok++;
}
console.log(`[PASS] registered ${ok} skills to ${outBase} (${stub} stubs skipped — see README for npx skills add)`);
NODE

echo ""
echo "== verify =="
bash scripts/verify.sh || true
echo ""
echo "done — run: bash scripts/verify.sh"
