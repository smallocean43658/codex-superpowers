# Codex Tool Mapping

Use Codex's native tools directly. Older Superpowers text may mention Claude Code
tool names; translate them with the tables below.

## Codex Quick Reference

| Goal | Codex tool | Minimal use |
|------|------------|-------------|
| Track checklist or plan state | `update_plan` | `update_plan({plan:[{step,status}]})` |
| Start a subagent | `spawn_agent` | `spawn_agent({agent_type:"worker", message:"..."})` |
| Start a read-only code explorer | `spawn_agent` | `spawn_agent({agent_type:"explorer", message:"..."})` |
| Wait for subagent result | `wait_agent` | `wait_agent({targets:[agent_id], timeout_ms:30000})` |
| Free a finished subagent slot | `close_agent` | `close_agent({target:agent_id})` |

Plan statuses are `pending`, `in_progress`, and `completed`. Keep exactly one
item `in_progress`.

## Legacy Name Translation

| Skill reference | Codex action |
|-----------------|--------------|
| `Task` tool | Use `spawn_agent`; pick `worker` for implementation/review or `explorer` for read-only codebase questions |
| Multiple `Task` calls | Use multiple `spawn_agent` calls; in Codex, only delegate when the user explicitly allowed subagents or parallel agents |
| Task returns result | Use `wait_agent` with the returned agent id |
| Task is no longer needed | Use `close_agent` |
| `TodoWrite` | Use `update_plan` |
| `Skill` tool | Read the applicable `SKILL.md`, announce the skill, and follow it |
| `Read`, `Write`, `Edit` | Use native file tools; use `apply_patch` for manual edits |
| `Bash` | Use `exec_command` |

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait_agent`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.

## Named agent dispatch

Claude Code skills reference named agent types like `superpowers:code-reviewer`.
Codex does not have a named agent registry. Convert named agents into a
`spawn_agent(agent_type="worker", message=...)` call using the referenced prompt
file.

When a skill says to dispatch a named agent type:

1. Find the agent's prompt file (e.g., `agents/code-reviewer.md` or the skill's
   local prompt template like `code-quality-reviewer-prompt.md`)
2. Read the prompt content
3. Fill any template placeholders (`{BASE_SHA}`, `{WHAT_WAS_IMPLEMENTED}`, etc.)
4. Spawn a `worker` agent with the filled content as the `message`
5. Wait with `wait_agent`; close with `close_agent` when the result is handled

| Skill instruction | Codex equivalent |
|-------------------|------------------|
| `Task tool (superpowers:code-reviewer)` | Fill `code-reviewer.md`, then `spawn_agent(agent_type="worker", message=...)` |
| `Task tool (general-purpose)` with inline prompt | `spawn_agent(message=...)` with the inline prompt |

### Message framing

The `message` parameter is user-level input, not a system prompt. Structure it
for maximum instruction adherence:

```
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content from the agent's .md file]
</agent-instructions>

Execute this now. Output ONLY the structured response following the format
specified in the instructions above.
```

- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
- End with an explicit execution directive to prevent summarization of the instructions

### When this workaround can be removed

This approach compensates for Codex's plugin system not yet supporting an `agents`
field in `plugin.json`. When `RawPluginManifest` gains an `agents` field, the
plugin can symlink to `agents/` (mirroring the existing `skills/` symlink) and
skills can dispatch named agent types directly.

## Environment Detection

Skills that create worktrees or finish branches should detect their
environment with read-only git commands before proceeding:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)

See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
Step 1 for how each skill uses these signals.

## Codex App Finishing

When the sandbox blocks branch/push operations (detached HEAD in an
externally managed worktree), the agent commits all work and informs
the user to use the App's native controls:

- **"Create branch"** — names the branch, then commit/push/PR via App UI
- **"Hand off to local"** — transfers work to the user's local checkout

The agent can still run tests, stage files, and output suggested branch
names, commit messages, and PR descriptions for the user to copy.
