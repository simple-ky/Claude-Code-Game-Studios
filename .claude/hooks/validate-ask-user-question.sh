#!/bin/bash
# Claude Code PreToolUse hook: Validates AskUserQuestion widgets enforce
# user-friendly dual-content options.
#
# Per CLAUDE.md "User-Friendly Decision Language" rule, every option's
# description MUST satisfy ALL of the following:
#
#   1. Contains a PLAIN-ENGLISH marker:
#        "What you'll experience" | "What you will experience"
#        | "The player sees/hears/feels/will/can/won't"
#   2. Contains a TECHNICAL marker (the word "Technical")
#   3. The plain-English marker appears BEFORE the technical marker
#      (user reads plain first; technical block is the audit-trail footer).
#   4. The plain-English section is short (<= 40 words after markdown strip).
#   5. The plain-English section is JARGON-FREE — no code identifiers,
#      ADR/TR/AC IDs, file paths, PascalCase class names, ALL_CAPS constants,
#      backtick-wrapped code, or function-call syntax.
#   6. The whole option description is short (<= 100 words).
#
# Rationale: the previous hook only verified the marker STRINGS existed,
# so options could pass the check while still being unreadable jargon.
# The user explicitly reported that options were "too full" and the
# plain-English half "still had many sentences I don't understand".
# These rules force the plain half to actually be plain.
#
# Exit codes:
#   0 = allow the widget (or hook skipped because no Python found)
#   2 = block; stderr is shown to the model so it can rewrite and retry

INPUT=$(cat)

# Find a working Python interpreter -- matches validate-commit.sh
PYTHON_CMD=""
for cmd in python python3 py; do
    if command -v "$cmd" >/dev/null 2>&1; then
        PYTHON_CMD="$cmd"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "WARNING: validate-ask-user-question.sh skipped (no Python interpreter found). Widget allowed without check." >&2
    exit 0
fi

PYSCRIPT=$(cat <<'PYEOF'
import json
import re
import sys

# ---- Parse input -------------------------------------------------------------

try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)  # Fail open on malformed input -- don't block all widgets

if data.get("tool_name") != "AskUserQuestion":
    sys.exit(0)

questions = data.get("tool_input", {}).get("questions", [])

# ---- Patterns ---------------------------------------------------------------

# Plain-English marker. The "." in "you.ll" / "won.t" matches either a
# straight apostrophe or the curly one, so we don't fail on smart-quote
# autocorrect.
PLAIN_PATTERN = re.compile(
    r"what you.ll experience"
    r"|what you will experience"
    r"|the player (sees|hears|feels|will|can|won.t)",
    re.IGNORECASE,
)

TECH_PATTERN = re.compile(r"\btechnical\b", re.IGNORECASE)

# Jargon patterns -- applied ONLY to the plain-English section, never to the
# Technical section (which is allowed to contain all of these by design).
# Each entry: (regex, human_label).
JARGON_PATTERNS = [
    # Backtick-wrapped inline code: `something`
    (re.compile(r"`[^`\n]+`"), "backtick-wrapped code"),
    # snake_case identifiers: at least one underscore between letter/digit runs.
    # Catches: process_mode, tk_prep_floor, sfx_bus, lane_map, state_loaded.
    (re.compile(r"\b[a-z][a-z0-9]*_[a-z0-9][a-z0-9_]*\b"), "snake_case identifier"),
    # PascalCase / camelCase identifiers with >=2 capital-letter words joined.
    # Catches: AudioStreamPlayer, PlayerController, AudioBus.
    # Single capitalized words like "Save" or "Continue" are NOT flagged.
    (re.compile(r"\b[A-Z][a-z]+(?:[A-Z][a-z]+){1,}\b"), "PascalCase identifier (class name)"),
    # ALL_CAPS constants joined by underscores: PROCESS_MODE_ALWAYS, MAX_HEALTH.
    (re.compile(r"\b[A-Z][A-Z0-9]*_[A-Z0-9][A-Z0-9_]*\b"), "ALL_CAPS constant"),
    # ID references: ADR-0004, TR-0042, AC-LM-17, FR-12, NFR-3.
    (re.compile(r"\b(?:ADR|TR|AC|FR|NFR|EPIC|STORY|TASK)-[A-Z]*-?\d+\b"),
     "ID reference (ADR/TR/AC/FR/NFR)"),
    # File extensions used as code references: .gd, .cs, .tscn, .tres, etc.
    (re.compile(r"\.(?:gd|cs|tscn|tres|gdshader|py|sh|csproj|json|yaml|yml|toml|cfg|md)\b",
                re.IGNORECASE),
     "file extension / path"),
    # Function-call syntax: foo(), bar(x).
    (re.compile(r"\b[a-zA-Z_]\w*\([^)]*\)(?!\s*(?:second|minute|hour|day|pixel))"),
     "function-call syntax"),
    # Engine API arrows / scope ops: ->, ::
    (re.compile(r"->|::"), "code syntax (->, ::)"),
    # Forward-slash paths: design/gdd/foo, .claude/hooks/bar
    (re.compile(r"(?:\.\w+|\w+)/[\w./-]+"), "file path"),
]

# Length caps (in words, after stripping markdown bold/italic markers).
PLAIN_MAX_WORDS = 40
DESC_MAX_WORDS = 100


def strip_markdown(text):
    """Strip ** and * bold/italic markers so word counts reflect prose only."""
    return re.sub(r"\*+", "", text)


def validate_option(header, label, desc):
    issues = []

    plain_m = PLAIN_PATTERN.search(desc)
    tech_m = TECH_PATTERN.search(desc)

    if not plain_m:
        issues.append("missing plain-English marker (e.g. \"What you'll experience:\" or \"The player sees...\")")
    if not tech_m:
        issues.append("missing \"Technical\" marker")

    # Ordering check: plain MUST come before technical.
    if plain_m and tech_m and plain_m.start() > tech_m.start():
        issues.append("plain-English section must appear BEFORE the Technical section (the user reads plain first)")

    # Whole-description length cap.
    total_words = len(strip_markdown(desc).split())
    if total_words > DESC_MAX_WORDS:
        issues.append(f"option description too long: {total_words} words (max {DESC_MAX_WORDS}). Trim both sections.")

    # Plain-section content checks -- only meaningful when both markers exist
    # AND plain comes first.
    if plain_m and tech_m and plain_m.start() < tech_m.start():
        plain_section = desc[plain_m.start():tech_m.start()]
        plain_clean = strip_markdown(plain_section)

        # Length cap on plain section.
        plain_words = len(plain_clean.split())
        if plain_words > PLAIN_MAX_WORDS:
            issues.append(f"plain-English section too long: {plain_words} words (max {PLAIN_MAX_WORDS}). Pick the most important player-facing fact and cut the rest.")

        # Jargon scan. Blank out the marker phrase itself so the marker
        # words don't trigger jargon patterns.
        marker_text = plain_m.group(0)
        scan_text = plain_clean.replace(marker_text, " " * len(marker_text), 1)

        for pat, name in JARGON_PATTERNS:
            found = pat.findall(scan_text)
            # findall may return tuples (capture groups) or strings;
            # normalize to strings for display.
            samples = []
            for f in found:
                token = f if isinstance(f, str) else (f[0] if f else "")
                if token and token not in samples:
                    samples.append(token)
                if len(samples) >= 3:
                    break
            if samples:
                quoted = ", ".join(repr(s) for s in samples)
                issues.append(f"jargon in plain-English section -- {name}: {quoted}. Rephrase in everyday words a non-programmer would use.")

    return issues


violations = []
for q in questions:
    header = q.get("header", "(no header)")
    for opt in q.get("options", []):
        label = opt.get("label", "(no label)")
        desc = opt.get("description", "") or ""
        opt_issues = validate_option(header, label, desc)
        for issue in opt_issues:
            violations.append(f"  [{header} > {label}] {issue}")


if violations:
    out = sys.stderr
    print("=== AskUserQuestion BLOCKED: user-friendly option format required ===", file=out)
    print("", file=out)
    print("Every option's description must satisfy ALL of:", file=out)
    print("  1. Has a PLAIN-ENGLISH marker (\"What you'll experience\" or \"The player sees/hears/feels/will/can/won't\")", file=out)
    print("  2. Has a TECHNICAL marker (the word \"Technical\")", file=out)
    print("  3. Plain marker comes BEFORE technical marker", file=out)
    print(f"  4. Plain section <= {PLAIN_MAX_WORDS} words", file=out)
    print(f"  5. Whole description <= {DESC_MAX_WORDS} words", file=out)
    print("  6. Plain section is JARGON-FREE (no snake_case, PascalCase, ALL_CAPS,", file=out)
    print("     ADR/TR/AC IDs, file paths, backtick code, or function calls)", file=out)
    print("", file=out)
    print("Violations:", file=out)
    for v in violations:
        print(v, file=out)
    print("", file=out)
    print("Canonical option format:", file=out)
    print("", file=out)
    print("  **What you'll experience:** <short, jargon-free sentence about what", file=out)
    print("  the user/player sees, hears, feels, or does. Plain words only --", file=out)
    print("  if the user can't picture it, rewrite it.>", file=out)
    print("", file=out)
    print("  **Technical:** <jargon, file paths, ADR IDs, variable names. Keep", file=out)
    print("  short -- this is an audit-trail footer, not the explanation.>", file=out)
    print("", file=out)
    print("Tip: if you keep hitting jargon flags, you are probably writing the", file=out)
    print("technical answer first and translating to plain English second.", file=out)
    print("Write the plain version FIRST as if explaining to a friend who has", file=out)
    print("never seen the code; then add the technical footer.", file=out)
    print("=================================================================", file=out)
    sys.exit(2)

sys.exit(0)
PYEOF
)

echo "$INPUT" | "$PYTHON_CMD" -c "$PYSCRIPT"
