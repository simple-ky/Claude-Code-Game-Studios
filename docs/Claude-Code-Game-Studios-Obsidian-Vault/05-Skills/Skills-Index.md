---
title: Skills Index
tags: [skills, index]
---

# Skills Index

All ~70 slash commands in one place, by category. Type `/` in Claude Code to autocomplete any of them.

> Source of truth: `.claude/skills/*/SKILL.md`. Original reference: `.claude/docs/skills-reference.md`.

---

## Onboarding & navigation

| Command | Purpose | Phase |
|---------|---------|-------|
| `/start` | First-time onboarding — asks where you are, routes you | Pre-Phase 1 |
| `/help` | Context-aware "what do I do next?" | Any |
| `/project-stage-detect` | Full audit — phase + gap analysis | Any |
| `/setup-engine` | Configure engine + version + naming + budgets | Phase 1 |
| `/adopt` | Brownfield format audit + migration plan | Any (D path) |

See [[05-Skills/Onboarding-Skills]].

---

## Game design

| Command | Purpose | Phase |
|---------|---------|-------|
| `/brainstorm` | Guided ideation — MDA, verb-first, player psychology | Phase 1 |
| `/map-systems` | Decompose concept into systems | Phase 1 |
| `/design-system` | Section-by-section GDD authoring | Phase 2 |
| `/quick-design` | Lightweight spec for tiny systems | Phase 2 / 5 |
| `/review-all-gdds` | Cross-GDD consistency + design theory | Phase 2 |
| `/consistency-check` | Cross-GDD entity-level checks | Phase 2 / 5 |
| `/propagate-design-change` | Find affected ADRs when a GDD revises | Any |

See [[05-Skills/Design-Skills]].

---

## UX & interface

| Command | Purpose | Phase |
|---------|---------|-------|
| `/ux-design` | Section-by-section UX spec authoring | Phase 4 |
| `/ux-review` | Validate UX specs (GDD + accessibility) | Phase 4 |

---

## Architecture

| Command | Purpose | Phase |
|---------|---------|-------|
| `/create-architecture` | Master architecture doc + Required ADR list | Phase 3 |
| `/architecture-decision` | Author one ADR | Phase 3 |
| `/architecture-review` | Validate all ADRs | Phase 3 |
| `/create-control-manifest` | Flat programmer rules sheet | Phase 3 |

See [[05-Skills/Architecture-Skills]].

---

## Stories & sprints

| Command | Purpose | Phase |
|---------|---------|-------|
| `/create-epics` | GDDs+ADRs → epics | Phase 4 |
| `/create-stories` | Epic → stories | Phase 4 |
| `/dev-story` | Read story, implement, route to programmer | Phase 5 |
| `/sprint-plan` | Plan a sprint, init sprint-status.yaml | Phase 4–5 |
| `/sprint-status` | 30-line sprint snapshot | Phase 5 |
| `/story-readiness` | Validate a story is implementation-ready | Phase 5 |
| `/story-done` | 8-phase completion review, close the story | Phase 5 |
| `/estimate` | Effort estimate with confidence | Any |

See [[05-Skills/Production-Skills]].

---

## Reviews & analysis

| Command | Purpose | Phase |
|---------|---------|-------|
| `/design-review` | Single GDD review | Phase 1 / 2 |
| `/code-review` | Architectural code review | Phase 5 |
| `/balance-check` | Formula/data outlier scan | Phase 6 |
| `/asset-audit` | Naming, sizes, formats, orphans | Phase 6 |
| `/content-audit` | GDD-specified vs implemented content | Phase 5–6 |
| `/scope-check` | Scope creep detection | Phase 5 |
| `/perf-profile` | Performance profiling + recommendations | Phase 5–6 |
| `/tech-debt` | Track + prioritize technical debt | Any |
| `/gate-check` | Phase-transition validation | At gates |

---

## QA & testing

| Command | Purpose | Phase |
|---------|---------|-------|
| `/qa-plan` | Generate test plan per epic/sprint | Phase 4–5 |
| `/smoke-check` | Critical path smoke test gate | Phase 5 |
| `/soak-test` | Extended-session protocol | Phase 6 |
| `/regression-suite` | Map test coverage to GDD critical paths | Phase 5–6 |
| `/test-setup` | Scaffold test framework + CI | Phase 4 |
| `/test-helpers` | Engine-specific helper libraries | Phase 4 |
| `/test-evidence-review` | Test file + manual evidence quality review | Phase 5 |
| `/test-flakiness` | Detect non-deterministic tests | Phase 6 |
| `/skill-test` | Validate skill files for compliance | Meta |

---

## Production

| Command | Purpose | Phase |
|---------|---------|-------|
| `/milestone-review` | Milestone progress + go/no-go | Major checkpoints |
| `/retrospective` | Sprint or milestone retrospective | After sprints |
| `/bug-report` | Structured bug report | Phase 5–7 |
| `/bug-triage` | Re-prioritize open bugs | Sprint boundaries |
| `/reverse-document` | Generate docs from existing implementation | Brownfield |
| `/playtest-report` | Structured playtest doc | Phase 4 / 6 |

---

## Release

| Command | Purpose | Phase |
|---------|---------|-------|
| `/release-checklist` | Pre-release validation | Phase 7 |
| `/launch-checklist` | Final launch readiness | Phase 7 |
| `/changelog` | Auto-generate changelog | Phase 7 |
| `/patch-notes` | Player-facing patch notes | Phase 7 |
| `/hotfix` | Emergency fix workflow | Post-release |
| `/day-one-patch` | Day-one patch scoping | Phase 7 |

---

## Creative & content

| Command | Purpose | Phase |
|---------|---------|-------|
| `/prototype` | Throwaway mechanic validation | Phase 4 |
| `/onboard` | Generate contextual onboarding doc | Brownfield |
| `/localize` | Localization workflow | Phase 6–7 |
| `/asset-spec` | Per-asset visual specs + AI gen prompts | Phase 4 |
| `/art-bible` | Visual identity authoring | Phase 1 |
| `/security-audit` | Save tampering, exploits, data exposure | Phase 6 |

---

## Team orchestration

Multi-agent coordination skills:

| Command | Coordinates |
|---------|-------------|
| `/team-combat` | game-designer + gameplay-programmer + ai-programmer + technical-artist + sound-designer + qa-tester |
| `/team-narrative` | narrative-director + writer + world-builder + level-designer |
| `/team-ui` | ux-designer + ui-programmer + art-director + accessibility-specialist |
| `/team-release` | release-manager + qa-lead + devops-engineer + producer |
| `/team-polish` | performance-analyst + technical-artist + sound-designer + qa-tester |
| `/team-audio` | audio-director + sound-designer + technical-artist + gameplay-programmer |
| `/team-level` | level-designer + narrative-director + world-builder + art-director + systems-designer + qa-tester |
| `/team-live-ops` | live-ops-designer + economy-designer + analytics-engineer + community-manager + writer + narrative-director |
| `/team-qa` | qa-lead + qa-tester + gameplay-programmer + producer |

See [[05-Skills/Team-Orchestration-Skills]].

---

## Skill-improvement skills (meta)

| Command | Purpose |
|---------|---------|
| `/skill-improve` | Test-fix-retest loop on a skill |
| `/skill-test` | Validate a skill file for structure/behavior |

These maintain the template itself.

---

## How skills relate to phases

See [[05-Skills/Skills-by-Phase]] for a phase-by-phase view.

---

## See also

- [[05-Skills/Skills-by-Phase]] — same skills, organized by phase
- [[02-Core-Concepts/The-7-Phase-Pipeline]] — when to use which group
- [[_Maps/Pipeline-Map]] — visual flow
- `.claude/docs/skills-reference.md` — original reference
