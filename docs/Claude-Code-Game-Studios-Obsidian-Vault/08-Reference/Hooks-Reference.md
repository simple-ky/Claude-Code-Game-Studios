---
title: Hooks Reference
tags: [reference, hooks]
---

# Hooks Reference

Automated shell commands that run on Claude Code events. Configured in `.claude/settings.json`. Source: `.claude/docs/hooks-reference.md`.

---

## What hooks are

Hooks run **automatically** when Claude Code events fire. Unlike skills (which run on user invocation), hooks fire without prompting and without the collaboration protocol.

Use cases:
- Show recent git activity at session start
- Run pre-commit code quality checks
- Run pre-push test gate
- Validate assets after a merge
- Sprint retrospective trigger after sprint completion

Hooks don't write files (other than logs). They observe events and may block actions (e.g., a failing pre-commit aborts the commit).

---

## Hook events

| Event | Fires when | Example use |
|-------|------------|-------------|
| `SessionStart` | Claude Code session begins | Show recent commits, recover session state |
| `PreToolUse` | Before any tool call | Audit tool usage |
| `PostToolUse` | After any tool call | Log tool outcome |
| `UserPromptSubmit` | User sends a message | Optional gate / inject context |
| `Stop` | Claude finishes a response | Notification |
| `PreCommit` | Before `git commit` | Code quality + design checks |
| `PrePush` | Before `git push` | Test gate |
| `PostMerge` | After `git merge` | Asset validation |
| `PostSprint` | When sprint marked done | Auto-retrospective |

Some events are Git-driven (PreCommit, PrePush, PostMerge); others are Claude Code-driven (SessionStart, etc.).

---

## Configured hooks (this project)

From `.claude/settings.json`:

| Hook | Event | What it does |
|------|-------|--------------|
| `session-start.sh` | SessionStart | Shows current branch, recent commits, detects active session state |
| `pre-commit-design-check` | PreCommit | Validates that any changed GDD/ADR has required sections |
| `pre-commit-code-quality` | PreCommit | Linting + naming conventions for code files |
| `pre-push-test-gate` | PrePush | Runs unit + integration tests; blocks push on failure |
| `post-merge-asset-validation` | PostMerge | Checks asset naming + size budgets after a merge |
| `post-sprint-retrospective` | (manual trigger) | Suggests `/retrospective` when a sprint closes |
| `log-agent` hooks | PreToolUse / PostToolUse | Audit trail in `production/session-logs/` |

See `.claude/docs/hooks-reference.md` for each hook's full schema.

---

## How hooks are configured

In `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "command": ".claude/hooks/session-start.sh",
        "name": "session-start"
      }
    ],
    "PreToolUse": [
      {
        "command": ".claude/hooks/log-agent-pre.sh",
        "name": "log-agent-pre",
        "matchers": [{"tool": "Task"}]
      }
    ]
  }
}
```

Each hook has:
- A **command** (shell script path or inline command)
- A **name** for display
- Optional **matchers** to filter when it fires

---

## The `session-start.sh` hook

Runs when a new Claude Code session opens. Displays:

```
=== Claude Code Game Studios — Session Context ===
Branch: tower-defense-game

Recent commits:
  666e0fc Fix log-agent hooks reading wrong field — audit trail always logged "unknown" (#21)
  dd2769a Update FUNDING.yml: GitHub Sponsors + Buy Me a Coffee
  ...

=== ACTIVE SESSION STATE DETECTED ===
A previous session left state at: production/session-state/active.md
Read this file to recover context and continue where you left off.

Quick summary:
[first 5 lines of active.md]
===================================
```

This is what makes session resume *just work* — you see the state file's existence and a preview without needing to remember it.

---

## Pre-commit hooks

Run before `git commit`:

### `pre-commit-design-check`

Validates that any changed GDD/ADR has required sections. If a GDD is missing the "Formulas" section, the commit is blocked with a clear message.

### `pre-commit-code-quality`

Runs linters + naming convention checks on changed code files. Catches:
- Wrong case in filenames (Windows-vs-Linux trap)
- GDScript lacking static typing
- C# class without `partial` keyword

**If a hook blocks the commit:** read the message, fix the underlying issue, re-stage, retry. Don't skip the hook (`--no-verify`) without addressing the cause — that's how broken stuff lands in main.

---

## Pre-push test gate

Runs the test suite headlessly before push. Blocks on failure.

For Godot: `godot --headless --script tests/gdunit4_runner.gd`.

If your tests are slow, this hook is annoying — but the alternative is broken main. Strategies:
- Keep the test suite under 5 minutes
- Run subset before push, full suite in CI
- Mark slow tests as integration-only (skipped in pre-push)

---

## Audit trail hooks (`log-agent`)

PreToolUse and PostToolUse hooks log every Task tool call to `production/session-logs/<date>.jsonl`. Useful for:
- Reproducing a session
- Auditing what each agent did
- Debugging unexpected behavior

The log entry includes the agent type, prompt, result summary, and timing. The recent fix #21 corrected a field-mapping bug that previously logged "unknown" instead of the agent type.

---

## Adding your own hooks

1. Write the script (shell, Python, anything executable)
2. Add to `.claude/settings.json`'s appropriate event array
3. Test by triggering the event
4. Document in `.claude/docs/hooks-reference.md`

Best practices:
- **Fail loudly with a clear message** when blocking
- **Make output human-readable** — these run automatically
- **Be fast** — slow hooks degrade the workflow
- **Idempotent** — running twice produces the same result

---

## When hooks fire and the protocol

Hooks bypass the collaboration protocol — they're automated. If a hook does block (e.g., pre-commit fails), the user sees the failure and decides:

- Fix the underlying issue and retry
- Override (rare; documented; user-invoked)
- Disable the hook (rarer; document why)

Hooks are not autonomous in the "writes files" sense — they observe and gate. They never *create* design artifacts.

---

## See also

- `.claude/settings.json` — where hooks are configured
- `.claude/docs/hooks-reference.md` — full reference
- `.claude/docs/hooks-reference/` — per-hook detail docs
- [[07-Project-Conventions/Context-Management]] — session-start.sh role in recovery
