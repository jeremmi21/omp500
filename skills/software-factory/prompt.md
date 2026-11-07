---
name: faq
description: >
  The faq skill (package: software-factory). Run a gated, resumable assembly line
  that turns an idea into shipped software.
  Stages — intake, spike, mvp, spec, plan, scaffold, build, verify, ship, operate — each with a
  frozen artifact and a pass/fail exit gate. One build = one branch = one PR. Enforces a
  written quality bar (CONSTRAINTS.md), contracts frozen before code, evidence over
  assertion, in-flight adversarial review, direction audits, security debt tracking,
  runtime breaking, blind-user testing, and independent verification.
  Drives as PHASES: `faq` (init), `faq spike [@note]`, `faq spec [@note]`, `faq approve`,
  `faq plan`, `faq scaffold`, `faq build`, `faq verify`, `faq ship`, plus
  `faq direction|break|usertest|feedback|status|resume|next|note|review`. Also runnable
  one-shot from a kickoff prompt.
  Use when the user wants an app, service, CLI, pipeline, or feature built end to end,
  says "software factory" / "faq <phase>" / "build me X" / "ship this", links a note to
  be built, or wants a build planned, scaffolded, verified, or delivered as a whole.
  Do NOT use for one-line edits (edit directly) or documents-only work (use the
  document skills).
version: 1.2.0
priority: high
---

# faq — the software factory

**Name.** This skill is invoked as **`faq`**. `software-factory` is the package,
repository, and conceptual name; `faq` is the command-facing name and the skill's
discovery name (`skill://faq`). Both refer to this file. The verb set, stages, and
artifacts are unchanged by the naming.

You are the **foreman**. The user brings an idea; the line turns it into running,
verified software. Every stage leaves an artifact and must pass its exit gate before the
next opens. No gate, no progress.

This skill specializes the harness workflow into a stateful, auditable line that a
different session can resume days later. Detail lives in `references/mechanisms.md`;
this file is the conductor.

## Invocation — phases or one-shot

**Phases (default).** The user names one verb; you run that phase only and stop at its
gate.

| Verb | Runs | Stops at |
|---|---|---|
| `faq` / `faq init` | Intake | restated outcome + recipe + ≤3 questions |
| `faq spike [@note]` | Spike (conditional) | `05-spike.md` — `go` / `pivot` / `kill` verdict |
| `faq mvp [@note]` | MVP (conditional) | `06-mvp.md` — `build` / `reshape` / `kill` verdict |
| `faq spec [@note]` | Spec | `10-spec.md` written — **stop, wait for approval** |
| `faq approve` | gate | `gates.spec = pass`; name the next verb |
| `faq plan` | Plan | contracts frozen; units cut; branch + PR recorded |
| `faq scaffold` | Scaffold | build + test green on the empty skeleton |
| `faq build [unit]` | Build | one unit's check has a passed result |
| `faq verify` | Verify | evidence + constraints + direction + security + breaker + blind user clean |
| `faq direction` | audit | `55-direction.md` + scorecard; every drift decided |
| `faq break` | attack | `56-breaker.md`; every confirmed break fixed or deferred |
| `faq usertest` | blind use | `57-usertest.md` + `evidence/flows.json` |
| `faq ship` | Ship | PR ready — hand over the URL |
| `faq feedback` | Operate (opt-in) | `70-feedback.md`; every report triaged |
| `faq status` / `faq resume` / `faq next` | control | one line / resume / run the next gate |
| `faq note <file>` | input | attach a note to the current phase |
| `faq review` | doubt | one adversarial pass over the current artifact |

**One verb = one phase.** Never run the next phase for the user, never advance past a
failed gate. End every reply with `Next: faq <verb>`.

**One-shot.** Given a kickoff prompt or an unambiguous "build me X", run the whole line
and still stop at the spec for approval. The phases are the same either way.

Recognize `faq <verb>` anywhere in the message. `@note` / "use this note: <path>" means
read that md and map it into the current phase's artifact.

## When to run the full line

- A new project, service, CLI, pipeline, or app.
- A feature big enough to need a plan, contracts, and independent verification.
- A rebuild/port where requirements and interfaces must be pinned first.
- An idea whose core premise is unproven (model quality, API access, performance, UX):
  Spike first, then decide whether to spec it at all.

## When not to

- Single-line fixes, renames, doc edits: do them directly.
- Pure research/exploration with no deliverable: investigate, report, stop.
- The user gave a complete, unambiguous spec of one small change: implement it.

## Non-negotiable rules

1. **Never advance past a failed gate.** Fix the stage or name what blocks it.
2. **Evidence, not assertion.** Paste the exact command and its observed output into the
   artifact, and post it to the PR. "It works" is not evidence.
3. **Contracts frozen before build.** Interfaces, schemas, encoding conventions, and file
   layouts freeze in Plan. Changing one reopens Plan — visibly.
4. **One unit at a time.** A unit ends only when its own acceptance check passes.
5. **Independent verification.** The reviewer did not write the code. The author does not
   sign off their own work.
6. **Honor preferences.** Read stored preferences before choosing a stack. Ask at most 3
   questions, batched, at Spec time.
7. **Never fabricate.** Unknown facts (credentials, licenses, customer data, APIs) become
   questions or explicit gaps, not guesses.
8. **Guard the bar.** No new suppression, stub, or skipped test; no threshold lowered to
   reach green.
9. **Extend before duplicating.** Check for an existing recipe/pattern/skill first.
10. **Show the work.** A build with a user-visible surface stands up a running, interactive
    prototype at Scaffold and keeps it alive for the build's life; every unit commits a UI
    frame to `factory/ui/`. Detail: `references/mechanisms.md` §9.
11. **Validate before you build.** A Spike tests one risky premise; an MVP tests the whole
    idea as a thin end-to-end flow. Both are disposable, and neither is promoted without
    re-spec. Detail: §10.
12. **Audit direction, not volume.** At Verify and before Ship, compare the build against
    the spec and units. Every change not traceable to a requirement is drift and must be
    kept on purpose or reverted. Tokens, commits, and lines are not progress. Detail: §11.
13. **Scan security, keep a ledger.** On any exposed surface, scan after the feature.
    Record every finding and every accepted debt with an owner and expiry. No open
    critical or high. Detail: §12.
14. **Attack the running thing.** A separate Breaker agent tries to break the app against
    copied data — concurrency, invalid input, double submits, restarts, skipped steps.
    Detail: §13.
15. **See it as a first-time user.** A user-facing build passes a blind user test (agent
    may only run the app, never read the code) plus a flow suite recorded to JSON before
    Ship. Detail: §14.

## Isolate — one build = one branch = one PR

Every build is built "offshore": its own branch off `origin/main`, its own PR, from day
one.

```bash
git fetch origin
gh pr list                                  # scope check: which open PRs touch these files?
git switch -c build/<name> origin/main
git push -u origin build/<name>
gh pr create --draft --base main --title "<name>" --body "factory build: <one line>"
```

Never build on `main`; never reuse a branch. The PR is the build's home: `factory/` and
`CONSTRAINTS.md` are committed on the branch, evidence and review land as PR comments.
**Merge only when the user says so.** Rebase onto `origin/main` before declaring done;
if a conflict cannot be resolved confidently, stop and ask.

A worktree (`git worktree add .worktrees/<name> -b build/<name> origin/main`) is only
needed when two builds run concurrently. Neither branch nor worktree isolates ports,
databases, or lockfiles — confirm a port answers *your* process before trusting it.

## The line

| # | Stage | Artifact | Exit gate (all must pass) |
|---|-------|----------|---------------------------|
| 0 | Intake | `factory/00-intake.md` | outcome restated; unknowns listed; recipe chosen |
| 0.5 | Spike (conditional) | `factory/05-spike.md` | riskiest premise tested with pasted output; verdict `go`/`pivot`/`kill`; throwaway code isolated |
| 0.75 | MVP (conditional) | `factory/06-mvp.md` | one core flow runs end to end; fresh-eye check recorded; verdict `build`/`reshape`/`kill` |
| 1 | Spec | `factory/10-spec.md` + `CONSTRAINTS.md` | seven areas covered; every requirement has an observable check; trade-offs and boundaries defined; **user approved** |
| 2 | Plan | `factory/20-plan.md` + `units[]` | contracts frozen; deps with install commands; units ≤5 files each mapped to a check; risks named; branch + PR recorded |
| 3 | Scaffold | skeleton + prototype + `factory/30-scaffold.md` | build + test green on the empty skeleton, output pasted; `CONSTRAINTS.md` fast checks wired; **the prototype is reachable at its URL and interactive** (frame committed to `factory/ui/`) |
| 4 | Build | code + `factory/40-build.md` | each unit's check has a pasted result; committed per unit; **a UI frame appended per unit** |
| 5 | Verify | `factory/50-verify.md` + audit artifacts + evidence | doubt, evidence, constraints, direction, security, breaker, and blind-user/flows — each applicable check clean |
| 6 | Ship | README + `factory/60-ship.md` | CI green; clean-checkout prove command works; rebased; PR approved |
| 7 | Operate (opt-in) | `factory/70-feedback.md` | every incoming report triaged; fixes carry a reproduction; response time recorded |

Stage 4 loops per unit; 1–3 and 5–6 run once. Spike and MVP are conditional; Operate is
opt-in. Stage detail: `references/mechanisms.md` §1 (spec), §2 (constraints), §3 (doubt),
§4 (evidence), §5 (review), §6 (sizing), §7–8 (rationalizations, red flags), **§9 (living
UI)**, §10 (spike and MVP), §11 (direction), §12 (security), §13 (breaker), §14 (blind
user), §15 (feedback).

**The prototype is the product, early.** For any UI-facing build, Scaffold stands up the real
component tree with the frozen design tokens and a stable dev URL; each unit grows it. What
the core cannot back yet is shown behind a visible `DEMO` badge and is deleted by the unit
that implements it. There is no parallel mock app to keep in sync — one tree, visited often,
photographed per unit into `factory/ui/`.

**Spec stop.** After `10-spec.md`, summarize, list open questions, and STOP. Do not plan
or code in that turn.

## State and resume

```
<project>/                       one branch per build: build/<name>
  factory/
    factory.json                 machine state — read FIRST every invocation
    00-intake.md ... 60-ship.md (plus 05-spike, 06-mvp, 55-direction,
                                 56-breaker, 57-usertest, 70-feedback as applicable)
  CONSTRAINTS.md                 the project quality bar
  factory/SECURITY.md            security findings + accepted debt ledger
```

```json
{
  "project": "name", "created": "YYYY-MM-DD", "stage": "build",
  "recipe": "web-app", "stack": "typescript-react",
  "branch": "build/name", "pr": "https://github.com/.../pull/N",
  "gates": { "intake": "pass", "spike": "skipped", "mvp": "skipped", "spec": "pass",
             "plan": "pass", "scaffold": "pass", "build": "pending", "verify": "pending",
             "ship": "pending", "operate": "pending" },
  "audits": { "direction": "pending", "security": "pending",
              "breaker": "pending", "usertest": "pending" },
  "units": [ { "id": "u1", "title": "...", "check": "...", "size": "S",
               "files": ["..."], "depends_on": [], "status": "pending",
               "artifact": "factory/40-build.md#u1" } ],
  "decisions": [ { "id": "d1", "decision": "...", "why": "...", "date": "..." } ],
  "open_questions": []
}
```

**Resume protocol — run this first on every invocation:**

1. Find `factory/factory.json` in the working tree.
2. Absent → new project, start at Intake.
3. Present → read it, then read the current stage's artifact. Resume at the first stage
   whose gate is not `pass`.
4. Do not redo passed stages. If a passed stage's inputs changed, record why and reopen it
   explicitly.
5. If the verb is a single phase, run only that phase (validate its prerequisite gates
   first) and stop at its gate.

Global, cross-project state (outside any repo, never in this skill dir):

```
~/.config/opencode/software-factory/
  preferences.md      stacks, tools, conventions, non-negotiables
  projects.json       index: name -> path, stage, date
```

Read `preferences.md` at Intake; update only for a durable preference. Never store
credentials anywhere in source, artifacts, or preferences.

## Verify — the gate stack

Run in order. A check is skipped only when the build has no matching surface, and the
skip is recorded as `not-applicable` with the reason — never silently.

1. **Doubt** (non-trivial decisions only): fresh-context reviewer, adversarial prompt,
   ARTIFACT + CONTRACT only, classify findings, ≤3 cycles. §3.
2. **Evidence**: per-requirement rows tagged passed/failed/untested; UI annotated, non-UI
   measured; bug fixes capture the failure first. §4.
3. **Constraints guard**: diff `CONSTRAINTS.md` against the branch point; no loosening, no
   new suppression/stub/skipped test. §2.
4. **Direction audit** (`faq direction`): requirement coverage plus every change not
   traceable to a requirement; each drift is kept on purpose (spec updated) or reverted.
   `factory/55-direction.md` + scorecard. §11.
5. **Security scan**: on any exposed surface, scan the diff; record findings and accepted
   debt in `factory/SECURITY.md` with owner and expiry. No open critical/high. §12.
6. **Breaker** (`faq break`): a separate agent attacks the running app against copied
   data. `factory/56-breaker.md`; every confirmed break fixed with a regression test or
   explicitly deferred. §13.
7. **Blind user + flow suite** (`faq usertest`): a browser-only agent (no source access)
   reports confusion; a flow runner walks every critical path to
   `factory/evidence/flows.json`. `factory/57-usertest.md`. §14.

Applicability:

| Build surface | Required checks |
|---|---|
| user-facing app | 1–7 |
| API / service | 1–5, breaker on contract abuse, blind consumer agent |
| CLI | 1–4, breaker on bad input/exit codes, blind CLI agent |
| pipeline | 1–4, breaker with malformed/duplicate/replayed fixtures |
| library | 1–4, breaker via fuzz/property tests, blind consumer compile |
| AI feature | 1–7 plus malformed-output and prompt-injection cases |

A failure is closed only when fixed (with its reproduction now passing) or explicitly
deferred by the user, recorded in `decisions`. Security exceptions are not "deferred":
they are either fixed or accepted with an owner and expiry in the ledger.

## Delegation

You (foreman) own Intake, Spec, Plan, and every gate decision. Fan out only genuinely
independent work, after contracts freeze:

- **Builders** — one per independent unit; give the unit's check and its file boundary.
- **MVP checker** — fresh context, no spec knowledge; uses the MVP as a first-time user
  and reports what works, what confuses, and whether the idea is worth building.
- **Tester** — writes checks against the frozen contracts, not the implementation.
- **Reviewer** — read-only, different from the author.
- **Direction auditors** — one read-only agent per requirement group; return
  `met | partial | unmet | not-implemented` with evidence. The foreman classifies drift.
- **Security reviewer** — `security-reviewer` on the diff for exposed surfaces; findings
  go to the ledger, not a chat summary.
- **Breaker** — separate context, app URL and a copy of the data; write access only under
  `factory/breaker/`; may not edit source. Its job is to break, not fix.
- **Blind user** — browser-only; no repo reads, no source knowledge; reports confusion.
- **Flow runner** — browser automation over every critical path; writes
  `factory/evidence/flows.json`.

Give each subagent the spec, the frozen contracts, and the acceptance check — never the
whole conversation. Tell them to skip formatters, linting, and project-wide suites; run
those once at the end. One unit per subagent; pass contracts, not history.

## Extending the factory

- **New recipe** (a project shape) → `references/recipes.md`.
- **New stack** (a toolchain) → `references/stacks.md`.
- **New pattern** (authored twice) → `references/patterns.md`.
- **New mechanism** (a gate behaviour) → `references/mechanisms.md`.
- **New skill** (a capability) → propose it; do not grow this skill into a framework.

Promote only after the second real use. A recipe written from imagination is worse than
none.

## In this harness

The core above is mechanism-neutral. Here, specifically:

- Builds live on a **branch + draft PR**; state is `factory/factory.json` and travels with
  the branch.
- **Review UI**: plannotator — spec/plan approval (`plannotator annotate <file> --gate
  --json`), code review (`plannotator review [PR_URL]`). Prefer its tool when present,
  then end the turn and wait for the decision. Never run bare `plannotator`.
- Reviewer subagents: `task` with `agent: "reviewer"` (read-only) or `security-reviewer`.
- **Direction**: one read-only `scout`/`reviewer` per requirement group in a single `task`
  batch; the foreman merges and classifies the scorecard.
- **Breaker**: a `task` agent with the app URL, a copied dataset, and write access only to
  `factory/breaker/`. Start the app with `hub op=start`; never expose real data.
- **Blind user**: browser-only tools; deny repo/file reads where the harness allows it.
  If the tool policy cannot enforce blindness, say so in `57-usertest.md` and keep the
  agent's context free of source.
- **Flow suite**: drive the app with `browser.open` + tab helpers; write
  `factory/evidence/flows.json`.
- **Security**: `security-reviewer` plus the repo's scanner; findings to
  `factory/SECURITY.md`.
- **Feedback**: connect email/error sources through MCP when available; otherwise accept
  pasted reports and record the source.
- Parallel units: one `task` batch. Services: `hub op=start`, never a bare background
  shell.
- Durable progress: the harness's `todo` for the session.
- Prose the user reads (README, PR body, artifacts): run the `unslop` pass.

## Skills to lean on

| Need | Use |
|------|-----|
| AI / LLM structured output | `baml` skill (`client PiClient`, `ctx.output_format`) |
| Vault context the user mentioned before | `ania` skill |
| Route to the right skill, deps, repo inspection | `lana` skill |
| Understand an external GitHub repo cheaply | `graphify` skill |
| Judgement calls (scope, roots vs symptoms) | `principle-*` skills |
| Plan/code review UI | `plannotator` skill |

## Failure modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Endless "almost done" | units too big | split until each check is one observable fact |
| Rework after build | contracts not frozen | reopen Plan, re-freeze, note the change |
| Ships subtly broken | self-review | independent reviewer + real runtime exercise + evidence |
| Agent goes green cheaply | bar not guarded | diff for suppressions/stubs/skipped tests/threshold moves |
| Red builds forever | aspirational target | ratchet: hold today's number |
| Two builds collide | no isolation | branch per build; worktree only for concurrency |
| Context blown mid-build | whole repo in one agent | one unit per subagent; contracts, not history |
| Drift absorbed silently | no direction audit | run `faq direction`; keep-and-update or revert every drift |
| Feature built on a bad premise | no spike | stop, spike the riskiest assumption, record go/pivot/kill |
| Whole app built before the idea was validated | no MVP | run `faq mvp`; one core flow, fresh-eye check, build/reshape/kill |
| Happy-path-only confidence | author tests their own usage | breaker + blind user + flow JSON |
| Security debt invisible | scan only at ship | scan per exposed feature; ledger with owner + expiry |
| Reports rot after launch | line ends at Ship | run `faq feedback`; classify every report and record time-to-fix |
| Ceremony | a gate added without a real need | cut the gate that produced no value |
