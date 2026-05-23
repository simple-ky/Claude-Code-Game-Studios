# Systems Index: Last Stand: Champions

> **Status**: Draft — Director-Reviewed (2026-04-25); Run State #8 **Approved** (R3 + ADR propagation 2026-05-01); **Lane / Map #7 Approved** (R2.1 inline-fix pass 2026-05-02); **Input System #1 Designed** (`/design-system` 2026-05-16 — pending `/design-review`); **Camera System #6 Designed** (`/design-system` 2026-05-23 — pending `/design-review`); Wave Summary UI #32 DELETED
> **Created**: 2026-04-25
> **Last Updated**: 2026-05-23 (Camera #6 designed via `/design-system`; lean review mode; qa-lead audited Section H; ready for `/design-review` in fresh session)
> **Source Concept**: design/gdd/game-concept.md
>
> **Director Review Summary**: Both `creative-director` and `technical-director`
> returned CONCERNS. All 11 findings have been applied: 3 tier swaps, 1 new
> system (Test Harness), Language column added, 6 ADRs added to the
> pre-GDD-authoring plan (now 7 total), Build/Modifier reordered ahead of Card
> via Effect Taxonomy ADR, performance watchlist added, anti-pillar guards
> added to Difficulty Modifier and Wall/Fortification.

---

## Overview

*Last Stand: Champions* is a top-down hero-defense roguelite where 45 systems
combine to deliver a single hypothesis: **the Champion pick fundamentally
reshapes the game's moment-to-moment feel** (Pillar 1), every kill is visceral
(Pillar 2), build variety beats build depth (Pillar 3), and mastery comes from
build expression rather than reflexes (Pillar 4). The mechanical scope is
large for a solo first-time dev (concept estimates 12-18 months to V1), so
this index is the single source of truth for what gets built, in what order,
and at what scope tier. Every system listed below maps to one of the concept's
five core mechanics, the core loop, or an inferred dependency the concept
implies but doesn't name.

The MVP question is binary: *is the Champion × card-roll × horde-defense loop
fun enough to keep players coming back?* The 28 MVP systems below exist to
answer that question. The remaining 17 systems take that validated loop and
shape it into the V1 launch product.

---

## Systems Enumeration

| # | System Name | Category | Priority | Language | Status | Design Doc | Depends On |
|---|---|---|---|---|---|---|---|
| 1 | Input System | Core | MVP | GDScript | **Designed** (`/design-system` 2026-05-16; lean review mode; 14 Core Rules, 28-action vocabulary, 3 formulas, 28 edge cases, 24 ACs, 7 Open Questions; **pending `/design-review` in fresh session**) | [input-system.md](input-system.md) | — |
| 2 | Save / Load System | Persistence | Vertical Slice | GDScript | Not Started | — | — |
| 3 | Audio Bus / Sound Manager | Audio | MVP | GDScript | Not Started | — | — |
| 4 | VFX / Particle System | Core | MVP | GDScript | Not Started | — | — |
| 5 | Dynamic Lighting System | Core | Vertical Slice | GDScript | Not Started | — | — |
| 6 | Camera System | Core | MVP | GDScript | **Designed** (`/design-system` 2026-05-23; lean review mode; 9 Core Rules, 10 formulas D.1–D.10, 24 edge cases in E.1–E.3, 5 dependencies, 8 tuning knobs, 23 ACs (14 BLOCKING, 4 DEFERRED), 10 Open Questions; qa-lead audited Section H; **pending `/design-review` in fresh session**) | [camera-system.md](camera-system.md) | Lane / Map, Run State, Champion, Juice, Input |
| 7 | Lane / Map System | Core | MVP | GDScript | **Approved** (R2.1 inline-fix pass 2026-05-02 — `/design-review` Round 2 returned CONDITIONAL APPROVED, all 2 blockers + 16 inline fixes resolved same session; pending `/propagate-design-change` for ADR-0001/0002 amendments per [decisions-2026-05-02.md](reviews/lane-map-system-decisions-2026-05-02.md) Section G) | [lane-map-system.md](lane-map-system.md) | — |
| 8 | Run State / Game Flow System | Core | MVP | GDScript | **Approved** (R3 applied + ADRs 0001+0006 propagated 2026-05-01) | [run-state-game-flow.md](run-state-game-flow.md) | — |
| 9 | Juice / Feedback Pipeline | Core | MVP | GDScript | Not Started | — | Audio Bus, Camera, VFX |
| 10 | Adaptive Music System (inferred) | Audio | Alpha | GDScript | Not Started | — | Audio Bus, Run State |
| 11 | Crowd Pathfinding | Core | MVP | **C#** | Not Started | — | Lane / Map |
| 12 | Champion System | Gameplay | MVP | GDScript | Not Started | — | — (contract) |
| 13 | Damage & Health System (inferred) | Gameplay | MVP | **C# hot-path / GDScript orchestration** | Not Started | — | VFX, Juice |
| 14 | Player Controller / Movement (inferred) | Gameplay | MVP | GDScript | Not Started | — | Input, Camera, Champion |
| 15 | Weapon / Shooting System (inferred) | Gameplay | MVP | GDScript | Not Started | — | Input, Champion, Damage & Health, VFX |
| 16 | Ability System | Gameplay | MVP | GDScript | Not Started | — | Input, Champion, Damage & Health, VFX |
| 17 | Zombie / Enemy AI | Gameplay | MVP | GDScript | Not Started | — | Crowd Pathfinding, Damage & Health |
| 18 | Wave & Spawn System | Gameplay | MVP | **C# batching / GDScript orchestration** | Not Started | — | Zombie AI, Lane / Map, Run State |
| 19 | Streak / Combo System | Gameplay | **MVP** | GDScript | Not Started | — | Damage & Health |
| 20 | Resource / Economy System | Economy | MVP | GDScript | Not Started | — | Run State, Wave |
| 21 | Card System | Gameplay | MVP | GDScript | Not Started | — | Champion, Ability, Weapon, Build/Modifier (Effect Taxonomy) |
| 22 | Card-Roll System | Gameplay | MVP | GDScript | Not Started | — | Card, Run State, Wave |
| 23 | Build / Modifier Stacking (inferred) | Gameplay | MVP | **C# math / GDScript orchestration** | Not Started | — | Champion, Ability, Weapon *(Card consumed at runtime; taxonomy authored first)* |
| 24 | Placeable Unit System | Gameplay | MVP | GDScript | Not Started | — | Zombie AI, Damage & Health |
| 25 | Placement & Grid System (inferred) | Gameplay | MVP | GDScript | Not Started | — | Lane / Map, Placeable Unit, Resource / Economy |
| 26 | Tower Upgrade System | Gameplay | Vertical Slice | GDScript | Not Started | — | Placeable Unit, Resource / Economy |
| 27 | Wall / Fortification System | Gameplay | Vertical Slice | GDScript | Not Started | — | Lane / Map, Damage & Health, Resource / Economy |
| 28 | Loot / Drop System | Economy | MVP | GDScript | Not Started | — | Wave, Zombie AI, Resource / Economy |
| 29 | HUD System (inferred) | UI | MVP | GDScript | Not Started | — | Damage & Health, Ability, Resource / Economy, Streak, Run State |
| 30 | Card-Roll UI (inferred) | UI | MVP | GDScript | Not Started | — | Card-Roll |
| 31 | Placement UI (inferred) | UI | MVP | GDScript | Not Started | — | Placement & Grid, Placeable Unit, Resource / Economy |
| ~~32~~ | ~~Wave Summary UI~~ | ~~UI~~ | ~~**Vertical Slice**~~ | ~~GDScript~~ | **DELETED 2026-05-01 (Run State GDD R2 / D2)** — replaced by HUD #29 toast notification + Tab-toggle run summary; no dedicated wave-summary consumer | — | — |
| 33 | Main Menu & Champion Select (inferred) | UI | **Vertical Slice** | GDScript | Not Started | — | Champion, Meta-Progression, Run State |
| 34 | Run Results / Death UI (inferred) | UI | MVP | GDScript | Not Started | — | Run State, Meta-Currency |
| 35 | Damage Number / Kill Feedback | UI | MVP | GDScript | Not Started | — | Damage & Health, Juice |
| 36 | Tutorial / Onboarding | Meta | Vertical Slice | GDScript | Not Started | — | (most Core + UI systems) |
| 37 | Meta-Currency System | Progression | Alpha | GDScript | Not Started | — | Save / Load, Run State |
| 38 | Meta-Progression / Unlocks | Progression | Alpha | GDScript | Not Started | — | Meta-Currency, Save / Load |
| 39 | Per-Champion Mastery Track | Progression | Alpha | GDScript | Not Started | — | Meta-Progression, Save / Load |
| 40 | Difficulty Modifier System | Gameplay | Alpha | GDScript | Not Started | — | Meta-Progression, Wave |
| 41 | Leaderboard System | Meta | Alpha | GDScript | Not Started | — | Save / Load, Run State |
| 42 | Settings / Options (inferred) | Persistence | Vertical Slice | GDScript | Not Started | — | Save / Load, Audio Bus, Input |
| 43 | Accessibility System | Meta | Alpha | GDScript | Not Started | — | Input, HUD, Settings |
| 44 | Achievement System (inferred) | Progression | Full Vision | GDScript | Not Started | — | Save / Load, Meta-Progression |
| 45 | Test Harness / Simulation Runner (TD-added) | Meta | MVP | GDScript | Not Started | — | Run State *(card-combo simulations come online after Card GDD)* |

> **Bold** = revised from original draft per director review (priority, language).
> System 45 added by Technical Director recommendation to mitigate card-combo combinatorial test risk.

---

## Categories

| Category | Description | Systems in this index |
|----------|-------------|-----------------------|
| **Core** | Foundation systems everything depends on | 1, 4, 5, 6, 7, 8, 9, 11 |
| **Gameplay** | The systems that make the game fun | 12-19, 21-28, 40 |
| **Progression** | How the player grows over time (across runs) | 37, 38, 39, 44 |
| **Economy** | Resource creation and consumption | 20, 28 |
| **Persistence** | Save state and continuity | 2, 42 |
| **UI** | Player-facing information displays | 29-35 |
| **Audio** | Sound and music systems | 3, 10 |
| **Meta** | Systems outside the core game loop | 36, 41, 43, 45 |

*(No Narrative category — concept specifies "no cutscenes; light lore through loading cards and Champion backstories." Lore content is delivered through Card and Champion systems' data, not a dedicated dialogue system.)*

---

## Language Routing Policy (per ADR-003)

| Language | Used For | Rationale |
|----------|----------|-----------|
| **GDScript** | Default for all systems unless flagged | Productivity for solo dev; native Godot signal/scene model fit |
| **C#** | Performance-critical hot-paths | `Crowd Pathfinding (11)`, `Damage & Health hot-path (13)`, `Wave/Spawn batching (18)`, `Build/Modifier math (23)` |
| **GDExtension (C++)** | None planned | Not required for MVP/V1 scope |

**Boundary rule**: signals over direct cross-language method calls. Champion (12) orchestration stays GDScript even though its math (via Build/Modifier 23) runs in C#.

---

## Priority Tiers

| Tier | Definition | Target Milestone | Count |
|------|------------|------------------|-------|
| **MVP** | Required to answer "is the core loop fun?" — Champion × card-roll × horde-defense | Tier 0 prototype (3-4 months) | 28 |
| **Vertical Slice** | MVP polished to demo-quality — Steam Next Fest / playtest readiness | VS demo | 8 |
| **Alpha** | Concept's Tier 1 V1 launch target — full content, meta-progression, bosses | Alpha milestone (12-18 months) | 8 |
| **Full Vision** | Stretch / post-launch (concept's Tier 2-3) | Post-launch updates | 1 |

### Per-tier "why" highlights

- **MVP — Champion System**: Pillar 1 is the entire hypothesis. Without 2 distinct Champions, the MVP cannot answer its core question.
- **MVP — Card System**: Pillar 3 (build variety > depth) cannot be tested without ~20 cards covering meaningful archetypes.
- **MVP — Juice Pipeline**: Pillar 2 ("satisfying kills, always") mandates this as a *reusable* system from day 1. Concept warns: "If built per-weapon, it becomes unmaintainable."
- **MVP — Wave & Spawn**: Without designed wave compositions, you can't test whether *composition* (not HP inflation) drives difficulty (Pillar 2 anti-pillar).
- **MVP — Card-Roll**: The retention hook itself. "Will players run again to discover combos?" is core to the MVP question.
- **MVP — Streak/Combo (revised)**: Promoted from VS per CD review. Pillar 2 is "Satisfying Kills, **Always**"; the concept's 30-second loop names "Streak meter builds on uninterrupted kills; losing the meter loses tempo." Streak is moment-to-moment feel, not retention layer. Damage numbers prove "kills register"; streak proves "kills compound into tempo."
- **MVP — Test Harness (TD-added)**: Concept flags card-combo combinatorial coverage as a top-5 risk. Authoring the headless run runner + deterministic RNG + fixture loader at MVP enables card-combo simulation tests as soon as Card (21) ships.
- **VS — Wave Summary UI (revised)**: Demoted from MVP per CD review. MVP can use a console summary; full UI is VS-tier polish. Saves ~1 week of UI plumbing for the Champion authoring (the actual hypothesis test).
- **VS — Main Menu & Champion Select (revised)**: Demoted from MVP per CD review. MVP can use a debug Champion-picker dropdown; full menu is VS-tier polish. Saves ~1-2 weeks.
- **VS — Tower Upgrade & Walls**: Deferred from MVP because placement-only mechanics let us validate "is placement fun?" without conflating cognitive load.
- **VS — Wall/Fortification (rationale clarified)**: Deferred to VS to isolate placement-validation, NOT because walls are low-priority. The concept's prep loop names "repair walls" as a primary action; this system rejoins at VS once placement-fun is validated alone.
- **VS — Tutorial**: Concept *explicitly* says: "MVP uses a dev tutorial prompt overlay only."
- **VS — Save/Load**: Concept defers all meta-progression from MVP; runs don't need to persist for fun-validation. **However**, ADR-006 (Save Schema) is MVP-blocking — see ADR plan below.
- **VS — Dynamic Lighting**: Visual identity is a *Vertical Slice = look right* concern; MVP runs on placeholder art per concept.
- **Alpha — Adaptive Music**: Concept defers "full audio pass" to Tier 1.
- **Alpha — Difficulty Modifier (anti-pillar guard)**: Modifiers MUST scale composition (lane count, special density, mini-boss inclusion), NOT stat multipliers. Concept anti-pillar: "NOT difficulty-through-HP-inflation." Design test enforced in GDD.
- **Alpha — Accessibility**: Concept *explicitly* says: "full pass at Alpha."
- **Alpha — Meta-Progression cluster**: Concept's Tier 1 V1 target.
- **Full Vision — Achievement**: Inferred from Bartle Achiever profile; can ride on Meta-Progression unlock events; not required for V1.

---

## Dependency Map

### Layer 0 — Foundation (zero dependencies)

1. **Input System** — Engine-level KB/M + partial gamepad wrapper.
2. **Save / Load System** — Engine-level serialization. ADR-006 (Save Schema) authored at MVP, GDD at VS.
3. **Audio Bus / Sound Manager** — Bus structure for layered combat audio.
4. **VFX / Particle System** — Engine-level particle factory; pool gibs/particles from day 1.
5. **Dynamic Lighting System** — 2D dynamic lights per visual identity.
6. **Camera System** — Top-down camera with screen-shake hooks.
7. **Lane / Map System** — Structural map definition. **Bottleneck.**
8. **Run State / Game Flow System** — State machine sequencing run phases. **Bottleneck.**

### Layer 1 — Derived Foundation

9. **Juice / Feedback Pipeline** — depends on: Audio Bus (3), Camera (6), VFX (4). ADR-004 required.
10. **Adaptive Music System** — depends on: Audio Bus (3), Run State (8).
11. **Crowd Pathfinding** — depends on: Lane / Map (7). ADR-002 required. **C#.**
12. **Test Harness / Simulation Runner** — depends on: Run State (8). Card-combo simulations come online once Card (21) ships.

### Layer 2 — Core Gameplay

13. **Champion System** — depends on: — *(defines the contract; consumed by 14, 15, 16, 21, 23, 33)*. **Bottleneck.** ADR-005 (`ModifierTarget`) inside this GDD.
14. **Damage & Health System** — depends on: VFX (4), Juice (9). **Bottleneck. C# hot-path.**
15. **Player Controller / Movement** — depends on: Input (1), Camera (6), Champion (12).
16. **Weapon / Shooting System** — depends on: Input (1), Champion (12), Damage & Health (13), VFX (4).
17. **Ability System** — depends on: Input (1), Champion (12), Damage & Health (13), VFX (4).
18. **Zombie / Enemy AI** — depends on: Crowd Pathfinding (11), Damage & Health (13).
19. **Wave & Spawn System** — depends on: Zombie AI (17), Lane / Map (7), Run State (8). **C# batching.**
20. **Streak / Combo System** — depends on: Damage & Health (13). **MVP per CD review.**

### Layer 3 — Feature

21. **Resource / Economy System** — depends on: Run State (8), Wave (18).
22. **Build / Modifier Stacking** — depends on: Champion (12), Ability (16), Weapon (15). ADR-007 (Effect Taxonomy) required BEFORE Card. **C# math.**
23. **Card System** — depends on: Champion (12), Ability (16), Weapon (15), Build/Modifier Effect Taxonomy (23 via ADR-007).
24. **Card-Roll System** — depends on: Card (21), Run State (8), Wave (18).
25. **Placeable Unit System** — depends on: Zombie AI (17), Damage & Health (13).
26. **Placement & Grid System** — depends on: Lane / Map (7), Placeable Unit (24), Resource / Economy (20).
27. **Tower Upgrade System** — depends on: Placeable Unit (24), Resource / Economy (20).
28. **Wall / Fortification System** — depends on: Lane / Map (7), Damage & Health (13), Resource / Economy (20).
29. **Loot / Drop System** — depends on: Wave (18), Zombie AI (17), Resource / Economy (20).

### Layer 4 — Presentation

30. **HUD System** — depends on: Damage & Health (13), Ability (16), Resource / Economy (20), Streak (19), Run State (8).
31. **Card-Roll UI** — depends on: Card-Roll System (22).
32. **Placement UI** — depends on: Placement & Grid (25), Placeable Unit (24), Resource / Economy (20).
33. **Wave Summary UI** — depends on: Wave (18), Run State (8).
34. **Main Menu & Champion Select** — depends on: Champion (12), Meta-Progression (38), Run State (8).
35. **Run Results / Death UI** — depends on: Run State (8), Meta-Currency (37).
36. **Damage Number / Kill Feedback** — depends on: Damage & Health (13), Juice (9). Pool `Label` / `MultiMeshInstance2D`.
37. **Tutorial / Onboarding** — depends on: most Core + UI systems.

### Layer 5 — Meta

38. **Meta-Currency System** — depends on: Save / Load (2), Run State (8).
39. **Meta-Progression / Unlocks** — depends on: Meta-Currency (37), Save / Load (2).
40. **Per-Champion Mastery Track** — depends on: Meta-Progression (38), Save / Load (2).
41. **Difficulty Modifier System** — depends on: Meta-Progression (38), Wave (18).
42. **Leaderboard System** — depends on: Save / Load (2), Run State (8).

### Layer 6 — Polish

43. **Settings / Options** — depends on: Save / Load (2), Audio Bus (3), Input (1).
44. **Accessibility System** — depends on: Input (1), HUD (29), Settings (42).
45. **Achievement System** — depends on: Save / Load (2), Meta-Progression (38).

---

## Recommended Design Order

Strict dependency-layer order, MVP-tier first within each layer. Build/Modifier (#23) is reordered ahead of Card (#21) because its Effect Taxonomy (ADR-007) is the contract Card consumes — same pattern as Champion's `ModifierTarget`. Independent systems within the same layer can be designed in parallel.

| Order | System | # | Priority | Layer | Language | Agent(s) | Effort | Notes |
|-------|--------|---|----------|-------|----------|----------|--------|-------|
| 1 | Run State / Game Flow | 8 | MVP | Foundation | GDScript | game-designer | M | **ADR-001 REQUIRED before GDD** |
| 2 | Lane / Map System | 7 | MVP | Foundation | GDScript | game-designer + level-designer | M | **Paper-prototype 2-lane MVP map first** |
| 3 | Input System | 1 | MVP | Foundation | GDScript | game-designer | S | |
| 4 | Camera System | 6 | MVP | Foundation | GDScript | game-designer + technical-artist | S | |
| 5 | Audio Bus / Sound Manager | 3 | MVP | Foundation | GDScript | sound-designer | S | |
| 6 | VFX / Particle System | 4 | MVP | Foundation | GDScript | technical-artist | S | Pool gibs/particles from day 1 (perf watchlist) |
| 7 | Save / Load System | 2 | VS | Foundation | GDScript | game-designer | M | **ADR-006 (Save Schema) authored at MVP, GDD at VS** |
| 8 | Dynamic Lighting System | 5 | VS | Foundation | GDScript | technical-artist | S | |
| 9 | Juice / Feedback Pipeline | 9 | MVP | Derived Foundation | GDScript | technical-artist + sound-designer | M | **ADR-004 REQUIRED before GDD** (autoload vs resource; global vs per-actor hit-stop) |
| 10 | Crowd Pathfinding | 11 | MVP | Derived Foundation | **C#** | ai-programmer + game-designer | L | **ADR-002 REQUIRED first**, then prototype to validate (NavigationServer2D vs flow-field vs hybrid) |
| 11 | Test Harness / Simulation Runner | 45 | MVP | Derived Foundation | GDScript | game-designer + qa-lead | M | Headless run runner + deterministic RNG + fixture loader. Card-combo sims come online after Card GDD |
| 12 | Adaptive Music System | 10 | Alpha | Derived Foundation | GDScript | sound-designer | S | |
| 13 | Champion System | 12 | MVP | Core Gameplay | GDScript | game-designer + systems-designer | L | **Prototype Champ 1+2 + 1-2 cards before GDD freeze**; ADR-005 (`ModifierTarget`) inside this GDD |
| 14 | Damage & Health System | 13 | MVP | Core Gameplay | **C# hot-path / GDScript orchestration** | game-designer + systems-designer | L | **Run /design-review TWICE — design + technical**; pool damage numbers (perf watchlist) |
| 15 | Player Controller / Movement | 14 | MVP | Core Gameplay | GDScript | game-designer | M | |
| 16 | Weapon / Shooting System | 15 | MVP | Core Gameplay | GDScript | game-designer + systems-designer | M | |
| 17 | Ability System | 16 | MVP | Core Gameplay | GDScript | game-designer + systems-designer | M | |
| 18 | Zombie / Enemy AI | 17 | MVP | Core Gameplay | GDScript | game-designer + ai-programmer | L | 5 distinct types |
| 19 | Wave & Spawn System | 18 | MVP | Core Gameplay | **C# batching / GDScript orchestration** | game-designer + level-designer | M | Object pooling for instantiation spikes (perf watchlist) |
| 20 | Streak / Combo System | 19 | MVP | Core Gameplay | GDScript | game-designer | S | **Promoted from VS per CD review** (Pillar 2 moment-to-moment) |
| 21 | Resource / Economy System | 20 | MVP | Feature | GDScript | systems-designer | M | |
| 22 | Build / Modifier Stacking | 23 | MVP | Feature | **C# math / GDScript orchestration** | systems-designer | M | **ADR-007 (Effect Taxonomy) REQUIRED before Card GDD authoring** |
| 23 | Card System | 21 | MVP | Feature | GDScript | game-designer + systems-designer | L | 20 cards at MVP; uses `ModifierTarget` (Champion) and Effect Taxonomy (Build/Modifier) |
| 24 | Card-Roll System | 22 | MVP | Feature | GDScript | game-designer | S | |
| 25 | Placeable Unit System | 24 | MVP | Feature | GDScript | game-designer + ai-programmer | L | 4 unit types, autonomous AI |
| 26 | Placement & Grid System | 25 | MVP | Feature | GDScript | game-designer | M | |
| 27 | Loot / Drop System | 28 | MVP | Feature | GDScript | systems-designer | S | |
| 28 | Tower Upgrade System | 26 | VS | Feature | GDScript | systems-designer | S | |
| 29 | Wall / Fortification System | 27 | VS | Feature | GDScript | game-designer | S | **VS rationale: deferred to isolate placement-validation, NOT low-priority** |
| 30 | HUD System | 29 | MVP | Presentation | GDScript | ux-designer | M | Many widgets |
| 31 | Card-Roll UI | 30 | MVP | Presentation | GDScript | ux-designer | S | |
| 32 | Placement UI | 31 | MVP | Presentation | GDScript | ux-designer | S | |
| 33 | Damage Number / Kill Feedback | 35 | MVP | Presentation | GDScript | ux-designer + technical-artist | S | **Pool `Label` / `MultiMeshInstance2D` from day 1** (perf watchlist) |
| 34 | Run Results / Death UI | 34 | MVP | Presentation | GDScript | ux-designer | S | Minimal version |
| 35 | Wave Summary UI | 32 | VS | Presentation | GDScript | ux-designer | S | **Demoted from MVP per CD review** (debug stand-in at MVP) |
| 36 | Main Menu & Champion Select | 33 | VS | Presentation | GDScript | ux-designer | S | **Demoted from MVP per CD review** (debug Champion-picker dropdown at MVP) |
| 37 | Tutorial / Onboarding | 36 | VS | Presentation | GDScript | game-designer + ux-designer | M | |
| 38 | Meta-Currency System | 37 | Alpha | Meta | GDScript | systems-designer | S | |
| 39 | Meta-Progression / Unlocks | 38 | Alpha | Meta | GDScript | systems-designer | M | |
| 40 | Per-Champion Mastery Track | 39 | Alpha | Meta | GDScript | systems-designer | S | |
| 41 | Difficulty Modifier System | 40 | Alpha | Meta | GDScript | systems-designer | M | **Composition-scaling only (lane count, special density, mini-boss inclusion); NO HP/damage multipliers (anti-pillar)** |
| 42 | Leaderboard System | 41 | Alpha | Meta | GDScript | game-designer | S | |
| 43 | Settings / Options | 42 | VS | Polish | GDScript | ux-designer | S | |
| 44 | Accessibility System | 43 | Alpha | Polish | GDScript | ux-designer + accessibility-specialist | M | |
| 45 | Achievement System | 44 | Full Vision | Polish | GDScript | systems-designer | S | |

*Effort: S = 1 session, M = 2-3 sessions, L = 4+ sessions.*

---

## ADRs Required Before GDD Authoring

Per Technical Director recommendation, the following ADRs must be authored before specific GDDs can begin. ADRs are smaller than GDDs (one decision, one document) and lock cross-cutting contracts that ripple across many systems.

| ADR | Title | Blocks | Why |
|-----|-------|--------|-----|
| **ADR-001** | Run State / Game Flow | GDD #1 (Run State) | State enum, transition events, save snapshot points. 9+ systems depend on this contract. |
| **ADR-002** | Crowd Pathfinding Architecture | GDD #10 (Crowd Pathfinding) | NavigationServer2D vs flow-field vs hybrid; target 100+ agents @ 60fps; C# language choice. |
| **ADR-003** | Language Routing Policy | All Layer 2+ GDDs | GDScript vs C# vs GDExtension assignment; signal-based boundary rules. |
| **ADR-004** | Juice Pipeline Integration Model | GDD #9 (Juice) | Autoload vs resource pattern; global `Engine.time_scale` vs per-actor hit-stop; signal contract from Damage & Health. |
| **ADR-005** | `ModifierTarget` Contract (in Champion GDD) | GDD #13 (Champion), #16 (Ability), #15 (Weapon), #22 (Build/Modifier), #23 (Card) | Which Champion kit properties are moddable (damage, fire-rate, cooldown, projectile count). Cards consume this interface. |
| **ADR-006** | Save Schema & Versioning | All systems with persistent data | Schema rules (versioning, migration, recovery) lock at MVP even though Save/Load GDD ships at VS. Run State, Champion, Card data shapes need to know schema rules. |
| **ADR-007** | Effect Composition Taxonomy (in Build/Modifier GDD) | GDD #23 (Card) | Additive/multiplicative/replace/trigger composition rules. Card declares effects in this taxonomy. CD-flagged: this is the silent Pillar 3 (build variety) hinge. |

---

## Circular Dependencies

**No structural cycles found.** Three coordination patterns warrant attention:

### Pattern 1: Run State ↔ Wave System (event-based)

Run State drives the state machine; Wave System emits "wave complete" events. Clean A→B→A *event* pattern, not a structural dependency cycle.

**Resolution**: ADR-001 owns the state enum and transition rules; Wave System publishes events, doesn't control flow.

### Pattern 2: Champion ↔ Card System (interface contract)

Cards modify Champion stats; Champion exposes which properties are moddable.

**Resolution**: `ModifierTarget` interface (ADR-005) lives inside the Champion GDD. Cards read this interface; Champion does not depend on Cards.

### Pattern 3: Build/Modifier ↔ Card (taxonomy contract)

Cards declare effects; Build/Modifier composes them. Looks cyclic because Card GDD authors 20 effects, Build/Modifier GDD authors composition rules over those effects.

**Resolution**: ADR-007 (Effect Composition Taxonomy) is authored as Phase 1 of Build/Modifier GDD *before* Card GDD authoring begins. Card declares effects in the taxonomy; Build/Modifier's runtime stacking implementation comes after Card is data-locked.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **Champion System (12)** | Design | Pillar 1 hinges on 4 distinct-feel Champions; concept flagged as #1 creative risk. Some Champions will go through 3-4 redesigns. | **Prototype Champion 1 + Champion 2 with 1-2 cards BEFORE locking the GDD contract.** Plan for redesign rounds. ADR-005 (`ModifierTarget`) inside the GDD. |
| **Crowd Pathfinding (11)** | Technical | 100+ zombies @ 60fps in Godot 4.6 is feasible but not automatic. | **ADR-002 required FIRST**, then prototype to validate the chosen architecture. C# implementation. |
| **Juice Pipeline (9)** | Technical | Concept warns: "If built per-weapon, becomes unmaintainable." | **ADR-004 required before GDD**: autoload vs resource pattern; global vs per-actor hit-stop; signal contract from Damage & Health. |
| **Save / Load (2)** | Technical | Concept warns: corrupted saves kill retention. | **ADR-006 (Save Schema) authored at MVP**, even though Save/Load GDD ships at VS. Versioning + migration + recovery design. |
| **Card System (21)** | Design | 60-80 cards = thousands of combos; manual testing won't cover broken synergies. | **System 45 Test Harness mitigates this** via simulation runner. Defensive design rules; budget 2-3 months pure balance work in Tier 1 timeline. |
| **Run State / Game Flow (8)** | Architectural | Bottleneck — 9+ systems depend on it. | **ADR-001 required BEFORE GDD authoring.** Lock state enum + event contract early. |
| **Damage & Health (13)** | Architectural | Bottleneck — 8+ systems read/write. | **Run /design-review TWICE** — design + technical. C# hot-path. |
| **Lane / Map (7)** | Design | Bottleneck — pathfinding, wave spawning, placement, walls all assume its shape. | **Paper-prototype the 2-lane MVP map BEFORE GDD authoring.** |
| **Build / Modifier Stacking (23)** *(CD-added)* | Design | Pillar 3 (Build Variety > Depth) lives or dies in stacking rules; "thousands of combos" comes from rules, not card count. | **ADR-007 (Effect Composition Taxonomy) REQUIRED before Card GDD authoring.** Reorder design pass: Build/Modifier first, Card second. |

### Performance Watchlist (TD-added)

Beyond Crowd Pathfinding, these systems can blow the 60fps / 1500 draw call / 2GB budget if implemented naively:

- **Damage Numbers / Kill Feedback (35)**: At 100+ zombies, naive `Label` instantiation kills draw calls. Mandate pooled `Label` or `MultiMeshInstance2D` from day 1. Tuning Knob: max simultaneous numbers on screen.
- **VFX / Particle (4)**: Gibs at peak waves can spike. Pool particle emitters; cap simultaneous gib count.
- **Wave & Spawn (18)**: Instantiation spikes at wave start. Use object pooling, NOT `instantiate()` per zombie. Tuning Knob: pool size per zombie type.
- **Damage & Health (13)**: Per-frame health updates on 100+ enemies = signal flood. Batch in C# hot-path; emit signals only on state transitions (full-health → damaged, alive → dead).

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 45 |
| Design docs started | 4 (Run State #8, Lane / Map #7, Input #1, Camera #6) |
| Design docs reviewed | 2 (Run State — Approved 2026-05-01 R3; Lane / Map — Approved 2026-05-02 R2.1) |
| Design docs approved | **2** (Run State #8, Lane / Map #7) |
| Design docs designed (pending review) | **2** (Input #1 — `/design-system` 2026-05-16; Camera #6 — `/design-system` 2026-05-23) |
| Design docs in revision (post-review) | 0 |
| ADRs authored | 5 / 7 (0001, 0002, 0003, 0004, 0006; 0005+0007 live inside future GDDs); **ADR-0001 + ADR-0002 amendments pending `/propagate-design-change` after Lane/Map R2.1** |
| MVP systems designed | **4 / 28** (Run State #8 Approved, Lane / Map #7 Approved, Input #1 + Camera #6 Designed/pending review) |
| Vertical Slice systems designed | 0 / 8 (36 cumulative) |
| Alpha systems designed | 0 / 8 (44 cumulative) |
| Full Vision systems designed | 0 / 1 (45 cumulative) |

---

## Next Steps

### Phase A — ADRs (must complete before related GDDs)

- [ ] Author **ADR-001 Run State / Game Flow** — `/architecture-decision`
- [ ] Author **ADR-002 Crowd Pathfinding Architecture** — `/architecture-decision`
- [ ] Author **ADR-003 Language Routing Policy** — `/architecture-decision`
- [ ] Author **ADR-004 Juice Pipeline Integration Model** — `/architecture-decision`
- [ ] Author **ADR-006 Save Schema & Versioning** — `/architecture-decision` *(ADR-005 lives inside Champion GDD; ADR-007 lives inside Build/Modifier GDD)*

### Phase B — Paper Prototypes (gate specific GDDs)

- [ ] **Paper-prototype 2-lane MVP map** before GDD #2 (Lane / Map)
- [ ] **Prototype flow-field pathfinding for 100+ zombies** after ADR-002, before GDD #10 — `/prototype crowd-pathfinding`
- [ ] **Prototype Champion 1 + Champion 2 with 1-2 cards** before GDD #13 (Champion) freezes — `/prototype champion-feel`

### Phase C — GDD Authoring (in design order)

- [ ] Begin MVP-tier GDD authoring — `/design-system run-state-game-flow`
- [ ] Auto-pick the next undesigned system at any time — `/map-systems next`
- [ ] Run `/design-review design/gdd/[system].md` after each GDD is authored
- [ ] Run **`/design-review design/gdd/damage-and-health.md` TWICE** (design + technical) when that GDD is authored

### Phase D — Validation Gates

- [ ] Run `/review-all-gdds` after MVP cluster is complete
- [ ] Run `/gate-check pre-production` when all MVP GDDs are authored and reviewed
