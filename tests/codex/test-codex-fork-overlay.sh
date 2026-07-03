#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

python3 - "$REPO_ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])

def read(path: str) -> str:
    target = root / path
    if not target.exists():
        raise AssertionError(f"{path} must exist")
    return target.read_text(encoding="utf-8")

def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"{label}: missing {needle!r}")

readme = read("README.md")
require(readme, "# Codex Superpowers", "README title")
require(readme, "Codex-first fork", "README positioning")
require(readme, "github.com/smallocean43658/codex-superpowers", "README fork repo")
require(readme, "~/.codex/superpowers", "README local clone target")
require(readme, "~/.agents/skills/superpowers", "README Codex skill link")
require(readme, "Replace Existing Install", "README migration guidance")
require(readme, "not run beside the upstream marketplace install", "README marketplace conflict guidance")
for banned in [
    "### Claude Code",
    "### Antigravity",
    "### Cursor",
    "### Factory Droid",
    "### GitHub Copilot CLI",
    "### Kimi Code",
    "### OpenCode",
    "### Pi",
    "official Codex plugin marketplace",
    "openai/plugins",
]:
    if banned in readme:
        raise AssertionError(f"README should be Codex-specific; found {banned!r}")

notes = read("CODEX_OPTIMIZATIONS.md")
require(notes, "v6.1.1", "optimization notes baseline")
require(notes, "Codex overlay", "optimization notes overlay")
require(notes, "Do not restore", "optimization notes obsolete prompt guidance")
require(notes, "Allowed Overlay Surface", "optimization notes overlay policy")
require(notes, "Maintenance Flow", "optimization notes maintenance flow")
require(notes, "test-package-codex-plugin.sh", "optimization notes package verification")

codex_tools = read("skills/using-superpowers/references/codex-tools.md")
for needle in [
    "update_plan",
    "spawn_agent",
    "wait_agent",
    "close_agent",
    "apply_patch",
    "exec_command",
    "review-package",
    "task-brief",
]:
    require(codex_tools, needle, "Codex tool mapping")
require(codex_tools, "close every finished subagent", "Codex subagent lifecycle")
require(codex_tools, "Do not paste full task briefs, reports, or diffs", "Codex file handoff guidance")
require(codex_tools, "multi_agent_v1.spawn_agent", "Codex namespaced multi-agent example")
require(codex_tools, "callable name", "Codex runtime tool name guidance")
require(codex_tools, "tools list", "Codex runtime tool name guidance")

using = read("skills/using-superpowers/SKILL.md")
require(using, "Codex-first", "using-superpowers Codex positioning")
require(using, "references/codex-tools.md", "using-superpowers Codex reference")
for banned in ["Pi:", "Antigravity:", "antigravity-tools.md", "pi-tools.md"]:
    if banned in using:
        raise AssertionError(f"using-superpowers should only expose Codex active path; found {banned!r}")

requesting_review = read("skills/requesting-code-review/SKILL.md")
require(requesting_review, "codex-tools.md", "requesting-code-review Codex dispatch mapping")
require(requesting_review, "Do not use `HEAD~1`", "requesting-code-review multi-commit range guard")

worktrees = read("skills/using-git-worktrees/SKILL.md")
require(worktrees, "AGENTS.md", "using-git-worktrees Codex instruction file")

for old_prompt in [
    "skills/subagent-driven-development/spec-reviewer-prompt.md",
    "skills/subagent-driven-development/code-quality-reviewer-prompt.md",
]:
    if (root / old_prompt).exists():
        raise AssertionError(f"obsolete v5 reviewer prompt restored: {old_prompt}")

for path in [
    "skills/requesting-code-review/SKILL.md",
    "skills/using-git-worktrees/SKILL.md",
]:
    text = read(path)
    for banned in ["TodoWrite", "Task tool", "Skill tool"]:
        if banned in text:
            raise AssertionError(f"{path} should not use stale upstream tool name {banned!r}")

manifest = json.loads(read(".codex-plugin/plugin.json"))
require(manifest.get("interface", {}).get("displayName", ""), "Codex Superpowers", "Codex plugin display name")
require(manifest.get("repository", ""), "smallocean43658/codex-superpowers", "Codex plugin repository")

print("Codex fork overlay looks good")
PY
