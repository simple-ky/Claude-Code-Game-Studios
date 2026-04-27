---
title: Directory Structure
tags: [conventions, structure]
---

# Directory Structure

The repo's folder layout, with what each directory holds and which skills read/write it.

> Source of truth: `.claude/docs/directory-structure.md`.

---

## Top-level layout

```
/
├── CLAUDE.md                 # Master configuration (Claude Code reads this on startup)
├── .claude/                  # Agent definitions, skills, hooks, rules, docs (template machinery)
├── src/                      # Game source code
├── assets/                   # Game assets (art, audio, vfx, shaders, data)
├── design/                   # Design documents (gdd, narrative, levels, balance, ux)
├── docs/                     # Technical docs (architecture, api, postmortems, engine-reference)
├── tests/                    # Test suites (unit, integration, performance, playtest)
├── tools/                    # Build and pipeline tools
├── prototypes/               # Throwaway prototypes (isolated from src/)
└── production/               # Production management (sprints, milestones, releases)
    ├── session-state/        # Ephemeral session state (gitignored)
    └── session-logs/         # Session audit trail (gitignored)
```

---

## `.claude/` — template machinery

```
.claude/
├── agents/             # Agent definitions (one .md per agent)
├── skills/             # Skill definitions (one folder per skill, contains SKILL.md)
├── docs/               # Template-internal docs
│   ├── workflow-catalog.yaml      # Authoritative pipeline
│   ├── technical-preferences.md   # Engine + naming + budgets
│   ├── coding-standards.md
│   ├── coordination-rules.md
│   ├── directory-structure.md
│   ├── agent-roster.md
│   ├── agent-coordination-map.md
│   ├── skills-reference.md
│   └── templates/                  # Boilerplate for ADRs, GDDs, sprint plans, etc.
├── settings.json       # Hooks + permissions
└── hooks/              # Hook scripts (session-start, pre-commit, etc.)
```

**Don't edit by hand** unless you know what you're doing. Skills update these.

---

## `src/` — game code

```
src/
├── core/        # Engine/framework code, foundational systems
├── gameplay/    # Gameplay-specific systems (combat, movement, etc.)
├── ai/          # AI systems (behavior trees, perception)
├── networking/  # Multiplayer code (if applicable)
├── ui/          # UI code (HUD, menus, screens)
└── tools/       # Dev tools (in-engine debug utilities)
```

`/dev-story` writes here. Each programmer specialist owns a sub-folder roughly:
- `gameplay/` → `gameplay-programmer`
- `core/` → `engine-programmer`
- `ai/` → `ai-programmer`
- `networking/` → `network-programmer`
- `ui/` → `ui-programmer`
- `tools/` → `tools-programmer`

---

## `assets/` — game assets

```
assets/
├── art/         # Sprites, models, textures
├── audio/       # Music, SFX
├── vfx/         # Particle effects
├── shaders/     # Shader files (.gdshader, etc.)
└── data/        # JSON config / balance data (data-driven values per coding standards)
```

`/asset-spec` and `/asset-audit` read here. Naming + size budgets enforced by `/asset-audit`.

---

## `design/` — design docs

```
design/
├── gdd/                 # Per-system GDDs + game-concept.md + systems-index.md
├── narrative/           # Story, lore, dialogue
├── levels/              # Level design documents
├── balance/             # Balance spreadsheets and data
├── ux/                  # UX specifications
├── art/                 # Art bible + asset specs (art-bible.md, asset-manifest.md)
├── accessibility-requirements.md   # Accessibility tier
└── assets/              # (alt path used by some templates) asset-manifest.md
```

This is the **design-as-code** layer — every document here is an artifact a skill produces.

---

## `docs/` — technical docs

```
docs/
├── CLAUDE.md                       # Sub-instructions for the docs/ directory
├── COLLABORATIVE-DESIGN-PRINCIPLE.md
├── WORKFLOW-GUIDE.md               # Original guide (this vault complements it)
├── architecture/                   # Architecture decisions
│   ├── architecture.md
│   ├── adr-NNN-*.md
│   ├── architecture-review-*.md
│   ├── control-manifest.md
│   └── tr-registry.yaml
├── engine-reference/               # Version-pinned engine API snapshots
│   ├── godot/
│   ├── unity/
│   └── unreal/
├── examples/                       # Worked examples
├── postmortems/                    # Project postmortems (post-launch)
└── obsidian-vault/                 # ← this vault!
```

The `engine-reference/` subdirectories are critical — they're how engine specialists avoid stale-training-data errors. See [[08-Reference/Engine-Reference-Index]].

---

## `tests/` — test suites

```
tests/
├── unit/             # Unit tests (per-system folders matching src/)
├── integration/      # Multi-system integration tests
├── performance/      # Perf benchmarks
├── playtest/         # Playtest data (rare; usually production/playtests/)
├── helpers/          # Test helper libraries
├── regression-suite.md
└── (engine-specific runner files)
```

Naming: `[system]_[feature]_test.[ext]`. See [[07-Project-Conventions/Testing-Standards]].

---

## `production/` — production management

```
production/
├── stage.txt                  # Current phase (Concept / Systems Design / ... / Release)
├── review-mode.txt            # Full / Lean / Solo
├── sprint-status.yaml         # Per-story sprint status (canonical)
├── session-state/
│   └── active.md              # Current task, decisions, files in progress (gitignored)
├── session-logs/              # Audit trail (gitignored)
├── sprints/
│   └── sprint-N.md            # Per-sprint plans
├── epics/
│   └── <epic-slug>/
│       ├── EPIC.md
│       └── <story-slug>.md
├── playtests/                 # Playtest reports
├── retros/                    # Sprint retrospectives
├── milestones/                # Milestone definitions and reviews
├── qa/
│   ├── bugs/                  # Bug reports
│   ├── evidence/              # Manual test evidence
│   └── *-audit-*.md           # Audit reports
├── releases/                  # Release checklists, patch notes
├── hotfixes/                  # Hotfix records
├── perf/                      # Performance reports
├── balance/                   # Balance reports
├── polish/                    # Team-polish reports
└── security/                  # Security audit reports
```

This is the **active project state** — what the team is doing now, recently, or last sprint.

`production/session-state/` is **gitignored**. The state file persists across sessions but isn't checked in.

---

## `prototypes/` — throwaway code

```
prototypes/
└── <name>/
    ├── README.md               # Required — describes the hypothesis + findings
    ├── (engine project files)
    └── ...
```

**Lower coding standards apply here** — speed > polish. The `/prototype` skill scaffolds these. Don't refactor production code into prototypes; treat them as separate.

---

## `tools/` — build and pipeline

```
tools/
├── ci/             # CI/CD configs
├── build/          # Build scripts
└── asset-pipeline/ # Asset processing tools
```

Owned by `devops-engineer` and `tools-programmer`.

---

## What goes where (cheat sheet)

| Need to write... | Goes in... |
|------------------|------------|
| A GDD | `design/gdd/` |
| An ADR | `docs/architecture/` |
| A UX spec | `design/ux/` |
| An epic/story | `production/epics/<slug>/` |
| A sprint plan | `production/sprints/` |
| Game code | `src/` |
| A test | `tests/unit/<system>/` |
| A playtest report | `production/playtests/` |
| A bug report | `production/qa/bugs/` |
| A throwaway prototype | `prototypes/<name>/` |

---

## See also

- [[06-Documents-Produced/Document-Map]] — who writes which file
- `.claude/docs/directory-structure.md` — original reference
- [[07-Project-Conventions/Coding-Standards-Godot]]
- [[07-Project-Conventions/Testing-Standards]]
