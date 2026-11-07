# OMP500 — your OMP, portable

One repo to recreate your OMP on any device. Clone, run one script, and both you and your agent are set up.

> **Agent?** Jump to [Agent bootstrap contract](#agent-bootstrap-contract) — that's your install prompt.

## Human quickstart (UX — 2 minutes)

```bash
git clone https://github.com/<you>/omp500.git
cd omp500
cp settings/secrets.example.env .env   # fill in keys when asked, never commit .env
bash scripts/install.sh                # installs deps + BAML client + registers skills
bash scripts/verify.sh                 # prints PASS/FAIL per check
```

That's it. Same skills, same pipeline on this device and the next. Update later with `bash scripts/update.sh` or tell your agent "refresh OMP500".

**Windows:** use Git Bash (comes with Git for Windows) for the bash commands, or run `scripts\install.bat` which wraps the same steps.

## What's inside

```
omp500/
├── skills/registry.json        ← the master list (48 skills on this build)
├── skills/<name>/              ← one folder per skill: manifest.yaml + prompt.md
├── skills/_template/           ← copy this to add a skill
├── baml/                       ← pipeline.baml, types.baml, clients.baml
├── settings/                   ← config.yaml + secrets.example.env (placeholders only)
├── scripts/                    ← install.sh / update.sh / verify.sh (idempotent)
└── VERSION                     ← 500.1.0 + git tag v500.1.0
```

48 skills registered — union of what's installed (`~/.agents/skills`, 27) and what's locked in `skills-lock.json` (32):

| category | skills |
|---|---|
| hyperframes/media | algorithmic-art, captions-overlay, changelog-video, cut-the-curve, embedded-captions, faceless-explainer, figma, general-video, gsap-timeline, hyperframes, hyperframes-animation, hyperframes-audio, hyperframes-cli, hyperframes-core, hyperframes-creative, hyperframes-keyframes, hyperframes-registry, media-use, motion-doctrine, motion-graphics, music-to-video, oversized-cursor, pr-to-video, product-launch-video, remotion-to-hyperframes, seam-craft, slideshow, talking-head-recut |
| egm | egm, egm-brainstorm, egm-draft, egm-resolve, egm-review |
| review | plannotator, plannotator-annotate, plannotator-last, plannotator-review |
| visual | anatomy |
| writing | make-revision |
| ui | makeuicute |
| quant | monster-alphas, wq-alpha-research |
| dev-tool | codebase-design, find-skills, leanrea, prototype, software-factory, ui-demo |

Stubs (no `SKILL.md` on source device — source shown in manifest): `algorithmic-art`, `captions-overlay`, `changelog-video`, `codebase-design`, `cut-the-curve`, `embedded-captions`, `faceless-explainer`, `figma`, `find-skills`, `general-video`, `gsap-timeline`, `leanrea`, `motion-doctrine`, `music-to-video`, `oversized-cursor`, `pr-to-video`, `product-launch-video`, `remotion-to-hyperframes`, `seam-craft`, `slideshow`, `talking-head-recut`. Install stubs with `npx skills add <source> --skill <name>` then re-copy `SKILL.md` → `skills/<name>/prompt.md`.

## After install

- **Use skills:** your agent discovers them from `skills/registry.json` — no hardcoded names in BAML. Tell it "use `anatomy` to draw..." or "run `make-revision`".
- **Add a skill (DX):** `cp -r skills/_template skills/my-skill`, fill `manifest.yaml` + `prompt.md`, add one entry to `skills/registry.json`, bump `VERSION`, `git tag v500.x.y && git push`.
- **Stay in sync:** `bash scripts/update.sh` does `git pull --ff-only` → re-reads registry → diffs → re-registers → re-applies `settings/`/`baml/` → `verify.sh` → prints changelog + commit.

## Repo is source of truth

If this README and the repo disagree, the repo wins. `INSTALL.md` is the full step-by-step. Secrets are always placeholders — the scripts ask you for real values.

---

## Agent bootstrap contract (AX — copy-paste for a fresh agent)

> You are installing OMP500 from GitHub. The repo at `https://github.com/<you>/omp500` (branch `main`) is source of truth.

1. `git clone https://github.com/<you>/omp500.git && cd omp500`
2. Read `README.md` and `INSTALL.md` fully before acting.
3. `cp settings/secrets.example.env .env` — if `.env` is missing, prompt the human for values; never invent secrets, never commit `.env`.
4. `bash scripts/install.sh` — installs dependencies, BAML client, validates `settings/config.yaml`, registers every skill in `skills/registry.json`.
5. Load `skills/registry.json` (authoritative list, 48 entries). For each entry, load `skills/<name>/manifest.yaml` + `prompt.md`. Verify: count equals `settings/config.yaml` `expected_skill_count`, every folder exists, folder name equals `name`. On mismatch, stop and report missing/duplicate/orphan names — do not silently drop.
6. `bash scripts/verify.sh` — must report PASS for: config valid, BAML compiles, registry valid, each skill present, VERSION matches tag.
7. Report: install status, skill count by category, BAML pipeline health, version/commit, gaps needing human input.

**Self-update (on "refresh OMP500" or `scripts/update.sh`):** `git pull --ff-only` → re-read `registry.json` → diff vs loaded set → register new / flag removed → re-apply `settings/` + `baml/` if changed → `verify.sh` → report changelog (added/removed skills, changed configs, commit hash). If repo and prompt disagree, follow the repo.

**Registry entry shape:** `name, description, category, triggers, inputs, outputs, dependencies, model, prompt_file, version, source` — see `skills/registry.json`.
