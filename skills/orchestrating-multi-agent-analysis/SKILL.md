---
name: orchestrating-multi-agent-analysis
description: Use when the user explicitly asks for multi-agent, multi-subagent, or six-agent review or divergent analysis of the same target, such as 多子代理审查, 多代理审查, 六代理审查, 多子代理评审, 多代理评审, 六代理评审, 多子代理发散分析, 多代理发散分析, 六代理发散分析, multi-agent review, multi-subagent review, or multi-agent divergent analysis.
---

# Orchestrating Multi-Agent Analysis

## Overview

Use this skill to run a disciplined six-subagent analysis loop over one target artifact, decision, plan, or question. It has two modes:

- `review`: stress-test a concrete plan or artifact.
- `divergent-analysis`: expand the option space through materially different angles.

The value is not statistical independence. The value is controlled decomposition, explicit disagreement, and durable evidence for what each worker was asked, what it returned, and why the main agent stopped or continued.

## Trigger Boundary

Use this skill only when the user explicitly asks for multi-agent, multi-subagent, or six-agent analysis of the same target. Strong triggers include:

- Chinese: `多子代理审查`, `多代理审查`, `六代理审查`, `多子代理评审`, `多代理评审`, `六代理评审`
- Chinese divergent mode: `多子代理发散分析`, `多代理发散分析`, `六代理发散分析`
- English: `multi-agent review`, `multi-subagent review`, `six-agent review`, `multi-agent divergent analysis`

Do not use for single-agent review, generic planning help, brainstorming, debugging, implementation work, pull request review, or several separate tasks in parallel unless the user explicitly requests multi-agent analysis of one target.

If the target artifact, decision, or question is unclear, ask one concise clarification question before creating a run record.

## Required Tooling

Before dispatching workers, read `skills/using-superpowers/references/codex-tools.md` if the active worker tool names are not already obvious. Use the callable names in the active tools list for spawn, wait, and close. Record those callable names in `state.json`.

Do not hardcode one namespace. In some sessions the callable names may be bare; in others they may be namespaced. The runtime tools list is the authority.

If no worker-capable multi-agent tools are available, stop and report the blocker. Do not simulate six subagents, do not invent worker results, and do not silently downgrade this skill to single-agent analysis.

Required `state.json.tooling` shape:

```json
{
  "tooling": {
    "spawn": "<callable spawn tool from active tools list>",
    "wait": "<callable wait tool from active tools list>",
    "close": "<callable close tool from active tools list>"
  }
}
```

## Run Record

Every run must create a local record before the first dispatch:

- Root: `.superpowers/multi-agent-analysis/`
- Run directory format: `YYYY-MM-DD-HHMM-<mode>-<slug>/`
- Required files at initialization: `brief.md`, `ledger.md`, `state.json`
- Required round files: `round-N.json` and `round-N.md` where `N` is the round number rendered by the helper as `round-01.json`, `round-01.md`, and so on.

Use the helper when available:

```bash
skills/orchestrating-multi-agent-analysis/scripts/run-ledger init \
  --root .superpowers/multi-agent-analysis \
  --mode review \
  --target docs/plan.md \
  --objective "Decide whether the plan is ready" \
  --spawn-tool "$SPAWN_TOOL" \
  --wait-tool "$WAIT_TOOL" \
  --close-tool "$CLOSE_TOOL"
```

The helper owns only mechanical file creation and assignment validation. The main agent still owns judgment: mode selection, lens choice after round one, synthesis, continuation decisions, and user communication.

The `brief.md` file is the canonical handoff. Put the target, objective, known constraints, source paths, and any user-provided context there. Worker prompts should refer to this file instead of pasting long briefs into each worker prompt.

## Review Mode

Use review mode for an explicit multi-agent review of a concrete plan, design, implementation proposal, skill, spec, or decision.

Round 1 must use exactly six subagents with these fixed lenses:

| Slot | Lens | Purpose |
|---|---|---|
| A1 | First Principles | Strip the plan to goals, constraints, causal mechanics, and irreducible requirements. |
| A2 | Occam's Razor | Detect unnecessary complexity, removable mechanisms, and overfit abstractions. |
| A3 | Bounded Bayesian | Reason under limited evidence; state priors, updates, confidence, and missing evidence. |
| A4 | Expected Cost Optimality | Compare downside, upside, reversibility, opportunity cost, and cost of being wrong. |
| A5 | Adversarial Review | Attack the plan through edge cases, incentives, brittle dependencies, and abuse paths. |
| A6 | Execution Friction | Test usability, ownership, sequencing, testability, maintenance, and handoff risk. |

Do not replace, merge, or skip these lenses in round 1.

## Divergent-Analysis Mode

Use divergent-analysis mode only when the user explicitly asks for multi-agent, multi-subagent, or six-agent divergent analysis on one target. The target may be broad angle discovery or non-obvious option exploration, but that alone is not a trigger.

Round 1 must use exactly six subagents with five fixed slots plus one constrained wildcard:

| Slot | Lens | Core question |
|---|---|---|
| S1 | User Behavior & Adoption | Who must change behavior, and why would they adopt, resist, misunderstand, or ignore this? |
| S2 | Workflow & Operational Reality | How does this change workflows, handoffs, ownership, rollout, training, support, and day-2 operations? |
| S3 | System Mechanics & Dependencies | What mechanisms, interfaces, data flows, components, and dependencies must hold? |
| S4 | Failure, Abuse & Recovery | How does this fail under stress, misuse, edge cases, or adversarial conditions, and how is it recovered? |
| S5 | Economics, Time & Opportunity Cost | Is this worth building and operating compared with simpler alternatives or doing nothing? |
| S6 | Wildcard Non-Obvious Angle | Which material angle is not covered by S1-S5 and could change the decision? |

Allowed S6 wildcard families:

- `Measurement & Falsifiability`
- `Regulatory & Policy`
- `Market & Competitive Dynamics`
- `Historical Analogy`
- `Ecosystem & Dependency Power`
- `Second-Order Effects`
- `Governance & Ownership`
- `Reversibility & Option Value`

Before dispatching S6, record these fields in the round plan:

- `wildcard_family`
- `why_material`
- `why_not_redundant`

If you cannot explain why S6 is materially different from S1-S5 in one sentence, use `Measurement & Falsifiability` and record the fallback reason.

## Round Preparation

Create the assignment file yourself, then validate it with the helper:

```bash
skills/orchestrating-multi-agent-analysis/scripts/run-ledger prepare-round \
  --run-dir .superpowers/multi-agent-analysis/2026-07-03-1200-review-plan \
  --round 1 \
  --assignments /tmp/round-01-assignments.json
```

The assignment file must be a JSON array with exactly six objects. Each object must include `slot`, `lens`, and `question`. Use `round-subagent-prompt.md` as the prompt template for each worker.

If the helper rejects the assignments, fix the assignment file before dispatch. Do not dispatch a partial round.

## Dispatch Lifecycle

For each round:

1. Prepare `brief.md`.
2. Prepare and validate exactly six assignments.
3. Dispatch all six workers. If the API allows batch calls, dispatch them in one batch. Otherwise spawn them one after another without waiting between successful spawns.
4. Record every spawned agent id and its callable tool name in `round-N.json` and `ledger.md` before waiting.
5. Wait for every spawned worker.
6. Record each result before closing the worker.
7. Close every finished worker and record the close status.
8. Synthesize only after six usable results exist or after a documented blocked path stops the run.

Use the helper commands for live bookkeeping:

```bash
skills/orchestrating-multi-agent-analysis/scripts/run-ledger record-spawn \
  --run-dir .superpowers/multi-agent-analysis/<run-id> \
  --round 1 \
  --slot A1 \
  --agent-id <agent-id> \
  --status spawned

skills/orchestrating-multi-agent-analysis/scripts/run-ledger record-result \
  --run-dir .superpowers/multi-agent-analysis/<run-id> \
  --round 1 \
  --slot A1 \
  --status completed \
  --summary "Short factual result summary"

skills/orchestrating-multi-agent-analysis/scripts/run-ledger record-close \
  --run-dir .superpowers/multi-agent-analysis/<run-id> \
  --round 1 \
  --slot A1 \
  --status closed
```

If a spawn, wait, or close call fails, write the failure into `ledger.md` and decide whether the run is blocked. On partial spawn failure, drain and close every worker that already spawned before reporting the run as blocked. Do not proceed as if the missing worker returned a result.

## Resume And Recovery

When resuming an interrupted run, start with:

```bash
skills/orchestrating-multi-agent-analysis/scripts/run-ledger status \
  --run-dir .superpowers/multi-agent-analysis/<run-id>
```

Trust `state.json` and the latest `round-N.json` over conversation memory. Continue only the missing lifecycle actions: wait for spawned-but-unrecorded workers, record returned results, close finished workers, and then synthesize. Do not dispatch replacement workers unless the prior round is explicitly marked blocked and the user agrees to restart the round.

## Synthesis Contract

After each complete round, write a synthesis into the round markdown file and structured decision fields into the round JSON file. Include:

- `convergence`: issues surfaced by multiple lenses
- `disagreement`: conflicts between lenses
- `critical_disagreements`: unresolved conflicts that can change the final decision
- `cannot_verify`: important claims the current round cannot validate
- `high_impact_low_evidence`: findings that matter but need more evidence
- `action_list`: concrete changes, decisions, or next checks
- `expected_value_of_another_round`: why another six-agent round would or would not change the decision
- `next_round_decision`: `stop`, `continue_round_2`, or `ask_user`
- `stop_reason` or `next_round_question`

Do not average away disagreement. Preserve conflicts and name the evidence that would resolve them.

After the synthesis is written, mark the round decision:

```bash
skills/orchestrating-multi-agent-analysis/scripts/run-ledger finalize-round \
  --run-dir .superpowers/multi-agent-analysis/<run-id> \
  --round 1 \
  --decision stop \
  --summary "Actionable recommendation exists; no decision-critical disagreement remains."
```

Use `--decision continue_round_2` only when the continuation gate is satisfied. Use `--decision ask_user` when user approval is required before the next dispatch.

## Continuation Gate

Round 1 runs when the skill is triggered and prerequisites are satisfied.

Round 2 runs automatically only when there is a decision-critical disagreement or a high-value missing perspective or evidence gap.

Round 3 and later require user approval before dispatch. Round 4 is the absolute cap and also requires user approval.

Continue only when all of these are true:

- The unresolved question is decision-level, not just useful detail.
- The next round has one narrower question.
- Six new assignments can be non-duplicative.
- At least four of the six assignments have clear expected new information compared with the previous round.
- The next round can plausibly change the recommendation, priority, or risk judgment.
- No user-approval threshold has fired.

Stop when any of these are true:

- There is an actionable recommendation and no unresolved decision-critical disagreement.
- Remaining work is implementation or external verification, not analysis.
- Another six-agent assignment set would be filler.
- The tool lifecycle is incomplete and the missing result would affect synthesis integrity.

## User-Facing Reporting

After a round, report:

- Run record path.
- Short synthesis of convergence and major disagreement.
- Concrete action list.
- Whether the run stopped or why another round is justified.

For Chinese user requests, answer in Chinese unless the user asks otherwise.

## Common Mistakes

- Triggering on ordinary review language without explicit multi-agent wording.
- Running fewer than six workers while still claiming this skill was used.
- Pasting large briefs into every worker prompt instead of using `brief.md`.
- Continuing into round 2 because more analysis is possible rather than decision-changing.
- Starting Round 3 without user approval.
- Failing to close workers after collecting results.
- Hiding worker failures in the synthesis.
