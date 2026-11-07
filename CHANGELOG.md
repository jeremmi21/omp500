# Changelog

## 500.1.0 — 2026-11-07

- Initial OMP500 build: 48 skills from `~/.agents/skills` (27) + `skills-lock.json` (32), deduped union.
- Registry: `skills/registry.json` as single source of truth; BAML pipeline discovers from it.
- BAML: `baml/` scaffold with `clients.baml`, `pipeline.baml`, `types.baml` (see `baml-agents/baml_src` for legacy source).
- Scripts: `install.sh` / `update.sh` / `verify.sh` + Windows `install.bat`.
- Docs: `README.md` (agent bootstrap contract) + `INSTALL.md`.

