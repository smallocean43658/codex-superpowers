# Codex Optimization Notes

This repository is a Codex-first fork of `obra/superpowers`. The goal is to keep
Superpowers as a discipline document while making the active skill paths match
Codex's available tools and discovery model.

## What Changed

### Codex-First Entry Skill

`skills/using-superpowers/SKILL.md` now keeps the main entry path focused on
Codex:

- Read the applicable `SKILL.md`
- Announce the skill being used
- Follow the skill directly
- Use `skills/using-superpowers/references/codex-tools.md` for tool mapping

Claude Code and Gemini notes were moved to references so the main discipline
document does not distract Codex with other platforms' tool names.

### Codex Tool Mapping

`skills/using-superpowers/references/codex-tools.md` now gives direct Codex
tool guidance:

- `update_plan` for checklist and plan tracking
- `spawn_agent` for subagents
- `wait_agent` for subagent results
- `close_agent` after results are handled
- `apply_patch` for manual file edits
- `exec_command` for shell commands

### Subagent and Review Workflows

Prompt templates and review instructions now describe Codex dispatch directly:

- Implementer subagents use `spawn_agent(agent_type="worker", message=...)`
- Spec reviewers use `spawn_agent(agent_type="worker", message=...)`
- Code-quality reviewers use `spawn_agent`, then `wait_agent`, then
  `close_agent`
- `requesting-code-review` reads `code-reviewer.md`, fills placeholders, and
  dispatches a worker subagent

### Plan Tracking

Legacy `TodoWrite` references in active Codex paths were replaced with
`update_plan`.

### Description Triggers

Several skill frontmatter descriptions were rewritten to focus only on when the
skill should load. This avoids workflow summaries in `description` fields and
reduces the chance that Codex follows a summary instead of reading the full
skill.

Updated skills include:

- `brainstorming`
- `finishing-a-development-branch`
- `receiving-code-review`
- `requesting-code-review`
- `using-git-worktrees`
- `verification-before-completion`

### Worktree Conventions

`using-git-worktrees` now checks `AGENTS.md` as well as `CLAUDE.md` for project
preferences, which better matches Codex projects.

## Verification Performed

The optimization was checked with:

- `git diff --check`
- Markdown code fence balance checks
- Description trigger scans
- Residual legacy-instruction scans for active skill paths
- Codex dispatch pressure dry-runs
- A fresh Codex terminal validation by the maintainer

## Attribution

Original project: [obra/superpowers](https://github.com/obra/superpowers)

This fork is intended for Codex users who want the Superpowers workflow with
Codex-native tool guidance.
