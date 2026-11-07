---
name: egm
description: "Elephant-Goldfish Model (EGM) design workflow for AI agents: brainstorm a feature into a concept brief, draft a design spec with full project context (elephant), then stress-test it with fresh zero-context reviewer subagents (goldfish). Use when a feature needs design decisions before code, when asked to brainstorm/draft/review a design doc or spec, when checking checked-in docs against the code, or when bootstrapping docs for an existing codebase. Triggers on: EGM, elephant goldfish, design draft, concepts_brief.md, design_draft.md, goldfish review."
---

# Elephant-Goldfish Model (EGM)

Plugin root (all paths below are relative to it):
`C:/Users/zhy3o/.agents/skills/egm/`

Read the sub-skill file before running it. They are the upstream upstream files, unmodified.

| Skill | File | Use it to |
| --- | --- | --- |
| Brainstorm | `skills/egm_brainstorm/SKILL.md` | Turn a half-baked idea into `concepts_brief.md` |
| Draft | `skills/egm_draft/SKILL.md` | Turn brief/notes into a section-by-section design document |
| Review | `skills/egm_review/SKILL.md` | Five-phase Goldfish review of a draft |
| Resolve | `skills/egm_resolve/SKILL.md` | Work through review findings to agreed changes |
| Review loop | `skills/egm_review_loop/SKILL.md` | Run a configured reviewer group for one review task |
| Bootstrap | `skills/egm_bootstrap/SKILL.md` | Create/update docs for an existing codebase |
| Drift report | `skills/egm_drift_report/SKILL.md` | Compare checked-in documents against current source |

Reviewer personas: `agents/*.md`. Document standards: `resources/document_standards/*.md`.

## Harness mapping (this harness: omp)

Where a sub-skill says "spawn a subagent":

- Tool: `task`, `agent: "task"` (general-purpose). Goldfish reviewers need a fresh context, so never review a draft in this conversation.
- Personas are not registered by name here: the subagent's first instruction is
  `Read C:/Users/zhy3o/.agents/skills/egm/agents/<persona>.md and follow it.` then the review target and file list.
- Nesting is available, so the synthesizer phase runs as upstream describes rather than direct dispatch.
- `${CLAUDE_PLUGIN_ROOT}` in upstream text resolves to the plugin root above. Read `docs/harnesses.md` only if a sub-skill's harness branch matters.

Artifact directory: relative paths resolve against the current working directory unless the prompt says otherwise; add `EGM artifact directory: <path>` to the request to redirect.

## Limits

Upstream ships this as a plugin for Antigravity, Claude Code, Codex, Cowork, and ChatGPT; none of those CLIs are installed on this machine, so this directory is the install. Plugin cloning/updating: `git -C C:/Users/zhy3o/.agents/skills/egm pull`.
A review is not a substitute for tests or human approval.
