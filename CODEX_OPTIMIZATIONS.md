# Codex Optimization Notes

This repository is a Codex-first fork of `obra/superpowers`. The current fork is
built on upstream `v6.1.1` and adds a thin Codex overlay instead of carrying a
large divergent copy of every skill.

## What Changed

### v6.1.1 Baseline

The fork intentionally keeps the upstream `v6.1.1` behavior for the core
workflow:

- subagent-driven development uses one task reviewer per task and one broad
  whole-branch review at the end
- task briefs, implementer reports, and review diffs move through files instead
  of pasted prompts
- `.superpowers/sdd/progress.md` records durable task progress across
  compaction
- `using-git-worktrees` detects existing isolated workspaces and avoids fighting
  the harness
- the brainstorming visual companion includes the upstream security and
  lifecycle hardening
- the Codex plugin manifest declares `hooks: {}` to suppress accidental
  SessionStart hook auto-discovery
- the upstream Codex portal packaging script and tests are present

### Codex Overlay

The Codex overlay keeps the active skill paths executable in Codex:

- `skills/using-superpowers/SKILL.md` says this checkout is Codex-first and
  points agents to `references/codex-tools.md`
- `skills/using-superpowers/references/codex-tools.md` maps actions to Codex
  tools: `update_plan`, `spawn_agent`, `wait_agent`, `close_agent`,
  `apply_patch`, and `exec_command`
- subagent guidance emphasizes Codex's agent lifecycle: wait for every
  subagent result and close every finished subagent
- SDD guidance keeps upstream file handoffs (`task-brief`, `review-package`,
  report files) and explicitly tells Codex not to paste full task briefs,
  reports, or diffs into controller context
- README and install docs are Codex-specific and avoid upstream multi-harness
  installation content
- `.codex-plugin/plugin.json` identifies this fork as Codex Superpowers while
  keeping the skill set rooted at `./skills/`

### What Was Preserved From The Earlier Fork

The original `v5.0.6` Codex fork solved a real runtime mismatch: upstream skills
described Claude Code tool names while Codex exposed different tools and native
skill discovery. The same intent remains:

- skills should tell Codex what to do with tools it actually has
- Codex project conventions use `AGENTS.md`
- checklists become `update_plan`
- subagents are generic Codex workers or explorers created with `spawn_agent`
- manual file edits use `apply_patch`
- shell work uses `exec_command`

### What Was Not Preserved

Do not restore the old `v5.0.6` prompt structure directly.

- Do not restore `skills/subagent-driven-development/spec-reviewer-prompt.md`
  or `code-quality-reviewer-prompt.md`; upstream `v6.x` replaced them with
  `task-reviewer-prompt.md`
- Do not re-expand the compressed `using-superpowers` bootstrap unless a Codex
  run proves the short form is insufficient
- Do not copy upstream multi-harness README sections back into this fork
- Do not replace upstream visual companion, SDD, or worktree behavior with the
  older fork versions

## Allowed Overlay Surface

Keep the Codex fork small. Long-term Codex-specific changes should stay in
these paths unless a real Codex run proves a deeper skill change is needed:

- `README.md` and Codex-specific documentation
- `CODEX_OPTIMIZATIONS.md`
- `.codex-plugin/plugin.json`
- `.agents/plugins/marketplace.json`
- `skills/using-superpowers/SKILL.md`
- `skills/using-superpowers/references/codex-tools.md`
- narrow Codex clarifications in active workflow skills when the global mapping
  is not enough, such as review dispatch or `AGENTS.md` project conventions
- `tests/codex/**`

Avoid broad rewrites of upstream workflow skills. Prefer a small Codex note plus
a regression test over copying an old fork version of a skill.

## Maintenance Flow

When updating from upstream:

1. Fetch upstream and move the Codex branch to the new upstream release.
2. Reapply only the allowed overlay surface.
3. Check that removed v5 prompt files stay removed.
4. Run:
   ```bash
   bash tests/codex/test-codex-fork-overlay.sh
   bash tests/codex/test-marketplace-manifest.sh
   bash tests/codex/test-package-codex-plugin.sh
   git diff --check
   ```
5. Smoke-test a fresh Codex session against the symlink install path.

## Verification

Run these checks before publishing or relying on a new fork update:

```bash
bash tests/codex/test-codex-fork-overlay.sh
bash tests/codex/test-marketplace-manifest.sh
bash tests/codex/test-package-codex-plugin.sh
git diff --check
```

Useful targeted scans:

```bash
rg 'TodoWrite|Task tool|Skill tool' skills/using-superpowers skills/subagent-driven-development skills/requesting-code-review
rg 'update_plan|spawn_agent|wait_agent|close_agent|apply_patch|exec_command' skills/using-superpowers
```

## Attribution

Original project: [obra/superpowers](https://github.com/obra/superpowers).

This fork is intended for Codex users who want the Superpowers workflow with
Codex-native tool guidance.
