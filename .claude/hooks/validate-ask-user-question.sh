#!/bin/bash
# Claude Code PreToolUse hook: Validates AskUserQuestion widgets enforce dual-content format.
#
# Per CLAUDE.md "User-Friendly Decision Language" rule, every option's description
# in an AskUserQuestion widget MUST contain BOTH:
#   1. A plain-English / player-experience marker
#      ("What you'll experience" | "What you will experience" |
#       "The player sees/hears/feels/will/can/won't")
#   2. A "Technical" marker (for the jargon translation)
#
# Without both, the rule's "round-trip" property breaks -- the user either sees
# unexplained jargon OR loses the technical translation needed for the audit trail.
#
# Exit codes:
#   0 = allow the widget through (or hook skipped because no Python found)
#   2 = block; stderr is shown to the model so it can rewrite and retry
#
# Input schema (PreToolUse for AskUserQuestion):
# {
#   "tool_name": "AskUserQuestion",
#   "tool_input": {
#     "questions": [
#       { "question": "...", "header": "...", "multiSelect": bool,
#         "options": [ { "label": "...", "description": "..." } ] }
#     ]
#   }
# }

INPUT=$(cat)

# Find a working Python interpreter -- matches the pattern used by validate-commit.sh
PYTHON_CMD=""
for cmd in python python3 py; do
    if command -v "$cmd" >/dev/null 2>&1; then
        PYTHON_CMD="$cmd"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "WARNING: validate-ask-user-question.sh skipped (no Python interpreter found). Widget allowed without dual-content check." >&2
    exit 0
fi

# Embed Python validator in a heredoc-fed bash variable, then run via `python -c`.
# This frees up stdin so the piped $INPUT actually reaches Python.
# (Using `python - <<EOF` would redirect the heredoc INTO stdin, hiding $INPUT.)
PYSCRIPT=$(cat <<'PYEOF'
import json
import re
import sys

# ---- Parse input -------------------------------------------------------------

try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    # Malformed input -- fail open (don't block all widgets on a parse glitch)
    sys.exit(0)

if data.get("tool_name") != "AskUserQuestion":
    sys.exit(0)

tool_input = data.get("tool_input", {})
questions = tool_input.get("questions", [])

# ---- Validation patterns ----------------------------------------------------
# Plain-English marker: any of these phrases qualifies a description as having
# a player-experience explanation. The "." in "you.ll" matches the apostrophe
# regardless of straight or curly form.
PLAIN_PATTERN = re.compile(
    r"what you.ll experience"
    r"|what you will experience"
    r"|the player (sees|hears|feels|will|can|won.t)",
    re.IGNORECASE,
)

TECH_PATTERN = re.compile(r"\btechnical\b", re.IGNORECASE)

# ---- Walk questions and options ---------------------------------------------

violations = []

for q in questions:
    header = q.get("header", "(no header)")
    options = q.get("options", [])
    for opt in options:
        label = opt.get("label", "(no label)")
        desc = opt.get("description", "") or ""

        missing_parts = []
        if not PLAIN_PATTERN.search(desc):
            missing_parts.append("plain-English marker")
        if not TECH_PATTERN.search(desc):
            missing_parts.append("technical marker")

        if missing_parts:
            violations.append(
                f"  [{header} > {label}] missing: {' + '.join(missing_parts)}"
            )

# ---- Report and exit --------------------------------------------------------

if violations:
    out = sys.stderr
    print("=== AskUserQuestion BLOCKED: dual-content format required ===", file=out)
    print("", file=out)
    print("Per CLAUDE.md \"User-Friendly Decision Language\" rule, every option's", file=out)
    print("description must contain BOTH of these markers:", file=out)
    print("", file=out)
    print("  1. Plain-English marker -- one of:", file=out)
    print("       \"What you'll experience\"", file=out)
    print("       \"What you will experience\"", file=out)
    print("       \"The player sees/hears/feels/will/can/won't\"", file=out)
    print("", file=out)
    print("  2. Technical marker:", file=out)
    print("       \"Technical\"", file=out)
    print("", file=out)
    print("Violations:", file=out)
    for v in violations:
        print(v, file=out)
    print("", file=out)
    print("Rewrite each flagged option in the dual-content format, e.g.:", file=out)
    print("", file=out)
    print("  **What you'll experience:** <plain-English description -- what the", file=out)
    print("  user/player sees, hears, feels, or what changes visibly>", file=out)
    print("", file=out)
    print("  **Technical:** <jargon, file paths, ADR IDs, variable names, etc.>", file=out)
    print("", file=out)
    print("Then re-issue the AskUserQuestion call.", file=out)
    print("=================================================================", file=out)
    sys.exit(2)

sys.exit(0)
PYEOF
)

# Run python with the heredoc'd code; stdin carries the JSON payload from $INPUT.
echo "$INPUT" | "$PYTHON_CMD" -c "$PYSCRIPT"