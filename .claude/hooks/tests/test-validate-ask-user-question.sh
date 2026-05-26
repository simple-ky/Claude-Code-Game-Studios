#!/bin/bash
# Tests for .claude/hooks/validate-ask-user-question.sh
#
# Each test feeds a JSON payload (matching the AskUserQuestion PreToolUse
# shape) into the hook and checks the exit code.
#   - exit 0 = widget allowed
#   - exit 2 = widget blocked (validation failed)
#
# Run from repo root:  bash .claude/hooks/tests/test-validate-ask-user-question.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$REPO_ROOT/.claude/hooks/validate-ask-user-question.sh"

PASS=0
FAIL=0
FAILED_NAMES=()

run_test() {
    local name="$1"
    local expected="$2"
    local input="$3"
    local stderr_file
    stderr_file=$(mktemp)

    echo "$input" | bash "$HOOK" >/dev/null 2>"$stderr_file"
    local actual=$?

    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name (expected exit $expected, got $actual)"
        echo "    stderr:"
        sed 's/^/      /' "$stderr_file"
        FAIL=$((FAIL + 1))
        FAILED_NAMES+=("$name")
    fi
    rm -f "$stderr_file"
}

# ===== Helpers ===============================================================
# Build a single-option payload. $1 = description string.
single_opt() {
    local desc="$1"
    python -c "
import json, sys
desc = sys.argv[1]
print(json.dumps({
    'tool_name': 'AskUserQuestion',
    'tool_input': {
        'questions': [{
            'question': 'Test question?',
            'header': 'Test',
            'multiSelect': False,
            'options': [{'label': 'Option A', 'description': desc}],
        }],
    },
}))
" "$desc"
}

echo "=== validate-ask-user-question.sh tests ==="
echo

# ===== PASS cases (exit 0) ===================================================
echo "-- PASS cases --"

# 1. Clean dual-content option (everyday plain English, short Technical).
run_test "clean option passes" 0 "$(single_opt $'**What you\'ll experience:** The player sees a green checkmark after saving and can keep playing without waiting.\n\n**Technical:** Adds save_complete flag to SaveManager autoload.')"

# 2. The "bookkeeping" case -- legitimate "the player sees nothing".
run_test "bookkeeping option passes" 0 "$(single_opt $'**What you\'ll experience:** The player sees nothing new -- this is bookkeeping.\n\n**Technical:** Updates entity registry only.')"

# 3. "The player will" form.
run_test "the-player-will form passes" 0 "$(single_opt $'**What you will experience:** The player will hear a soft chime when a tower is placed.\n\n**Technical:** Hooks tower-placement audio cue.')"

# 4. Non-AskUserQuestion tool -- hook skips and allows.
run_test "non-AskUserQuestion tool skipped" 0 '{"tool_name":"Bash","tool_input":{"command":"ls"}}'

# 5. Empty questions array -- nothing to validate, allow.
run_test "empty questions array passes" 0 '{"tool_name":"AskUserQuestion","tool_input":{"questions":[]}}'

# 6. Malformed JSON -- fail-open (don't block all widgets on parse glitch).
run_test "malformed JSON fails open" 0 'this is not json'

echo

# ===== FAIL cases (exit 2) ===================================================
echo "-- FAIL cases --"

# 7. Missing plain-English marker.
run_test "missing plain marker blocks" 2 "$(single_opt 'This option does a thing. **Technical:** flips a flag.')"

# 8. Missing Technical marker.
run_test "missing technical marker blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees a checkmark.')"

# 9. Plain section contains snake_case identifier.
run_test "snake_case in plain section blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees process_mode kick in when paused.\n\n**Technical:** sets PROCESS_MODE_ALWAYS.')"

# 10. Plain section contains ADR ID reference.
run_test "ADR id in plain section blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees the behavior governed by ADR-0004 take effect.\n\n**Technical:** per ADR-0004.')"

# 11. Plain section contains file path / extension.
run_test "file extension in plain section blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees what is described in lane_map.gd come alive.\n\n**Technical:** lane_map.gd handles it.')"

# 12. Plain section contains PascalCase class name.
run_test "PascalCase in plain section blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees AudioStreamPlayer fire when an impact happens.\n\n**Technical:** uses AudioStreamPlayer pool.')"

# 13. Plain section contains backtick code.
run_test "backtick code in plain section blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees `sfx_bus` light up.\n\n**Technical:** activates `sfx_bus`.')"

# 14. Plain section ordering: Technical comes BEFORE plain.
run_test "wrong ordering blocks" 2 "$(single_opt $'**Technical:** does a thing.\n\n**What you\'ll experience:** The player sees something.')"

# 15. Plain section too long (>40 words).
LONG_PLAIN="**What you'll experience:** The player will see a long sequence of events happen one after another as the system processes multiple inputs from several different sources at once across many different lanes of the map and updates the visual state of every single tower in real time across the whole screen smoothly. **Technical:** stuff."
run_test "plain section too long blocks" 2 "$(single_opt "$LONG_PLAIN")"

# 16. Whole description too long (>100 words).
LONG_DESC="**What you'll experience:** The player sees a checkmark. **Technical:** $(printf 'word %.0s' {1..120})"
run_test "whole description too long blocks" 2 "$(single_opt "$LONG_DESC")"

# 17. ALL_CAPS constant in plain section.
run_test "ALL_CAPS in plain section blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees MAX_HEALTH cap the bar.\n\n**Technical:** clamps to MAX_HEALTH.')"

# 18. Function call syntax in plain section.
run_test "function-call syntax in plain section blocks" 2 "$(single_opt $'**What you\'ll experience:** The player sees take_damage() fire on hit.\n\n**Technical:** calls take_damage().')"

# 19. Multiple options, one violating -- whole call blocked.
MULTI_OPT_INPUT=$(python -c "
import json
print(json.dumps({
    'tool_name': 'AskUserQuestion',
    'tool_input': {
        'questions': [{
            'question': 'Pick one',
            'header': 'Pick',
            'multiSelect': False,
            'options': [
                {'label': 'Good',
                 'description': \"**What you'll experience:** The player sees a checkmark.\n\n**Technical:** trivial.\"},
                {'label': 'Bad',
                 'description': \"**What you'll experience:** The player sees process_mode change.\n\n**Technical:** sets flag.\"},
            ],
        }],
    },
}))
")
run_test "multi-option one violator blocks all" 2 "$MULTI_OPT_INPUT"

echo

# ===== Summary ===============================================================
echo "=========================================="
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -ne 0 ]; then
    echo "Failed tests:"
    for n in "${FAILED_NAMES[@]}"; do
        echo "  - $n"
    done
    exit 1
fi
echo "All tests passed."
exit 0
