#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LEDGER="$REPO_ROOT/skills/orchestrating-multi-agent-analysis/scripts/run-ledger"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

root="$tmpdir/.superpowers/multi-agent-analysis"

run_dir="$("$LEDGER" init \
  --root "$root" \
  --mode review \
  --target docs/plan.md \
  --objective "Decide whether the implementation plan is ready" \
  --spawn-tool multi_agent_v1.spawn_agent \
  --wait-tool multi_agent_v1.wait_agent \
  --close-tool multi_agent_v1.close_agent \
  --cwd "$REPO_ROOT" \
  --title "Plan review")"

for path in \
  "$root/.gitignore" \
  "$run_dir/brief.md" \
  "$run_dir/ledger.md" \
  "$run_dir/state.json"
do
  [[ -f "$path" ]] || {
    echo "missing expected ledger file: $path" >&2
    exit 1
  }
done

python3 - "$run_dir/state.json" <<'PY'
import json
import sys
from pathlib import Path

state = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for key in [
    "version",
    "run_id",
    "mode",
    "status",
    "tooling",
    "expected_agents_per_round",
    "round_cap",
]:
    if key not in state:
        raise SystemExit(f"state.json missing {key}")
if state["mode"] != "review":
    raise SystemExit("state.json mode mismatch")
if state["expected_agents_per_round"] != 6:
    raise SystemExit("expected_agents_per_round must be 6")
if state["round_cap"] != 4:
    raise SystemExit("round_cap must be 4")
for key in ["spawn", "wait", "close"]:
    if key not in state["tooling"]:
        raise SystemExit(f"tooling missing {key}")
PY

six="$tmpdir/six.json"
cat >"$six" <<'JSON'
[
  {"slot": "A1", "lens": "First Principles", "question": "What assumptions must hold?"},
  {"slot": "A2", "lens": "Occam's Razor", "question": "What can be simplified?"},
  {"slot": "A3", "lens": "Bounded Bayesian", "question": "What would update confidence?"},
  {"slot": "A4", "lens": "Expected Cost Optimality", "question": "What is the expected cost of being wrong?"},
  {"slot": "A5", "lens": "Adversarial Review", "question": "How can this break?"},
  {"slot": "A6", "lens": "Execution Friction", "question": "What makes this hard to use or maintain?"}
]
JSON

"$LEDGER" prepare-round \
  --run-dir "$run_dir" \
  --round 1 \
  --assignments "$six" >/dev/null

for path in "$run_dir/round-01.json" "$run_dir/round-01.md"; do
  [[ -f "$path" ]] || {
    echo "missing expected round file: $path" >&2
    exit 1
  }
done

python3 - "$run_dir/round-01.json" <<'PY'
import json
import sys
from pathlib import Path

round_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assignments = round_doc.get("assignments")
if not isinstance(assignments, list):
    raise SystemExit("round-01.json assignments must be a list")
if len(assignments) != 6:
    raise SystemExit("round-01.json must contain exactly six assignments")
if [assignment["slot"] for assignment in assignments] != ["A1", "A2", "A3", "A4", "A5", "A6"]:
    raise SystemExit("review round 1 slots must be A1-A6 in order")
for assignment in assignments:
    for key in [
        "slot",
        "lens",
        "question",
        "spawn_tool",
        "wait_tool",
        "close_tool",
        "spawn_status",
        "result_status",
        "close_status",
    ]:
        if key not in assignment:
            raise SystemExit(f"assignment missing {key}")
for key in [
    "convergence",
    "disagreement",
    "critical_disagreements",
    "cannot_verify",
    "high_impact_low_evidence",
    "action_list",
    "expected_value_of_another_round",
    "next_round_decision",
]:
    if key not in round_doc.get("synthesis", {}):
        raise SystemExit(f"synthesis missing {key}")
PY

"$LEDGER" record-spawn \
  --run-dir "$run_dir" \
  --round 1 \
  --slot A1 \
  --agent-id agent-a1 \
  --status spawned >/dev/null

"$LEDGER" record-result \
  --run-dir "$run_dir" \
  --round 1 \
  --slot A1 \
  --status completed \
  --summary "A1 returned a first-principles finding." >/dev/null

"$LEDGER" record-close \
  --run-dir "$run_dir" \
  --round 1 \
  --slot A1 \
  --status closed >/dev/null

python3 - "$run_dir/round-01.json" <<'PY'
import json
import sys
from pathlib import Path

round_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assignment = round_doc["assignments"][0]
if assignment["agent_id"] != "agent-a1":
    raise SystemExit("record-spawn did not persist agent_id")
if assignment["spawn_status"] != "spawned":
    raise SystemExit("record-spawn did not persist status")
if assignment["result_status"] != "completed":
    raise SystemExit("record-result did not persist status")
if "first-principles" not in assignment["result_summary"]:
    raise SystemExit("record-result did not persist summary")
if assignment["close_status"] != "closed":
    raise SystemExit("record-close did not persist close status")
PY

status_json="$("$LEDGER" status --run-dir "$run_dir")"
python3 - "$status_json" <<'PY'
import json
import sys

status = json.loads(sys.argv[1])
if status["current_round"] != 1:
    raise SystemExit("status current_round mismatch")
if status["rounds"]["round-01"]["spawned"] != 1:
    raise SystemExit("status spawned count mismatch")
if status["rounds"]["round-01"]["closed"] != 1:
    raise SystemExit("status closed count mismatch")
PY

five="$tmpdir/five.json"
python3 - "$six" "$five" <<'PY'
import json
import sys
from pathlib import Path

assignments = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
Path(sys.argv[2]).write_text(
    json.dumps(assignments[:5], indent=2) + "\n",
    encoding="utf-8",
)
PY

if "$LEDGER" prepare-round --run-dir "$run_dir" --round 2 --assignments "$five" >/dev/null 2>&1; then
  echo "prepare-round should reject assignment counts other than six" >&2
  exit 1
fi
[[ ! -f "$run_dir/round-02.json" ]] || {
  echo "failed prepare-round should not leave round-02.json" >&2
  exit 1
}

duplicate="$tmpdir/duplicate.json"
python3 - "$six" "$duplicate" <<'PY'
import json
import sys
from pathlib import Path

assignments = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assignments[1]["slot"] = "A1"
Path(sys.argv[2]).write_text(json.dumps(assignments, indent=2) + "\n", encoding="utf-8")
PY

duplicate_run="$("$LEDGER" init \
  --root "$tmpdir/.superpowers/duplicate" \
  --mode review \
  --target docs/plan.md \
  --objective "Test duplicate slots" \
  --spawn-tool spawn_agent \
  --wait-tool wait_agent \
  --close-tool close_agent \
  --title "Duplicate slot test")"

if "$LEDGER" prepare-round --run-dir "$duplicate_run" --round 1 --assignments "$duplicate" >/dev/null 2>&1; then
  echo "prepare-round should reject duplicate slots" >&2
  exit 1
fi

if "$LEDGER" prepare-round --run-dir "$run_dir" --round 5 --assignments "$six" >/dev/null 2>&1; then
  echo "prepare-round should reject rounds beyond the cap" >&2
  exit 1
fi

if "$LEDGER" prepare-round --run-dir "$run_dir" --round 3 --assignments "$six" >/dev/null 2>&1; then
  echo "prepare-round should reject skipped rounds on a fresh run" >&2
  exit 1
fi

"$LEDGER" finalize-round \
  --run-dir "$run_dir" \
  --round 1 \
  --decision continue_round_2 \
  --summary "Round two is justified for test coverage." >/dev/null

round2="$tmpdir/round2.json"
cat >"$round2" <<'JSON'
[
  {"slot": "B1", "lens": "Follow-up 1", "question": "What needs follow-up 1?"},
  {"slot": "B2", "lens": "Follow-up 2", "question": "What needs follow-up 2?"},
  {"slot": "B3", "lens": "Follow-up 3", "question": "What needs follow-up 3?"},
  {"slot": "B4", "lens": "Follow-up 4", "question": "What needs follow-up 4?"},
  {"slot": "B5", "lens": "Follow-up 5", "question": "What needs follow-up 5?"},
  {"slot": "B6", "lens": "Follow-up 6", "question": "What needs follow-up 6?"}
]
JSON

"$LEDGER" prepare-round \
  --run-dir "$run_dir" \
  --round 2 \
  --assignments "$round2" >/dev/null

divergent_root="$tmpdir/.superpowers/divergent"
divergent_run="$("$LEDGER" init \
  --root "$divergent_root" \
  --mode divergent-analysis \
  --target docs/plan.md \
  --objective "Find non-obvious decision angles" \
  --spawn-tool spawn_agent \
  --wait-tool wait_agent \
  --close-tool close_agent \
  --title "Divergent plan analysis")"

divergent_bad="$tmpdir/divergent-bad.json"
cat >"$divergent_bad" <<'JSON'
[
  {"slot": "S1", "lens": "User Behavior & Adoption", "question": "Who adopts?"},
  {"slot": "S2", "lens": "Workflow & Operational Reality", "question": "What workflow changes?"},
  {"slot": "S3", "lens": "System Mechanics & Dependencies", "question": "What mechanisms hold?"},
  {"slot": "S4", "lens": "Failure, Abuse & Recovery", "question": "How can this fail?"},
  {"slot": "S5", "lens": "Economics, Time & Opportunity Cost", "question": "Is this worth it?"},
  {"slot": "S6", "lens": "Wildcard Non-Obvious Angle", "question": "What else matters?"}
]
JSON

if "$LEDGER" prepare-round --run-dir "$divergent_run" --round 1 --assignments "$divergent_bad" >/dev/null 2>&1; then
  echo "divergent S6 should require wildcard metadata" >&2
  exit 1
fi

divergent_good="$tmpdir/divergent-good.json"
python3 - "$divergent_bad" "$divergent_good" <<'PY'
import json
import sys
from pathlib import Path

assignments = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assignments[5]["wildcard_family"] = "Measurement & Falsifiability"
assignments[5]["why_material"] = "The decision needs falsifiable success criteria."
assignments[5]["why_not_redundant"] = "No fixed slot directly tests measurement quality."
Path(sys.argv[2]).write_text(json.dumps(assignments, indent=2) + "\n", encoding="utf-8")
PY

"$LEDGER" prepare-round \
  --run-dir "$divergent_run" \
  --round 1 \
  --assignments "$divergent_good" >/dev/null

echo "orchestrating-multi-agent-analysis ledger helper looks good"
