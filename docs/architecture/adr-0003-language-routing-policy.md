# ADR-0003: Language Routing Policy

## Status

Proposed

## Date

2026-04-25

## Engine Compatibility

| Field                     | Value                                                                                                                                                                                                                                                                        |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Engine**                | Godot 4.6.2                                                                                                                                                                                                                                                                  |
| **Domain**                | Core / Scripting                                                                                                                                                                                                                                                             |
| **Knowledge Risk**        | LOW–MEDIUM                                                                                                                                                                                                                                                                   |
| **References Consulted**  | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`                                                                       |
| **Post-Cutoff APIs Used** | GDScript variadic args (4.5), `@abstract` (4.5), C# automatic translation string extraction (4.6) — all additive, no migration risk                                                                                                                                          |
| **Verification Required** | Microbenchmark of GDScript→C# signal round-trip cost at 100+ emissions/frame (informs Damage & Health signal-flood mitigation in System 13). Confirm `partial` C# class compilation in Godot 4.6.2 + .NET SDK on dev machine before authoring System 11 (Crowd Pathfinding). |

## ADR Dependencies

| Field             | Value                                                                                                                                                                                                                                                                                                                                                                      |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Depends On**    | None — foundational ADR                                                                                                                                                                                                                                                                                                                                                    |
| **Enables**       | ADR-001 (Run State), ADR-002 (Crowd Pathfinding), ADR-004 (Juice Pipeline), ADR-006 (Save Schema), and all Layer 2+ GDDs                                                                                                                                                                                                                                                   |
| **Blocks**        | All Layer 2+ GDD authoring (cannot route system code to a language until this policy is Accepted). Specifically: Crowd Pathfinding (#10 in design order), Damage & Health (#14), Wave & Spawn (#19), Build/Modifier (#22).                                                                                                                                                 |
| **Ordering Note** | This ADR must be Accepted **first** in the ADR sequence, even though it is numbered ADR-003 in the systems index. ADRs 001/002/004/006 each implicitly assume a language has been chosen for their target system. Per `production/session-state/active.md`: _"ADR-003 (Language Routing) first since it's cross-cutting, then ADR-001 (Run State) since it gates GDD #1."_ |

## Context

### Problem Statement

Last Stand: Champions has 45 systems spanning Foundation, Core Gameplay, Feature, Presentation, Meta, and Polish layers. Godot 4.6.2 supports three first-class scripting options — GDScript, C# (via .NET 8+), and GDExtension (C++ via godot-cpp; or other languages via community bindings) — and the choice for each system has cascading consequences:

- **GDScript** ships with the engine, hot-reloads in seconds, and binds idiomatically to nodes/signals/resources, but is interpreted and ~5–10× slower than C# for hot-path numerical work.
- **C#** is JIT-compiled and roughly 5–10× faster than GDScript for tight loops and math, but requires `partial` class declarations, slower iteration (rebuild required), and a heavier toolchain (.NET SDK + IDE).
- **GDExtension/C++** is the fastest option and is the language of the engine itself, but requires native build pipelines per platform, has no hot reload, and is dramatically more complex for a solo first-time developer.

Without a written policy, individual system GDDs (and worse, individual story implementations) would re-debate this question 28 times for MVP and 45 times by V1 — producing a codebase where the language of each system reflects whoever wrote it on the day, not a coherent strategy. The Technical Director review of the systems index already flagged four systems as needing C# hot-paths (Crowd Pathfinding, Damage & Health, Wave & Spawn, Build/Modifier). This ADR formalizes that policy and the cross-language boundary rule so future systems can route deterministically.

### Constraints

- **Solo developer, first-time game dev.** Iteration speed matters more than per-system performance optimization for systems that aren't hot-paths.
- **Performance budget**: 60 fps / 16.6 ms / 1500 draw calls / 2 GB RAM (per `.claude/docs/technical-preferences.md`). The 100+ zombie target (concept) and ~thousands of card-combo permutations (concept) cannot be served entirely by GDScript.
- **Test Harness (System 45) requires deterministic, headless execution**, so the language choice must support running the simulation runner without graphics — both GDScript and C# do; GDExtension would require additional build configuration.
- **No mobile / no console** — eliminates concerns about platform-specific compilation pain (Godot mobile C# was historically rough; this is a PC-only release).
- **Engine pinned to 4.6.2.** Godot 4.6 makes both GDScript and C# fully first-class (auto string extraction from C#, dual-focus UI, IK restored — none of which favor one language over the other for our domain).

### Requirements

- Must support 100+ AI agents at 60 fps (Crowd Pathfinding requirement, System 11).
- Must support 100+ entities receiving damage events per frame without blowing the signal-flood budget (Damage & Health requirement, System 13 — see Performance Watchlist in systems index).
- Must support batched instantiation at wave-start spikes (Wave & Spawn requirement, System 18).
- Must support deep numerical composition over potentially thousands of stacked modifier permutations (Build/Modifier requirement, System 23).
- Must preserve solo-dev iteration speed for the remaining ~41 systems where performance is not the constraint.
- Must define a single, testable boundary rule between languages so cross-language coupling does not become a debugging swamp.
- Must keep gameplay values data-driven (project coding standard) regardless of language.

## Decision

**Hybrid policy: GDScript by default, C# for performance-critical hot-paths, GDExtension excluded from MVP and V1 scope. Cross-language boundaries communicate via signals — never direct method calls — with the GDScript side as the orchestrator.**

### Routing Rules

1. **GDScript is the default language for all new systems** unless the system meets a documented hot-path criterion (below). All UI (Control nodes), all scene/orchestration code, all data-driven gameplay glue, all save/load code, all signal wiring, and all `_ready()` / `_process()` lifecycle code lives in GDScript.

2. **C# is required when at least one of the following is true:**
   - The system runs tight numerical loops over **>50 entities per frame** at peak load (e.g., per-frame health updates on 100 zombies).
   - The system performs **batch object creation/destruction** at known spike points (e.g., wave start spawning 30+ enemies in one frame).
   - The system performs **combinatorial math composition** where naive iteration would exceed 0.5 ms (e.g., stacking N modifiers across M targets to compute final stats).
   - Profiling against a written budget shows GDScript cannot hit it (must be measured, not guessed).

3. **GDExtension (C++ via godot-cpp) is excluded from MVP and V1 scope.** Re-evaluate only post-V1 if profiling shows C# itself cannot hit budget for a specific system. No exceptions during MVP or V1 without a new ADR superseding this one.

4. **Hot-path scope is bounded.** When a system is flagged as C#, only the hot-path code (the inner loop, the math kernel, the batch operation) is C#. The orchestration, the configuration loading, the signal wiring, and the editor-side scene composition stay in GDScript. The systems-index makes this explicit with the `C# hot-path / GDScript orchestration` annotation.

### Initial System Routing (per systems-index, frozen by this ADR)

| System                    | #   | Language                             | Hot-path Justification                                                               |
| ------------------------- | --- | ------------------------------------ | ------------------------------------------------------------------------------------ |
| Crowd Pathfinding         | 11  | C#                                   | 100+ agents per frame; meets criterion 1                                             |
| Damage & Health           | 13  | C# hot-path / GDScript orchestration | Per-frame health updates on 100+ enemies; meets criteria 1 + signal-flood mitigation |
| Wave & Spawn              | 18  | C# batching / GDScript orchestration | Spike-instantiation at wave start; meets criterion 2                                 |
| Build / Modifier Stacking | 23  | C# math / GDScript orchestration     | Combinatorial composition over thousands of card permutations; meets criterion 3     |

All other 41 systems route to GDScript.

### Cross-Language Boundary Contract

The single, project-wide rule: **signals over direct cross-language method calls.**

- **C# emits, GDScript connects** is the default direction (GDScript is the orchestrator).
- **GDScript→C#**: Use direct method calls only when invoking a stateless C# computation (e.g., `BuildModifier.ComputeStats(input)` — user-defined C# methods preserve PascalCase across the GDScript boundary; only `[Signal]` delegate names auto-translate to snake_case, see line below and `forbidden_patterns: csharp_method_snakecase_in_gdscript_call` registered by ADR-0002). Do not call C# methods from GDScript signal handlers in tight loops — pre-resolve the Callable once and reuse.
- **C# signal definitions** use the C# delegate pattern: `[Signal] public delegate void HealthChangedEventHandler(float oldValue, float newValue);` per `.claude/docs/technical-preferences.md`. The signal name in PascalCase + `EventHandler` suffix on the C# side surfaces to GDScript as `health_changed` (snake_case).
- **GDScript→C# signal connection** uses the typed Callable form: `health_component.health_changed.connect(_on_health_changed)`. Avoid string-based connection (deprecated since Godot 4.0; see `deprecated-apis.md`).
- **Shared data shapes** (the things that cross the boundary) use Godot built-in types (`Vector2`, `float`, `int`, `Array`, `Dictionary`) or Godot `Resource` subclasses. Custom C# struct types do not cross to GDScript.
- **Marshalling cost is load-bearing.** Every C#↔GDScript signal crossing incurs Variant marshalling overhead on each argument. At 100+ emissions/frame this cost compounds materially. **Therefore the "batch in C#; emit signals only on state transitions" rule for Damage & Health (System 13) is mandatory, not advisory** — emitting per-hit damage signals from C# to GDScript at peak load is the cross-language equivalent of GDScript signal-flood and will blow the frame budget. This rule generalizes: any C# hot-path that emits to GDScript more than ~50 times per frame must batch.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                      GDScript Orchestration Layer                    │
│  (Run State, Champion, Player Controller, Weapon, Ability, UI,       │
│   Card-Roll, Placement & Grid, Loot, HUD, all of Layer 4–6, etc.)    │
│                                                                      │
│   • Owns scene tree, _process loop, signal connections               │
│   • Loads data resources, drives state machines                      │
│   • Emits orchestration signals; connects to C# signals via Callable │
└────────────────┬───────────────────────▲─────────────────────────────┘
                 │ method call (rare)    │ signal (default)
                 │ for stateless compute │ from C# hot-paths
                 ▼                       │
┌──────────────────────────────────────────────────────────────────────┐
│                       C# Hot-Path Layer                              │
│  (Crowd Pathfinding inner loop, Damage & Health per-frame batch,     │
│   Wave/Spawn batched instantiation, Build/Modifier math kernel)      │
│                                                                      │
│   • partial classes extending Godot.Node / Godot.RefCounted          │
│   • [Signal] delegates emit results out                              │
│   • No GDScript node lookups inside hot loops                        │
└──────────────────────────────────────────────────────────────────────┘
                 ─── ✗ GDExtension/C++: not used in MVP/V1 ───
```

### Key Interfaces

The boundary contract is established by these interface conventions:

- **`signal_signature` (C# → GDScript)**: `[Signal] public delegate void <PascalName>EventHandler(<typed args>);` — emitter is C#, consumer is GDScript.
- **`stateless_compute (GDScript → C#)`**: `public static <ReturnType> <PascalMethodName>(<typed args>)` — invoked via cached `Callable` from GDScript, no per-frame node lookup.
- **`shared_resource` (both directions)**: `Resource` subclasses defined in GDScript may be passed to C# as `Godot.Resource` and vice versa. C# accesses GDScript `Resource` properties via `Get("property_name")` / `Set("property_name", value)` — never via reflection on GDScript-declared types.
- **C# base class selection for hot-path classes**: Use `Godot.RefCounted` for stateless computation kernels (e.g., Build/Modifier math kernel, System 23) — no scene-tree overhead, no `_process()` lifecycle, ideal for pure computation. Use `Godot.Node` (or a more specific subclass like `CharacterBody2D`) only when the class needs scene-tree presence or lifecycle methods (e.g., Crowd Pathfinding agents in System 11, per-entity health components in System 13). Choosing `Node` when `RefCounted` would suffice imposes scene-tree overhead on every instance — measurable at 100+ entities.

## Alternatives Considered

### Alternative 1: All-GDScript (defer C# until proven necessary)

- **Description**: Write every system in GDScript. Profile after MVP playtests. Migrate the slowest 1–2 systems to C# only if measurements force it.
- **Pros**:
  - Simplest tooling — no .NET SDK setup, no `partial` boilerplate, no signal-delegate pattern to learn.
  - Fastest iteration — GDScript hot-reloads in seconds; C# requires rebuild.
  - One mental model for all 45 systems.
- **Cons**:
  - Concept's 100+ zombie target is at the very edge of GDScript's capability for AI/pathfinding. Empirical reports from the Godot community put it well below 60fps in pure GDScript without significant per-frame work culling.
  - Migrating a system mid-development is dramatically more expensive than picking the right language at GDD time. The hot-path systems are also the highest-risk systems (Crowd Pathfinding flagged technical risk; Damage & Health is a bottleneck). Migration during the bottleneck phase is the worst possible time.
  - The Test Harness (System 45) needs to simulate thousands of card combos for combinatorial coverage — GDScript will likely make these tests painfully slow even when run headlessly.
- **Rejection Reason**: The four flagged systems already have known performance characteristics that GDScript cannot hit. Deferring C# means accepting one or more late-stage emergency migrations during the highest-risk phase of the project. The cost of upfront C# routing for four systems (~20% of MVP code, by system count) is lower than the cost of one mid-MVP migration.

### Alternative 2: GDScript + GDExtension/C++ (skip C#)

- **Description**: Use C++ via godot-cpp for the four hot-path systems. No C# in the project at all.
- **Pros**:
  - Highest possible performance — same language as the engine; no managed runtime overhead.
  - One toolchain to learn alongside GDScript instead of two.
  - No CLR / GC pauses.
- **Cons**:
  - Dramatically more complex build pipeline — godot-cpp requires SCons/CMake, per-platform binary builds, and careful ABI management.
  - No hot reload — rebuild required after every change. Slowest iteration of all three options.
  - Solo first-time game dev does not have the bandwidth to manage native build issues alongside game design.
  - Debug experience is worse than C# (LLDB/GDB vs. Visual Studio / Rider integrated debugging).
  - Most importantly: C# is sufficient for the four flagged systems. C++ buys performance we don't need at iteration-cost we can't afford.
- **Rejection Reason**: GDExtension solves a problem we don't have (we are not pushing the limits of C# performance — we are pushing the limits of GDScript performance for four specific systems). The toolchain complexity for a solo first-time dev is the dealbreaker. Re-evaluate post-V1 only if profiling shows C# itself cannot hit budget.

### Alternative 3: All-C# (skip GDScript entirely)

- **Description**: Adopt C# for all 45 systems. Treat GDScript as a configuration / data-only language (or eliminate it).
- **Pros**:
  - One language for all gameplay code.
  - Best performance ceiling without dropping to native.
  - Industry-standard tooling (Visual Studio / Rider) for the whole project.
- **Cons**:
  - `partial` boilerplate, `[Export]` attribute soup, and explicit type declarations slow down rapid prototyping for the 41 systems that don't need them.
  - GDScript is the engine's first language — the documentation, community examples, and tutorial ecosystem are GDScript-first. A solo first-time dev relies heavily on community examples; converting them mentally to C# adds cost on every reference.
  - Hot-reload story for C# is significantly worse than GDScript. Iteration loop on UI/feedback tuning (where most of the _fun_ gets discovered) becomes notably slower.
  - Concept explicitly warns: "If built per-weapon, becomes unmaintainable" (Juice Pipeline) — the warning generalizes. Maintainability comes from staying close to community idioms; the Godot community idiom is GDScript.
- **Rejection Reason**: Optimizes for a constraint we don't have (uniform performance across all systems) at the cost of the constraint that matters most (solo-dev iteration speed). The hybrid policy gives us C# exactly where it pays off and GDScript everywhere it doesn't hurt.

## Consequences

### Positive

- Each of the 45 systems has a deterministic, written-down language assignment by the time GDD authoring begins. No language re-debate per system.
- The four highest-risk systems (Crowd Pathfinding, Damage & Health, Wave/Spawn, Build/Modifier) get the language that gives them the best chance of hitting their performance budgets on the first attempt.
- Signal-based boundary keeps cross-language coupling explicit and discoverable — the signal connections in GDScript form a readable contract diagram of which C# components produce which events.
- Solo-dev iteration speed is preserved for ~91% of systems (41 of 45 are GDScript-only).
- Test Harness (System 45) can drive both languages headlessly because Godot's simulation runner doesn't care about language — only about the scene tree.

### Negative

- **Two toolchains to maintain**: .NET SDK + Godot. CI must build both. New machines need both installed.
- **Two naming conventions in the repo**: snake_case for GDScript, PascalCase / `_camelCase` for C#. Code reviews need to enforce this per file (already in `.claude/docs/technical-preferences.md`).
- **C# requires `partial` class declarations** that GDScript-trained eyes find unfamiliar. New C# files need a project file (`.csproj`) entry — a step easy to forget.
- **`.csproj` setup prerequisite**: Godot 4.6 C# requires the project to have been opened in the Godot editor at least once after `.csproj` creation, so the editor can generate the `GodotSharp` assembly reference. A fresh clone that goes straight to `dotnet build` without opening Godot first will fail to compile. CI must include `godot --headless --import` (or equivalent project-open step) before `dotnet build`. The Migration Plan §1 verification catches this on the dev machine.
- **Signal naming differs across the boundary** — `HealthChangedEventHandler` (C#) surfaces as `health_changed` (GDScript). Refactoring a signal name requires updating both the C# delegate and any GDScript Callable connection sites.
- **Stories that touch a hot-path system must coordinate with the orchestration GDScript side**, increasing the surface area of a single feature change. This is mitigated by signal contracts (the C# side defines the signal once; orchestration consumes it stably).

### Risks

1. **Risk: Signal round-trip cost between C# and GDScript exceeds budget at peak load (e.g., 100+ damage signals/frame).**
   - **Mitigation**: Microbenchmark on the dev machine before authoring System 13 (Damage & Health). If the round-trip cost is unacceptable, batch signal emission (one signal per frame summarizing all changes) instead of one signal per change. The Damage & Health entry in the systems-index Performance Watchlist already specifies: _"Per-frame health updates on 100+ enemies = signal flood. Batch in C# hot-path; emit signals only on state transitions."_ This ADR aligns with that mitigation.

2. **Risk: A system originally routed to GDScript turns out to need C# (or vice versa) after implementation begins.**
   - **Mitigation**: The hot-path criteria are written down (see Decision §2). If a GDScript system later meets criterion 1, 2, or 3 under profiling, that triggers a follow-up ADR documenting the migration. Re-routing without an ADR is forbidden — the registry is the single source of truth.

3. **Risk: Solo dev unfamiliarity with C# slows down the four hot-path systems disproportionately.**
   - **Mitigation**: The C# scope is bounded — only the hot-path code is C#; the surrounding orchestration stays in GDScript. The first hot-path system (Crowd Pathfinding) is preceded by a prototype phase per systems-index, which is the right place to absorb the C# learning cost.

4. **Risk: GDScript→C# coupling becomes a debugging swamp via implicit type conversions or signal signature drift.**
   - **Mitigation**: Forbidden patterns registered alongside this ADR (see §6 Registry Update): no string-based signal connections; no untyped Variant arrays crossing the boundary; cached Callable for hot-loop calls.

## GDD Requirements Addressed

| GDD System                     | Requirement                                                                                                                                     | How This ADR Addresses It                                                                                                                                                                                      |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Crowd Pathfinding (11)         | "100+ zombies @ 60 fps in Godot 4.6 is feasible but not automatic" (systems-index High-Risk)                                                    | Routes to C#; bounds hot-path scope to the inner loop; preserves orchestration in GDScript so the system author can iterate on tuning quickly.                                                                 |
| Damage & Health (13)           | "Per-frame health updates on 100+ enemies = signal flood. Batch in C# hot-path; emit signals only on state transitions" (Performance Watchlist) | Routes to C# hot-path / GDScript orchestration; signal-batching mitigation aligns with C# emit / GDScript connect direction defined here.                                                                      |
| Wave & Spawn (18)              | "Instantiation spikes at wave start. Use object pooling, NOT `instantiate()` per zombie" (Performance Watchlist)                                | Routes batching to C#; the pool itself can be C#-managed; orchestration (which wave is active, what to spawn) stays GDScript and reads from data resources.                                                    |
| Build / Modifier Stacking (23) | "Pillar 3 (Build Variety > Depth) lives or dies in stacking rules; thousands of combos comes from rules, not card count" (High-Risk)            | Routes the math composition kernel to C# so combinatorial stack evaluation stays under budget; the taxonomy itself (defined by ADR-007) is data, consumed by C#.                                               |
| Test Harness (45)              | "Headless run runner + deterministic RNG + fixture loader" (systems-index)                                                                      | Both GDScript and C# run under `--headless`; the language boundary doesn't break the simulation runner. Deterministic RNG must be threaded through both languages — registered in §6 as an interface contract. |
| All other Layer 2+ GDDs        | Each must declare a language at GDD time                                                                                                        | Routing rules in Decision §1–§3 give each system a deterministic answer without per-GDD debate.                                                                                                                |

## Performance Implications

- **CPU**: C# hot-paths buy ~5–10× headroom for the four flagged systems vs. naive GDScript. Net effect: keeps 100+ zombie scenes inside the 16.6 ms frame budget. No CPU regression for the 41 GDScript systems (which would not have benefited from C# anyway).
- **Memory**: .NET CLR adds ~50–80 MB resident overhead. Within the 2 GB RAM ceiling — non-issue.
- **Load Time**: Initial .NET assembly load adds ~100–300 ms cold-start. Acceptable for desktop launcher startup; not on a critical path.
- **Network**: N/A — single-player game.

## Migration Plan

This ADR is foundational; there is no existing code to migrate. The plan is the order in which the policy is **applied**:

1. **Verification step (before any system implementation)**: Confirm `partial` C# class compilation in Godot 4.6.2 + .NET SDK on the dev machine. Run a 30-line "hello signal from C#" sanity check connected from a GDScript scene. This is a 1-hour budget; if it fails, this ADR is blocked and we re-evaluate.
2. **Microbenchmark step**: Measure the round-trip cost of a C#→GDScript signal at 100, 500, 1000 emissions/frame. Document the result inline in the System 13 (Damage & Health) GDD as the basis for the batching decision.
3. **First C# system**: Crowd Pathfinding (System 11) — preceded by a prototype per systems-index. The prototype phase is the C# learning runway.
4. **Subsequent C# systems**: Damage & Health (13), Wave & Spawn (18), Build/Modifier (23) — each follows the prototype/GDD/implementation flow with the language already settled.
5. **All 41 GDScript systems**: Proceed with no language consideration — the policy says GDScript by default.

## Validation Criteria

This ADR is correct if the following hold by end of MVP:

- All 28 MVP systems have shipped in the language assigned by this ADR (no migrations during MVP).
- The 100+ zombie target hits 60 fps on the dev machine for at least one playtested wave configuration (validates Crowd Pathfinding C# routing).
- The signal-flood mitigation in Damage & Health holds at peak load (validates the boundary contract under stress).
- No story implementer has logged a blocked-on-language-choice issue (validates that the policy is unambiguous in practice).

This ADR is incorrect (and would warrant a superseding ADR) if any of:

- A second emergency C# migration is needed mid-MVP because criteria 1/2/3 missed a hot-path.
- Signal round-trip cost itself becomes the bottleneck even after batching, indicating the boundary model is wrong (would push toward a shared-resource direct-write model — but this would also fail the safety properties).
- The solo dev reports that maintaining two languages costs more time than the C# performance buys (would push toward all-GDScript with aggressive culling; quantitative threshold: >2 weeks lost to language-toolchain churn).

## Related Decisions

- `design/gdd/systems-index.md` — Language Routing Policy table (frozen by this ADR).
- `.claude/docs/technical-preferences.md` — Naming Conventions section, File Extension Routing table (this ADR is the _why_; technical-preferences.md is the _what to type_).
- ADR-001 (Run State / Game Flow) — pending — will use GDScript per this policy.
- ADR-002 (Crowd Pathfinding Architecture) — pending — will use C# per this policy.
- ADR-004 (Juice Pipeline Integration Model) — pending — will use GDScript per this policy.
- ADR-006 (Save Schema & Versioning) — pending — schema must serialize state owned by both GDScript and C# systems; will reference this ADR's boundary contract.
- ADR-005 (`ModifierTarget` Contract — inside Champion GDD) — Champion is GDScript orchestration; the `ModifierTarget` interface is consumed by the C# Build/Modifier math kernel via signals/Callables per this policy.
- ADR-007 (Effect Composition Taxonomy — inside Build/Modifier GDD) — taxonomy is data; runtime composition is C# per this policy.
