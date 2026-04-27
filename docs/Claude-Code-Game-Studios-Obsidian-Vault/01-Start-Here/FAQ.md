---
title: FAQ
tags: [start, faq]
---

# FAQ

The honest answers to the questions everyone asks.

---

## Is this for solo devs or teams?

**Both, but tuned for solo and small teams.** The agent hierarchy gives a solo dev studio-grade discipline (e.g. a `qa-lead` review of test plans even when the user *is* the QA lead). Teams use it as scaffolding — the docs become the team's shared brain.

The **review mode** dial scales it: Full mode for teams, Lean for solo devs, Solo for jams.

---

## Do I need to use all 48 agents?

**No.** You don't pick agents — skills do. You'll typically interact with skills (`/brainstorm`, `/dev-story`) and the skill spawns the right agents under the hood.

The agent count looks intimidating but reflects the real division of labor in a studio. Most projects use ~15 agents heavily and the rest sporadically.

---

## Is this only for Godot?

**No, but this template is preconfigured for Godot 4.6.2.** Equivalent agent sets exist for **Unity** and **Unreal** — see [[04-Agents/Engine-Specialists-Godot-Unity-Unreal]]. To switch, run `/setup-engine` and pick another engine; the engine reference docs and naming conventions update accordingly.

---

## Why so many gates and reviews? It feels heavy.

Run **Solo mode** (`/start` → "Solo"). That removes director reviews entirely. The gates remain but are **advisory** — they never hard-block you.

Heavy process is on by default because the *cost of skipping* shows up later: a skipped GDD review becomes a refactor in Production. But it's your call.

---

## Can I jump straight to coding?

**Technically yes.** Practically: `/dev-story` won't run if there's no story file, and stories require an epic, which requires accepted ADRs, which require a GDD with the right Status. So the system enforces discipline by sequencing inputs.

If you really want to skip ahead — write code in `prototypes/`. That folder is intentionally outside the discipline pipeline. See [[03-Phases/Phase-4-Pre-Production#Prototype]].

---

## What if my game doesn't fit the template?

The template assumes a single-player or moderate-multiplayer release game. It can stretch to:

- **Live-service games** — `live-ops-designer` and `/team-live-ops` cover seasons/events.
- **Game jams** — Solo mode + skip Polish + skip half of Pre-Production.
- **Educational toys** — Skip systems-index complexity; one GDD is fine.

It's harder for: AAA-scale projects (>10 systems with sprawling dependencies), heavily research-driven games, or games where the engine is custom-built. In those cases, treat the template as **inspiration**, not contract.

---

## How does Claude Code know my project state?

Three sources:

1. **`production/stage.txt`** — current phase (set by `/gate-check` or manually)
2. **`production/session-state/active.md`** — current task, files in progress
3. **Filesystem** — Glob patterns in the workflow catalog detect artifact existence

`/help` reads all three to tell you what's next. See [[07-Project-Conventions/Context-Management]].

---

## What's the difference between a skill and an agent?

- **Skill** = the verb (a slash command — *what you ask for*)
- **Agent** = the noun (an AI persona — *who does it*)

A skill might spawn 1–10 agents. An agent never spawns a skill. See [[02-Core-Concepts/Skills-vs-Agents-vs-Docs]].

---

## Why ADRs? They feel academic.

ADRs prevent **the same architectural argument three months later**. They're 2-page docs that capture *why* you chose option A over B and what the trade-offs are. When a future you (or a new contributor) wonders "why are we using signals instead of direct calls?", the ADR is the answer.

The template enforces them in Phase 3. Skip them only at your peril. See [[06-Documents-Produced/ADR-Architecture-Decision-Record]].

---

## What happens at a gate-check?

`/gate-check` reads the workflow catalog, checks artifact existence, and returns:

- ✅ **PASS** — all required artifacts present
- ⚠️ **CONCERNS** — gaps with suggestions
- ❌ **FAIL** — missing required artifacts

**The verdict is advisory.** You can advance regardless. See [[02-Core-Concepts/Gates-and-Reviews]].

---

## My session crashed. Did I lose my work?

**No.** The system writes file-backed state continuously:

- `production/session-state/active.md` — what you were doing
- Any partially-written design doc — incrementally saved per section
- The workflow catalog is unchanged regardless

Just reopen Claude Code, run `/help`, and continue. See [[07-Project-Conventions/Context-Management]].

---

## Can I run multiple agents in parallel?

Yes — when calling the `Task` tool, multiple agents can be spawned simultaneously if their inputs are independent. The `team-*` skills do this automatically. See [[05-Skills/Team-Orchestration-Skills]].

For full parallel sessions across separate Claude Code instances, see the experimental Agent Teams pattern in `.claude/docs/coordination-rules.md`.

---

## How do I update an existing project to match this template?

Run path D in `/start`:

1. `/project-stage-detect` — full audit of what exists vs what's expected
2. `/adopt` — checks internal format compliance (e.g. does your GDD have the 8 required sections?) and produces a migration plan
3. Address gaps incrementally

---

## Where do I report issues with this vault or the template?

The template is on GitHub — file an issue. The vault you're reading is custom-generated; if a note is wrong, edit it locally or delete the vault and regenerate.

---

## See also

- [[01-Start-Here/What-Is-This-Repo]] — the mental model
- [[01-Start-Here/Glossary]] — every term defined
- [[01-Start-Here/First-Session-Walkthrough]] — what `/start` does
