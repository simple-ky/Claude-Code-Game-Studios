---
title: Glossary
tags: [start, reference, glossary]
---

# Glossary

Every term used in this vault and the repo, defined once. Linked from everywhere.

---

## A

**ADR (Architecture Decision Record)** — A short Markdown document capturing one significant technical decision: context, options considered, decision, consequences. Created via `/architecture-decision`. Stored in `docs/architecture/adr-NNN-*.md`. See [[06-Documents-Produced/ADR-Architecture-Decision-Record]].

**Agent** — A specialized AI persona defined in `.claude/agents/*.md` with a sharp domain (e.g. `gameplay-programmer`, `qa-tester`). Spawned by skills, not by the user directly. See [[04-Agents/Agents-Index]].

**Approved (status)** — A document state. A GDD must be `Status: Approved` before its system can be implemented. Set during `/design-review` or `/review-all-gdds`.

**Art Bible** — The visual identity specification for the project. Authored via `/art-bible`. Gates all asset production. See [[03-Phases/Phase-1-Concept]].

**Artifact** — Any file the workflow produces (a GDD, an ADR, a sprint plan). The workflow catalog tracks artifact globs to detect phase progress.

## B

**Backlog** — Stories or epics not yet scheduled into a sprint. Lives in `production/epics/**/*.md` with `Status: Ready`.

**Brainstorm** — The opening creative skill (`/brainstorm`). Uses MDA, verb-first design, player psychology frameworks to develop a game concept.

**Brownfield** — A project with existing artifacts that may not match template format. Use path D in `/start`, then `/adopt`.

## C

**Concept Phase** — Phase 1. Develops a documented game concept with pillars and scope tiers. See [[03-Phases/Phase-1-Concept]].

**Control Manifest** — Flat actionable rules sheet generated from accepted ADRs. Tells programmers exactly what they must do, must never do, and must guard against. See [[06-Documents-Produced/Control-Manifest]].

**`/clear`** — Claude Code command that wipes the conversation context. Use between unrelated tasks. State persists in files.

## D

**`/dev-story`** — The implementation skill in Production. Reads a story file, routes to the right programmer agent, and implements it. See [[05-Skills/Production-Skills]].

**Design Review (`/design-review`)** — Validates a single GDD for the 8 required sections, internal consistency, and design coherence. Returns NEEDS REVISION / APPROVED / MAJOR REVISION.

**Director** — A Tier-1 Opus-tier agent: `creative-director`, `technical-director`, `producer`. Highest creative/technical authority.

## E

**Engine Specialist** — Engine-specific agent set: Godot, Unity, or Unreal. Use only the set matching your engine. See [[04-Agents/Engine-Specialists-Godot-Unity-Unreal]].

**Epic** — A unit of work that maps to one architectural module. Contains multiple stories. Created via `/create-epics`. See [[06-Documents-Produced/Epic-and-Story]].

## F

**Foundation Layer** — Cross-cutting systems that everything else depends on (input, save/load, scene management). Decided first via Foundation-layer ADRs.

## G

**`/gate-check`** — Phase-transition validation skill. Returns PASS / CONCERNS / FAIL verdict. **Advisory** — the user always decides. See [[02-Core-Concepts/Gates-and-Reviews]].

**GDD (Game Design Document)** — A per-system design document with 8 required sections. Produced by `/design-system`. See [[06-Documents-Produced/GDD-Game-Design-Document]].

**GDExtension** — Native C++/Rust binding system for Godot 4. Owned by `godot-gdextension-specialist`.

## H

**Hook** — An automated shell command run on a Claude Code event (session start, tool use, pre-commit, post-merge). Configured in `.claude/settings.json`. See [[08-Reference/Hooks-Reference]].

## I

**Implementation Agent** — Any agent that writes code: `gameplay-programmer`, `engine-programmer`, `ai-programmer`, etc.

## L

**Lean Mode** — Default review mode. Director reviews only at gate transitions. See [[02-Core-Concepts/Gates-and-Reviews]].

## M

**MDA Framework** — Mechanics, Dynamics, Aesthetics — a game design lens used in `/brainstorm`.

**MOC (Map of Content)** — An Obsidian-specific note that just lists links to a topic's pages. The vault's [[_Maps/Studio-Map|Studio Map]] is an MOC.

## P

**Phase** — One of the 7 lifecycle phases (Concept → Release). Tracked in `production/stage.txt`. See [[02-Core-Concepts/The-7-Phase-Pipeline]].

**Phase Gate** — A `/gate-check` between two phases. Advisory verdict.

**Pillar** — A core design pillar — a non-negotiable principle the game is built around. Defined in the game concept doc.

**Producer** — Tier-1 agent that coordinates the directors and tracks production. Doesn't override creative or technical decisions.

**Prototype** — A throwaway proof-of-concept built in the `prototypes/` folder, isolated from `src/`. Created via `/prototype`.

## R

**Required ADR** — An ADR that must exist before a phase can advance. Listed by `/create-architecture`.

## S

**Session State** — The file `production/session-state/active.md` that tracks current task, decisions, files in progress. See [[07-Project-Conventions/Context-Management]].

**Skill** — A slash command in `.claude/skills/*/SKILL.md`. The user-facing entry point to a workflow. See [[05-Skills/Skills-Index]].

**Solo Mode** — Review mode with no director reviews. For jams and prototypes.

**Sprint** — A time-boxed work cycle in Production. Planned via `/sprint-plan`. Tracked via `sprint-status.yaml`.

**Story** — A per-feature implementable unit. Belongs to an epic. Implemented via `/dev-story`. See [[06-Documents-Produced/Epic-and-Story]].

**Subagent** — An agent spawned via the `Task` tool inside a single Claude Code session. Returns a result to the parent. Used by `team-*` skills.

**Systems Index** — `design/gdd/systems-index.md`. Lists every system, its priority tier (MVP / Vertical Slice / Alpha / Full Vision), dependencies, and design order.

## T

**Tier (model)** — Opus / Sonnet / Haiku. Determines model used for an agent or skill. See [[04-Agents/Agents-Index]].

**TR ID (Technical Requirement ID)** — Stable identifier (e.g. `TR-MOV-001`) linking a GDD requirement to stories. Maintained in `tr-registry.yaml`.

## U

**UX Spec** — A per-screen UX design document. Produced via `/ux-design`. See [[06-Documents-Produced/UX-Spec]].

## V

**Vertical Slice** — A single complete play-through of the core loop. Required artifact at the end of Pre-Production.

## W

**Wiki-link** — Obsidian's `[[Page Name]]` syntax that creates backlinks and graph edges. Used everywhere in this vault.

**Workflow Catalog** — `.claude/docs/workflow-catalog.yaml`. Authoritative list of phases, steps, required artifacts. Read by `/help` and `/gate-check`.

---

## See also

- [[01-Start-Here/What-Is-This-Repo]] — start here if a term is unfamiliar
- [[01-Start-Here/FAQ]] — common questions
- [[_Maps/Studio-Map]] — full vault navigation
