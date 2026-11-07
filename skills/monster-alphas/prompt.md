---
name: monster-alphas
description: "Use when starting or resuming an alpha generation session on the local WorldQuant BRAIN harness: read the quota and the queue, pick a signal family, preview templates free, queue one-point tasks, read the verdicts, and update the report. Triggers: build alphas, generate templates, run the alpha pipeline, monster alphas, WQB session, alpha harness."
---

# Monster Alphas — the session procedure

The harness runs at `http://127.0.0.1:1234` and owns the account, the quota and the alphas.
Everything here is a thin loop over its own API. **Nothing in this skill submits an alpha.**

Working folder: `C:/Users/zhy3o/Documents/1design/linework/Build/8080/alphas/build/build/`

## Start here, every session

```bash
python pipeline.py next
```

That prints the quota, the tasks in flight, the claim and expression counts, and the one action
the state implies. `pipeline.py status` prints the same without the recommendation;
`pipeline.py verdicts` prints every finished task with its checks and the claim it came from.

If the harness does not answer, start it with `webui/serve.bat` and wait for the dashboard.

## The loop

1. **Pick the signal family first.** This is the decision that matters. Measured on 24 templates:
   `leverage`, `cash flow / cap` and `reporting currency` were green at two or three constraint
   levels; `ROE`, `asset turnover` and `capex − leverage` at none or one. Normalisation and gating
   move a family by a check or two, never from dead to green.

2. **Write the template as one line of Fast Expression.** `x = ...;` lines name the steps, the
   last line is the alpha. Save it as a `.txt` under `corpus/templates/` so it has an address.

   ```bash
   printf 'x = group_rank(ts_rank(ts_backfill(fnd6_currencya_curcd, 120), 240), densify(subindustry)); x\n' \
     > corpus/templates/t04-currency.txt
   ```

3. **Preview free.** The preview is the only validator that matters: it rejects unknown fields,
   unknown operators and missing settings in the platform's own words, and returns how many
   combinations the template would search.

   ```bash
   python gen_template.py corpus/templates/t04-currency.txt --claim "rare reporting currency"
   ```

   A claim names **one point**, so `combinations` must be 1. The script refuses a sweep unless
   `--search-ok` is passed.

4. **Queue it.** Adding a task is free; it sits at `IDLE`.

   ```bash
   python gen_template.py corpus/templates/t04-currency.txt --claim "rare reporting currency" --create
   ```

   The trial is appended to `corpus/trials.jsonl`, which is what later joins the verdict back to
   the sentence that produced it.

5. **Run it.** One point, one simulation: `simulations=1`. A single-point template run at
   `simulations=10` produced 16 draws, 15 cache hits and a stop — do not do that.

   ```bash
   curl -s -X POST -H "X-Harness-Client: 1" http://127.0.0.1:1234/api/lab-tasks/<id>/run
   ```

   Or press Run in Tasks. Batch size is 1; two tasks run at a time.

6. **Read the verdict.**

   ```bash
   python pipeline.py verdicts
   ```

   Each check carries its own `limit` **for that configuration**. Read limit and value together;
   never compare against a table.

## The four slots

| Slot | Decision | Bound by | Range that passed |
|---|---|---|---|
| Signal | what is scored, and its sign | `LOW_SHARPE`, `SELF_CORRELATION` | fundamental or analyst field |
| Normalizer | `rank` / `group_rank(·, subindustry)` | `CONCENTRATED_WEIGHT` | all 24 passed |
| Clock | window + `decay` | `HIGH_TURNOVER`, `LOW_FITNESS` | turnover 1.5–30% |
| Gate | `trade_when(rank(volume*close) > 0.2, ·, -1)` | `LOW_SUB_UNIVERSE_SHARPE` | moved 0.71 → 0.86 |

Fitness is `Sharpe × sqrt(|returns| / max(TO, 0.125))`, so the clock decides whether a good
signal can be submitted. Set decay before writing the expression.

`decay`, `truncation`, `pasteurization`, `nan_handling` and `test_period` are **task-level
scalars**: a template cannot vary them per alpha. Settings advice belongs to Settings Sampler.

## Failure → slot

| Failing check | Change |
|---|---|
| `LOW_SHARPE` | signal: different field or idea, not the window |
| `LOW_FITNESS` | clock: raise decay |
| `HIGH_TURNOVER` | clock: raise decay |
| `LOW_TURNOVER` | clock: shorter window, faster field |
| `CONCENTRATED_WEIGHT` | normalizer: `rank`, lower truncation, `ts_backfill` |
| `LOW_SUB_UNIVERSE_SHARPE` | gate: liquidity filter; it saturates around 0.86 |
| `SELF_CORRELATION` | signal: new field or idea; parameter tweaks do not move it |
| `PROD_CORRELATION` | signal; only appears at submission |

## Gates that are not preferences

- **Preview before any task.** A typo caught by the preview is free; caught by the queue it costs
  simulations.
- **One claim, one simulation.** See step 5.
- **Never above `cores: 4`** without reading the account's own limit. `gen_template.py` defaults
  to 4; the server's default is 8.
- **Stop under 50 simulations left.** The quota is 1,800/day and does not roll over.
- **Never submit, never store credentials.** Submission is a hand action on the platform; the
  harness keeps the key sealed.
- **One field family per batch.** Self-correlation is a property of the bet, not the syntax.

## Where things live

| Path | What |
|---|---|
| `pipeline.py` | `status` / `verdicts` / `next` |
| `gen_template.py` | one template → free preview → optional IDLE task |
| `make_templates.py` | the four-slot model, 24 templates, previews only |
| `harvest.py` | expressions out of a folder of cloned repos, previewed free |
| `corpus/claims.jsonl` | 191 forum claims: kind, text, said_by, quote, thread, status |
| `corpus/expressions.jsonl` | 217 mined expressions with the sentence each sat next to |
| `corpus/templates/` | the templates themselves, one `.txt` each |
| `corpus/trials.jsonl` | template → task → claim, appended on `--create` |
| `docs/MONSTER-ALPHAS.md` | the report: model, evidence, research, consulting notes |
| `docs/alpha-curriculum.pen` | the visual curriculum, 17 slides, with `docs/shots-curriculum/` |

## What a finished session looks like

A new template that previews clean, one simulation spent on it, its verdict read, and the report
or the claim store updated with what the verdict said. A green alpha is a by-product, not the
goal: the goal is that the next template is better informed than the last one.
