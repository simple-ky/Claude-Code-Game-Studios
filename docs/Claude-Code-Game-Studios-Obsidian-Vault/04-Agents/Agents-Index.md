---
title: Agents Index
tags: [agents, index]
---

# Agents Index

All 48 agents in one table, sortable, with model tier and primary skill.

> Source: `.claude/agents/*.md` and `.claude/docs/agent-roster.md`. Visual: [[_Maps/Agent-Org-Chart]].

---

## At a glance

| Tier | Count | Model | Notes |
|------|-------|-------|-------|
| Tier 1 — Leadership | 3 | Opus | High-stakes synthesis, gate sign-offs |
| Tier 2 — Department Leads | 8 | Sonnet | Domain ownership, design + review |
| Tier 3 — Specialists | 22 | Sonnet / Haiku | Specific implementation |
| Engine Specialists | 15 | Sonnet | Engine-specific patterns (Godot/Unity/Unreal) |
| **Total** | **48** | | |

---

## Tier 1 — Leadership (Opus)

| Agent | Domain | Used in skill | Note |
|-------|--------|---------------|------|
| `creative-director` | High-level vision | `/brainstorm`, `/review-all-gdds`, `/gate-check` | Pillar conflicts, tone |
| `technical-director` | Technical vision | `/architecture-review`, `/create-architecture`, `/gate-check` | Stack choice, perf strategy |
| `producer` | Production management | `/sprint-plan`, `/scope-check`, `/milestone-review` | Coordination, risk |

See [[04-Agents/Tier-1-Directors]].

---

## Tier 2 — Department Leads (Sonnet)

| Agent | Domain | Primary skill |
|-------|--------|---------------|
| `game-designer` | Game design | `/design-system` |
| `lead-programmer` | Code architecture | `/code-review`, `/dev-story` (delegate) |
| `art-director` | Visual direction | `/art-bible` |
| `audio-director` | Audio direction | `/team-audio` |
| `narrative-director` | Story + writing | `/team-narrative` |
| `qa-lead` | Quality assurance | `/qa-plan`, `/gate-check` |
| `release-manager` | Release pipeline | `/release-checklist`, `/launch-checklist` |
| `localization-lead` | Internationalization | `/localize` |

See [[04-Agents/Tier-2-Department-Leads]].

---

## Tier 3 — Specialists

### Design specialists (Sonnet)

| Agent | Domain | Primary skill |
|-------|--------|---------------|
| `systems-designer` | Mechanic/formula design | `/design-system` |
| `level-designer` | Level layouts, encounters | `/team-level` |
| `economy-designer` | Resources, loot, progression | `/balance-check` |

### Programmer specialists (Sonnet)

| Agent | Domain | Primary skill |
|-------|--------|---------------|
| `gameplay-programmer` | Feature implementation | `/dev-story` |
| `engine-programmer` | Core engine, rendering, physics | `/dev-story` |
| `ai-programmer` | Behavior trees, pathfinding | `/dev-story` |
| `network-programmer` | Replication, lag compensation | `/dev-story` |
| `tools-programmer` | Editor extensions, pipeline tools | `/dev-story` |
| `ui-programmer` | UI framework, screens | `/dev-story` |

### Other Tier-3 specialists

| Agent | Domain | Model | Primary skill |
|-------|--------|-------|---------------|
| `technical-artist` | Shaders, VFX, optimization | Sonnet | `/team-polish` |
| `sound-designer` | SFX specs, audio events | Haiku | `/team-audio` |
| `writer` | Dialogue, lore, descriptions | Sonnet | `/team-narrative` |
| `world-builder` | World rules, factions, history | Sonnet | `/team-narrative` |
| `qa-tester` | Test cases, bug reports | Haiku | `/qa-plan`, `/bug-report` |
| `performance-analyst` | Profiling, optimization | Sonnet | `/perf-profile` |
| `devops-engineer` | CI/CD, build scripts | Haiku | `/test-setup`, `/team-release` |
| `analytics-engineer` | Telemetry, A/B tests | Sonnet | `/team-live-ops` |
| `ux-designer` | User flows, wireframes | Sonnet | `/ux-design` |
| `prototyper` | Throwaway prototypes | Sonnet | `/prototype` |
| `security-engineer` | Anti-cheat, save encryption | Sonnet | `/security-audit` |
| `accessibility-specialist` | WCAG, colorblind, remap | Haiku | `/ux-review` |
| `live-ops-designer` | Seasons, events, retention | Sonnet | `/team-live-ops` |
| `community-manager` | Patch notes, player feedback | Haiku | `/patch-notes` |

See [[04-Agents/Tier-3-Specialists]].

---

## Engine specialists (use the matching set)

### Godot 4

| Agent | Owns |
|-------|------|
| `godot-specialist` | Cross-language decisions, node/scene architecture |
| `godot-gdscript-specialist` | All `.gd` files |
| `godot-csharp-specialist` | All `.cs` files |
| `godot-shader-specialist` | `.gdshader`, VisualShader resources |
| `godot-gdextension-specialist` | C++/Rust bindings |

### Unity

| Agent | Owns |
|-------|------|
| `unity-specialist` | MonoBehaviour vs DOTS decisions |
| `unity-dots-specialist` | DOTS/ECS, Jobs, Burst |
| `unity-shader-specialist` | Shader Graph, VFX Graph |
| `unity-addressables-specialist` | Asset management |
| `unity-ui-specialist` | UI Toolkit, UGUI |

### Unreal Engine 5

| Agent | Owns |
|-------|------|
| `unreal-specialist` | Blueprint vs C++, UE subsystems |
| `ue-gas-specialist` | Gameplay Ability System |
| `ue-blueprint-specialist` | Blueprint architecture |
| `ue-replication-specialist` | Networking, replication |
| `ue-umg-specialist` | UMG, CommonUI |

See [[04-Agents/Engine-Specialists-Godot-Unity-Unreal]].

---

## Delegation rules (summary)

A leadership agent can delegate to its leads. A lead can delegate to its specialists. A specialist cannot delegate; it can only consult horizontally with permission.

| From | Can delegate to |
|------|-----------------|
| `creative-director` | `game-designer`, `art-director`, `audio-director`, `narrative-director` |
| `technical-director` | `lead-programmer`, `devops-engineer`, `performance-analyst`, `technical-artist` |
| `producer` | Any agent (task assignment within their domain only) |
| `lead-programmer` | All programmer specialists |
| `game-designer` | `systems-designer`, `level-designer`, `economy-designer` |
| `qa-lead` | `qa-tester` |
| `[engine]-specialist` | engine sub-specialists |
| Specialists | (cannot delegate further) |

Full table: `.claude/docs/agent-coordination-map.md`.

---

## How to talk to agents

You don't, directly. Skills do that. But if you must:

- `Task` tool with `subagent_type: <agent-name>` spawns the agent
- Provide a complete brief — agents don't see prior conversation
- Use the protocol in [[02-Core-Concepts/Collaboration-Protocol]]

---

## See also

- [[_Maps/Agent-Org-Chart]] — visual hierarchy
- [[02-Core-Concepts/The-Studio-Metaphor]] — why this structure exists
- [[04-Agents/Tier-1-Directors]]
- [[04-Agents/Tier-2-Department-Leads]]
- [[04-Agents/Tier-3-Specialists]]
- [[04-Agents/Engine-Specialists-Godot-Unity-Unreal]]
