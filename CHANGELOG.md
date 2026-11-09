# Changelog

## Unreleased

- Docs: `INSTALL.md` §2b — adding an OpenCode API key by hand, for both omp (`omp auth import`,
  `OPENCODE_API_KEY`) and the OpenCode CLI (`auth.json`). Placeholders only; no key material.
- Secrets template: `OPENCODE_API_KEY` listed as a commented placeholder.
- `verify.sh`: new check — fails when a real key appears in any tracked file, not just in the
  secrets template.

## 500.1.0 — 2026-11-07

- Initial OMP500 build: 48 skills from `~/.agents/skills` (27) + `skills-lock.json` (32), deduped union.
- Registry: `skills/registry.json` as single source of truth; BAML pipeline discovers from it.
- BAML: `baml/` scaffold with `clients.baml`, `pipeline.baml`, `types.baml` (see `baml-agents/baml_src` for legacy source).
- Scripts: `install.sh` / `update.sh` / `verify.sh` + Windows `install.bat`.
- Docs: `README.md` (agent bootstrap contract) + `INSTALL.md`.

