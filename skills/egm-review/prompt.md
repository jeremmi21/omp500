---
name: egm-review
description: "EGM Review: five-phase Goldfish review (zoom out, comprehension, design critique, intermediate zoom out, implementation readiness) of a design document with fresh zero-context reviewer subagents. Use when a draft or spec needs stress-testing before code."
---

Read `C:/Users/zhy3o/.agents/skills/egm/skills/egm_review/SKILL.md` and follow it verbatim.

- Plugin root: `C:/Users/zhy3o/.agents/skills/egm/` (`${CLAUDE_PLUGIN_ROOT}` and `../../` paths resolve there).
- Goldfish subagents: `task` with `agent: "task"`; instruct each one to read `C:/Users/zhy3o/.agents/skills/egm/agents/<persona>.md` first, then the target doc and its referenced files. Never review a draft in this conversation.
- Document standards: `C:/Users/zhy3o/.agents/skills/egm/resources/document_standards/`.
