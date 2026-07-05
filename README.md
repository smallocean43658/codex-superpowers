# Codex Superpowers

Codex Superpowers is a Codex-first fork of
[obra/superpowers](https://github.com/obra/superpowers).

The upstream project provides the software-development discipline: skill
selection, brainstorming, planning, TDD, systematic debugging, subagent-driven
development, code review, and branch finishing. This fork keeps that discipline
on the upstream `v6.1.1` skill base, then adds a Codex overlay so the active
instructions match Codex's local skill discovery and tools.

## Relationship To Upstream

This repository is not the original Superpowers project. It is a public fork
optimized for Codex users.

- Original project: <https://github.com/obra/superpowers>
- Current upstream baseline: `v6.1.1`
- Fork repository: <https://github.com/smallocean43658/codex-superpowers>
- Upstream author and project credit belong to the Superpowers maintainers
- This fork changes Codex-facing skill instructions and documentation

For other harnesses, use the upstream repository and its installation docs.

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

### Replace Existing Install

This fork is intended to replace the active `superpowers` skills entry in
Codex, not run beside the upstream marketplace install. If
`~/.agents/skills/superpowers` already exists, inspect it and replace it with
the symlink above:

```bash
ls -la ~/.agents/skills/superpowers
rm ~/.agents/skills/superpowers
ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
```

Use the upstream marketplace package if you want the official multi-harness
Superpowers plugin. Use this fork when you want the Codex-specific local skill
overlay.

### Verify Installation

```bash
ls -la ~/.agents/skills/superpowers
```

You should see a symlink pointing to:

```text
~/.codex/superpowers/skills
```

Then start a new Codex session and ask for something that should trigger a
skill:

```text
help me plan this feature
```

or:

```text
let's debug this failing test
```

Codex should load and announce the relevant Superpowers skill.

## Optional Multi-Agent Support

Subagent-heavy workflows such as `dispatching-parallel-agents` and
`subagent-driven-development` require Codex multi-agent support. Add this to
`~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Without this feature, the planning, debugging, TDD, and review disciplines still
apply, but subagent dispatch instructions need to be executed inline.

## Update

```bash
cd ~/.codex/superpowers
git pull
```

Because Codex reads skills through the symlink, updates take effect after a new
Codex session starts.

## What Is Codex-Specific

This fork keeps upstream `v6.1.1` skill behavior, including the newer
subagent-driven development file handoffs, durable progress ledger, worktree
detection, and hardened brainstorming visual companion.

The Codex overlay adds:

- Codex-native tool mapping: `update_plan`, `spawn_agent`, `wait_agent`,
  `close_agent`, `apply_patch`, and `exec_command`
- Codex-first `using-superpowers` entry guidance
- Codex-oriented subagent lifecycle rules, including closing finished agents
- Local symlink installation instructions
- Codex fork metadata in the Codex plugin manifest
- Verification tests that prevent the fork from drifting back to upstream
  multi-harness documentation

See [CODEX_OPTIMIZATIONS.md](CODEX_OPTIMIZATIONS.md) for the detailed notes.

## Core Workflow

- `using-superpowers` - entry discipline document for checking and loading skills
- `brainstorming` - design new functionality before implementation
- `using-git-worktrees` - ensure isolated workspace behavior is deliberate
- `writing-plans` - turn approved specs into implementation plans
- `subagent-driven-development` - execute independent plan tasks with task
  review and final whole-branch review
- `executing-plans` - execute written plans inline or in a separate session
- `test-driven-development` - enforce RED/GREEN/REFACTOR
- `systematic-debugging` - find root cause before fixing
- `requesting-code-review` - request independent review before proceeding
- `receiving-code-review` - evaluate review feedback rigorously
- `verification-before-completion` - verify before claiming work is complete
- `finishing-a-development-branch` - finish, verify, and decide merge/PR/handoff

## Verification

The Codex overlay is checked with:

- `tests/codex/test-codex-fork-overlay.sh`
- `tests/codex/test-marketplace-manifest.sh`
- `git diff --check`
- targeted scans for stale upstream-only tool names in active Codex paths

## License

This repository keeps the upstream MIT license. See [LICENSE](LICENSE).

## Attribution

This fork is based on [obra/superpowers](https://github.com/obra/superpowers).
Please use the upstream repository for the original project, official
multi-harness installation instructions, and upstream community resources.
