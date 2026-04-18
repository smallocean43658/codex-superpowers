# Codex Superpowers

Codex Superpowers is a Codex-first fork of
[obra/superpowers](https://github.com/obra/superpowers).

The upstream project provides a disciplined software-development workflow built
from composable agent skills. This fork keeps that workflow, but adjusts the
active skill instructions for OpenAI Codex:

- Codex-native tool mapping: `update_plan`, `spawn_agent`, `wait_agent`,
  `close_agent`, `apply_patch`, and `exec_command`
- Codex-first `using-superpowers` entry skill
- Codex-oriented subagent, code-review, and plan-tracking instructions
- Cleaner skill `description` triggers that describe when each skill should load
- `AGENTS.md` support in worktree convention checks

See [CODEX_OPTIMIZATIONS.md](CODEX_OPTIMIZATIONS.md) for the detailed
optimization notes.

## Relationship To Upstream

This repository is not the original Superpowers project. It is a public fork
optimized for Codex users.

- Original project: <https://github.com/obra/superpowers>
- Original author/project credit belongs to the upstream Superpowers maintainers
- This fork changes Codex-facing skill instructions and documentation
- For Claude Code, Cursor, OpenCode, Gemini, marketplace installs, and upstream
  community resources, use the original project

## Install For Codex

Clone this fork:

```bash
git clone https://github.com/smallocean43658/codex-superpowers.git ~/.codex/superpowers
```

Expose the skills to Codex:

```bash
mkdir -p ~/.agents/skills
ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
```

Restart Codex so it discovers the skills.

### Verify Installation

```bash
ls -la ~/.agents/skills/superpowers
```

You should see a symlink pointing to:

```text
~/.codex/superpowers/skills
```

Then start a new Codex session and ask for something that should trigger a
skill, for example:

```text
help me plan this feature
```

or:

```text
let's debug this failing test
```

Codex should load and announce the relevant Superpowers skill.

## Update

```bash
cd ~/.codex/superpowers
git pull
```

Because Codex reads skills through the symlink, updates take effect after a new
Codex session starts.

## What Is Included

### Core Workflow

- `using-superpowers` - entry discipline document for checking and loading skills
- `brainstorming` - design new functionality before implementation
- `using-git-worktrees` - create isolated workspaces for feature work
- `writing-plans` - turn approved specs into implementation plans
- `subagent-driven-development` - execute independent plan tasks with subagents
- `executing-plans` - execute written plans in a separate session
- `finishing-a-development-branch` - finish, verify, and decide merge/PR/handoff

### Engineering Discipline

- `test-driven-development` - enforce RED/GREEN/REFACTOR
- `systematic-debugging` - find root cause before fixing
- `verification-before-completion` - verify before claiming work is complete
- `requesting-code-review` - request independent review before proceeding
- `receiving-code-review` - evaluate review feedback rigorously

### Meta Skills

- `writing-skills` - create and test skills
- `dispatching-parallel-agents` - split independent work across subagents

## What Was Optimized For Codex

This fork updates active Codex skill paths so the instructions refer to tools
Codex actually exposes:

- `TodoWrite` style instructions were replaced with `update_plan`
- Claude-style `Task` dispatch instructions were rewritten around `spawn_agent`
- Reviewer templates now describe `spawn_agent`, `wait_agent`, and `close_agent`
- Manual file edits point to `apply_patch`
- Shell command references point to `exec_command`
- The `using-superpowers` entry skill keeps Codex guidance in the main body and
  moves other platform notes to references

## Verification

The current Codex optimization pass was checked with:

- `git diff --check`
- Changed markdown code fence checks
- Skill `description` trigger scans
- Legacy instruction scans for active Codex paths
- Codex dispatch dry-runs
- Fresh Codex terminal validation

## License

This repository keeps the upstream MIT license. See [LICENSE](LICENSE).

## Attribution

This fork is based on [obra/superpowers](https://github.com/obra/superpowers).
Please use the upstream repository for the original project, official platform
instructions, and upstream community resources.
