# INSTALL — OMP500 on a fresh device

This is the full procedure. `README.md` is the 30-second version; this file is the one you follow.

## 0) Prereqs

- **Git** — `git --version`
- **Node 20+** — `node --version` (for `npx skills` and BAML checks)
- **Bash** — macOS/Linux has it. Windows: use **Git Bash** (installed with Git for Windows) or run `scripts\install.bat` instead.
- **Python 3.10+** optional — only for `baml-agents` pipeline if you use it locally.

> Windows note: all `bash scripts/*.sh` commands below assume Git Bash. If you double-click `install.bat`, it does the same thing with no terminal typing.

## 1) Clone

```bash
git clone https://github.com/jeremmi21/omp500.git
cd omp500
```

Repo: https://github.com/jeremmi21/omp500 — branch `main`. Branch is `main`.

If the repo is private, Git will prompt for auth (or use `gh auth login`).

## 2) Secrets (placeholders only)

```bash
cp settings/secrets.example.env .env
# open .env and fill in real keys
```

The repo never contains real keys. `settings/secrets.example.env` lists every key the setup needs as `KEY=placeholder`. `.env` is gitignored. If you skip this, `install.sh` will create `.env` from the template and prompt you.

## 2b) Adding an OpenCode API key by hand

Two programs on a device can use an OpenCode key and they read it from **different places**.
Neither needs the OpenCode console. Provider id: `opencode-go`.

| Program | Where the key lives | Hand-editable |
|---|---|---|
| omp | `~/.omp/agent/agent.db` → table `auth_credentials` | **no** — SQLite (WAL); write via `omp auth import` |
| OpenCode CLI | `~/.local/share/opencode/auth.json` | yes — plain JSON |

### omp, persistent

Write a file — say `creds.json` — then import it and delete it:

```json
{
  "version": 1,
  "credentials": [
    {
      "provider": "opencode-go",
      "credential": { "type": "api_key", "key": "sk-..." }
    }
  ]
}
```

```bash
omp auth import creds.json   # Imported 1 credential(s) for opencode-go.
rm creds.json                # it held a live secret
```

Import **merges**: existing keys stay. If an older `opencode-go` entry is already stored, it can
win round-robin and the new key appears unused. Check with `omp auth export` before adding.

### omp, one process

```bash
OPENCODE_API_KEY=sk-... omp
```

Nothing is stored. `omp --api-key=sk-...` does the same for a single invocation.

### OpenCode CLI

Edit `~/.local/share/opencode/auth.json` and set the `opencode-go` entry:

```json
{ "opencode-go": { "type": "api", "key": "sk-..." } }
```

**The two stores spell the type differently** — `api_key` in omp's import JSON, `api` in
`auth.json`. Swapping them is the usual cause of a key that "does nothing".

### Verify

```bash
omp token opencode-go          # the key omp will actually use
omp auth export                # whole credential store, as JSON
omp models | grep opencode-go  # provider listed, with its model count
```

Never write a real key into a tracked file. `verify.sh` fails the build if one appears anywhere
in the repo; `.env` is the only place a key belongs, and it is gitignored.


## 3) Install

```bash
bash scripts/install.sh
```

What it does, in order:

1. Checks `git`, `node`, `bash` are present.
2. Validates `settings/config.yaml` and `skills/registry.json` (valid YAML/JSON, required fields).
3. Ensures `.env` exists (copies template if missing) and asks for missing values — never invents them.
4. Sets up BAML client: if `baml_src/` or `baml/` contains a `baml` CLI, runs `baml generate` or `pip install baml-agents` as configured. Skips gracefully if BAML isn't needed on this device.
5. Registers skills from `skills/registry.json`:
   - For each entry, copies `skills/<name>/prompt.md` (+ `manifest.yaml`) into your local skills dir (`~/.agents/skills/<name>/SKILL.md`) or, if `npx skills` is available, runs `npx skills add <source> --skill <name>` for locked stubs.
   - Idempotent — running again re-copies without duplicating, missing stubs are reported not silently skipped.
6. Runs `scripts/verify.sh` and prints a report.

On success you see `PASS` per check plus `version 500.x.y @ <commit>`.

## 4) Verify

```bash
bash scripts/verify.sh
```

Expected output:

```
[PASS] config.yaml valid
[PASS] secrets.example.env has no real keys
[PASS] registry.json valid (48 entries)
[PASS] each skill folder present (manifest.yaml + prompt.md)
[PASS] skill count 48 matches expected 48
[PASS] VERSION 500.1.0 matches tag v500.1.0
[PASS] BAML compiles  (or [WARN] baml CLI not installed — skipped)
```

If any check is `FAIL`, it names the file or skill. Fix it, re-run `verify.sh`.

## 5) Agent bootstrap (AX)

Give a fresh agent this prompt (also in `README.md` under Agent bootstrap contract):

> Clone `https://github.com/jeremmi21/omp500` on `main`, read `README.md` + `INSTALL.md`, copy `settings/secrets.example.env` → `.env` and prompt for values, run `scripts/install.sh`, load `skills/registry.json` (48 entries) and each `skills/<name>/manifest.yaml` + `prompt.md`, check count and folder/name match, run `scripts/verify.sh`, report install status + skill count by category + BAML health + version/commit.

The agent treats the repo as source of truth — if this prompt and the repo disagree, it follows the repo and notes the conflict.

## 6) Stay in sync (update)

On any device that's behind `main`:

```bash
bash scripts/update.sh
# or tell the agent: "refresh OMP500"
```

This runs `git pull --ff-only` → re-reads `registry.json` → diffs against installed set → registers new / flags removed → re-applies `settings/` + `baml/` if changed → re-runs `verify.sh` → prints a changelog with commit hash.

It stops before overwriting local changes — commit or stash them first.

## 7) Add a new skill (DX)

```bash
cp -r skills/_template skills/my-skill
# edit skills/my-skill/manifest.yaml + prompt.md
# add one entry to skills/registry.json
# bump VERSION, commit, tag, push
```

`skills/registry.json` is the only list. The BAML pipeline reads it — no hardcoded skill names in BAML.

```bash
# version bump
echo "500.1.1" > VERSION
git add skills/registry.json skills/my-skill VERSION CHANGELOG.md
git commit -m "feat(skills): add my-skill"
git tag v500.1.1
git push && git push --tags
```

Other devices pick it up on next `update.sh`.

## Troubleshooting

| symptom | fix |
|---|---|
| `bash: command not found` on Windows | Use Git Bash, or run `scripts\install.bat` |
| `registry.json: count 48 but expected 67` | `settings/config.yaml` stores `expected_skill_count`. 48 is current union (installed+locked). If you're aiming for 67, add the remaining skills then bump `expected_skill_count` and `VERSION`. |
| `FAIL skill <name>: prompt.md missing` | Locked stub — run `npx skills add <source> --skill <name>` (source shown in `manifest.yaml` / `registry.json` `source`), then copy `~/.agents/skills/<name>/SKILL.md` → `skills/<name>/prompt.md` |
| `FAIL VERSION mismatch` | `VERSION` file and git tag must agree: `git tag v$(cat VERSION)` |
| `FAIL secrets: real key found` | You committed a real key — `git restore` the file, rotate the key, re-check |
| `git pull --ff-only` refuses | You have local edits: `git stash` → `bash scripts/update.sh` → `git stash pop` |

Questions: open an issue or run `bash scripts/verify.sh` and paste the output.
