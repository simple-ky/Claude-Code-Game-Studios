---
title: What Is This Repo?
tags: [start, overview]
---

# What Is This Repo?

A 5-minute mental model. Read this first.

---

## In one sentence

> **Claude Code Game Studios** is a *studio template* — a pre-configured set of 48 specialized AI agents, ~70 slash-command skills, and a 7-phase pipeline that lets a solo developer (or small team) ship games with the discipline of a real studio.

It is **not a game**. It is the *factory* that builds games.

---

## What you actually get

When you clone the repo, you don't get game code — you get:

| Asset | What it is | Where it lives |
|-------|-----------|----------------|
| **48 agents** | AI personas with sharply scoped roles | `.claude/agents/*.md` |
| **~70 skills** | Reusable slash commands you invoke (e.g. `/brainstorm`, `/dev-story`) | `.claude/skills/*/SKILL.md` |
| **Workflow catalog** | Authoritative list of phases and required artifacts | `.claude/docs/workflow-catalog.yaml` |
| **Templates** | Boilerplate for ADRs, GDDs, sprint plans, etc. | `.claude/docs/templates/` |
| **Engine references** | Version-pinned API snapshots (Godot/Unity/Unreal) | `docs/engine-reference/` |
| **Hooks** | Automated checks on commit/push/session-start | `.claude/settings.json` |
| **Session state** | Auto-recovers what you were doing across sessions | `production/session-state/active.md` |

You bring the game idea (or use `/brainstorm` to find one). The template handles process.

---

## How it works in three lines

1. **You invoke a `/skill`** in Claude Code.
2. **The skill spawns the right `agent(s)`** to do the work.
3. **The output is a `document` or `code` written to a known location** — which the next skill can read.

Skills, agents, and documents are the [[02-Core-Concepts/Skills-vs-Agents-vs-Docs|three layers]] of the system. They're tightly linked: you almost never need to think about which agent to spawn — the skill knows.

---

## Why it's organized like a studio

Real game studios separate **creative direction**, **technical direction**, and **production management**. They have **leads** for each department (design, art, audio, code, QA), each with **specialists** under them.

This template encodes that hierarchy as agents. The benefits:

- **Quality gates** are baked in (a `lead-programmer` review precedes a `qa-lead` review)
- **Domain boundaries** prevent cross-talk (the `economy-designer` doesn't decide UI patterns)
- **Escalation paths** are clear (design-vs-tech conflict → `producer` → directors)
- **Token efficiency** — using a Haiku-tier `qa-tester` for read-only checks saves cost vs always using Opus

See [[02-Core-Concepts/The-Studio-Metaphor]] for the full picture.

---

## The 7-phase pipeline

Every project moves through these in order, with a `/gate-check` between each:

1. **[[03-Phases/Phase-1-Concept|Concept]]** — what game are we even making?
2. **[[03-Phases/Phase-2-Systems-Design|Systems Design]]** — break the concept into systems and write a GDD per system
3. **[[03-Phases/Phase-3-Technical-Setup|Technical Setup]]** — architecture, ADRs, control manifest
4. **[[03-Phases/Phase-4-Pre-Production|Pre-Production]]** — UX specs, prototype, epics, stories, first sprint
5. **[[03-Phases/Phase-5-Production|Production]]** — implement, review, close stories, repeat
6. **[[03-Phases/Phase-6-Polish|Polish]]** — performance, balance, playtests
7. **[[03-Phases/Phase-7-Release|Release]]** — final QA, launch checklist, ship

Drawn out: [[_Maps/Pipeline-Map|Pipeline Map]].

---

## What you'll do as a user

You will mostly:

- **Run `/start`** once at the beginning
- **Run `/help`** any time you're not sure what comes next
- **Invoke skills in order** (the template tells you which)
- **Approve drafts** before files are written (every agent asks)
- **Decide** at each `/gate-check` whether to advance

The system is **collaborative, not autonomous** — agents *propose*, you *decide*. See [[02-Core-Concepts/Collaboration-Protocol]] for the protocol.

---

## What you won't do

You won't:

- Pick which agent to spawn (skills do that)
- Write boilerplate templates from scratch (templates exist)
- Track which phase you're in by hand (`/help` and `production/stage.txt` do that)
- Lose your work to context compaction (session state file is the source of truth)

---

## See also

- [[01-Start-Here/First-Session-Walkthrough]] — what `/start` actually shows you
- [[01-Start-Here/Glossary]] — every term defined
- [[02-Core-Concepts/The-Studio-Metaphor]] — *why* the agent hierarchy looks like that
- [[02-Core-Concepts/The-7-Phase-Pipeline]] — the full lifecycle
- [[_Maps/Studio-Map]] — full vault navigation
