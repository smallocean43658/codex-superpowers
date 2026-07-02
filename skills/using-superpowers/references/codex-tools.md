# Codex Tool Mapping

This fork is Codex-first. Use the tools exposed in the active Codex session
when a skill names a generic action or an older upstream tool name. Tool names
can be exposed directly (`spawn_agent`) or through a namespace
(`multi_agent_v1.spawn_agent`); use the callable name shown in the current
tools list.

## Quick Reference

| Goal | Codex action | Notes |
|------|--------------|-------|
| Track checklist or plan state | `update_plan` | Keep exactly one item `in_progress` |
| Dispatch implementation or review work | active multi-agent spawn tool | Common names: `spawn_agent`, `multi_agent_v1.spawn_agent`; use a worker reviewer/worker role |
| Dispatch read-only code exploration | active multi-agent spawn tool | Use an explorer/read-only role when available |
| Wait for a subagent result | active multi-agent wait tool | Common names: `wait_agent`, `multi_agent_v1.wait_agent` |
| Free a finished subagent slot | active multi-agent close tool | Common names: `close_agent`, `multi_agent_v1.close_agent`; close every finished subagent after handling its result |
| Edit files manually | `apply_patch` | Prefer this over shell heredocs for hand edits |
| Run shell commands | `exec_command` | Use the repo root as `workdir` where possible |

## Legacy Name Translation

| Skill reference | Codex action |
|-----------------|--------------|
| `TodoWrite` | Use `update_plan` |
| `Task` or `Task tool` | Use the active multi-agent spawn tool |
| `general-purpose` subagent | Use a worker-capable subagent role |
| code reviewer subagent | Fill the reviewer prompt, then use a worker subagent |
| read-only investigation subagent | Use an explorer/read-only subagent role |
| `Read`, `Write`, `Edit` | Use native file reads and `apply_patch` for manual edits |
| `Bash` | Use `exec_command` |
| `Skill` tool | Read the applicable `SKILL.md`, announce it, and follow it |

## Multi-Agent Support

Subagent workflows require Codex multi-agent support. Add this to
`~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

This enables the multi-agent spawn, wait, and close actions for skills like
`dispatching-parallel-agents` and `subagent-driven-development`. If the tools
are not listed in the active session, load or enable the multi-agent tools
before following a subagent workflow.

When using subagents:

- choose `worker` for implementation, fix, and review work
- choose `explorer` for read-only codebase questions
- wait for every agent whose result matters
- read the result before acting on it
- close every finished subagent after the result is handled

## Subagent-Driven Development In Codex

Upstream `v6.1.0` SDD intentionally moves bulky artifacts through files. Keep
that design in Codex.

- Generate task briefs with `skills/subagent-driven-development/scripts/task-brief`
- Generate review packages with `skills/subagent-driven-development/scripts/review-package`
- Keep implementer reports in files named from the task brief
- Keep the durable progress ledger at `.superpowers/sdd/progress.md`
- Do not paste full task briefs, reports, or diffs into the controller prompt
- Pass file paths to subagents and have them read the files

This keeps Codex controller context small and makes compaction recovery
possible.

## Message Framing

When a skill tells you to dispatch a prompt template, read the template, fill
its placeholders, and send the filled instructions as the worker `message`.
Frame the message as a concrete task:

```text
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt template]
</agent-instructions>

Execute this now. Return only the structured response requested above.
```

Do not paste your whole session history into the subagent message. Give the
task, the relevant file paths, the required interfaces, and the report contract.

## Environment Detection

Skills that create worktrees or finish branches should detect their environment
with read-only git commands before proceeding:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` means the checkout may already be a linked worktree
- `BRANCH` empty means detached HEAD and no branch name is available

Also check `git rev-parse --show-superproject-working-tree` before treating
`GIT_DIR != GIT_COMMON` as a worktree signal, because submodules have different
git dirs too.

## Codex App Finishing

When branch or push operations are owned by the Codex App workspace, commit the
work locally when possible and tell the user which App control to use:

- **Create branch** - names the branch, then push/PR through the App UI
- **Hand off to local** - transfers work to the user's local checkout

The agent can still run tests, stage files, and provide suggested branch names,
commit messages, and PR descriptions.
