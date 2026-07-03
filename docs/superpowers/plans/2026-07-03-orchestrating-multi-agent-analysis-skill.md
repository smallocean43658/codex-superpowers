# Orchestrating Multi-Agent Analysis Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Codex-first Superpowers skill that runs explicit six-subagent review or divergent-analysis sessions, records runtime evidence locally, synthesizes the results, and continues only when another six-agent round has decision-level expected value.

**Architecture:** Implement one skill, `orchestrating-multi-agent-analysis`, with two modes: `review` and `divergent-analysis`. The skill body owns mode detection, lens selection, subagent dispatch contracts, synthesis, continuation gates, and failure handling. A narrow ledger helper may own mechanical run-directory initialization and state-file validation; judgment remains in `SKILL.md`. The skill reuses Codex runtime tool mapping from `skills/using-superpowers/references/codex-tools.md` instead of hardcoding one tool namespace.

**Tech Stack:** Markdown skill instructions, JSON test prompts, optional Python standard-library ledger helper, shell regression tests, Codex multi-agent tools exposed in the active session, and local run records under `.superpowers/multi-agent-analysis/`.

## Global Constraints

- Trigger only when the user explicitly asks for multi-agent, multi-subagent, or six-agent analysis of one target.
- Do not trigger on ordinary `方案审查`, `计划审查`, `设计审查`, `架构审查`, `可行性分析`, `发散分析`, `多个角度`, or `列 6 个角度` unless the same request also makes multi-agent or six-reviewer intent explicit.
- Every analysis round uses exactly six subagents. If six cannot be spawned and completed as usable results, the round is not a complete six-agent round.
- Do not silently downgrade to fewer than six subagents. A smaller round requires a separate user-approved mode outside this v1 skill.
- Use the active multi-agent callable names shown in the current Codex tools list, such as `multi_agent_v1.spawn_agent`, `multi_agent_v1.wait_agent`, and `multi_agent_v1.close_agent`.
- Create durable run records before dispatching any subagent. A run without a writable record is blocked.
- Pass file paths to subagents. Do not paste full conversation history, full prior results, or bulky diffs into subagent prompts.
- Wait for every required subagent result and close every finished subagent after its result is recorded.
- Default to one round. Run a second round only for a decision-critical disagreement or a high-value missing perspective/evidence gap. Ask the user before any third round. Four rounds is the absolute cap.
- Do not claim six subagents are statistically independent evidence. Describe the result as parallel multi-lens analysis.
- Start with documentation TDD: write behavioral prompt contracts and failing/static checks before writing the skill body.

---

## Recommended Shape

Create one skill, not two.

Both requested workflows share the same machinery: build a brief, create a run record, dispatch exactly six subagents, record lifecycle evidence, synthesize, decide whether another round is justified, and stop. Splitting into two skills would duplicate orchestration and increase drift.

Mode detection:

- `review`: user explicitly asks for multi-agent or six-agent review, critique, validation, challenge, stress test, or审查 of one target.
- `divergent-analysis`: user explicitly asks for multi-agent or six-agent divergent analysis,发散分析, option-space expansion, or non-obvious angle discovery on one target.

Proposed frontmatter:

```yaml
---
name: orchestrating-multi-agent-analysis
description: Use when the user explicitly asks for multi-agent, multi-subagent, or six-agent review or divergent analysis of the same target, such as 多子代理审查, 多代理审查, 六代理审查, 多子代理评审, 多代理评审, 六代理评审, 多子代理发散分析, 多代理发散分析, 六代理发散分析, multi-agent review, multi-subagent review, or multi-agent divergent analysis.
---
```

Body `When Not To Use` must state:

- Do not use for ordinary single-agent review, ordinary planning help, generic brainstorming, PR review, code review, debugging, or implementation planning unless the user explicitly requests multi-agent analysis of one target.
- Do not use when the user wants several separate tasks worked in parallel; that is parallel execution, not multi-agent analysis of one target.
- Do not use when the target artifact, decision, or question is unclear. Ask one concise clarification question first.

## Functional Design

### Shared Workflow

1. Parse the target: identify the artifact or idea, objective, constraints, and decision the user wants improved.
2. Determine mode from explicit multi-agent trigger language.
3. Confirm worker-capable multi-agent tools are available in the active session.
4. Create the local run record before dispatch:
   - Root: `.superpowers/multi-agent-analysis/`
   - Run directory format: `.superpowers/multi-agent-analysis/YYYY-MM-DD-HHMM-<mode>-<slug>/`
   - Required files at initialization: `brief.md`, `ledger.md`, `state.json`
5. Write `brief.md` with the target, objective, constraints, mode, and source file paths. Subagents read this file first.
6. Prepare `round-01.json` and `round-01.md` with exactly six planned slots.
7. Dispatch all six subagents in one batch where the tool API allows batch use. If calls must be issued one at a time, do not wait between spawns unless a spawn fails.
8. For each successful spawn, record the agent id and callable name in `round-01.json` and `ledger.md`.
9. Wait for results. Record each result before closing its subagent.
10. Close every finished subagent. Record close status.
11. Synthesize only after six usable results are recorded or after a documented failure path stops the run.
12. Decide stop or continuation using the continuation gate below. Record the decision before reporting it to the user.

### Review Mode: First-Round Lenses

The user's proposed first five angles are sound because they cover assumptions, simplicity, uncertainty, decision economics, and adversarial failure. Add a sixth lens for execution friction because plans often fail through workflow, ownership, and maintenance problems.

First round uses these six lenses:

| Lens | Purpose | Output emphasis |
|---|---|---|
| First Principles | Strip the plan to goals, constraints, and causal mechanics | Hidden assumptions, irreducible requirements, objective mismatch |
| Occam's Razor | Detect unnecessary complexity | Simpler equivalent plan, removable mechanisms, overfit abstractions |
| Bounded Bayesian | Reason under limited evidence | Priors, likelihood updates, confidence, evidence that would change the conclusion |
| Expected Cost Optimality | Compare options by expected downside/upside | Cost of being wrong, opportunity cost, reversible vs irreversible decisions |
| Adversarial Review | Attack the plan as if trying to break it | Failure modes, incentives, edge cases, abuse paths, brittle dependencies |
| Execution Friction | Test whether the plan can be used and maintained | Workflow friction, ownership, sequencing, testability, handoff risk |

### Divergent-Analysis Mode: First-Round Lenses

Use five fixed slots plus one constrained wildcard. This keeps divergent mode broad but testable.

| Slot | Lens | Core question | Boundary |
|---|---|---|---|
| S1 | User Behavior & Adoption | Who must change behavior, and why would they adopt, resist, misunderstand, or ignore this? | Discuss implementation only when it directly changes behavior. |
| S2 | Workflow & Operational Reality | How does this change real workflows, handoffs, ownership, rollout, training, support, and day-2 operations? | Discuss desirability only when it becomes execution burden. |
| S3 | System Mechanics & Dependencies | What mechanisms, interfaces, data flows, components, and dependencies must hold for this to work? | Avoid user-opinion arguments unless the mechanism forces them. |
| S4 | Failure, Abuse & Recovery | How does this fail under stress, misuse, edge cases, or adversarial conditions, and how is it recovered? | Default to pressure, abnormal, and adversarial conditions. |
| S5 | Economics, Time & Opportunity Cost | Is this worth building and operating compared with simpler alternatives or doing nothing? | Treat every added mechanism as a budget claim. |
| S6 | Wildcard Non-Obvious Angle | Which material angle is not covered by S1-S5 and could change the decision? | Must choose from the allowed wildcard family list. |

Allowed `S6` wildcard families:

- `Measurement & Falsifiability`
- `Regulatory & Policy`
- `Market & Competitive Dynamics`
- `Historical Analogy`
- `Ecosystem & Dependency Power`
- `Second-Order Effects`
- `Governance & Ownership`
- `Reversibility & Option Value`

Before dispatching S6, the main agent records these fields in `round-N.json`:

- `wildcard_family`
- `why_material`
- `why_not_redundant`

If the main agent cannot explain in one sentence why S6 is materially different from S1-S5, use `Measurement & Falsifiability` and record the fallback reason.

### Subagent Prompt Contract

The skill should put the reusable prompt template in `skills/orchestrating-multi-agent-analysis/round-subagent-prompt.md`.

Required prompt shape:

```text
You are one of six reviewers in a parallel multi-lens analysis round.

Mode: <review|divergent-analysis>
Round: <N>
Slot: <A1-A6 or S1-S6>
Lens: <lens name>
Brief file: <absolute-or-repo-relative path to brief.md>
Target: <artifact path or concise target title>
Objective: <decision to improve or make>
Constraints: <known constraints>

Read the brief file first. Analyze only through your assigned lens. Do not summarize other lenses. If a point mainly belongs to another lens, note it briefly and move on.

Return:
1. Verdict or thesis
2. Top 3 findings
3. Assumptions challenged
4. Recommended changes or next questions
5. Confidence from 0.0 to 1.0
6. What evidence would change your view
7. Whether this lens deserves deeper follow-up
```

### Main-Agent Synthesis Contract

After each complete round, the main agent writes a synthesis to `round-N.md` and the structured decision to `round-N.json`.

Required synthesis fields:

- `convergence`: issues surfaced by multiple lenses
- `disagreement`: conflicts between lenses
- `critical_disagreements`: unresolved conflicts that can change the final decision
- `cannot_verify`: important claims the current round cannot validate
- `high_impact_low_evidence`: findings that matter but need more evidence
- `action_list`: concrete changes, decisions, or next checks
- `expected_value_of_another_round`: why another six-agent round would or would not change the decision
- `next_round_decision`: `stop`, `continue_round_2`, or `ask_user`
- `stop_reason` or `next_round_question`

Do not average away disagreement. Preserve conflicts and state what evidence would resolve them.

### Continuation Rules

Default policy:

- Round 1 runs when the skill is triggered and prerequisites are satisfied.
- Round 2 runs automatically only when there is a decision-critical disagreement or a high-value missing perspective/evidence gap.
- Round 3 and later require user approval before dispatch.
- Round 4 is the absolute cap and also requires user approval.

Continue only when every item below is true:

- The unresolved question is decision-level, not just useful detail.
- The next round has one narrower question.
- Six new assignments can be non-duplicative.
- At least four of the six assignments have clear expected new information compared with the previous round.
- The next round can plausibly change the recommendation, priority, or risk judgment.
- No user-approval threshold has fired.

Stop when any item below is true:

- There is an actionable recommendation and no unresolved decision-critical disagreement.
- Remaining work is implementation or external verification, not analysis.
- Another six-agent assignment set would be filler.
- The previous round produced no new critical finding and mostly restated earlier conclusions.
- Multi-agent lifecycle or durable logging is incomplete.

Ask the user before continuing when:

- The next round would be Round 3 or later.
- The next round expands scope beyond the original target.
- More than two of six subagents would need the most capable available model.
- Two or more subagents in a round fail, timeout, or return unusable results.
- The mode would switch between review and divergent analysis.

### Local Record Format

Each run creates a directory:

```text
.superpowers/
  multi-agent-analysis/
    .gitignore
    2026-07-03-1059-review-example-plan/
      brief.md
      ledger.md
      state.json
      round-01.md
      round-01.json
      round-02.md
      round-02.json
```

`.superpowers/multi-agent-analysis/.gitignore` should ignore all run directories:

```gitignore
*
!.gitignore
```

`state.json` minimum shape:

```json
{
  "version": 1,
  "run_id": "2026-07-03-1059-review-example-plan",
  "mode": "review",
  "status": "initialized",
  "created_at": "2026-07-03T10:59:00+08:00",
  "updated_at": "2026-07-03T10:59:00+08:00",
  "cwd": "/home/oocc/.codex/superpowers",
  "target": "docs/superpowers/plans/example.md",
  "objective": "review the implementation plan",
  "constraints": ["six subagents per complete round"],
  "tooling": {
    "spawn": "multi_agent_v1.spawn_agent",
    "wait": "multi_agent_v1.wait_agent",
    "close": "multi_agent_v1.close_agent"
  },
  "expected_agents_per_round": 6,
  "round_cap": 4,
  "current_round": 1,
  "last_finalized_round": 0,
  "next_action": "prepare_round",
  "open_agents": [],
  "last_error": null,
  "stop_reason": null
}
```

`round-N.json` minimum shape:

```json
{
  "round": 1,
  "status": "prepared",
  "created_at": "2026-07-03T11:00:00+08:00",
  "finalized_at": null,
  "lenses": ["First Principles", "Occam's Razor", "Bounded Bayesian", "Expected Cost Optimality", "Adversarial Review", "Execution Friction"],
  "agents": [
    {
      "slot": "A1",
      "lens": "First Principles",
      "question": "Which assumptions and causal mechanics must be true?",
      "model": "standard",
      "agent_id": null,
      "attempt": 1,
      "spawn_status": "planned",
      "spawned_at": null,
      "wait_status": "pending",
      "waited_at": null,
      "close_status": "pending",
      "closed_at": null,
      "usable": null,
      "summary": null,
      "confidence": null,
      "follow_up": null,
      "error": null
    }
  ],
  "synthesis": null,
  "decision": null
}
```

`ledger.md` is append-only and human-readable:

```markdown
# Multi-Agent Analysis Ledger

run_id: 2026-07-03-1059-review-example-plan
mode: review
status: initialized
created: 2026-07-03T10:59:00+08:00
target: docs/superpowers/plans/example.md
spawn_tool: multi_agent_v1.spawn_agent
wait_tool: multi_agent_v1.wait_agent
close_tool: multi_agent_v1.close_agent
expected_agents_per_round: 6
round_cap: 4

## Events

- 2026-07-03T10:59:00+08:00 run_initialized
- 2026-07-03T11:00:10+08:00 round_1_prepared lenses=6
```

### Failure Modes To Encode In The Skill

- No worker-capable multi-agent tools available: stop and report blocked capability. Do not simulate a multi-agent review.
- Target unclear: ask one concise clarification question before creating a run.
- Run directory or initial files cannot be created: stop before dispatching any subagent.
- Fewer than six subagents can be spawned: retry the failed slot once; if still fewer than six, drain and close spawned agents, mark the run blocked, and do not synthesize a complete round.
- Subagent timeout or unusable result: retry that lens once. If still unusable, record the missing result, stop the run, and report evidence incomplete.
- Close failure: retry close once. If still failing, record the agent id in `state.json.open_agents`, do not start another round, and report cleanup blocked.
- Log or state write fails after spawn: stop further analysis, drain and close what can be closed, and report the last durable checkpoint.
- Controller resumes from a half-finished round: trust `state.json` and `ledger.md`, not memory. If open agents or unclosed slots remain, mark the run interrupted and ask whether to restart that round.
- User asks to skip logging or tools for speed: refuse to call the result multi-agent analysis. Offer a plain inline analysis only if the user explicitly accepts that it is not this skill.

## File Structure

Create:

- `skills/orchestrating-multi-agent-analysis/SKILL.md`
- `skills/orchestrating-multi-agent-analysis/test-prompts.json`
- `skills/orchestrating-multi-agent-analysis/round-subagent-prompt.md`
- `skills/orchestrating-multi-agent-analysis/scripts/run-ledger`
- `tests/codex/test-orchestrating-multi-agent-analysis-ledger.sh`

Modify:

- `tests/codex/test-codex-fork-overlay.sh`

Generate/check during implementation:

- Use `/home/oocc/.codex/skills/.system/skill-creator/scripts/init_skill.py` to scaffold the skill directory.
- Use `/home/oocc/.codex/skills/.system/skill-creator/scripts/quick_validate.py` to validate the skill.
- Use `/home/oocc/.codex/skills/.system/skill-creator/scripts/generate_openai_yaml.py` only if the scaffold or packaging path requires local `agents/openai.yaml`. Current repo packaging seeds OpenAI metadata from a prior package, so do not hand-maintain `agents/openai.yaml` unless implementation verification shows it is needed.

## Test Strategy

Use documentation TDD before writing `SKILL.md`.

Behavior contracts in `test-prompts.json`:

1. Explicit six-agent review baseline.
2. Explicit six-agent divergent-analysis baseline.
3. Anti-cheat no-tools control.
4. Trigger overreach negative control for ordinary `帮我审查这个方案`.
5. Unclear target.
6. Review happy path.
7. Divergent happy path.
8. Missing multi-agent support.
9. Fewer-than-six or partial lifecycle failure.
10. Log/ledger initialization failure.
11. User speed pressure to skip logging.
12. Continuation overrun when round 1 is enough.
13. Decision-critical disagreement that justifies round 2.

Static checks in `tests/codex/test-codex-fork-overlay.sh`:

- skill exists
- frontmatter includes explicit Chinese and English multi-agent triggers
- broad ordinary review terms are not frontmatter triggers
- review mode names the six fixed first-round lenses
- divergent mode names the five fixed slots plus constrained wildcard
- skill requires `.superpowers/multi-agent-analysis/`
- skill requires `brief.md`, `ledger.md`, `state.json`, and `round-N.json`
- skill requires active callable mapping instead of one hardcoded tool name
- skill requires wait and close lifecycle
- skill blocks rather than simulates when multi-agent tools are missing
- skill says Round 3 and later require user approval
- skill has no stale upstream-only tool names such as `Task tool`, `TodoWrite`, or `Skill tool`

Ledger helper tests in `tests/codex/test-orchestrating-multi-agent-analysis-ledger.sh`:

- `run-ledger init` creates `.gitignore`, `brief.md`, `ledger.md`, and `state.json`
- `state.json` is valid JSON and contains `version`, `run_id`, `mode`, `status`, `tooling`, `expected_agents_per_round`, and `round_cap`
- `run-ledger prepare-round` creates `round-01.json` and `round-01.md`
- `round-01.json` is valid JSON and contains exactly six agent slots
- invalid assignment count fails

Forward verification after implementation:

- Run one fresh-context review prompt against a real target.
- Run one fresh-context divergent-analysis prompt against the same target.
- Inspect the resulting `.superpowers/multi-agent-analysis/<run-id>/` directory.
- Confirm every completed subagent has result and close evidence before claiming the skill works.

## Implementation Tasks

### Task 1: Add Behavior Prompt Contracts

**Files:**
- Create: `skills/orchestrating-multi-agent-analysis/test-prompts.json`

**Interfaces:**
- Produces: behavioral cases consumed by skill forward testing.

- [ ] **Step 1: Create the test prompt directory**

Run:

```bash
mkdir -p skills/orchestrating-multi-agent-analysis
```

- [ ] **Step 2: Write `test-prompts.json` with the 13 cases from Test Strategy**

Use the existing shape from `skills/using-superpowers/test-prompts.json`: each entry has `id`, `scenario`, `prompt`, and `expected`.

- [ ] **Step 3: Validate JSON**

Run:

```bash
python3 -m json.tool skills/orchestrating-multi-agent-analysis/test-prompts.json >/dev/null
```

Expected: exit 0.

- [ ] **Step 4: Record RED intent**

Append a short note to the implementation report: these prompts are written before `SKILL.md`; at least the explicit six-agent and no-tools cases should fail without the skill by producing single-agent analysis or simulated multi-agent claims.

### Task 2: Add Static RED Checks

**Files:**
- Modify: `tests/codex/test-codex-fork-overlay.sh`
- Create: `tests/codex/test-orchestrating-multi-agent-analysis-ledger.sh`

**Interfaces:**
- Consumes: planned skill file paths.
- Produces: failing regression checks before Task 3 creates the skill.

- [ ] **Step 1: Extend `test-codex-fork-overlay.sh`**

Add checks for the static invariants listed in Test Strategy. These checks should fail before `SKILL.md` exists.

- [ ] **Step 2: Add `test-orchestrating-multi-agent-analysis-ledger.sh`**

The shell test should create a temporary directory, run `skills/orchestrating-multi-agent-analysis/scripts/run-ledger init`, verify generated files, run `prepare-round` with six assignments, and reject five assignments.

- [ ] **Step 3: Run overlay RED**

Run:

```bash
bash tests/codex/test-codex-fork-overlay.sh
```

Expected: fails because the skill does not exist yet.

- [ ] **Step 4: Run ledger RED**

Run:

```bash
bash tests/codex/test-orchestrating-multi-agent-analysis-ledger.sh
```

Expected: fails because `scripts/run-ledger` does not exist yet.

### Task 3: Scaffold The Skill

**Files:**
- Create: `skills/orchestrating-multi-agent-analysis/SKILL.md`
- Create: `skills/orchestrating-multi-agent-analysis/scripts/`

**Interfaces:**
- Consumes: system `skill-creator` scripts.
- Produces: scaffolded skill directory.

- [ ] **Step 1: Initialize the skill directory**

Run:

```bash
python3 /home/oocc/.codex/skills/.system/skill-creator/scripts/init_skill.py orchestrating-multi-agent-analysis --path /home/oocc/.codex/superpowers/skills --resources scripts
```

Expected: `skills/orchestrating-multi-agent-analysis/SKILL.md` and `skills/orchestrating-multi-agent-analysis/scripts/` exist.

- [ ] **Step 2: Replace scaffold frontmatter**

Use the frontmatter from Recommended Shape.

### Task 4: Implement The Ledger Helper

**Files:**
- Create: `skills/orchestrating-multi-agent-analysis/scripts/run-ledger`

**Interfaces:**
- Consumes: CLI arguments for `init` and `prepare-round`.
- Produces: local run directories and JSON/Markdown state files.

- [ ] **Step 1: Implement `init`**

Required command shape:

```bash
skills/orchestrating-multi-agent-analysis/scripts/run-ledger init \
  --root .superpowers/multi-agent-analysis \
  --mode review \
  --target docs/superpowers/plans/example.md \
  --objective "review the implementation plan" \
  --spawn-tool multi_agent_v1.spawn_agent \
  --wait-tool multi_agent_v1.wait_agent \
  --close-tool multi_agent_v1.close_agent
```

Expected behavior:
- creates the root directory
- writes `.gitignore`
- creates one timestamped run directory
- writes `brief.md`, `ledger.md`, and `state.json`
- prints the run directory path

- [ ] **Step 2: Implement `prepare-round`**

Required command shape:

```bash
skills/orchestrating-multi-agent-analysis/scripts/run-ledger prepare-round \
  --run-dir .superpowers/multi-agent-analysis/2026-07-03-1059-review-example-plan \
  --round 1 \
  --assignments /tmp/assignments.json
```

Expected behavior:
- rejects assignment arrays with any length other than six
- writes `round-01.json`
- writes `round-01.md`
- appends a `round_1_prepared` event to `ledger.md`

- [ ] **Step 3: Run ledger GREEN**

Run:

```bash
bash tests/codex/test-orchestrating-multi-agent-analysis-ledger.sh
```

Expected: exit 0.

### Task 5: Write The Skill Body And Prompt Template

**Files:**
- Modify: `skills/orchestrating-multi-agent-analysis/SKILL.md`
- Create: `skills/orchestrating-multi-agent-analysis/round-subagent-prompt.md`

**Interfaces:**
- Consumes: ledger helper, active Codex multi-agent callable names, `brief.md`.
- Produces: repeatable skill instructions.

- [ ] **Step 1: Write `SKILL.md` sections**

Include these sections in order:
- Overview
- When to Use
- When Not to Use
- Preconditions
- Mode Selection
- Review Mode First-Round Lenses
- Divergent-Analysis First-Round Lenses
- Run Record Protocol
- Dispatch Protocol
- Synthesis Contract
- Continuation Gate
- Failure Handling
- Common Mistakes
- Verification Checklist

- [ ] **Step 2: Add the blocked-tool rule**

The skill must state: if no worker-capable multi-agent tool is available, stop and do not claim multi-agent analysis was performed.

- [ ] **Step 3: Add the six-agent hard rule**

The skill must state: a complete round has exactly six usable subagent results; fewer results are a blocked or degraded run, not a complete six-agent round.

- [ ] **Step 4: Write `round-subagent-prompt.md`**

Use the prompt contract from Functional Design and include both review and divergent-analysis slot guidance.

- [ ] **Step 5: Run overlay GREEN**

Run:

```bash
bash tests/codex/test-codex-fork-overlay.sh
```

Expected: exit 0.

### Task 6: Validate Skill Metadata And Packaging

**Files:**
- Modify only if validation exposes a repo-convention mismatch.

**Interfaces:**
- Consumes: system skill validation scripts and existing package tests.
- Produces: validated skill directory and Codex package compatibility.

- [ ] **Step 1: Validate skill with system validator**

Run:

```bash
python3 /home/oocc/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/orchestrating-multi-agent-analysis
```

Expected: exit 0.

- [ ] **Step 2: Decide local OpenAI metadata handling**

Run:

```bash
python3 /home/oocc/.codex/skills/.system/skill-creator/scripts/generate_openai_yaml.py skills/orchestrating-multi-agent-analysis
```

Then inspect whether `skills/orchestrating-multi-agent-analysis/agents/openai.yaml` should be tracked in this repo. If existing repository conventions and package tests expect metadata to be seeded from a prior package, remove the generated metadata from the source diff and document that package metadata remains externally seeded.

- [ ] **Step 3: Validate JSON and package tests**

Run:

```bash
python3 -m json.tool skills/orchestrating-multi-agent-analysis/test-prompts.json >/dev/null
bash tests/codex/test-package-codex-plugin.sh
```

Expected: both exit 0.

### Task 7: Forward-Test The Skill

**Files:**
- Modify only if forward testing exposes skill gaps.

**Interfaces:**
- Consumes: active Codex multi-agent tools.
- Produces: one review run record and one divergent-analysis run record.

- [ ] **Step 1: Run review prompt in a fresh context if multi-agent tools are available**

Prompt:

```text
对 docs/superpowers/plans/2026-07-03-orchestrating-multi-agent-analysis-skill.md 做多子代理审查，按技能规则决定是否进入第二轮。
```

Expected:
- skill triggers
- run directory is created
- six review lenses are dispatched
- wait/close lifecycle is recorded
- synthesis contains action list and stop/continue reason

- [ ] **Step 2: Run divergent-analysis prompt in a fresh context if multi-agent tools are available**

Prompt:

```text
对 docs/superpowers/plans/2026-07-03-orchestrating-multi-agent-analysis-skill.md 做多子代理发散分析，保留六个子代理，并把运行记录写到 .superpowers/multi-agent-analysis/。
```

Expected:
- skill triggers
- S1-S5 fixed slots appear
- S6 wildcard records family, materiality, and non-redundancy
- run directory contains `brief.md`, `ledger.md`, `state.json`, and `round-01.json`

- [ ] **Step 3: Inspect run records**

Run:

```bash
find .superpowers/multi-agent-analysis -maxdepth 3 -type f | sort | tail -n 30
```

Expected: recent run files show both review and divergent-analysis records.

### Task 8: Final Verification

**Files:**
- No planned edits.

**Interfaces:**
- Consumes: all changed files.
- Produces: evidence before completion.

- [ ] **Step 1: Run all focused checks**

Run:

```bash
python3 -m json.tool skills/orchestrating-multi-agent-analysis/test-prompts.json >/dev/null
bash tests/codex/test-orchestrating-multi-agent-analysis-ledger.sh
bash tests/codex/test-codex-fork-overlay.sh
bash tests/codex/test-package-codex-plugin.sh
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 2: Review the implementation against Global Constraints**

Confirm each Global Constraint has a corresponding section in `SKILL.md` or a test in `tests/codex/`.

- [ ] **Step 3: Commit only after verification**

Run:

```bash
git status -sb
git add skills/orchestrating-multi-agent-analysis tests/codex/test-codex-fork-overlay.sh tests/codex/test-orchestrating-multi-agent-analysis-ledger.sh docs/superpowers/plans/2026-07-03-orchestrating-multi-agent-analysis-skill.md
git commit -m "feat: add multi-agent analysis orchestration skill"
```

Expected: commit succeeds after all verification evidence is available.

## Decisions Resolved

- Skill name: `orchestrating-multi-agent-analysis`
- Shape: one skill with two modes
- Review first-round sixth lens: `Execution Friction`
- Divergent-analysis first round: five fixed slots plus constrained S6 wildcard
- Trigger policy: explicit multi-agent or six-agent intent only
- Fanout: exactly six subagents per complete round
- Continuation: default one round, second only for decision-critical value, ask before third, absolute cap four
- Run record: `.superpowers/multi-agent-analysis/<run-id>/` with `brief.md`, `ledger.md`, `state.json`, and `round-N.{md,json}`

