# Lane / Map System

> **Status**: **R2.1 applied 2026-05-02; APPROVED for `/propagate-design-change`** (`/design-review` Round 2 returned CONDITIONAL APPROVED with 2 BLOCKERS + 16 inline fixes; all resolved inline same session per creative-director synthesis).
> **Author**: User + game-designer + level-designer + art-director (Visual/Audio); R2 author: revision pass against `design/gdd/reviews/lane-map-system-decisions-2026-05-02.md`; R2.1 author: inline-fix pass against `/design-review` Round 2 specialist findings.
> **Last Updated**: 2026-05-02 (R2.1)
> **Implements Pillar**: Pillar 4 (Low Skill Floor — readable lane spaces), Pillar 2 (Satisfying Kills — clear silhouette space). **Pillar 3 alignment retracted in R2** — Lane/Map is pillar-neutral on Build Variety; that pillar is owned by Cards (#21) and Build/Modifier (#23).
> **System Index Entry**: System #7, Foundation/Core, MVP, GDScript, Effort M (revised upward in R2 due to bigger-cell pipeline reset and geometry sharpening), agents `game-designer + level-designer`.
> **Governing ADRs**: ADR-0001 (Run State — bake fires before WAVE_PREP); ADR-0002 (Crowd Pathfinding — locked NavigationRegion2D + aggregated `LaneSystem.geometry_baked` contract); ADR-0003 (Language Routing — GDScript; **reclassified hard implementation-binding in R2**); ADR-0006 (Save Schema — no persistent state at MVP).
> **Review Mode**: `lean` initial pass; **`/design-review` Round 1 returned MAJOR REVISION NEEDED** — 8 blockers, 12 recommendations resolved per the locked decision log `design/gdd/reviews/lane-map-system-decisions-2026-05-02.md`. R2 applied by fresh session 2026-05-02; Round 2 re-verification pending.

## Overview

The Lane / Map System defines the battlefield: how many lanes a map has, how wide each lane is, where zombies enter (spawn zones), where they're trying to reach (goal zones), and what space the player can build on. From the player's perspective it's the shape of the fight — the funnel of lanes, the buildable strip behind the front line, the read-the-field-at-a-glance silhouette that shapes every placement decision wave after wave. From the project's perspective it's the foundation four other systems plug into: zombies path through it (Crowd Pathfinding), waves spawn from its zones (Wave / Spawn), towers and walls snap to its grid (Placement & Grid), and walls reshape its walkable space mid-fight (Wall / Fortification). MVP ships with **1 map and 2 lanes**; V1 expands to **3 maps** under the same data structure. The technical contract — how the navigation geometry is built, when it's ready, and what each lane exposes to its consumers — is locked separately in **ADR-0002 (Crowd / Pathfinding Architecture)**.

## Player Fantasy

*(R2.1: rewritten per Round 2 creative-director synthesis. The R1/R2 prose framed the buildable strip as "behind you, no rear, no reserve" — fitting the OLD geometry where the strip sat at the back of the lane. R2's DD#5 = "Fix the map" relocated the strip to surround the bend (40–65% lane depth). The user chose **forward-leaning kill-box** as the realigned fantasy: the player is the hunter at the seam, not the defender at the wall. This better aligns with Pillar 2 (Satisfying Kills, Always) and Pillar 4 (the bend is its own tutorial: see threat, build there, kill there).)*

The map isn't terrain — it's a verdict. Two lanes of broken road carry the dead toward the last lit ground in the world, and you take the seam where the road bends — the choke point where the threat has nowhere to go but through your guns. The buildable strip sits at the bend, small on purpose: not a wall behind you to retreat to, but **the kill-box you've claimed at the throat of the lane**. Between waves, you don't read the field as a sentry guarding a perimeter; you read it as a hunter sighting the trap. Every wave, the lanes glow brighter as they fill with bodies, and you understand the shape of the fight by the color of the threat funnelling into the seam you've drawn.

**The fantasy lands hardest** in the breath between mid-run waves, when the lanes still glow with the last wave's muzzle flashes and the kill-box at the bend is the only ground in the world that matters. Mid-wave wall placement (Section C Rule 8) is the player reaching back into the kill-box mid-fight and rebuilding the trap — DD#1's cooldown is what makes it feel like a clutch tool rather than a dial they spam.

### Pillar alignment

- **Pillar 4 (Low Skill Floor, High Expression Ceiling)** — Even a brand-new player feels "this lane, defend it" within their first few seconds on a new map. Comprehension comes from emotional clarity (one threat direction, one strip to defend, no rear to second-guess) rather than mechanical literacy. The expression ceiling lives in *what* you place, not in deciphering *where* matters. **R2 commitment**: the geometry must verifiably deliver this — sharpened bend (≥35°), buildable strip relocated to surround the bend, and a cold-playtest acceptance criterion (AC-LM-29) that gates this claim.
- **Pillar 2 (Satisfying Kills, Always)** — Kills land on the threshold of survival. Because the field constantly reads as scarce, every silhouette dropping inside it is a foot of ground kept. The visceral payoff doesn't depend on big numbers; it depends on the field-shape making each kill feel weighted.

> **Pillar 4 trade-off acknowledgment (added R2)**: Mid-wave wall placement (Section C Rule 8) is intentionally a time-pressured action. It does **not** honor Run State #8's "the run waits for you" promise — that promise is scoped to `WAVE_PREP` and `RUN_PAUSED`. Lane/Map frames mid-wave placement as a clutch tool with a real cooldown lever (DD#1 = "Click, then short cooldown"; user 2026-05-02), and accepts that the cooldown is what enforces "clutch, not optimal."

> **Pillar 3 (Build Variety) — retracted as a Lane/Map alignment claim in R2** (DD#6 = "Drop the claim"; user 2026-05-02): a small constrained strip *reduces* placement variety, it does not generate it. Build Variety is owned by Card (#21) and Build/Modifier (#23) — the actual drivers. Lane/Map's small-strip design constrains placement choices but does not generate the variety promised by Pillar 3.

### Implications carried forward

- The buildable strip stays small even at V1 scale (3 maps, 2–3 lanes each). A sprawling open-battlefield map design would break this fantasy and is therefore out of scope without a fantasy revision. *(Tracked in Section: Open Questions.)*
- Zombie types must visually distinguish at long lane range; lane lighting should shift with horde composition. *(Tracked in Section: Visual/Audio Requirements.)*
- **R2 cell-size impact**: `cell_size_px` raised 64 → 96 (DD#4 = "Bigger cells (96 px)"; user 2026-05-02). The whole project re-tunes against 96 px — every sprite, every tile, every level dimension scales up. Art Bible amendment required (tracked in Section: Open Questions). Champion sprite vs cell-size conflict resolved automatically: ≥72 px Champion now fits a single 96 px cell gap with margin.

## Detailed Design

### Core Rules

1. **A map is a named container of lane instances.** A map carries a display name and an ordered list of lane descriptors (V1 range: 2–3). The map carries no spatial data of its own; each lane owns its own geometry. V1 maps differentiate by lane count, buildable strip variant, and tile-set theme — the same lane scene may be reused across maps with different configuration values.

2. **A lane is the fundamental navigable unit.** Each lane is a `Node2D`-rooted scene with the following structure:

   | Attribute | Type | Description |
   |---|---|---|
   | `lane_id` | `int` | Zero-based index within the parent map |
   | `goal_zone_center` | `Vector2` | World-space centre of the goal zone (defender side) |
   | `spawn_zone_center` | `Vector2` | World-space centre of the spawn zone (attacker entry) |
   | `spawn_zone_radius` | `float` | World-space radius (px) within which Wave/Spawn distributes simultaneous spawns. **Default 64 px (≈ 0.67 cells at 96 px) for MVP** *(R2 — added per B5b: 50+ simultaneous spawns must not stack at a single Vector2 point; Wave/Spawn samples uniformly inside the disc)*. |
   | `lane_width_cells` | `int` | Width of the walkable corridor in grid cells (MVP default: **5**, paper-prototype-validated) |
   | `buildable_cells` | `Array[Vector2i]` | Grid cells in this lane designated as buildable; immutable for the run |

   Children of the lane root:
   - `NavigationRegion2D` — owns the baked `NavigationPolygon`; auto-registers a nav map RID with `get_world_2d()`.
   - `SpawnZone` and `GoalZone` — bare `Node2D`s used as world-space markers for the corresponding `Vector2` exports.
   - Three `TileMapLayer` siblings: `terrain_visual` (visual tiles only), `collision` (solid edges; informs `NavigationPolygon` outline), and `buildable_marks` (designates buildable cells as a distinct tile variant).

   **Aggregate signal `LaneSystem.geometry_baked()`** *(R2: ownership locked per B5a — aggregated form wins; the GDD's earlier per-lane parameterless emission is replaced)*: a parent `LaneSystem` autoload (or root coordinator node) emits a single `geometry_baked()` once **all lanes in the active map** have successfully completed their initial bake during `RUN_LOADING`, and once after each individual re-bake completes during `WAVE_ACTIVE`. The aggregated form is the contract that `architecture.yaml` already documents for ADR-0002; the per-lane signal is now an internal detail of the lane scene and is not part of the cross-system contract. CrowdManager and Wave/Spawn subscribe to the aggregate form.

3. **Lanes within a map are independent.** No cross-lane dependencies. Each lane's spawn zone, goal zone, and `NavigationPolygon` are isolated. Pathfinding queries for lane A do not depend on lane B's geometry. Multi-lane maps can add or remove lanes without modifying sibling lane scenes.

4. **At MVP, the two lanes run parallel.** Separate streams, separate goal-zone segments, no convergence. Each lane has its own `SpawnZone` at the top and its own `GoalZone` at the bottom. V1 may explore convergent or branching layouts in a *third* map design, but parallel is the canonical structural pattern.

5. **Each lane has one sharp bend at mid-lane** *(R2: angle range raised per B6 Path A)* — **35–45° inflection at approximately 60% lane depth**. The bend creates an implied chokepoint that gives a brand-new player an obvious wall-placement target without requiring them to read tactical theory — supporting Pillar 4's "low skill floor." The earlier 20–30° range (R1 draft) was too gentle to read as a chokepoint; reference tower-defense titles ship 60–90° bends, so 35–45° is the conservative end of "actually reads as a chokepoint" while preserving navigable corridor smoothness.

6. **Buildable cells form a small, discrete grid strip** *(R2: relocated to surround the bend per B6 Path A — strip is no longer behind the front line)*:
   - **Position**: horizontal strip spanning both lanes' width, **sitting at 40–65% lane depth so the strip surrounds the bend itself** (the bend at 60% lane depth falls inside the strip). This is the legal placement zone the player's eye is drawn to by the Collapse Markers (Visual/Audio §Bend chokepoint), so the affordance no longer lies — the cells the player wants to defend ARE the cells they can place on. *(R1 draft positioned the strip at the last 20% of lane depth, 6 cells away from the bend; this created a B6 Pillar 4 violation.)*
   - **Cell count at MVP** (2 lanes, 5-cell-wide each): start at **18 cells**; validate via paper prototype before story authoring.
   - **Strip depth**: ≤ 3 rows (hard cap, set by D.5).
   - **Grid origin**: pinned to the map's top-left corner; aligned with `TileMapLayer`'s native coordinate system.
   - **Visual distinction**: a distinct tile variant on the `buildable_marks` `TileMapLayer` (lighter pavement with a faint grid overlay) — readable as "placeable" without HUD.
   - **Immutability**: the buildable cell list is fixed at scene-authoring time and does not grow during a run. Any future card or upgrade that grows the strip becomes a new mutation event requiring API extension (tracked in Open Questions).

7. **Lane/Map owns NavigationPolygon geometry exclusively.** Wall/Fortification interacts with geometry only through the Lane/Map mutation API:
   - `add_wall_outline(lane_id: int, obstacle_polygon: PackedVector2Array, cell_ref: Vector2i) -> bool` — applies a convex obstacle outline to the lane's `NavigationPolygon` via `NavigationPolygon.add_outline()`. Returns `true` on success; returns `false` on (a) input-validation failure (malformed polygon, out-of-bounds `lane_id`, negative or out-of-bounds `cell_ref`), or (b) **queue-full admission failure** *(R2: Rule 11 admission policy)* when the mutation queue depth has hit `max_queue_depth = 8`. The mutation is NEVER rejected for path-blocking — see Rule 9. *(R2: extended `false`-return cases to cover queue-full per B5c.)*
   - `remove_wall_outline(lane_id: int, cell_ref: Vector2i)` — removes the outline previously added with the matching `cell_ref`. Always succeeds.

   *(R2 — B2 engine API verification flag)*: `NavigationPolygon.add_outline()` and the matching outline-removal API name are unverified for Godot 4.6.2 in `docs/engine-reference/godot/modules/navigation.md`. Story-authoring against this rule is gated on a WebSearch verification pass that confirms (a) the method name in 4.6.2, (b) whether outlines are removable by index or by vertex match, and (c) the documented behavior of `NavigationServer2D.map_changed` + `bake_navigation_polygon()` under sync mode (DD#2 = Sync). Update `docs/engine-reference/godot/modules/navigation.md` if entries are missing.

   *(R2.1 — `cell_ref → outline_index` mapping requirement, added per Round 2 godot-specialist independent verification)*: in Godot 4.x, `NavigationPolygon.remove_outline(idx: int)` takes an **integer index**, not a vertex match. The Lane/Map mutation API exposes `remove_wall_outline(lane_id, cell_ref)` to callers — Lane/Map MUST internally maintain a mapping (e.g., `Dictionary[Vector2i, int]`) from `cell_ref → outline_index` so it can translate the caller's `cell_ref` argument to the engine's required integer index. The mapping is built in `add_wall_outline` (record the index returned from `add_outline`) and consulted in `remove_wall_outline`. When an outline is removed, all subsequent indices shift down by 1; the mapping must be rebuilt or shifted accordingly. This is an undocumented implementation constraint that the Lane/Map story author must encode; flagged here so it is not discovered at implementation time.

   At MVP the API accepts a single shape per call. Batch mutation (multiple shapes in one call) is deferred to V1 and tracked in Open Questions.

   **R2: Forbidden-pattern lint** — `add_wall_outline` and `remove_wall_outline` may only be called from Wall/Fortification (#27). This is registered as a `forbidden_pattern` in `docs/registry/architecture.yaml` (`mutation_api_called_outside_wall_fortification`) so PR review and `/architecture-review` flag any violation. *(Replaces R1 draft AC-LM-27, which was a one-time manual grep — see Section H ACs.)*

8. **Walls may be placed during BOTH `WAVE_PREP` and `WAVE_ACTIVE`.** Mid-wave placement is allowed at MVP. The `Mutating` state can co-occur with `WAVE_ACTIVE`. Mid-wave placement is designed as a **clutch tool**, not the optimal strategy.

   **DD#1 (user 2026-05-02): "Click, then short cooldown"** — chosen by the user as the safer MVP behavior, with verbatim rationale: *"Click, then short cooldown."* Mid-wave stays available, but a real cooldown lever guarantees the engine has breathing room to re-bake without compounding frame stutters across consecutive placements.

   - **Cooldown invariant (R2 — promoted from a "tuning lever" to a real lever per B8)**: between any two accepted mid-wave `add_wall_outline` calls on the same player turn, `wall_mid_wave_cooldown_seconds` MUST elapse. The lever is owned by Wall/Fortification (#27) when that GDD lands, with a default ≥ 5s and a non-trivial value invariant (registered in `docs/registry/architecture.yaml` cross-system invariants).
   - **Cost invariant (R2 — promoted per B8)**: `wall_mid_wave_cost_multiplier` (resource cost penalty for mid-wave vs. prep-phase) MUST be ≥ 1.5× by default. Same registration as above.
   - **Pillar 4 trade-off acknowledgment (R2)**: this rule intentionally violates Run State #8's "the run waits for you" promise. The cooldown is the framing — mid-wave is meant to feel time-pressured. See Section B Pillar alignment note.
   - **`CrowdManager` no-path fallback (R2 — flag for ADR-0002 amendment per B5e)**: `CrowdManager` handles `NavigationServer2D.map_changed` events while zombies are mid-path. The behavior when a re-bake leaves zero path from a zombie's current cell to its goal is owned by ADR-0002. R2 flags this for an ADR-0002 amendment via `/propagate-design-change` after re-review closes (currently the spec is in Lane/Map's prose only).
   - **Acceptance criteria must verify** that re-bake during a 100+ zombie wave produces at most a single sub-frame stutter (≤ 1 frame below 60 fps per mid-wave placement; cooldown ensures stutter does not compound). See AC-LM-18.

9. **Walls may freely block the only path.** *(Revised 2026-05-01.)* Lane/Map performs **no path-validity check**. A run state where no path exists from `spawn_zone_center` to `goal_zone_center` is **legal** — zombies attack walls via the Combat / Wall HP rules owned by **Wall / Fortification (#27)**, and when walls are destroyed the geometry re-opens and paths restore naturally. **Cell-occupancy** ("is this cell already occupied by another wall, tower, or unit?") is owned by **Placement & Grid (#25)**, not Lane/Map. Once a placement passes Placement & Grid's occupancy check, Lane/Map applies the geometry change unconditionally (modulo Rule 7's input validation). This rule encodes a **load-bearing assumption** that walls are destructible and cannot be made impenetrable for a full wave — see Open Questions.

10. **Wall removal is unconditional.** `remove_wall_outline` always succeeds. Removing an obstacle cannot invalidate a previously valid path, so no check is required.

11. **Mutation requests during an in-flight bake are queued, with explicit FIFO + dedup + admission policy** *(R2: full queue spec per B5c)*:

    - **Order**: FIFO. Queued mutations are dequeued and applied in arrival order after the current bake completes.
    - **Dedup policy** *(DD#3 = Idempotent overwrite; user 2026-05-02 verbatim: "Idempotent overwrite"; "the player sees one wall at the cell — natural double-click feels idempotent, no error, no extra cost charged")*: when a second `add_wall_outline` is enqueued whose `(lane_id, cell_ref)` matches an entry already in the queue, the new entry **overwrites** the prior queued entry. The prior entry is replaced, not duplicated. Net effect: the player's last click on a given cell is the one that lands; a double-click on the same cell during an in-flight bake produces exactly one wall and exactly one re-bake event.
    - **Admission policy**: `max_queue_depth = 8` (scene-authoring constant; scoped to one lane; rationale: 8 placements / N-second cooldown × max-realistic-bake-time produces a comfortable upper bound). When the queue is at capacity, `add_wall_outline` returns `false` (see Rule 7's extended `false`-return contract) and logs a warning in debug builds. The queue NEVER discards a queued mutation silently.
    - **Thread-safety**: queue is single-threaded (DD#2 = Sync bake; the mutation API and the bake both run on the main thread, so no cross-thread coordination is required at MVP). If a future change moves to async bake (DD#2 Path B revisited at V1), the queue's dedup-and-admission policy must be revised for thread-safety; tracked in Section: Open Questions.
    - **Run-abort safety** *(R2: AC-LM-28 covers this)*: if the run is aborted while a mutation is queued and the bake is in flight, the lane scene is freed normally; the deferred queue consumer must NOT fire on a freed node. See AC-LM-28.

    No mutation that was admitted to the queue is silently lost; single-bake-at-a-time semantics are preserved.

### States and Transitions

**Bake mode (R2 — DD#2 = Sync bake; user 2026-05-02 verbatim: "Sync (matches Godot default)")**: `bake_navigation_polygon()` runs synchronously on the main thread. The `Baking` state below describes a main-thread blocking call, not an async worker-thread bake. This means: (a) main thread is blocked while baking — typically 5–15 ms during `RUN_LOADING`, 1–5 ms per re-bake during `WAVE_ACTIVE`; (b) a `Timer` cannot fire concurrently with a sync bake to abort it; (c) the 500 ms `RUN_LOADING` ceiling becomes a **post-bake assertion + pre-bake outline-vertex pre-validation** (see Section E and AC-LM-21), NOT a runtime live-abort timer.

| State | Meaning | Guarantees to consumers |
|---|---|---|
| `Unbaked` | Lane scene loaded but `NavigationPolygon` has not been baked yet | `NavigationRegion2D` exists in tree; `goal_zone_center` and `spawn_zone_center` readable. Nav map RID registered with `get_world_2d()` but not valid for queries |
| `Baking` | `NavigationRegion2D.bake_navigation_polygon()` in flight on the main thread (synchronous; blocks until complete) | No reliable geometry reads. Consumers must wait for `geometry_baked` before issuing path queries. The frame containing the bake call is one over budget by `t_navpoly_rebake` ms — see D.7. |
| `Ready` | Bake complete; `geometry_baked` has fired | Nav map RID valid. Spawn/goal zones valid for path queries. Buildable cell list immutable for this run. Path queries safe |
| `Mutating` | An accepted wall mutation is in flight; sync re-bake is running on the main thread | Geometry is partially updated. Nav map RID still exists but represents pre-mutation geometry. Consumers should use last-known path until `NavigationServer2D.map_changed` fires. New mutation requests are queued (Rule 11) |

| From | To | Trigger | Precondition | Effect |
|---|---|---|---|---|
| — | `Unbaked` | Lane scene instantiated during `RUN_LOADING` | None | Lane added to scene tree |
| `Unbaked` | `Baking` | `GameStateMachine` enters `RUN_LOADING` and lane's bake is initiated | Lane scene in tree | `bake_navigation_polygon()` called |
| `Baking` | `Ready` | Godot completes the nav-mesh bake | Bake finished | Lane emits `geometry_baked()`; nav map RID becomes valid |
| `Ready` | `Mutating` | Mutation API call accepts a wall outline change | Input validation passed (lane exists, polygon valid, cell_ref in range) | Outline applied; re-bake triggered |
| `Mutating` | `Ready` | `NavigationServer2D.map_changed` fires | Re-bake complete | Lane re-emits `geometry_baked()`; consumers re-query |
| `Mutating` | `Mutating` | A second mutation request arrives during a bake | Previous mutation still in flight | New request is queued and applied after the current bake completes |
| Any | `Unbaked` | Run ends (`RUN_RESULTS` → `MAIN_MENU`) | Run is over | Lane scene freed; all state discarded (no persistence per ADR-0006) |

**Cross-state constraints:**

- `geometry_baked` MUST have fired for ALL lanes in the active map before `GameStateMachine` may transition `RUN_LOADING → WAVE_PREP`. This is the bake gate locked by ADR-0001.
- The mutation API is NOT callable during `RUN_LOADING` or while any lane is in `Baking`. It IS callable during `WAVE_PREP` and `WAVE_ACTIVE`.
- `Mutating` may co-occur with `WAVE_PREP` or `WAVE_ACTIVE` run-states, but never with `RUN_LOADING`.

### Interactions with Other Systems

The Lane / Map System has four hard MVP-scope downstream consumers, all locked in `design/gdd/systems-index.md` row #7's Dependents column.

#### #11 Crowd Pathfinding (`CrowdManager`)

| Direction | Data | Notes |
|---|---|---|
| Lane/Map → CrowdManager | nav map RID via `lane_root.get_world_2d().navigation_map`; `goal_zone_center: Vector2`; `spawn_zone_center: Vector2` per lane | Delivered on `geometry_baked` signal. Re-read after `NavigationServer2D.map_changed` for re-bake events |
| CrowdManager → Lane/Map | None | One-way; CrowdManager is a pure consumer |
| Owner | Lane/Map owns geometry; CrowdManager derives a path cache from it | Per ADR-0002 |
| Ordering guarantee | CrowdManager MUST NOT issue path queries until `geometry_baked` has fired for all lanes |

#### #18 Wave / Spawn System

| Direction | Data | Notes |
|---|---|---|
| Lane/Map → Wave/Spawn | `spawn_zone_center: Vector2` per lane; `lane_id: int` | Read once after `geometry_baked` to position spawners |
| Wave/Spawn → Lane/Map | None | One-way |
| Owner | Lane/Map owns spawn zone positions |
| Ordering guarantee | Wave/Spawn MUST NOT begin spawning until all lanes have emitted `geometry_baked` |

#### #25 Placement & Grid System

| Direction | Data | Notes |
|---|---|---|
| Lane/Map → Placement & Grid | `buildable_cells: Array[Vector2i]` per lane, with lane affinity | Delivered once after `geometry_baked`. Cells are not added or removed mid-run |
| Placement & Grid → Lane/Map | `placement_changed(cell: Vector2i)` signal — Lane/Map does NOT subscribe (CrowdManager does, per ADR-0002) | Lane/Map's buildable cell list is immutable; runtime occupancy lives in Placement & Grid |
| Owner | Lane/Map owns cell *definitions*; Placement & Grid owns runtime occupancy |
| Ordering guarantee | Cell list delivered after `geometry_baked`; placements only legal during `WAVE_PREP` and `WAVE_ACTIVE` (gated by `GameStateMachine`) |

#### #27 Wall / Fortification System

| Direction | Data | Notes |
|---|---|---|
| Lane/Map → Wall/Fortification | Mutation API: `add_wall_outline(...) -> bool` and `remove_wall_outline(...)`. Spawn/goal zone positions readable for in-lane positioning (e.g., visualising distance from goal). Path-validity is NOT checked by Lane/Map. | Lane/Map is the sole geometry owner; Wall/Fortification is the sole authorised caller |
| Wall/Fortification → Lane/Map | API calls only | Wall/Fortification cannot touch `NavigationRegion2D` or its polygon directly |
| Owner | Lane/Map owns all geometry mutation |
| Ordering guarantee | Mutation API callable during `WAVE_PREP` AND `WAVE_ACTIVE`; not callable during `RUN_LOADING` or while any lane is `Baking` |

## Formulas

This system is performance-budget-driven rather than balance-curve-driven. Most formulas below are geometric derivations or budget constraints; there are no progression curves to tune.

### Locked constants

| Constant | Value | Origin |
|---|---|---|
| `cell_size_px` | **96** *(R2 — DD#4: raised from 64 → 96 per user 2026-05-02 verbatim "Bigger cells (96 px)"; whole-project re-tune; resolves Champion sprite vs single-cell-gap conflict)* | Section D decision (locks art pipeline scale) |
| `lane_width_cells` | 5 | Section C Rule 2 (paper-prototype-validated) |
| `bend_depth_fraction` | 0.60 | Section C Rule 5 |
| `bend_angle_deg` | **35–45** *(R2 — raised from 20–30 per B6 Path A: bend now reads as a chokepoint to a brand-new player)* | Section C Rule 5 |
| `total_buildable_cells_mvp` | 18 | Section C Rule 6 |
| `lane_count_mvp` | 2 | Section C Rule 4 |
| `lane_count_v1_max` | 3 | Section C Rule 1 |
| `spawn_zone_radius_px` | **64** *(R2 — added per B5b: Wave/Spawn distributes simultaneous spawns within this disc, prevents 50+ entities stacking at a single Vector2)* | Section C Rule 2 lane structure |
| `max_queue_depth` | **8** *(R2 — added per B5c: Rule 11 admission policy)* | Section C Rule 11 |

### D.1 — Cell to World (grid → world space)

**Definition:**
`world_pos = grid_origin + (cell_ref × cell_size_px) + cell_center_offset`

where `cell_center_offset = Vector2(cell_size_px / 2, cell_size_px / 2)`.

**Variables:**

| Symbol | Type | Range | Description |
|---|---|---|---|
| `world_pos` | `Vector2` | unbounded | Output world-space position of the cell centre |
| `grid_origin` | `Vector2` | scene-authoring-time constant | Top-left corner of `TileMapLayer` in world space; pinned to map origin |
| `cell_ref` | `Vector2i` | (0,0) to (map_width_cells−1, map_height_cells−1) | Integer grid coordinate (column, row) |
| `cell_size_px` | `int` | **96** *(R2 — DD#4)* | Locked constant |
| `cell_center_offset` | `Vector2` | (48, 48) *(R2 — was (32, 32) at 64 px)* | Half-cell offset for centring entities |

**Output Range:** Unbounded — any valid `cell_ref` maps to a unique world position. Out-of-bounds `cell_ref` values are rejected upstream by Placement & Grid's validity check, not here.

**Example** *(R2: recomputed for `cell_size_px = 96`)*: `grid_origin = (128, 64)`, `cell_ref = (3, 7)`:
`world_pos = (128, 64) + (3×96, 7×96) + (48, 48) = (128+288+48, 64+672+48) = (464, 784)`

### D.2 — World to Cell (world → grid)

**Definition:**
`cell_ref = floor((world_pos − grid_origin) / cell_size_px)` (integer floor per component; result is `Vector2i`)

**Variables:**

| Symbol | Type | Range | Description |
|---|---|---|---|
| `cell_ref` | `Vector2i` | (0,0) to map bounds | Output integer grid coordinate |
| `world_pos` | `Vector2` | world space | Input world position (e.g., mouse click) |
| `grid_origin` | `Vector2` | scene-authoring-time constant | Top-left corner of `TileMapLayer` |
| `cell_size_px` | `int` | **96** *(R2 — DD#4)* | Locked constant |

**Output Range:** May produce negative or out-of-bounds values if `world_pos` is outside the grid region. Callers must validate against map bounds before use; `TileMapLayer.get_cell_source_id(cell_ref)` returns `-1` for out-of-bounds and serves as the validity gate.

**Example** *(R2: recomputed for `cell_size_px = 96`)*: `world_pos = (464, 784)`, `grid_origin = (128, 64)`:
`cell_ref = floor((464−128)/96, (784−64)/96) = floor(3.5, 7.5) = (3, 7)` (inverse of D.1)

### D.3 — Lane width in pixels

**Definition:**
`lane_width_px = lane_width_cells × cell_size_px`

**Variables:**

| Symbol | Type | Range | Description |
|---|---|---|---|
| `lane_width_px` | `int` | **480** at MVP defaults *(R2: was 320 at 64 px cells)* | Walkable corridor width in pixels |
| `lane_width_cells` | `int` | 5 (locked) | Corridor width in grid cells |
| `cell_size_px` | `int` | **96** (locked) *(R2 — DD#4)* | Cell dimension |

**Output Range:** Fixed at **480 px** for MVP. Varies only if either constant changes at scene-authoring time.

**Example:** `5 × 96 = 480 px`

*(R2 viewport-implication note)*: at 96 px cells, `lane_depth_cells = 30` produces a lane 2880 px deep — well in excess of a 1080p viewport's 1080 vertical pixels. Camera scrolling or vertical zoom is required regardless. This was already implied at 64 px (1920 px vs 1080 viewport); 96 px makes the scrolling more pronounced. Camera GDD (#6 — when authored) must address this; tracked in Section: Open Questions #1.

### D.4 — Spawn-to-goal path length

**Treatment (R2 — per R2 of decision log)**: this formula is a **planning-time approximation only**. The actual path length is computed at runtime by `NavigationServer2D` (NavigationPathQueryParameters2D + `query_path()`, per ADR-0002's pathfinding API), and may diverge by 10–15% from the geometric formula (agents hug the outer wall of bends). Wave/Spawn MUST use the runtime-measured path length when computing zombie travel time, NOT the formula below. The formula remains documented for design-time sanity-checking only.

Each lane has one bend at 60% lane depth at a **35–45° inflection** *(R2: angle range raised per B6 Path A)* — the path is two straight segments.

**Definition:**

```
path_length_px = segment_pre_bend + segment_post_bend

segment_pre_bend  = bend_depth_fraction × lane_depth_cells × cell_size_px
lateral_offset_px = segment_pre_bend × tan(bend_angle_deg × π / 180)
segment_post_bend = sqrt((lane_depth_cells × (1 − bend_depth_fraction) × cell_size_px)² + lateral_offset_px²)
```

**Variables:**

| Symbol | Type | Range | Description |
|---|---|---|---|
| `path_length_px` | `float` | > `lane_depth_cells × cell_size_px` | Spawn-to-goal centreline distance (geometric approximation; see treatment above) |
| `lane_depth_cells` | `int` | typical 30 at MVP | Lane length in grid cells (set at scene-authoring time) |
| `cell_size_px` | `int` | **96** (locked) *(R2 — DD#4)* | Cell dimension |
| `bend_depth_fraction` | `float` | 0.60 (locked) | Fraction of lane depth where the bend occurs |
| `bend_angle_deg` | `float` | **35–45** (locked range) *(R2: raised per B6 Path A)* | Inflection angle |
| `segment_pre_bend` | `float` | > 0 | Length of straight section before the bend |
| `segment_post_bend` | `float` | > 0 | Length of post-bend section accounting for lateral offset |
| `lateral_offset_px` | `float` | > 0 | Horizontal displacement introduced by the bend |

**Output Range:** Always greater than a straight `lane_depth_cells × cell_size_px`. At 35° bend, post-bend is ~14% longer than straight equivalent; at 45° bend, ~25% longer (sharper bend = larger detour).

**Example** *(R2: recomputed for `cell_size_px = 96` and `bend_angle_deg = 40°`)*: `lane_depth_cells = 30`:
- `segment_pre_bend = 0.60 × 30 × 96 = 1728 px`
- `lateral_offset_px = 1728 × tan(40°) = 1728 × 0.8391 ≈ 1450 px`
- Post-bend depth: `30 × 0.40 × 96 = 1152 px`
- `segment_post_bend = sqrt(1152² + 1450²) ≈ sqrt(1327104 + 2102500) ≈ sqrt(3429604) ≈ 1852 px`
- `path_length_px ≈ 1728 + 1852 = 3580 px` (vs. straight `2880 px` — bend adds ~24.3%)

Wave/Spawn uses the **runtime-measured** path (per the treatment note above) divided by `agent.move_speed_px_per_sec` to get zombie travel time in seconds. The runtime measurement supersedes this formula's output.

### D.5 — Buildable strip distribution

Derives row count from the cell budget and lane configuration.

**Definition:**

```
cells_per_lane = total_buildable_cells / lane_count
strip_rows_needed = ceil(cells_per_lane / lane_width_cells)
```

**Variables:**

| Symbol | Type | Range | Description |
|---|---|---|---|
| `cells_per_lane` | `int` | 9 at MVP | Buildable cells allocated to one lane |
| `total_buildable_cells` | `int` | 18 at MVP | Total cells across all lanes (authoring-time constant) |
| `lane_count` | `int` | 2 at MVP, 2–3 at V1 | Lanes in the map |
| `strip_rows_needed` | `int` | 1–3; must be ≤ 3 | Row depth required |

**Output Range:** Must be ≤ 3 (Section C Rule 6 hard constraint). At MVP defaults: `cells_per_lane = 9`, `strip_rows_needed = ceil(9/5) = 2` — fits with one row of margin.

**Guards (R2 — R1 fix)**:

1. **Integer divisibility** *(R1 — added)*: at scene authoring, assert `total_buildable_cells % lane_count == 0`. Non-integer `cells_per_lane` (e.g., `total=20, lane_count=3` → 6.67) silently truncates by integer division and unevenly distributes cells across lanes; reject the map at authoring time.
2. **Strip-depth cap** *(unchanged)*: if `strip_rows_needed > 3`, the cell budget exceeds the strip-depth constraint and must be reduced before scene authoring.

**Example:** MVP — `total = 18`, `lane_count = 2`, `lane_width_cells = 5`:
`18 % 2 = 0` ✓; `cells_per_lane = 9` → `strip_rows_needed = ceil(9/5) = 2` ✓

### D.6 — Initial bake budget (`RUN_LOADING`)

Empirical, not closed-form. `NavigationPolygon` bake time scales with outline vertex count and obstacle count, but Godot's internal Clipper2 polygon-boolean cost has no public formula.

**Bound:** `t_bake ≈ k × (V + O × V_obs_avg)` where `k` is a device-dependent coefficient and `V_obs_avg` is the average vertex count per obstacle. Stated only to explain *why* outlines must stay simple; not implementable.

**Budget statement:**

| Condition | Budget | Source |
|---|---|---|
| Initial bake per lane | 5–15 ms one-shot (synchronous, blocks main thread) | ADR-0002 |
| Total `RUN_LOADING` ceiling | < 500 ms (post-bake assertion only — see treatment below) | ADR-0002 |

**Bake mode (R2 — DD#2 = Sync; user 2026-05-02 verbatim: "Sync (matches Godot default)")**: `bake_navigation_polygon()` runs synchronously on the main thread. The 500 ms ceiling is enforced via two mechanisms, NOT a runtime live-abort timer (which is impossible against a blocking call):

1. **Pre-bake outline-vertex pre-validation** *(R2 — B3 Path A)*: before each `bake_navigation_polygon()` call during `RUN_LOADING`, count the lane's `NavigationPolygon` outline vertices (including obstacle outlines, which during initial bake will be empty). If the vertex count exceeds a benchmarked safe threshold (TBD per the Steam Deck p95 benchmark — Open Question #7), abort BEFORE the bake call. The vertex-count threshold is the proxy for "this bake will exceed 500 ms"; it is benchmarked once and ships as a constant.
2. **Post-bake assertion (story-Done gate)** *(R2 — B3 Path A)*: after each bake completes, the measured `t_bake` is compared against the 500 ms ceiling. The story is Done **only if** the post-bake assertion passes on Steam Deck p95 hardware (Open Question #7 — promoted to a pre-Lane/Map-story benchmark gate). If the assertion fails on shipping hardware, the player's experience is a one-time stutter at startup rather than an error screen — see AC-LM-21.

**Design implication (R2 — recomputed for `cell_size_px = 96`)**: Keep each lane's `NavigationPolygon` outline to ≤ ~20 vertices. At 96 px cells, a 5-cell-wide × 30-cell-deep corridor with one 35–45° bend produces ~6–12 outline vertices (rectangular hull with one kink, plus pre-bend and post-bend segment endpoints). Wall obstacle outlines are 4-vertex convex rectangles. This comfortably fits the 5–15 ms one-shot budget on benchmarked hardware. The exact vertex threshold for pre-validation will be set by the Open Question #7 benchmark.

### D.7 — Per-mutation re-bake budget (`WAVE_ACTIVE`)

*(R2 — full rebuild per B1; the R1 draft double-counted CrowdManager sub-components, used the optimistic 6 ms engine overhead floor, omitted competing systems, and assumed a deferred-frame async bake. Each is corrected below.)*

The tightest constraint in this document. Mid-wave placement (Section C Rule 8) is **synchronous** (DD#2 = Sync bake): the re-bake blocks the main thread for the duration of `t_navpoly_rebake`. This means the frame containing the mid-wave bake is **expected** to drop one frame below 60 fps; the cooldown invariant (Rule 8 / DD#1) ensures the stutter does not compound across consecutive placements.

**Frame budget breakdown (60 fps target — R2 rebuilt)**:

| Component | Budget (ms) | Status | Source |
|---|---|---|---|
| Total frame budget | 16.6 | — | 60 fps target |
| Engine overhead (rendering, physics, audio) | **8.0** *(R2: was 6–8 range; B1 uses upper bound conservatively)* | Estimate | Typical Godot 2D Forward+ at 1080p |
| CrowdManager (per ADR-0002 — full envelope including spatial hash, velocity loop, MoveAndSlide ×100) | 2.0 | **Registered** | ADR-0002 / `architecture.yaml` |
| Juice (hit-stop dispatch + tween / shake / SFX) | 0.5 | **Registered** | ADR-0004 / `architecture.yaml` |
| VFX particle GPU simulation | TBD (~1.0–1.5 estimated) | Unregistered | *(R2 — placeholder until VFX GDD authored)* |
| HUD updates (resource counters, wave timer) | TBD (~0.3–0.5 estimated) | Unregistered | *(R2 — placeholder until HUD GDD authored)* |
| Wave/Spawn batch tick (next-spawn check, queue) | TBD (~0.2–0.3 estimated) | Unregistered | *(R2 — placeholder until Wave/Spawn GDD authored)* |
| Damage Numbers (pooled label updates) | TBD (~0.2–0.3 estimated) | Unregistered | *(R2 — placeholder until Damage Numbers GDD #35)* |
| **Subtotal (registered + estimated, all TBD systems at UPPER end)** | **~13.6** *(R2.1: was 13.1 due to arithmetic error; recomputed: 8.0 + 2.0 + 0.5 + 1.5 + 0.5 + 0.3 + 0.3 = 13.1, but VFX upper-end + HUD upper-end + Wave/Spawn upper-end + Damage upper-end = 1.5+0.5+0.3+0.3 = 2.6 → 8.0+2.0+0.5+2.6 = **13.1**; rounded subtotal range 12.5–13.1)* | — | — |
| **Remaining slack (worst-case — all TBD estimates at upper end)** | **~3 ms** *(R2.1: subtotal 13.1 + ~3 ms slack = 16.1 ms, leaving steady-state under 16.6 ms target)* | — | — |

**Honest slack statement (R2.1 — corrected for internal consistency per Round 2 performance-analyst)**: real per-frame slack at peak `WAVE_ACTIVE` load is **~3 ms (worst-case, all TBD estimates at upper end)**. This is the budget a mid-wave bake must fit into to avoid a frame drop. Per DD#1 (cooldown), Lane/Map accepts that some mid-wave bakes WILL exceed slack on a single frame — the cooldown ensures the next stutter is at least `wall_mid_wave_cooldown_seconds` away, so the player does not perceive compounded stuttering.

**Steady-state trigger rule (R2.1 — added per Round 2 performance-analyst Concern D / creative-director synthesis concern 19)**: as downstream GDDs land and their TBD line items are replaced with measured budgets, the steady-state subtotal will drift. The cooldown invariant protects against COMPOUND mid-wave stutter but does NOT protect the steady-state baseline. Therefore:

> **If steady-state frame budget (measured per `/architecture-review` aggregation across all registered + landed system budgets, on Tier-2 reference hardware = Steam Deck OLED + 2019-class laptop) exceeds 14.0 ms, Lane/Map mid-wave placement MUST escalate to one of: (a) thread the bake (V1 path B revisited — see Open Question #10), (b) disable mid-wave placement (revert Rule 8 to WAVE_PREP-only), (c) reduce vertex budget (tighten the pre-bake outline-vertex pre-validation threshold). The 3 ms slack is non-negotiable.**

This rule is enforced by `/architecture-review` summing the registered budgets and emitting an alert when the threshold is approached. The rule is mirrored in `architecture.yaml` as the `steady_state_ceiling_for_episodic_validity: 14.0` field on the `lane-map` performance budget entry.

**Definition:**
`t_rebake_total = t_navpoly_rebake + t_map_changed_propagation + t_path_requery`

**Variables:**

| Symbol | Type | Range | Description |
|---|---|---|---|
| `t_rebake_total` | `float` (ms) | target < ~3 ms slack | Total sync re-bake cycle cost on the main thread |
| `t_navpoly_rebake` | `float` (ms) | 1–5 (empirical, must benchmark) | Incremental bake after one obstacle outline added |
| `t_map_changed_propagation` | `float` (ms) | < 0.1 | Engine signal propagation |
| `t_path_requery` | `float` (ms) | ~0.5–1.0 per goal zone | `NavigationServer2D` path query per lane (per ADR-0002 pathfinding API) |
| `t_slack` | `float` (ms) | **~3 ms (worst-case — all TBD estimates at upper end)** *(R2.1: aligned with subtotal table and honest-slack statement)* | Frame budget remaining after engine overhead + registered + estimated systems |

**Output range and behavior (R2)**: `t_rebake_total < t_slack` is **the smoothness target**, not a hard constraint at MVP — one frame drop is acceptable per cooldown window. What IS a hard constraint: `t_rebake_total < ~6 ms` (a worse-than-30-fps frame is unacceptable even for one frame). At MVP (2 lanes = 2 path requeries):
- `t_path_requery ≈ 1.0 ms` (combined)
- `t_navpoly_rebake` for one 4-vertex obstacle added to a ~10-vertex outline: 1–3 ms (empirical, must benchmark per Open Question #7 benchmark gate)
- Combined: ~2–4 ms — at upper end this exceeds the ~3 ms slack and produces a one-frame stutter, which is the expected behavior under DD#1's cooldown framing.

**Lane/Map performance budget (R2 — registered in `architecture.yaml` per B1 step 6)**: a new entry `system: lane-map`, `budget_ms: 3` documents the D.7 hard constraint on `t_navpoly_rebake`. The cost is **episodic** — it fires only on accepted wall mutation events, not every frame. Registered to make the cost auditable by `/architecture-review`.

**Cooldown is the real lever (R2 — DD#1)**: `wall_mid_wave_cooldown_seconds` is the user-facing mechanism that converts "occasional one-frame stutter" into "occasional one-frame stutter spaced far enough apart to be imperceptible." The cooldown is not a fallback if D.7 fails — it is part of D.7's design.

**Example (R2 — recomputed for sync bake context)**: One mid-wave wall, MVP map, 100 zombies on screen:
- `t_navpoly_rebake = 2.5 ms` (estimated; must be benchmarked on Steam Deck per Open Question #7)
- `t_map_changed_propagation = 0.05 ms`
- `t_path_requery = 2 × 0.5 = 1.0 ms`
- `t_rebake_total = 3.55 ms` — exceeds the ~3 ms slack target by ~0.5 ms, which manifests as the bake-frame being ~17.1 ms (one frame drop just below 60 fps). Acceptable per DD#1 framing. The cooldown ensures the next mid-wave placement is at least `wall_mid_wave_cooldown_seconds` away.

### D.8 — *(removed in design pivot 2026-05-01)*

This formula slot previously specified a BFS-based pre-bake path-validity check, implementing the original Section C Rule 9. The check was **removed** in the design pivot of 2026-05-01: walls may now block all paths (Section C Rule 9 revised), and zombies destroy walls to re-open the geometry. The walkability boolean grid is no longer required at MVP. If a future design re-introduces path-validity rejection (for example, a difficulty mode that disallows total blocking), this formula slot is reserved for the BFS implementation.

The performance budget of D.7 (re-bake cycle ≤ ~3 ms steady-state slack target; one-frame stutter accepted under DD#1 cooldown framing) is unaffected — re-bake cost is dominated by `t_navpoly_rebake` and `t_path_requery`, both of which still apply to every accepted mutation. *(R2.1 — corrected from R1's stale ~5 ms slack figure; honest slack restated per B1.)*

## Edge Cases

### Mutation API inputs

- **If `add_wall_outline` is called with a negative `cell_ref` component** (e.g., `Vector2i(-1, 3)`): reject with `return false` immediately. The cell is outside the map grid; D.1/D.2 are undefined for negative inputs. Log an error in debug builds.
- **If `add_wall_outline` is called with a `lane_id` that has no corresponding lane scene**: reject with `return false`. Defensive guard against caller error; Wall/Fortification should not call with invalid IDs.
- **If `add_wall_outline` is called with a zero-area outline** (degenerate polygon — coincident vertices, or fewer than 3 vertices): reject with `return false`. Zero-area outlines could corrupt the polygon-boolean operation; reject on geometry validation before any nav-server work.
- **If `remove_wall_outline` is called at a `cell_ref` with no registered wall**: succeed silently (no-op, no error). Wall/Fortification owns its own placement registry; a missing entry is the degenerate case of "nothing to remove" (Rule 10).
- **If `add_wall_outline` is called during `RUN_LOADING` or while the target lane is in `Baking` state**: reject with `return false` immediately. The mutation API is forbidden during these states (Section C cross-state constraint). No queue, no defer.

### Mid-wave placement

- **If a zombie occupies the exact cell a wall placement targets at the moment `add_wall_outline` is called**: accept the mutation (Rule 8). Lane/Map only changes navigation geometry; the physical zombie-vs-wall collision is handled by Wall/Fortification + Combat. The zombie may be displaced or briefly tunnelled by physics — an acknowledged artefact of mid-wave placement, framed as a clutch tool, not a precision mechanic.
- **If `t_navpoly_rebake` alone exceeds the D.7 ~3 ms steady-state slack budget** *(R2.1 — corrected from stale ~5 ms; per B1 honest slack restate)*: the re-bake completes (no mid-bake cancellation in `NavigationServer2D` under DD#2 sync mode); the bake-frame drops one frame below 60 fps. Per DD#1 cooldown framing, this is **expected behavior, not a failure** — AC-LM-18 (b) verifies the bake-frame stays within 33.3 ms (≥ 30 fps), AC-LM-18 (c) gates `t_navpoly_rebake ≤ 3 ms`, and AC-LM-18 (d) verifies the cooldown prevents compound stutter. If `t_navpoly_rebake > 3 ms` at MVP scale on benchmarked hardware, the D.7 steady-state trigger rule escalates to threading (V1 path) or mid-wave disable per D.7's hard constraint.
- **If many mutations queue during a single bake** (Rule 11): each queued mutation is applied in arrival order after the current bake completes. With path-validity removed (Rule 9), there is no rejection-during-dequeue case — every queued mutation that passed input validation at queue time will succeed at dequeue.

### Walling the lane (path-blocking is legal)

- **If a wall mutation results in no path remaining from `spawn_zone_center` to `goal_zone_center`**: accept (Rule 9 — path-blocking is legal). Zombies in the lane will arrive at the closest reachable cell to the goal and engage the wall via Combat; Wall HP depletes; on `wall_destroyed`, Lane/Map removes the outline and re-bakes; geometry re-opens; `CrowdManager` re-queries on `NavigationServer2D.map_changed` and zombies resume pathing. Pathing fallback during the no-path window is owned by `CrowdManager` (per ADR-0002), not Lane/Map.

### State transitions

- **If `geometry_baked` is somehow emitted twice for the same bake** (defensive case against engine signal double-emission): the lane treats the second emission as a no-op. Consumers must be idempotent on their `map_changed` handler (ADR-0002 covers this for `CrowdManager`). Log a warning in debug builds.
- **If a lane's bake exceeds the 500 ms budget** *(R2 — sync-mode treatment per DD#2 + B3 Path A; replaces the R1 live-abort)*: there is **no runtime live-abort** — a `Timer` cannot interrupt a synchronous `bake_navigation_polygon()` call on the main thread. Instead, two checks apply:
  - **Pre-bake**: outline-vertex pre-validation (D.6) refuses to call `bake_navigation_polygon()` if the outline vertex count exceeds the benchmarked safe threshold. If pre-validation fails, `RUN_LOADING` aborts to `MAIN_MENU` with a "map too complex for this hardware" error before any bake fires.
  - **Post-bake**: the measured `t_bake` is asserted against the 500 ms ceiling. If `t_bake > 500 ms` on shipping hardware, the player sees a one-time stutter at startup but the run proceeds — the assertion is a story-Done benchmark gate (Open Question #7), not a runtime abort. The acceptance test for AC-LM-21 verifies the post-bake assertion mechanism, not a live-abort.
- **If the pre-bake outline-vertex pre-validation rejects** *(R2 — added)*: `GameStateMachine` transitions to `MAIN_MENU` with a non-empty error message ("map outline too complex for this hardware"). No bake call is issued. No partial state.
- **If a lane's bake genuinely fails** *(e.g., engine returns error)*: log a critical error; `GameStateMachine` transitions to `MAIN_MENU` with an error message. This is a defensive case for engine-level failures, not the 500 ms-budget case. *(Tracked in Open Questions for ADR-0001 amendment via `/propagate-design-change` — see Section: Open Questions #2.)*

### Numeric / authoring-time guards

- **If `strip_rows_needed > 3`** (D.5 evaluated at scene authoring with too-many cells for the lane configuration): reject the map scene before it enters the asset pipeline. The hard cap of 3 rows from Section C Rule 6 is an authoring-time gate, not a runtime fallback.
- **If `bend_angle_deg` is set to 0°**: D.4's `lateral_offset_px` collapses to 0 and the formula remains valid, but the implied chokepoint of Rule 5 disappears. This is a content-authoring issue, not a runtime edge case — map review should reject 0° bends as violating Pillar 4 intent.
- **If `grid_origin` is modified at runtime** (after lane scene load): undefined behaviour. D.1/D.2 become inconsistent with prior `cell_ref` ↔ `world_pos` conversions. `grid_origin` MUST be a scene-authoring-time constant; enforce by `@export` without a setter.

### Multi-lane

- **If one lane is `Ready` but its sibling is still `Baking` when `RUN_LOADING → WAVE_PREP` is attempted**: the transition blocks. ADR-0001's bake gate requires *all* lanes to have fired `geometry_baked` (Section C cross-state constraint). All-or-nothing — no partial-readiness.
- **If a wall mutation in lane 0 produces a NavigationPolygon whose world bounds overlap lane 1's polygon**: no nav-level collision occurs. Each lane's `NavigationRegion2D` registers a separate nav-map RID (Rule 3); `NavigationServer2D` handles multiple nav maps without merging. Cross-lane polygon overlap is a visual concern only.

### Run lifecycle

- **If the player triggers a hard quit during `Mutating`**: the lane scene is freed with the scene tree. ADR-0006 specifies zero persistence at MVP — no partial state is written. On next launch the run does not exist; the player starts fresh.
- **If the scene tree is reloaded mid-run via debug hot-reload**: all lane instances re-instantiate, resetting to `Unbaked`. The run state machine is also torn down. Developer-mode artefact; no design handling required at MVP.

## Dependencies

### Upstream — what Lane/Map depends on

| Dependency | Type | Interface / contract |
|---|---|---|
| Godot 4.6.2 engine primitives | Engine (**hard**) | `TileMapLayer` (terrain visual + collision + buildable_marks); `NavigationRegion2D` + `NavigationPolygon` (`add_outline()` API name unverified — flagged for B2); `NavigationServer2D.bake_navigation_polygon()` (synchronous in 4.x — DD#2) and `map_changed` signal; pathfinding via `NavigationPathQueryParameters2D` + `query_path()` per ADR-0002 |
| **#8 Game State Machine** | System (hard) | Lane/Map subscribes to `state_changed` to know when `RUN_LOADING` enters; emits aggregated `LaneSystem.geometry_baked()` (R2: B5a — aggregate form replaces per-lane); the state machine's `RUN_LOADING → WAVE_PREP` transition is gated on the aggregate signal |
| **ADR-0001 (Run State / Game Flow)** | Architecture (**hard**) | Defines `RUN_LOADING`, `WAVE_PREP`, `WAVE_ACTIVE`, `RUN_RESULTS` states + the bake gate. Section E flags this ADR for amendment to add the 500 ms post-bake assertion + pre-bake outline-vertex validation behaviour (DD#2 / B3 Path A — replaces the R1 live-abort plan). Amendment applied via `/propagate-design-change` after R2 re-review closes. |
| **ADR-0002 (Crowd Pathfinding Architecture)** | Architecture (**hard**) | Defines the geometry contract: aggregated `LaneSystem.geometry_baked` signal shape (R2: B5a), per-lane `spawn_zone_center` / `goal_zone_center` exports, `spawn_zone_radius` (R2: B5b), `NavigationRegion2D` usage, mutation → re-bake → `map_changed` triggers, **CrowdManager no-path fallback specification** (R2: B5e — flagged for ADR-0002 amendment via `/propagate-design-change`) |
| **ADR-0003 (Language Routing Policy)** | Architecture (**hard implementation-binding** — *R2: R6 reclassification, was "soft"*) | Lane/Map implementation = GDScript only. Lane/Map's GDScript→C# `geometry_baked` direction is already an undocumented contract (the aggregate signal goes from Lane/Map's GDScript autoload to CrowdManager's C# autoload), so ADR-0003's cross-language routing is binding for Lane/Map's interface, not just its internal implementation. |
| **ADR-0006 (Save Schema Versioning)** | Architecture | Lane/Map has zero persistent state at MVP; runs do not resume mid-run |

### Downstream — what depends on Lane/Map

#### Hard dependencies (MVP-blocking)

These four downstream MVP systems cannot author their own GDDs until Lane/Map's contract is locked:

| System | What they read from Lane/Map | Detailed contract |
|---|---|---|
| **#11 Crowd Pathfinding** | Nav map RID; per-lane `spawn_zone_center` + `goal_zone_center` (`Vector2`) | Section C "Interactions" / ADR-0002 |
| **#18 Wave / Spawn** | Per-lane `spawn_zone_center` + `lane_id` | Section C "Interactions" |
| **#25 Placement & Grid** | Per-lane `buildable_cells: Array[Vector2i]` (immutable for the run) + lane affinity | Section C "Interactions" |
| **#27 Wall / Fortification** | Mutation API: `add_wall_outline(...) -> bool`, `remove_wall_outline(...)` | Section C "Interactions" |

When each downstream GDD is authored, it MUST list Lane/Map as an upstream dependency. `/consistency-check` will verify the bidirectional link.

#### Soft / open dependencies

| System | Type | Status |
|---|---|---|
| **#6 Camera** | Open | Does Lane/Map expose `camera_bounds: Rect2`, or does Camera derive bounds from lane geometry independently? Tracked in Open Questions. |
| **#27 Wall / Fortification + Combat** (load-bearing) | **Bidirectional invariant — registered in `architecture.yaml` per R2 / B5d** | Lane/Map's Section C Rule 9 ("walls may freely block all paths") relies on the assumption that walls are destructible (have finite HP) and zombies can attack them via Combat. **R2: registered in `architecture.yaml` `cross_system_invariants` as `lane_map_rule_9_requires_wall_destructibility` so the constraint is machine-readable and `/architecture-review` flags any Wall/Fortification GDD draft that weakens destructibility.** |
| **#27 Wall / Fortification — Mid-wave cost & cooldown** *(R2 — promoted from "referenced knobs" to bidirectional invariant per B8)* | **Bidirectional invariant — registered in `architecture.yaml`** | Section C Rule 8 names `wall_mid_wave_cost_multiplier` (default ≥ 1.5×) and `wall_mid_wave_cooldown_seconds` (default ≥ 5s) as the levers enforcing "mid-wave is a clutch tool, not the optimal strategy." Both are owned by Wall/Fortification's GDD when authored, but their existence with non-trivial values is a Lane/Map invariant. **R2: registered in `architecture.yaml` `cross_system_invariants` as `wall_fortification_mid_wave_cost_lever_required` and `wall_fortification_mid_wave_cooldown_lever_required` so Wall/Fortification's GDD review flags omission.** |

### Hard vs soft hierarchy *(R2 — R6 ADR-0003 reclassified hard)*

- **Hard (system cannot function without it)**: ADR-0002 (geometry contract), ADR-0001 (state lifecycle), **ADR-0003 (language routing — implementation-binding for Lane/Map's interface; R2: R6 reclassification)**, Game State Machine, Godot navigation primitives.
- **Soft (enhanced by but works without)**: ADR-0006 (persistence policy is independent of design intent).
- **Bidirectional invariants to preserve when downstream GDDs are authored** *(R2: registered in `architecture.yaml` per Section G follow-ups)*:
  - Crowd Pathfinding's path queries must wait for the aggregated `LaneSystem.geometry_baked` (Section C ordering guarantee).
  - Wave/Spawn's zombie spawning must wait for `LaneSystem.geometry_baked` (Section C ordering guarantee).
  - Placement & Grid's occupancy state initialises after `LaneSystem.geometry_baked` and is the **sole rejector** of cell-occupancy conflicts. *(R2: re-authored as a Placement & Grid AC when that GDD lands — see B4 / Section H.)*
  - Wall/Fortification is the **sole authorised caller** of the mutation API; no other system may touch geometry. *(R2: registered as `forbidden_pattern: mutation_api_called_outside_wall_fortification` in `architecture.yaml` per B4 / Section H — replaces the R1 manual-grep AC-LM-27.)*
  - Wall HP > 0 with destructibility is a baseline rule in Wall/Fortification's GDD (R2: registered as a cross-system invariant per B5d).
  - Mid-wave cost multiplier ≥ 1.5× and cooldown ≥ 5s defaults in Wall/Fortification's GDD (R2: registered per B8).

### R2 cross-system AC re-authoring tracker *(R2 — added per B4)*

The following ACs were **deleted from this GDD** and must be re-authored in their owning systems' AC lists when those GDDs are authored. `/architecture-review` and `/consistency-check` should flag if any of these systems' GDDs go to "Approved" without picking up the corresponding AC:

| Origin AC (deleted from this GDD) | New owner | Required AC behavior |
|---|---|---|
| AC-LM-23 (R1 — full lane block resolves on wall destruction) | **#27 Wall / Fortification** | Verifies destructibility load-bearing assumption: blocked lane resolves when wall HP hits 0, `wall_destroyed` fires, `remove_wall_outline` is called, geometry re-bakes, zombies resume pathing. |
| AC-LM-26 (R1 — Placement & Grid is sole rejector of cell-occupancy) | **#25 Placement & Grid** | Verifies Placement & Grid's occupancy check runs before any `add_wall_outline` call; Lane/Map never returns `false` for occupancy reasons. |
| AC-LM-27 (R1 — Wall/Fortification is sole caller of mutation API) | **converted to** `forbidden_pattern` lint in `architecture.yaml` *(R2: replaces the manual grep)* | `/architecture-review` reports any caller outside Wall/Fortification. |
| AC-LM-30 *(R2.1: added per Round 2 qa-lead — was ADVISORY but only tracked in the Story-Type footnote and risked being silently skipped)* | **#27 Wall / Fortification** | Verifies mid-wave wall placement is more expensive than prep-phase placement (cost multiplier ≥ 1.5×) AND that the cooldown invariant (`wall_mid_wave_cooldown_seconds`) is enforced. Re-author this AC inside Wall/Fortification's GDD when that GDD lands. |

## Tuning Knobs

### Owned by Lane/Map (scene-authoring knobs unless noted)

| Knob | Controls | Safe range | If too low | If too high | Interactions |
|---|---|---|---|---|---|
| `lane_count` | Number of parallel lanes per map | 2 (MVP) – 3 (V1 max) | <2: trivial defense; no strategic variety | >3: Pillar 4 readability fails; `t_navpoly_rebake` scales | Affects D.5 `cells_per_lane`; affects D.7 path-requery cost (one query per lane) |
| `lane_width_cells` | Cells across each lane | 4–6 (MVP target: **5**, paper-prototype-validated) | 3: zombies single-file always; chokepoint loses meaning | 7+: silhouette illegible at 100+ density (Pillar 2 fails) | With `bend_angle_deg` — narrower lanes need shallower angles to stay readable |
| `lane_depth_cells` | Lane length in cells (spawn to goal centreline) | 25–40 (MVP target: **30**) | <25: zombies arrive too fast; Pillar 4 reaction-time fails | >40: wave pacing drags; "this is the fight" tension dilutes | With Wave/Spawn's zombie `move_speed_px_per_sec` (D.4 — runtime path length / move_speed = travel_time; runtime measurement supersedes formula per R2) |
| `bend_angle_deg` | Inflection angle at the mid-lane bend | **35–45°** *(R2: raised per B6 Path A; was 20–30°)* | <35°: Rule 5's implied chokepoint reads as a gentle curve, not a defensive position; first-time players don't recognize where to defend | >45°: NavigationPolygon outline becomes irregular; lane stops reading as a single corridor; pathfinding hugs outer wall too tightly | With `lane_width_cells` — narrower lanes can tolerate sharper angles before pathing gets tight |
| `bend_depth_fraction` | Where the bend sits along the lane | 0.50–0.70 (MVP target: **0.60**) | <0.50: bend too close to spawn; reduces player reaction time | >0.70: bend too close to goal; reduces defensive depth | With `buildable_strip_position_fraction` — strip is now COLOCATED with the bend, not behind it (R2: B6 Path A) |
| `total_buildable_cells_mvp` | Cell budget across all lanes | **12–22** *(R2: upper bound lowered from 24 to 22 per R1 — 24 hits the 3-row hard cap with zero margin)*; MVP target: **18**, paper-prototype-validated | <12: placement choice collapses to a single optimum; no spatial decision left to make *(R2: rewritten per B7 — was "build-variety Pillar 3 fails", which retracts with B7)* | >22: strip stops feeling like a strip; Section B fantasy breaks; D.5 strip-row hard cap (3 rows) hit with insufficient margin | With `lane_count` — D.5 enforces `strip_rows_needed ≤ 3` AND `total_buildable_cells % lane_count == 0` (R2: R1 integer guard) |
| `buildable_strip_position_fraction` | Where the buildable strip sits along the lane (fraction of lane depth) | **0.40–0.65** *(R2: relocated per B6 Path A; was 0.15–0.25 = "last 20% behind the bend")*; MVP target: **0.50–0.65 colocated with the bend** | <0.40: strip too far forward; chokepoint affordance breaks | >0.65: strip too close to goal; defensive depth collapses | With `bend_depth_fraction` — strip surrounds the bend; do not separate them |
| `cell_size_px` | Pixels per grid cell | **96** (effectively locked — pipeline-binding) *(R2: was 64; raised per DD#4 to fit Champion sprite ≥72 px in single-cell gap)* | Smaller (64 or below): Champion sprite no longer fits single-cell gap (the conflict R2 fixed) | Larger (128+): viewport real estate problem; lanes overflow 1080p without aggressive scrolling | **Do NOT change after MVP art begins** — every sprite is sized against this value. **Art Bible amendment required** for the 64→96 transition (tracked in Open Questions). |
| `inter_lane_gap_cells` *(R2 — added per R8)* | Cells between sibling lanes in a multi-lane map | scene-authoring constant (1–3 cells typical) | 0: lanes touch; visual confusion at lane boundary | >3: lanes drift apart; map fragments visually | Set at scene authoring; not runtime-tunable |
| `max_total_map_width_cells` *(R2 — added per R8)* | Hard cap on total map width in cells | safe range 13–20 (= 1248–1920 px at 96 px cells; tied to 1920×1080 viewport horizontal headroom) | <13: lanes too narrow or no inter-lane gap room | >20: map exceeds 1920 px wide and requires horizontal scrolling — out of scope at MVP | Constrains `lane_count × (lane_width_cells + inter_lane_gap_cells)`; scene authoring must verify |
| `spawn_zone_radius_px` *(R2 — added per B5b)* | World-space disc radius within which Wave/Spawn distributes simultaneous spawns | 32–96 px (default **64 px**) | <32: 50+ simultaneous spawns visibly stack; collision physics chokes | >96: spawn zone visibly overflows lane edges into walls | With Wave/Spawn's burst-spawn count: bigger bursts need bigger disc to avoid stacking |

### Referenced knobs owned by other systems

These knobs critically affect Lane/Map's behaviour but are **not** defined here. Listed so designers know they exist and which document is authoritative when they need to be tuned.

| Knob | Controls | Why Lane/Map cares | Owner |
|---|---|---|---|
| `wall_mid_wave_cost_multiplier` | Resource-cost penalty for placing a wall during `WAVE_ACTIVE` vs `WAVE_PREP` | Section C Rule 8 says mid-wave placement must be a *clutch tool*, not optimal. This multiplier is the primary lever. Too low (1.0×): mid-wave dominates planned placement. Too high (>3.0×): mid-wave never used; Rule 8's design intent is wasted. | **#27 Wall / Fortification** GDD (when authored) |
| `wall_mid_wave_cooldown_seconds` | Minimum wall-clock time between consecutive mid-wave placements | Same intent as cost multiplier — prevents mid-wave spam. Also caps the rate at which Lane/Map's mutation queue (Rule 11) can fill up. | **#27 Wall / Fortification** GDD (when authored) |

### Designer notes

- **Paper-prototype-gated knobs**: `lane_width_cells`, `total_buildable_cells_mvp`. The MVP defaults (5 / 18) are starting targets that MUST be validated by paper prototype before story authoring. Tracked in Open Questions.
- **Hard caps that are NOT tuning knobs** (these are invariants, not levers): max `strip_rows_needed = 3` (Section C Rule 6); `cell_size_px` post-pipeline-lock; the bake-gate ordering of ADR-0001.

## Visual/Audio Requirements

This section translates the project's Art Bible (`design/art/art-bible.md` — Direction D2 *Propaganda Poster Apocalypse*, with *Neon-Noir Pixel Apocalypse* fallback) for the Lane / Map System. It does not invent new visual direction; the bible is the authority.

### Lane visual treatment

Under Direction D2, a lane corridor reads as a **flat-fill ground plane enclosed by hard-edged orthogonal walls**, with the active Champion's 4-color palette (P1–P4) as the only colors in frame. No gradients, no ambient occlusion, no lighting pass — mood shifts are authored as tile-palette-slot swaps and prop placement, not post-process effects.

**Tile vocabulary** (per Art Bible §6.1 and §6.2):

The MVP map is "The Block" — a residential-commercial street grid. Each lane corridor is the floor of a cracked urban street, flanked by brick rowhouse walls.

| Surface | Interior grammar | Palette slot | Notes |
|---|---|---|---|
| Lane floor (asphalt) | No interior lines — 3 sub-tiles at ±3 L variation of P2 fill | **P2 dominant** | Art Bible §6.2: asphalt uses tile variation only, no lines |
| Wall face (brick) | Horizontal coursing every 4 px; vertical joint breaks every 8 px | **P1 (darkest)** for outlines + interior lines; P2 fill | §6.2: interior lines use P1 only |
| Buildable strip ground | Poured-concrete grammar: dot-scatter, 1 dot per 10×10 px | **P2 with P3 tint** (slightly warmer than lane floor) | §H Buildable-strip distinction below |
| Bend-point rubble (Collapse Markers) | Controlled 45° diagonal debris, P1 fill, near lane walls | **P1** | §6.4 — Category B, clustered near bend (implied threat direction) |

**Bend chokepoint — affordance without UI** (Art Bible §3.3 + §6.4):

The bend at ~60% lane depth communicates "place a wall here" through three layered cues:

1. **Shape**: the bend creates a lane-endpoint "chamfered mouth" — the corridor visually narrows at the inflection. Orthogonal walls bracket both sides; the player's eye completes the gap.
2. **Collapse Markers**: Category B props (bent chain-link at 45°, fallen timber-plank at 30°) cluster at the bend's near side. Diagonal lean direction points toward spawn (zombie threat direction). Players read this as "things have been hit here."
3. **Ground tile shift**: the one tile row immediately at the bend uses the ground-detail damage-overlay sub-tile, authored at P1-adjacent value — slightly darker, no interior lines. The floor looks "worse" at the chokepoint without any UI.

No explicit wall-placement arrow or highlight is authored — the geometry and Collapse Markers carry the message.

**Three-`TileMapLayer` translation** (Section C Rule 2):

| Layer | Authored content | Palette encoding |
|---|---|---|
| `terrain_visual` | Asphalt base tiles (3 variants), brick wall tiles, Collapse Marker props, lane-entry chamfered mouth shape, Consequence Markers (P1 abstract spatter at bend) | All tiles use proxy-color encoding (Art Bible §8.9): red=P1, green=P2, blue=P3, yellow=P4. Shader replaces at runtime. |
| `collision` | Solid boundary tiles — same visual as wall tiles on `terrain_visual` but in a separate layer for nav-geometry clarity. Not rendered (hidden or z-ordered below). | Same proxy encoding required if visible in editor; hidden in export. |
| `buildable_marks` | Distinct tile variant: poured-concrete grammar (dot-scatter) with faint 1 px grid crosshatch overlay. P3 slot used as fill. No outline on the crosshatch. | Same proxy encoding. P3 proxy = `#0000FF` in source art. |

**Buildable-strip distinction**: the strip distinguishes from the lane via three simultaneous signals — texture grammar change (asphalt → concrete dot-scatter), palette-slot shift (P2 → P3 fill), and grid-crosshatch overlay reading as "marked by a human hand." No HUD callout needed.

### Mood-state support

All 9 mood states (Art Bible §2) have map-layer implications. Because the game forbids a runtime lighting pass, palette and density shifts are authored as tile-variant swaps or prop-density rules — except the palette-swap shader (§8.9) which handles Champion-to-Champion transitions.

> **Trigger owner (R2 — added per R9)**: **Lane/Map subscribes to `GameStateMachine.state_changed`** and performs internal tile-variant swaps for mood transitions. This keeps presentation atomic — the lane doesn't get torn between a "prep-state" buildable strip and an "apex-wave-state" lane floor mid-frame because both swaps land in the same handler. Lane/Map does NOT subscribe to per-wave events from Wave/Spawn (mood states map to run-states, not wave numbers — except the "Early/Mid/Apex Wave" mood-states which are orchestrated by Wave/Spawn via a separate `wave_intensity_changed` signal that Lane/Map will subscribe to when Wave/Spawn's GDD lands).

| State | What the map looks like | What the player sees in the lane |
|---|---|---|
| **1 — Prep** | Full Champion palette at moderate saturation. Buildable strip tiles at P3 fill (warmest zone in frame). Outpost perimeter shown in Champion's primary outline. Lane floor clear. | A clear corridor: dark orthogonal walls, two-tone floor, glowing buildable strip inviting placement. |
| **2 — Early Wave (1–3)** | Background cools one authored step (select the P2 sub-tile with slightly lower L). Near-black zombie fills enter from spawn end. | Wide clear floor behind the horde front. Players see what IS the lane more than what IS NOT. |
| **3 — Mid Wave (4–6)** | Palette cools one further step. New zombie types render at P2-slot value. Negative space narrows. | Corridor begins to fill. Wall at bend chokepoint under pressure. |
| **4 — Apex Wave (7–9)** | Horde near-black fills majority of lane floor. Kill VFX is the frame's primary warmth source. Buildable strip P3 contrasts sharply against horde P1 mass. Rare card drop uses palette ceiling (V4) as a single-frame UI flash. | Chokepoint and buildable strip are the only lit zones. Champion located by heroic scale (§1 Principle 3). |
| **5 — Boss Fight** | Violation 1 active: universal crimson on boss silhouette and attack telegraphs. Environment desaturates one extra step. Crimson flat shapes appear on ground as attack telegraphs (temporary tile overlay on `terrain_visual`). | Lane floor reads as combat stage. Crimson ground telegraphs give player spatial reading. |
| **6 — Victory** | Violation 2: Gold/amber above palette ceiling in scoring UI and Champion pose accent. Environment desaturates further toward palest neutral. Outpost boundary intact in Champion outline. | Cleared lane. Frame centres on the outpost anchor. |
| **7 — Defeat** | Violation 3: flat ash-gray bleeds into background (full-screen `ColorRect` at low opacity). Champion accent suppressed via `modulate`. | Dark, heavy frame. Champion accent absent. Lane present but heavy. |
| **8 — Champion Select** | Each Champion's full 4-color palette at maximum expression via the §8.9 runtime swap. Cursor movement triggers `apply_champion_palette()`. | Color temperature of the whole environment changes on cursor movement. |
| **9 — Card-Roll** | Active Champion's palette dominates. Environment swaps to one-step-desaturated variant. Card hover uses palette ceiling as flat outline stroke. | Map feels like it's waiting. Cards are the only full-saturation elements. |

#### Wall-break visual beat (Section C Rule 9 — load-bearing)

When zombies attack a wall and it is destroyed, the sequence must read as a distinct dramatic moment:

1. **Attack phase**: the wall tile on `terrain_visual` switches to its damage-overlay variant as wall HP depletes. Tile swap; no new art beyond the standard damage variant. The damage tile uses the diagonal-break line grammar of Collapse Markers (30° crack line, P1-weight), visually flagging the wall as structurally compromised.
2. **Destruction**: on `wall_destroyed`, Lane/Map calls `remove_wall_outline`. Simultaneously, Wall/Fortification removes the visual tile and places a Collapse Marker prop (Category B: diagonal-leaning debris chunk at 45°, P1 fill) at the cell. The prop occupies the cell visually but does not block navigation.
3. **Re-open**: lane geometry re-bakes; zombie pathfinding resumes. The gap reads as an authored lane breach — debris makes the break visible and permanent for the rest of the wave.

This sequence gives the player a clear read: compromised → destroyed → open.

### Per-map differentiation (V1)

Maps differentiate on three independent axes: palette-slot proportion (Art Bible §4.6), tile-set theme (§6.1), and lane configuration. Palette is the most powerful axis because it works across all 4 Champions.

| Map | Dominant slot rule | Tile-set theme | Lane config | Visual reading |
|---|---|---|---|---|
| **Map 1 "The Block"** (MVP) | P2 ≥ 55% — cool, enclosed, shadowed | Brick rowhouses, asphalt, lamp posts, fire hydrants, orthogonal vehicles with 30°/45° tilt variants | 2 lanes, standard buildable strip (18 cells / 2 rows) | Two parallel enclosed corridors. Urban enclosure frames each lane. |
| **Map 2 "The Yard"** | P3 ≥ 45% — lit, worn, exposed | Corrugated metal outbuildings, gravel + concrete ground, fuel drums (octagons per §6.2), chain-link, stacked pallets | 2–3 lanes, wider interstitial zones | More open spatial reading. Wider negative space between lanes. |
| **Map 3 "The Last Line"** | P1 ≥ 40% upper two-thirds; P3 ≥ 40% lower third | Jersey barriers, sandbag walls, tire stacks, reinforced shipping container as outpost anchor (locked hero object). Zero authored props in primary lanes | 3 lanes, narrowed buildable strip | Three lanes in a fortification register. Upper screen feels compressed and dark; lower ground reads as arena. |

Tile-set theme carries the most authoring weight per map; palette-slot proportion is a rule applied to the same source art.

### Audio cue requirements

Lane/Map owns no audio assets and does not directly play sounds. It emits signals that an Audio system subscribes to.

| Signal | When emitted | Audio system plays | Rationale |
|---|---|---|---|
| `geometry_baked()` | Initial bake complete; re-bake after wall mutation complete | Subtle "settle" thud: low-frequency percussive hit (50–100 ms, non-musical) | Confirms map is ready / geometry settled. Prep-phase context = measured pace, so cue is subtle and not alarming. |
| `wall_placed` (owned by Wall/Fortification — listed for audio mapping completeness) | Accepted wall placement | Constructive thunk: dense, mid-weight percussive hit. Orthogonal and definitive. Not hollow. | The "Last Wall" fantasy requires placement to feel heavy and consequential. |
| `wall_destroyed` (owned by Wall/Fortification; Lane/Map calls `remove_wall_outline` in response) | Wall HP depleted to zero | Crack-and-crumble: sharp transient attack + short debris scatter tail (~300 ms) | The load-bearing visual-and-audio beat of Section C Rule 9. The crack must be distinct enough that the player knows a wall fell even when the camera is busy. |

**Ambient environment loop (per map)**: each map has a looping ambient bed owned by an Audio/Ambient system, triggered when `GameStateMachine` enters `WAVE_PREP`. Lane/Map does not own this — listed for design reference:

- **Map 1 "The Block"**: urban desolation — distant wind through concrete canyons, faint power-line hum, occasional paper-rustle. No human voices.
- **Map 2 "The Yard"**: industrial decay — low metallic resonance from corrugated structures, wind over gravel, intermittent creak of chain-link. Wider, exposed sound-space.
- **Map 3 "The Last Line"**: fortified silence — compressed reverb from close barriers, distant wind blocked by structure walls. Silence as a character.

Ambient loops desaturate (reduce by 3–6 dB) once `WAVE_ACTIVE` begins, as combat audio takes over the frequency space. The Audio system handles this by listening to `GameStateMachine.state_changed`.

### Asset spec readiness (MVP) — *R2: rescaled to `cell_size_px = 96`*

All assets size against `cell_size_px = 96` *(R2: was 64; DD#4)*. **Art Bible amendment required** for the 64→96 transition (tracked in Section: Open Questions). Naming convention per Art Bible §8.2: `env_[object]_[descriptor]_[size].[ext]`.

| Asset | Size | Format | Filename | Budget notes |
|---|---|---|---|---|
| Asphalt floor tile (base) | 96×96 px | PNG, 4-color proxy | `env_floor_asphalt_base_96.png` | 3 variants required (§6.2) |
| Asphalt floor tile (alternate) | 96×96 px | PNG, 4-color proxy | `env_floor_asphalt_alt_96.png` | Max 1-in-5 frequency (§6.2) |
| Asphalt floor tile (damage) | 96×96 px | PNG, 4-color proxy | `env_floor_asphalt_dmg_96.png` | Used at bend and mid-wave |
| Brick wall tile (intact) | 96×96 px | PNG, 4-color proxy | `env_wall_brick_intact_96.png` | Coursing grammar (§6.2) |
| Brick wall tile (damaged) | 96×96 px | PNG, 4-color proxy | `env_wall_brick_dmg_96.png` | Diagonal crack overlay, 30°/45° only |
| Lane-entry chamfered mouth shape | 192×96 px (spans 2 cells wide) | PNG, 4-color proxy | `env_lane_mouth_entry_192.png` | Hero environment shape (§3.3) |
| Buildable mark tile (concrete, grid crosshatch) | 96×96 px | PNG, 4-color proxy | `env_floor_buildable_base_96.png` | P3 slot as fill; crosshatch at P1 hairline weight |
| Collapse Marker — bent chain-link (45°) | 96×96 px | PNG, 4-color proxy | `env_prop_chainlink_broken_96.png` | Category B (§6.4). Max 5 interior lines |
| Collapse Marker — plank debris (30°) | 96×96 px | PNG, 4-color proxy | `env_prop_plank_fallen_96.png` | Category B. Max 5 interior lines |
| Boss-fight ground telegraph tile | 96×96 px | PNG, V1-crimson hardcoded (not proxy) | `env_floor_boss_telegraph_96.png` | Only tile using a fifth color. Must be absent from non-Boss states. Temporary overlay on `terrain_visual` |

**Draw-call budget** (Art Bible §8.8): the three Lane/Map `TileMapLayer` nodes consume 3 of the preferred 4 layer slots. Layer 4 reserved for Consequence Marker overlay if authored separately. Layers 5–6 (ceiling) reserved for atmospheric edge strips at V1.

**Texture memory**: active map tileset budgeted at 16 MB (§8.8). MVP uses a single tile atlas covering all tile types above; at 64×64 px per tile and ~12 distinct tiles, the atlas fits comfortably.

**Asset Spec flag**: 📌 After this section is approved and the Art Bible's Month-1 palette-swap shader prototype gates pass (Direction D2), run `/asset-spec system:lane-map-system` to produce per-asset visual descriptions, dimensions, and generation prompts.

### Fallback compatibility

The above spec is authored to be compatible with both D2 (Propaganda Poster) and the Neon-Noir Pixel Apocalypse fallback.

| Spec item | D2 | Neon-Noir fallback | Notes |
|---|---|---|---|
| 4-color proxy tile encoding (§8.9) | Required | Compatible — fallback adds dynamic lighting over flat-fill tiles; grammars are enhanced, not replaced (§6.2.10) | Tile source art identical under both directions |
| Flat fills, hard outlines, no gradients | Required | Compatible — fallback adds dynamic lighting as overlay; tiles remain flat | §6.2.10 explicit |
| Per-map dominant slot proportions (§4.6) | Required | Compatible — fallback uses fixed desaturated palette; dominant-slot proportion rule still applies | Dominant slot must be re-specified for fallback's fixed palette when activated |
| Mood-state tile-variant swaps | Required | Compatible — same variants; fallback dynamic lighting may amplify desaturation transitions | Same authored variants |
| Boss-fight crimson telegraph tile | Compatible — V1 violation color | Under fallback, telegraph becomes hot neon-red; fallback-palette variant tile must be authored | **Partially direction-locked.** One additional tile if fallback activates |
| Ambient audio loops | Direction-neutral | Compatible | Audio intent identical |
| Wall-break visual beat | Compatible | Compatible — diagonal debris grammar works under both; fallback may add dynamic shadow on debris | |

Bottom line: section is fully compatible with fallback activation except for the boss-fight ground telegraph tile, which requires one additional tile authored in fallback palette values.

## UI Requirements

Lane/Map has **no UI requirements at MVP**. The system is Foundation/Core
infrastructure: the player does not directly interact with a Lane/Map UI surface.

The visible affordances that *consumers* of Lane/Map render — and which players
might mistake for "Lane/Map UI" — are owned elsewhere:

| Visible affordance | Owner system | Notes |
|---|---|---|
| Cell-occupancy preview (grid cells lighting up under cursor) | **Placement & Grid (#25)** | Lane/Map exposes `cell_size_px` and the buildable-strip rect; Placement & Grid renders the highlight overlay. |
| Placement-validity hover (green/red on hover before commit) | **Placement & Grid (#25)** | Same boundary as above. |
| Lane labels / lane numbering, threat indicators | **Future HUD GDD** (not yet authored) | Lane/Map exposes `lane_count` and per-lane geometry; HUD chooses what to render. |
| Bake-failure error toast on the 500 ms timeout abort | **Future HUD GDD** + **Run State (#8)** | Lane/Map raises the abort signal; HUD renders the error screen. |

**Boundary call-out:** if a future story or PR puts cell-highlight or lane-label
rendering inside `lane_map.gd`, that is a violation of this boundary and must
be moved to its consumer system.

**No `/ux-design` flag is needed** for Lane/Map — there is no per-screen or HUD
work for this system to spec. UX work for the affordances above will be
specced when their owning GDD reaches authoring.

## Acceptance Criteria

Coverage: Core Rules C1–C11, Formulas D.1–D.7, Bake Gate (ADR-0001), the Section E timeout, the Section F wall-destructibility invariant, and the four bidirectional ordering guarantees.

### Core Rules (C1–C11)

**AC-LM-01** — Map is a container; no spatial data on the map root
- **GIVEN** a loaded MVP map scene with 2 lane instances
- **WHEN** the map root node's exported properties are inspected at runtime
- **THEN** the map root exposes only `display_name: String` and `lanes: Array[Node]`; it has no `NavigationRegion2D`, no `NavigationPolygon`, and no world-position exports; all geometry is owned by child lane nodes.

**AC-LM-02** — Lane node structure is correct and `geometry_baked` fires
- **GIVEN** a lane scene instantiated and added to the scene tree during `RUN_LOADING`
- **WHEN** `bake_navigation_polygon()` completes on that lane's `NavigationRegion2D`
- **THEN** the lane root emits `geometry_baked()` exactly once; the lane scene contains a `NavigationRegion2D` child, a `SpawnZone` marker, a `GoalZone` marker, and exactly three `TileMapLayer` siblings named `terrain_visual`, `collision`, and `buildable_marks`.
- *Test fixture: headless scene runner with signal spy to count emissions.*

**AC-LM-03** — Lanes are independent; cross-lane bake does not interfere
- **GIVEN** a 2-lane MVP map where lane 0 is in `Ready` state and lane 1 is in `Baking`
- **WHEN** lane 1's bake completes and emits `geometry_baked()`
- **THEN** lane 0's `NavigationPolygon` is unchanged (vertex count and outline hash identical before and after lane 1's bake); lane 0's `geometry_baked` signal is NOT re-emitted.

**AC-LM-04** — MVP map has exactly 2 parallel lanes
- **GIVEN** a loaded MVP map scene
- **WHEN** the lane list is queried
- **THEN** `map.lanes.size() == 2`; each lane has a distinct `spawn_zone_center` and a distinct `goal_zone_center`; neither lane references the other lane's `NavigationRegion2D` node.

**AC-LM-05** — Bend exists at approximately 60% lane depth *(R2 — kink-detection method rewritten per R12 from polygon vertex extraction to engine-stable path direction-change measurement)*
- **GIVEN** the MVP lane scene with `lane_depth_cells = 30`, `bend_depth_fraction = 0.60`, and `bend_angle_deg ∈ [35°, 45°]` *(R2: angle range raised per B6 Path A)*
- **WHEN** the spawn-to-goal path is queried from `NavigationServer2D` (using `NavigationPathQueryParameters2D` + `query_path()` per ADR-0002), and the path's direction-change is measured between adjacent path waypoints at the 55–65% path-length window
- **THEN** the maximum direction-change in that window is between 35° and 45° (matching `bend_angle_deg`); the location of the maximum direction-change falls within 55–65% of total path length.
- *Test fixture (R2)*: NavigationServer2D path query; direction-change computed from `path[i+1] - path[i]` adjacent vector dot products. **Engine-stable**: relies on the public `query_path()` API result, not on internal `NavigationPolygon` vertex layout (which can change between Godot versions). Tolerance band ±5% accounts for path-following overhead.

**AC-LM-06** — Buildable cell list: count, position, depth cap, and immutability *(R2.1 — corrected per Round 2 specialist findings; the R1/R2 text asserted the OLD strip position (last 20%, rows ≥ 24) which contradicted Rule 6's R2 relocation of the strip to surround the bend at 40–65% lane depth)*
- **GIVEN** a freshly baked MVP map with 2 lanes (`lane_depth_cells = 30`)
- **WHEN** the `buildable_cells` array is read from each lane after `LaneSystem.geometry_baked`
- **THEN** each lane contains exactly 9 `Vector2i` entries; all entries fall within **40–65% of lane depth (cell rows 12–19 inclusive for a 30-cell-deep lane)** — the band that surrounds the bend at `bend_depth_fraction = 0.60` (row 18) per Rule 6; no entry appears in more than 2 consecutive row bands (strip depth ≤ 2 rows, within the ≤ 3 row hard cap from D.5); the array is identical before and after any `add_wall_outline` or `remove_wall_outline` call made during the same run.

**AC-LM-07** — `add_wall_outline` returns `false` only on input-validation failure; accepted mutation triggers re-bake
- **GIVEN** a lane in `Ready` state during `WAVE_PREP`
- **WHEN** `add_wall_outline` is called with (a) a valid `lane_id`, valid 4-vertex convex polygon, and valid in-bounds `cell_ref`; then separately (b) a negative `cell_ref` component; (c) an out-of-bounds `lane_id`; (d) a 2-vertex degenerate polygon
- **THEN** call (a) returns `true` and the lane transitions to `Mutating` within the same frame; calls (b), (c), and (d) each return `false` and the lane state does not change.

**AC-LM-08** — Mid-wave placement is accepted; `Mutating` co-occurs with `WAVE_ACTIVE`
- **GIVEN** a run in `WAVE_ACTIVE` state with at least one zombie in motion
- **WHEN** `add_wall_outline` is called with a valid polygon on lane 0
- **THEN** the call returns `true`; the lane's internal state is `Mutating`; `GameStateMachine.current_state` remains `WAVE_ACTIVE` (not paused, not blocked); `geometry_baked` fires on lane 0 after the re-bake without the wave being interrupted.

**AC-LM-09** — Walls may freely block all paths; no rejection for path-blocking *(R2 — fixture switched to `NavigationPathQueryParameters2D` + `query_path()` per ADR-0002 pathfinding API; older `map_get_path()` may be deprecated in 4.6.2 — flagged for B2 verification)*
- **GIVEN** a lane in `Ready` state
- **WHEN** `add_wall_outline` calls are made in sequence until `NavigationServer2D` path query (via `NavigationPathQueryParameters2D` + `query_path()`) from `spawn_zone_center` to `goal_zone_center` returns an empty path
- **THEN** every individual `add_wall_outline` call that passed input validation and queue admission has returned `true`; no call returned `false` citing path-blocking; the lane is in `Ready` state after the final re-bake.
- *Test fixture: deterministic wall placement sequence; path emptiness verified via `query_path()` returning a result with `path.is_empty() == true`.*

**AC-LM-10** — Wall removal is unconditional; idempotent on missing key
- **GIVEN** a lane in `Ready` state
- **WHEN** `remove_wall_outline` is called (a) at a `cell_ref` that has a registered wall, then (b) at a `cell_ref` with no registered wall
- **THEN** call (a) removes the obstacle and triggers a re-bake (lane transitions to `Mutating`, then emits `geometry_baked`); call (b) completes silently with no error logged, no state change, and no re-bake triggered.

**AC-LM-11** — Queued mutations during in-flight bake are applied in order and dedup-overwrite on cell match *(R2 — fixture replaced per B4; the R1 mock-NavigationServer fixture was infeasible since the singleton can't be mocked. Replacement uses an injectable export flag.)*
- **GIVEN** a lane in `Mutating` state (sync bake "in flight" simulated via the injectable `_test_bake_suspend: bool = false` export flag set to `true` for the test, which defers the bake until cleared) with a first wall at `cell_ref A`; the export flag is **`OS.is_debug_build()`-gated** *(R2.1 — corrected from `OS.has_feature("editor")` per Round 2 godot-specialist; `is_debug_build()` is the correct guard because it returns `true` in editor + debug exports + headless test runs against debug templates, while `has_feature("editor")` returns `false` in headless test runs and would silently disable the flag)* and excluded from shipping (release) builds via that check
- **WHEN** a second `add_wall_outline` call is made with `cell_ref B` (different cell), then a third call with `cell_ref A` (same cell as first — exercises dedup-overwrite per Rule 11 / DD#3), all before `_test_bake_suspend` is cleared
- **THEN** all three calls return `true` immediately (queued; second and third pass admission; queue depth stays ≤ `max_queue_depth = 8`); when the test clears `_test_bake_suspend`, the first bake completes for the original cell-A wall; the queue then drains in FIFO order — the cell-B mutation runs (one re-bake), then the dedup-overwritten cell-A entry runs (one re-bake; the third call's outline is what is applied since it overwrote the prior queued entry); `LaneSystem.geometry_baked` fires three times total (initial + 2 dequeue re-bakes); the final baked polygon contains exactly two obstacle outlines (one at A, one at B).
- *Test fixture (R2.1)*: Lane scene with `_test_bake_suspend: bool` `@export` flag, gated by `if OS.is_debug_build(): pass`. Test toggles the flag to simulate an in-flight bake without mocking NavigationServer2D. The flag is fully removed from release-export builds because `OS.is_debug_build()` returns `false` in release templates.

### Formulas and Budgets (D.1–D.7)

**AC-LM-12** — D.1: Cell-to-world conversion is exact *(R2 — recomputed for `cell_size_px = 96`)*
- **GIVEN** `grid_origin = Vector2(128, 64)` and `cell_size_px = 96`
- **WHEN** `cell_to_world(Vector2i(3, 7))` is called
- **THEN** the returned `Vector2` equals `Vector2(464, 784)` (tolerance: 0.001 px).

**AC-LM-13** — D.2: World-to-cell conversion is the inverse of D.1 *(R2 — recomputed for `cell_size_px = 96`)*
- **GIVEN** `grid_origin = Vector2(128, 64)` and `cell_size_px = 96`
- **WHEN** `world_to_cell(Vector2(464, 784))` is called
- **THEN** the returned `Vector2i` equals `Vector2i(3, 7)`; calling `world_to_cell(cell_to_world(Vector2i(X, Y)))` for any in-bounds X, Y returns `Vector2i(X, Y)` (round-trip identity).

**AC-LM-14** — D.3: Lane width in pixels equals 480 at MVP defaults *(R2 — recomputed for `cell_size_px = 96`; was 320 at 64 px cells)*
- **GIVEN** the MVP lane scene with `lane_width_cells = 5` and `cell_size_px = 96`
- **WHEN** the walkable corridor width is measured from the baked `NavigationPolygon`'s leftmost to rightmost boundary at any row above the bend
- **THEN** the measured width is 480 px (tolerance: ±1 px for polygon edge precision).

**AC-LM-15** — D.4: Spawn-to-goal runtime path length matches geometric approximation within tolerance *(R2 — recomputed for `cell_size_px = 96`, `bend_angle_deg = 40°`; API switched to `NavigationPathQueryParameters2D` + `query_path()` per ADR-0002; tolerance widened to ±10% per R2 since runtime path hugs the outer wall of bends)*
- **GIVEN** a lane with `lane_depth_cells = 30`, `bend_angle_deg = 40°`, `cell_size_px = 96`
- **WHEN** `NavigationServer2D` is queried via `NavigationPathQueryParameters2D` + `query_path()` from `spawn_zone_center` to `goal_zone_center` on a freshly baked, wall-free lane
- **THEN** the returned path's total length is in the range [3220 px, 3940 px] (the D.4 formula yields ~3580 px; ±10% tolerance accounts for nav-mesh path-following overhead — agents hug the outer wall of bends, R2-documented in D.4 treatment).
- *Test fixture (R2)*: deterministic lane scene with fixed `bend_angle_deg = 40°`. Acts as the R2 calibration baseline; tighten the ±10% tolerance once the empirical divergence is measured on real geometry.

**AC-LM-16** — D.5: Buildable strip row depth does not exceed 3 rows
- **GIVEN** an MVP map with `total_buildable_cells = 18` and `lane_count = 2`
- **WHEN** `buildable_cells` is read from each lane and cell row indices are extracted
- **THEN** the unique row count per lane is ≤ 3; `cells_per_lane = 9`; the formula `ceil(9 / 5) = 2` matches the observed row count of 2.

**AC-LM-17** — D.6: Initial bake completes within per-lane and total budgets
- **GIVEN** an MVP map scene with 2 lanes, no pre-placed walls, run in `RUN_LOADING`
- **WHEN** both lanes' `bake_navigation_polygon()` calls complete
- **THEN** each individual lane bake duration is ≤ 15 ms (measured from bake call to `geometry_baked` emission); total elapsed time from first bake call to last `geometry_baked` emission is < 500 ms; verified on minimum-spec target hardware.
- *Test fixture: timer immediately before each bake call, stopped in the `geometry_baked` handler. Must be benchmarked on target hardware, not editor.*

**AC-LM-18** — D.7: Mid-wave re-bake stays under hard cap; cooldown prevents compound stutter; 60 fps maintained at steady state *(R2.1 — title and criteria rewritten per Round 2 specialist findings; the R1/R2 text required "frame ≤ 16.6 ms" which directly contradicted D.7's R2-rebuilt design intent that mid-wave bake-frames are EXPECTED to drop one frame below 60 fps under DD#1's cooldown framing)*
- **GIVEN** a `WAVE_ACTIVE` run with exactly 100 zombie agents in motion, all lanes in `Ready` state, **profiler OFF** during measurement, `Time.get_ticks_usec()` instrumentation around the bake call, 300-frame minimum measurement window (per R4 methodology + pinned Steam Deck OLED + 2019-class laptop in `technical-preferences.md`)
- **WHEN** a single `add_wall_outline` call is made (valid 4-vertex polygon, valid `cell_ref`) on one lane during `WAVE_ACTIVE`
- **THEN**:
  - **(a) Steady-state**: every frame OUTSIDE the bake-frame stays within budget (`frame_time ≤ 16.6 ms`).
  - **(b) Bake-frame ceiling (HARD)**: the single bake-frame containing the re-bake stays within `frame_time ≤ 33.3 ms` (one frame at ≥ 30 fps; D.7 explicitly accepts a one-frame drop below 60 fps but rejects below 30 fps).
  - **(c) `t_navpoly_rebake` ceiling**: ≤ 3 ms measured (if > 3 ms, the D.7 hard constraint is breached; the story is FAILING and the steady-state trigger rule (D.7) escalates to threading or mid-wave disable BEFORE the story is marked Done).
  - **(d) Cooldown invariant (no compound stutter)**: in the `wall_mid_wave_cooldown_seconds` window after the bake-frame, NO additional bake-frame may occur (verified by absence of `LaneSystem.geometry_baked` emission within the cooldown window).
  - **(e) `LaneSystem.geometry_baked` fires within the same frame or within 1 additional frame after `add_wall_outline` returns `true`.
- *Test fixture (R2.1)*: deterministic scene seeded with exactly 100 agents at fixed positions (no random spawn); `Time.get_ticks_usec()` instrumentation logs `t_frame[N]` for the 30 frames before, the bake-frame, and 30 frames after; signal spy on `LaneSystem.geometry_baked`. **No profiler running during measurement** — profiler overhead invalidates the timing.

### Bake Gate (ADR-0001)

**AC-LM-19** — `RUN_LOADING → WAVE_PREP` is blocked until all lanes emit `geometry_baked`
- **GIVEN** an MVP map with 2 lanes where lane 0 has emitted `geometry_baked` but lane 1 has not yet
- **WHEN** `GameStateMachine` attempts the `RUN_LOADING → WAVE_PREP` transition
- **THEN** the transition does not occur; `GameStateMachine.current_state` remains `RUN_LOADING`; the transition completes only after lane 1 emits `geometry_baked`; exactly 2 `geometry_baked` emissions have been recorded total before the transition succeeds.

**AC-LM-20** — Bake gate is all-or-nothing across lanes
- **GIVEN** a 2-lane map where lane 0 bakes in 8 ms and lane 1 bakes in 400 ms
- **WHEN** both bakes complete within the 500 ms window
- **THEN** `RUN_LOADING → WAVE_PREP` does not fire after lane 0's `geometry_baked`; it fires only after lane 1's `geometry_baked`; no partial state is exposed to consumers between the two emissions.

### Bake Pre-Validation and Mutation Lock *(R2 — section title rewritten: was "Timeout and Mutation Lock"; per DD#2 + B3 Path A, the runtime live-abort timer is replaced by pre-bake validation + post-bake assertion)*

**AC-LM-21** — Pre-bake outline-vertex pre-validation rejects too-complex maps; post-bake assertion gates story-Done *(R2 — rewritten per B4 + DD#2; tests signal+state only, not UI rendering — UI is HUD GDD's concern)*
- **GIVEN** a 2-lane MVP map where lane 0 has an outline-vertex count exceeding the benchmarked safe threshold; the threshold is overridden via the lane scene's **`_test_outline_vertex_threshold_override: int = -1`** export flag *(R2.1 — named per Round 2 qa-lead; same `OS.is_debug_build()`-gated injection pattern as `_test_bake_suspend` for AC-LM-11, set to a value lower than the actual outline vertex count to force pre-validation rejection)*
- **WHEN** Lane/Map's pre-bake outline-vertex pre-validation runs during `RUN_LOADING`
- **THEN** no `bake_navigation_polygon()` call is made for lane 0; Lane/Map emits a `bake_pre_validation_failed(lane_id: int, reason: String)` signal with `reason = "outline_vertex_count_exceeds_threshold"`; `GameStateMachine.current_state` transitions to `MAIN_MENU` (gated by GameStateMachine subscribing to the signal); no `WAVE_PREP` state is ever entered; no zombie spawning occurs. *(UI rendering of an error toast is owned by HUD GDD when authored; this AC verifies only the signal+state contract.)*
- **Post-bake assertion** *(separate but tracked by this AC)*: when bakes do proceed, the measured `t_bake` is recorded; the story is Done **only if** the post-bake `t_bake ≤ 500 ms` assertion passes on Steam Deck p95 hardware (pre-Lane/Map-story benchmark gate per Open Question #7).
- *Test fixture (R2.1)*: lane scene with `_test_outline_vertex_threshold_override: int = -1` export flag (`OS.is_debug_build()`-gated, same pattern as `_test_bake_suspend`); signal spy on `bake_pre_validation_failed`; state spy on `GameStateMachine`. **No** UI assertion (HUD owns that).

**AC-LM-22** — Mutation API is rejected during `RUN_LOADING` and `Baking`
- **GIVEN** a lane in `Baking` state (bake in flight during `RUN_LOADING`)
- **WHEN** `add_wall_outline` is called with a valid polygon and `cell_ref`
- **THEN** the call returns `false` immediately; the lane state does not change; no queue entry is created; an error is logged in debug builds; the same rejection applies if `add_wall_outline` is called while `GameStateMachine.current_state == RUN_LOADING` on any lane.

### Wall-Destructibility Invariant (Section F load-bearing) *(R2 — AC re-authored elsewhere)*

**AC-LM-23** — *(R2: DELETED from this GDD per B4; re-authored in Wall/Fortification's GDD when that GDD lands.)* The original AC tested CrowdManager + Wall/Fortification behavior using stubs of GDDs that don't exist yet. Wall/Fortification's AC list takes ownership: "Full lane block resolves when wall is destroyed and geometry re-opens." See R2 cross-system AC re-authoring tracker in Section F.

### Bidirectional Ordering Guarantees (Section F)

**AC-LM-24** — `CrowdManager` does not query paths before `LaneSystem.geometry_baked` *(R2.1 — generalized API reference per Round 2 godot-specialist; the R2 text named potentially-deprecated `map_get_path()` specifically — replaced with generic path-query language since B2 verification is still pending)*
- **GIVEN** a run entering `RUN_LOADING` with `CrowdManager` initialised but lanes still in `Baking`
- **WHEN** the bake is in flight and `LaneSystem.geometry_baked` has not yet fired
- **THEN** `CrowdManager` makes zero calls to ANY `NavigationServer2D` path-query API during this window (whether `query_path()` via `NavigationPathQueryParameters2D`, or any 4.6.2-equivalent API that B2 verification confirms); the first path query occurs only in the `LaneSystem.geometry_baked` signal handler (or later), never before.
- *Test fixture (R2.1)*: spy or call counter on the verified 4.6.2 `NavigationServer2D` path-query API name (per B2 WebSearch result) — fixture is authored only after B2 closes. Until B2 closes, this AC's automated test is GATED on engine-reference verification.

**AC-LM-25** — `Wave/Spawn` does not begin spawning before all lanes emit `geometry_baked`
- **GIVEN** a run entering `RUN_LOADING` with `Wave/Spawn` initialised
- **WHEN** `GameStateMachine.current_state == RUN_LOADING` and any lane is still in `Baking`
- **THEN** zero zombie instances are added to the scene tree; the first spawn call occurs only after `GameStateMachine` transitions to `WAVE_PREP` (gated by AC-LM-19); `SpawnZone` emits no `zombie_spawned` signals during `RUN_LOADING`.

**AC-LM-26** — *(R2: DELETED from this GDD per B4; re-authored in Placement & Grid's GDD when that GDD lands.)* The original AC tested Placement & Grid's calling sequence (a Placement & Grid contract, not Lane/Map's). Placement & Grid's AC list takes ownership: "Placement & Grid is the sole authority on cell-occupancy rejection." See R2 cross-system AC re-authoring tracker in Section F.

**AC-LM-27** — *(R2: CONVERTED per B4 from a one-time manual grep to a `forbidden_pattern` lint rule.)* Registered as `mutation_api_called_outside_wall_fortification` in `docs/registry/architecture.yaml`: "No script outside Wall/Fortification (#27) may call `add_wall_outline` or `remove_wall_outline`. `NavigationRegion2D.bake_navigation_polygon()` may only be called by Lane/Map itself." `/architecture-review` and PR review enforce automatically. See R2 cross-system AC re-authoring tracker in Section F.

### Cross-Rule Failure Interactions *(R2 — added per R11)*

**AC-LM-28** — Queue disposal during in-flight bake on run abort *(R2 — added per R11)*
- **GIVEN** a lane in `Mutating` state with a sync bake in flight (test simulated via `_test_bake_suspend = true`) AND at least one mutation queued behind it
- **WHEN** `GameStateMachine` transitions from `WAVE_ACTIVE` (or any in-run state) directly to `MAIN_MENU` (run abort), and the lane scene is freed as part of the run teardown
- **THEN** no crash occurs, no `NotificationPredelete` warning is logged for the queue consumer, no deferred `call_deferred` consumer fires on the freed lane node, and no error is logged. The queue is freed atomically with the lane scene.
- *Test fixture: spy on Godot's freed-node warnings; force run abort while `_test_bake_suspend = true`.*

### Pillar 4 Verification *(R2 — added per B6 Path A step 4)*

**AC-LM-29** — Cold-player wall placement readability test *(R2 — added per B6 Path A; verifies Pillar 4's HUD-free chokepoint readability claim)*
- **GIVEN** N=10 first-time playtesters who have never seen the game and receive **no verbal instruction** about where to defend
- **WHEN** they are dropped into a fresh MVP map and observed for their first wall placement decision; **"first wall placement" is defined as the FINAL placement at the moment the wave-start countdown reaches zero** *(R2.1 — tiebreaker added per Round 2 qa-lead; if a playtester places, picks up, and replaces the wall during the prep window, only the placement standing at countdown=0 is recorded; intermediate placements are not counted)*
- **THEN** ≥ 7 of 10 playtesters place their final wall within 2 cells of the bend chokepoint (i.e., inside the buildable strip's bend-colocated zone, Section C Rule 6).
- **Tag**: Playtest, ADVISORY (not BLOCKING — playtest results take time, but the claim Pillar 4 makes is gated on a passing result before that pillar can be claimed in V1 marketing material).
- *Test fixture (R2.1)*: facilitator follows a fixed script ("you have one wall to place; the wave begins in 30 seconds; place it where you think the threat will hit; you may move it as many times as you want before the countdown reaches zero"); the placement at countdown=0 is logged as the canonical "first placement"; pass/fail tally per playtester.

### Mid-Wave Cost Invariant *(R2 — added per B8)*

**AC-LM-30** — Mid-wave wall placement is more expensive than prep-phase placement *(R2 — added per B8; depends on Wall/Fortification GDD existing)*
- **GIVEN** Wall/Fortification's GDD has been authored AND defines `wall_mid_wave_cost_multiplier` AND `wall_mid_wave_cooldown_seconds`
- **WHEN** an `add_wall_outline` call is made during `WAVE_ACTIVE` AND a separate equivalent call is made during `WAVE_PREP` (same wall type, same lane, deterministic resource state)
- **THEN** the resource cost charged for the `WAVE_ACTIVE` call is ≥ 1.5× the resource cost charged for the `WAVE_PREP` call (default multiplier invariant); AND the cooldown clock prevents a second `WAVE_ACTIVE` placement within `wall_mid_wave_cooldown_seconds` of the first.
- **Tag**: Integration, ADVISORY (depends on Wall/Fortification GDD existing — author when that GDD lands).
- *Test fixture: deterministic resource pool; invoke both calls with same input; compare cost deltas.*

### Story-Type Classification *(R2 — updated; AC-LM-23/26 deleted, AC-LM-27 converted to lint, AC-LM-28/29/30 added)*

| AC IDs | Story Type | Gate Level | Evidence Required |
|---|---|---|---|
| AC-LM-01–04, 06–14, 16, 19, 20, 22, 24, 25, 28 | Logic / Integration | BLOCKING | Automated unit or integration test in `tests/unit/lane-map/` or `tests/integration/lane-map/` |
| AC-LM-05 | Logic | BLOCKING | Automated test with `query_path()` direction-change measurement (R12-rewritten, engine-stable) |
| AC-LM-15 | Logic | BLOCKING | Automated test calling `query_path()` and asserting path length within ±10% tolerance |
| AC-LM-17, 18 | Integration + Performance | **ADVISORY** *(R2 — R4 reclassified from BLOCKING)* | Profiler / benchmark on **pinned hardware** (Steam Deck OLED + 2019-class laptop named in `technical-preferences.md`); 300-frame minimum; profiler OFF during measurement; `Time.get_ticks_usec()` instrumentation around bake call; results logged to `production/qa/evidence/`. Manual benchmark gate, NOT CI BLOCKING. |
| AC-LM-21 | Logic + Integration | BLOCKING | Pre-bake validation signal+state contract via signal/state spy; post-bake assertion is a separate Steam Deck p95 benchmark gate (Open Question #7) |
| AC-LM-27 | *(N/A — converted to `forbidden_pattern` lint)* | Architecture lint (continuous) | `/architecture-review` enforces automatically |
| AC-LM-29 | Playtest | ADVISORY | Cold-playtester observation log; pass/fail tally per playtester |
| AC-LM-30 | Integration | ADVISORY | Depends on Wall/Fortification GDD; author when that lands |

**Total ACs in this GDD after R2**: 24 (was 27; -3 from B4 deletions/conversions; +3 from R11 / B6 / B8 additions). AC-LM-23, AC-LM-26, AC-LM-27 are tracked in Section F for cross-system re-authoring; their numbers are NOT renumbered (preserves traceability with R1 review).

**Four ACs are Advisory** *(R2.1 — corrected from "Three" per Round 2 specialists; the prose count was wrong)*: AC-LM-17, AC-LM-18, AC-LM-29, AC-LM-30. The remainder are independently verifiable BLOCKING.

> *Note on AC-LM-18 (R2.1)*: gate level updated to **ADVISORY** in the Story-Type table footnote per R4 methodology — pinned-hardware manual benchmark, NOT CI-BLOCKING — even though its criteria are testable, because performance is non-deterministic in CI.

## Open Questions

Each question carries forward into a downstream GDD or ADR. Owners are named so
none of these become orphaned.

### 1. Camera-bounds coupling

**Question:** Does Lane/Map expose `camera_bounds: Rect2`, or does Camera (#6)
derive its own bounds from lane geometry (spawn zones + goal zones + buildable
strip)?

**Why it matters:** Two valid architectures with different coupling cost.
Exposing `camera_bounds` makes Camera trivially correct but adds a public
surface to Lane/Map. Letting Camera derive its own bounds keeps Lane/Map
narrower but duplicates geometry math.

**Owner:** Camera GDD (when authored). Camera GDD must pick one and update
Lane/Map's interface accordingly.

---

### 2. ADR-0001 amendment for `RUN_LOADING` timeout-and-abort

**Question:** ADR-0001 (Run State / Game Flow) does not yet capture the
500 ms `RUN_LOADING` timeout-and-abort behaviour codified in this GDD's
Edge Cases (AC-LM-21).

**Why it matters:** The behaviour is now written in two places (this GDD +
ADR-0001's actual decision), so the ADR must be amended to reference the
timeout, the abort target (`MAIN_MENU`), and the error condition. Without
the amendment, future readers may treat the behaviour as Lane/Map–local
when it is in fact a run-state-flow contract.

**Owner:** ADR-0001 author — use `/architecture-decision` to amend, or open
a follow-up ADR if a separate decision is preferred.

---

### 3. Load-bearing wall-destructibility assumption

**Question:** Section C Rule 9 ("walls may freely block all paths") and the
lack of any path-validity check rely on a load-bearing assumption: walls are
destructible by zombies via Combat (finite HP, zombie-attackable hitbox).

**Why it matters:** If Wall/Fortification or Combat ever weakens
destructibility — for example, walls become indestructible in a difficulty
mode, or zombies cannot path-target walls — then a player can build a sealed
ring and trivially win. Rule 9 must be re-evaluated in that case.

**Owner:** Wall/Fortification GDD (when authored). The destructibility
assumption must persist into that GDD's Detailed Rules and Acceptance
Criteria so it cannot be silently dropped.

---

### 4. Paper-prototype validation gate

**Question:** `lane_width_cells = 5` and `total_buildable_cells_mvp = 18`
are starting targets. They MUST be paper-prototype-validated before any
implementation story is authored against them.

**Protocol:**
- Graph paper grid at 1 square = 1 cell.
- Hex tokens for zombies (3 archetypes minimum).
- Sticky notes for towers and walls (placement footprint = the sticky note).
- d6 for wave pressure (roll determines spawn count per wave tick).
- 30-minute session per map iteration.
- Validation criteria: does the player's read-the-field-at-a-glance fantasy
  hold at lane width 5 and 18 buildable cells, or does the strip feel either
  empty (room to spare) or claustrophobic (no choice)?

**Why it matters:** Both numbers are pipeline-binding once art assets are
authored against `cell_size_px = 96` *(R2 — was 64 in R1; raised per DD#4)*.
Validating on paper costs 30 minutes; re-tuning after art lock costs days.

**Owner:** producer + game-designer. Run before `/dev-story` is invoked
against any Lane/Map story.

---

### 5. Batch vs single-shape mutation API at V1

**Question:** Currently `add_wall_outline(shape) -> bool` accepts one shape
per call (Section C Interaction 4). At V1, certain upgrade cards or
fortification mechanics may want batch placement — e.g., "build a row of 4
walls in one click."

**Why it matters:** The signal contract `geometry_baked()` fires once per
mutation. A naive batch implementation that calls `add_wall_outline` four
times would trigger four bakes. The API must either accept a batch shape
list with a single bake, or callers must learn to wrap their batch in a
deferred-bake context.

**Owner:** Wall/Fortification GDD or a future V1-scope ADR — whichever
authors the batch mechanic first.

---

### 6. BFS walkability grid revival

**Question:** D.8 (BFS walkability grid for path-validity rejection) was
removed in the 2026-05-01 design pivot when Rule 9 was rewritten to allow
walls to freely block paths.

**Why it matters:** If a future difficulty mode or game variant disallows
total path-blocking (for instance, "Ironman" mode where walls cannot seal
the field), the BFS implementation slot is reserved in this GDD's Section D
under the deleted D.8 number. The work to re-introduce path validity is
small; the design decision to do so is not.

**Owner:** Difficulty-mode GDD (when authored, post-MVP).

---

### 7. Bake failure recovery beyond the 500 ms timeout — *PROMOTED in R2 to a pre-Lane/Map-story benchmark gate (per B3 / Section G of decision log)*

**Question:** Section E AC-LM-21 (R2 — rewritten) replaces the runtime live-abort with a pre-bake outline-vertex pre-validation + post-bake `t_bake ≤ 500 ms` assertion. The benchmarked safe vertex threshold AND the post-bake 500 ms assertion both depend on real measurements that don't yet exist. On low-end hardware (specifically Steam Deck with mid-tier thermals, or older laptops sharing a thread with antivirus scans), the bake may legitimately exceed 500 ms on a clean run. *(R2 — sync mode means this manifests as a one-time stutter, not an error screen.)*

**Why it matters (R2 — promoted reasoning):** The post-bake assertion gates story-Done. The pre-bake vertex threshold is a runtime constant that ships in code. **No story may be authored against this GDD until the Steam Deck p95 benchmark is on file.** This is not a "would be nice" — it is a hard precondition for `/dev-story` to proceed against any Lane/Map story.

**Owner:** Post-prototype performance review (producer + technical-director + performance-analyst). **Benchmark protocol (R2 — locked; R2.1 — adjacency-cost test added per Round 2 godot-specialist New Issue B)**: 95th percentile bake time across 3 map types on Steam Deck OLED + 2019-class laptop named in `technical-preferences.md`; 300-frame minimum measurement window; profiler OFF during measurement; `Time.get_ticks_usec()` instrumentation around bake call; results logged to `production/qa/evidence/`.

> **R2.1 adjacency-cost test (added per Round 2 godot-specialist)**: bake duration in Godot 4.x is driven by Clipper2 polygon-boolean cost, which is non-linear in **inter-outline adjacency**, not just total vertex count. The benchmark MUST include a "worst-case adjacency" scenario: 8 wall outlines placed in adjacent cells (cells touching corners or edges) inside the buildable strip, then measure bake time. If adjacency cost dominates over vertex count cost, the pre-bake outline-vertex pre-validation threshold (D.6) is INSUFFICIENT — the threshold must include an adjacency component (e.g., "max 4 walls in 3×3 cell window") OR be replaced with a wall-count + adjacency-window check. The benchmark surfaces which proxy is the right metric.

---

### 8. Art Bible amendment for `cell_size_px = 96` *(R2 — added per DD#4)*

**Question:** DD#4 raised `cell_size_px` from 64 to 96. The Art Bible (`design/art/art-bible.md`) was authored against 64 px. All asset specifications, palette-swap shader assumptions, draw-call budgets, texture memory budgets, and grid grammar references reference 64 px throughout.

**Why it matters:** Lane/Map's R2 GDD now has 96×96 px asset specs, but the Art Bible is the canonical authority on asset dimensions. The two must reconcile or future asset authoring will produce conflicts.

**Owner:** art-director + producer. Apply via Art Bible amendment after Lane/Map R2 re-review closes. Estimated effort: 1 short session — the change is mechanical (rescale all 64 px references to 96 px throughout §6, §8.2, §8.8 budget tables).

---

### 9. CrowdManager no-path fallback specification *(R2 — added per B5e)*

**Question:** Lane/Map Section C Rule 9 ("walls may freely block all paths") and the wall-destruction recovery flow disclaim the no-path behavior to ADR-0002 (CrowdManager). But ADR-0002 doesn't actually specify what CrowdManager does when a re-bake leaves zero path from a zombie's current cell to its goal.

**Why it matters:** Rule 9 ships a load-bearing assumption that ADR-0002 owns this. Until ADR-0002 is amended, the spec is in Lane/Map's prose only.

**Owner:** ADR-0002 author. Apply via `/propagate-design-change` after R2 re-review closes. The amendment must specify: (a) zombie behavior when path is empty (idle, attack-nearest-wall, retreat); (b) when a path query is retried (event-driven on `map_changed` only — no per-frame retry); (c) guarantees about "no zombie permanently stuck" if the lane re-opens later via `wall_destroyed`.

---

### 10. Mid-wave async bake revisit at V1 *(R2 — added per DD#1 + DD#2)*

**Question:** DD#1 = "Click, then short cooldown" + DD#2 = "Sync bake" together accept that mid-wave placements ship as occasional single-frame stutters. At V1, if benchmarks show this stutter is unacceptable on shipping hardware, the bake could be moved to a worker thread (DD#2 Path B revisited) — but only if Godot 4.6.2's NavigationServer2D is verified thread-safe AND the mutation queue (Rule 11) is rewritten with thread-safe primitives.

**Why it matters:** Documents the future path so V1 doesn't have to re-derive it. Records that the cooldown lever (DD#1) is partly a stand-in for an absent threading guarantee.

**Owner:** technical-director + performance-analyst. Re-evaluate at V1 once shipping benchmarks are on file. If async bake is adopted, Rule 11 queue must be redesigned for thread-safety.

---

## R2 Application Notes (Section J — appended 2026-05-02)

> **Authored by**: fresh-session R2 application of `design/gdd/reviews/lane-map-system-decisions-2026-05-02.md` (the locked contract from the Round 1 `/design-review`).

### Locked decisions (round-trip audit trail)

The 6 design decisions deferred by Round 1 specialists were resolved in this R2 session via a multi-tab `AskUserQuestion` widget on 2026-05-02. The plain-English answers are recorded verbatim alongside the technical translations (per the user-friendly decision language rule):

| ID | User's plain-English answer (verbatim) | Technical translation |
|---|---|---|
| **DD#1** (B1) | "Click, then short cooldown" | Section C Rule 8 keeps mid-wave placement; promotes `wall_mid_wave_cooldown_seconds` from a tuning lever to a real bidirectional invariant (registered in `architecture.yaml`). Mid-wave bake stutters are accepted as one-frame events; cooldown prevents them from compounding. |
| **DD#2** (B3) | "Sync (matches Godot default)" | Path A. Bake runs synchronously on the main thread. The 500 ms `RUN_LOADING` ceiling is enforced via pre-bake outline-vertex pre-validation + post-bake assertion (D.6 / AC-LM-21 rewritten). Open Question #7 promoted to a pre-Lane/Map-story benchmark gate. |
| **DD#3** (B5c) | "Idempotent overwrite" | Section C Rule 11 dedup policy: queued mutations dedup by `(lane_id, cell_ref)` with overwrite. A double-click on the same cell during an in-flight bake produces exactly one wall and exactly one re-bake event. |
| **DD#4** (B5f) | "Bigger cells (96 px)" | `cell_size_px` raised 64 → 96. All formulas D.1–D.4 recomputed; all asset specs rescaled to 96×96 px; D.7 frame budget recomputed; Champion sprite vs single-cell-gap conflict resolved. **Art Bible amendment required** (Open Question #8). |
| **DD#5** (B6) | "Fix the map (Recommended)" | Path A. Bend angle raised 20–30° → 35–45°; buildable strip relocated from "last 20% behind the bend" to "40–65% surrounding the bend"; AC-LM-29 added (cold-playtester wall placement test, ≥7/10 must place at the bend without instruction); Pillar 4 trade-off acknowledgment added to Section B. |
| **DD#6** (B7) | "Drop the claim (Recommended)" | Path A. Header updated: Lane/Map is pillar-neutral on Pillar 3 (Build Variety). Section B Pillar alignment: added retraction note. Tuning Knobs `total_buildable_cells_mvp` "If too low" entry rewritten to drop build-variety reference. |

### Blockers applied

- **B1** — D.7 frame budget rebuilt: removed CrowdManager double-counting; engine overhead bumped to 8 ms upper bound; juice 0.5 ms registered; VFX/HUD/Wave/Spawn/Damage Numbers added as TBD line items; honest slack restated as ~3 ms; `system: lane-map, budget_ms: 3` registered for `architecture.yaml`.
- **B2** — Godot 4.6.2 API verification flag: `NavigationPolygon.add_outline()`, `bake_navigation_polygon()` sync behavior, `get_world_2d().navigation_map` property, `NavigationServer2D.map_changed` signal, and `query_path()` (replacing deprecated `map_get_path()`) flagged for WebSearch verification before story authoring. Update `docs/engine-reference/godot/modules/navigation.md` accordingly.
- **B3** — Sync-mode bake locked (DD#2). Pre-bake validation + post-bake assertion replace runtime live-abort.
- **B4** — Cross-system ACs stripped: AC-LM-23 deleted (Wall/Fortification owns); AC-LM-26 deleted (Placement & Grid owns); AC-LM-27 converted to `forbidden_pattern` lint; AC-LM-21 rewritten to test signal+state only; AC-LM-11 fixture replaced with `_test_bake_suspend` injectable export flag.
- **B5** — Cross-system contracts locked: aggregate `LaneSystem.geometry_baked` (B5a); `spawn_zone_radius` added to lane data model (B5b); Rule 11 mutation queue fully specified (FIFO + dedup-overwrite per DD#3 + admission policy + max queue depth) (B5c); wall destructibility registered as cross-system invariant (B5d); CrowdManager no-path fallback flagged for ADR-0002 amendment via `/propagate-design-change` (B5e); Champion sprite vs cell-size resolved by DD#4 (B5f).
- **B6** — Geometry made to deliver Pillar 4 (DD#5 Path A): bend sharpened, strip relocated, AC-LM-29 cold-playtest test added, Pillar 4 trade-off acknowledgment added.
- **B7** — Pillar 3 alignment claim retracted (DD#6 Path A).
- **B8** — Mid-wave clutch invariants (`wall_mid_wave_cost_multiplier`, `wall_mid_wave_cooldown_seconds`) promoted to bidirectional cross-system invariants; AC-LM-30 added to verify mid-wave cost ≥ 1.5× prep-phase.

### Recommendations applied

R1 (D.5 upper bound 22 + integer guard), R2 (D.4 marked planning-time approximation; runtime measurement supersedes), R3 (folded into B4), R4 (AC-LM-17/18 reclassified ADVISORY with pinned-hardware methodology), R5 (folded into B5c), R6 (ADR-0003 reclassified hard implementation-binding), R7 (folded into B6 Path A), R8 (`inter_lane_gap_cells` and `max_total_map_width_cells` added to Tuning Knobs), R9 (mood-state trigger owner: Lane/Map subscribes to `state_changed`), R10 (folded into B4), R11 (AC-LM-28 added — queue disposal during run abort), R12 (AC-LM-05 kink-detection rewritten to engine-stable `query_path()` direction-change measurement).

### Outstanding follow-ups (post-R2)

- **`docs/registry/architecture.yaml` updates** — applied this session per decision log Section G: lane-map performance budget; aggregated `LaneSystem.geometry_baked` interface contract; cross-system invariants for wall destructibility, mid-wave cost, mid-wave cooldown; `forbidden_pattern: mutation_api_called_outside_wall_fortification`.
- **ADR-0001 amendment** (Open Question #2) — apply via `/propagate-design-change` after re-review closes. The 500 ms `RUN_LOADING` behavior in ADR-0001 must reflect DD#2 Sync mode (post-bake assertion + pre-bake validation; no live-abort).
- **ADR-0002 amendment** (Open Question #9 — added in R2) — CrowdManager no-path fallback specification, applied via `/propagate-design-change`.
- **Art Bible amendment** (Open Question #8 — added in R2) — `cell_size_px = 96` propagation, applied by art-director + producer.
- **Steam Deck p95 bake benchmark** (Open Question #7 — promoted in R2) — pre-Lane/Map-story gate. No story authored against this GDD until the benchmark is on file.
- **Paper prototype** (Open Question #4) — unchanged from prior plan. Must run before any Lane/Map story.

### Re-review

`/design-review design/gdd/lane-map-system.md` (Round 2) is run as the next session step. Round 2 verdict will be the second entry in `design/gdd/reviews/lane-map-system-review-log.md`.

If Round 2 returns APPROVED (or REVISION with inline-only fixes), `/propagate-design-change` runs immediately after to apply the ADR-0001 + ADR-0002 amendments, the entity registry updates, and any remaining cross-document touches per the decision log.

---

## R2.1 Inline-Fix Notes (appended 2026-05-02 — same session)

> **Authored by**: Round 2 inline-fix pass after `/design-review` returned **CONDITIONAL APPROVED** with 2 confirmed BLOCKERS + 16 inline-fixable findings.

### Round 2 verdict and fix authorization

`/design-review` Round 2 spawned 5 specialists (game-designer, systems-designer, qa-lead, godot-specialist, performance-analyst) + creative-director (senior synthesizer). Specialist verdicts converged on:
- 2 BLOCKERS (AC-LM-06 wrong strip position; AC-LM-18 contradicts D.7 design intent) — both inline-fixable in this session per creative-director synthesis
- 16 inline-fixable findings (stale text sweep, AC bookkeeping, engine-binding clarifications, hardware spec stub, ludonarrative realignment, registry structured fields, steady-state trigger rule)

Per the decision log Section H: "If re-review passes (or REVISION with inline fixes only), runs `/propagate-design-change`." The inline-fix path was authorized; one user creative-decision was bundled in: the Player Fantasy ludonarrative realignment.

### User decision (R2.1 round-trip audit trail)

| ID | User's plain-English answer (verbatim) | Technical translation |
|---|---|---|
| **DD#7** *(R2.1 — added inline)* | "Forward-leaning kill-box (Recommended)" | Player Fantasy section rewritten: the buildable strip at the bend reads as the player's kill-box (the seam where they hunt the threat), not as the rear bastion they retreat to. Aligns with Pillar 2 (Satisfying Kills) and Pillar 4 (the bend is its own tutorial). Visual/Audio cues stay forward-leaning; Champion silhouette pose faces toward spawn; tutorial copy (when authored) frames "you take the seam," not "you defend behind the strip." |

### R2.1 inline fixes applied

**Confirmed BLOCKERS (resolved inline)**:
1. **AC-LM-06**: rewritten to assert strip cells fall within 40–65% lane depth (rows 12–19 for a 30-cell lane), surrounding the bend at row 18, instead of the R1/R2 stale "last 20%, rows ≥ 24" that contradicted the R2 strip relocation.
2. **AC-LM-18**: title rewritten ("re-bake stays under hard cap; cooldown prevents compound stutter; 60 fps maintained at steady state"); GIVEN updated to "profiler OFF" with `Time.get_ticks_usec()` instrumentation; criteria split into (a) steady-state ≤ 16.6 ms, (b) bake-frame ≤ 33.3 ms (≥ 30 fps hard cap), (c) `t_navpoly_rebake` ≤ 3 ms, (d) cooldown invariant verified, (e) signal timing. Resolves the contradiction with D.7's stutter-acceptance design intent.

**Inline fixes (single-session sweep)**:
3. D.8 prose: "≤ ~5 ms slack" → "≤ ~3 ms steady-state slack target; one-frame stutter accepted under DD#1 cooldown framing."
4. Section E mid-wave-placement edge case: "the D.7 ~5 ms slack budget" → "the D.7 ~3 ms steady-state slack budget" with stutter-acceptance prose.
5. AC-LM-24: `NavigationServer2D.map_get_path()` reference generalized to "any `NavigationServer2D` path-query API" (deprecated method name removed; B2 verification gates the actual fixture).
6. AC-LM-11 + AC-LM-21: test-fixture guard changed from `OS.has_feature("editor")` to `OS.is_debug_build()` (per godot-specialist — `is_debug_build()` survives headless test runs).
7. AC-LM-21: vertex-count override mechanism named (`_test_outline_vertex_threshold_override: int = -1`).
8. AC-LM-29: "first wall placement" defined as the FINAL placement at countdown=0 (tiebreaker for facilitator script).
9. Section F cross-system AC re-authoring tracker: AC-LM-30 added (was only in Story-Type footnote, risked silent skip).
10. Section H closing line: "Three ACs are Advisory" → "Four ACs are Advisory" (LM-17, LM-18, LM-29, LM-30); AC-LM-18 explicitly noted as ADVISORY per R4 methodology.
11. **Player Fantasy section rewritten** (DD#7): forward-leaning kill-box framing per creative-director recommendation + user decision.
12. Rule 7: documented `cell_ref → outline_index` mapping requirement (Lane/Map maintains internal `Dictionary[Vector2i, int]`; `remove_outline()` takes integer index in 4.x; story author must encode this).
13. D.7: arithmetic corrected; slack figure reconciled (table shows ~3 ms worst-case, prose matches); **steady-state trigger rule added** ("if steady-state > 14.0 ms, mandate threading or disable mid-wave"; non-negotiable 3 ms slack).
14. Open Question #7 benchmark spec: adjacency-cost test added (Clipper2 polygon-boolean cost is non-linear in inter-outline adjacency, not just total vertex count; benchmark must include 8-walls-in-3×3-window worst case).
15. `.claude/docs/technical-preferences.md`: Tier-2 reference hardware spec added (Steam Deck OLED + 2019-class laptop with full CPU/GPU/RAM/OS specs); benchmark methodology codified (300-frame minimum, profiler OFF, p95 reporting).
16. `architecture.yaml` `lane-map` performance budget entry: `cost_model: episodic`, `steady_state_ms: 0.0`, `episodic_ms: 3.0`, `steady_state_ceiling_for_episodic_validity: 14.0` structured fields added (per performance-analyst Concern E — `/architecture-review` now correctly distinguishes episodic from steady-state).

### Outstanding follow-ups (post-R2.1)

- **`/propagate-design-change`** runs as the next session step to apply ADR-0001 + ADR-0002 amendments per decision log Section G. R2.1 added one new amendment requirement: the steady-state trigger rule (D.7 R2.1) should be referenced in any future Lane/Map-specific ADR if one is authored, but does NOT itself require a new ADR (per creative-director synthesis: "registry + GDD edit, not an ADR, because no architectural decision is being changed — we are codifying an existing implicit invariant of DD#1").
- **Steam Deck p95 bake benchmark + adjacency-cost test** (Open Question #7) — pre-Lane/Map-story gate. Now expanded to include the worst-case adjacency scenario (R2.1).
- **Art Bible amendment** (Open Question #8) — `cell_size_px = 96` propagation, owned by art-director + producer.
- **Wall/Fortification GDD authoring** can begin; AC-LM-30 (mid-wave cost ≥ 1.5× prep + cooldown) is in the Section F tracker for re-authoring inside Wall/Fortification's AC list when that GDD lands.
- **CrowdManager GDD authoring** can begin; AC-LM-23 (no-path fallback) is in the Section F tracker for re-authoring inside Wall/Fortification's AC list (the no-path behavior crosses both systems).
- **Placement & Grid GDD authoring** can begin; AC-LM-26 (sole occupancy rejector) is in the Section F tracker for re-authoring.

### R2.1 verdict

After R2.1 inline fixes: **APPROVED** for `/propagate-design-change`. No formal R3 spawn required (per creative-director synthesis). The four downstream consumer GDDs (#11/#18/#25/#27) have a clean foundation to author against.
