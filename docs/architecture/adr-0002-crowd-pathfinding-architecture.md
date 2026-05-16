# ADR-0002: Crowd Pathfinding Architecture

## Status
Proposed (Wall-Block No-Path Fallback amendment 2026-05-02 from `design/gdd/lane-map-system.md` R2.1)

## Date
2026-04-27 (original) / 2026-05-02 (Wall-Block No-Path Fallback amendment per Lane/Map R2.1 Open Question #9)

## Revision History

- **Original (2026-04-27)**: Authored via `/architecture-decision`. Validated by `/architecture-review` 2026-04-28 (PASS).
- **2026-04-28**: `architecture.yaml` populated with `crowd-pathfinding` performance budget (2.0 ms/frame at 100 agents).
- **2026-05-02 (Wall-Block No-Path Fallback)**: Amendment propagated from `design/gdd/lane-map-system.md` R2.1 / decision log Section G. Adds new "Wall-Block No-Path Fallback" subsection specifying CrowdManager behavior when `query_path()` returns a path that does not reach the goal (legitimate no-path case from Lane/Map Rule 9). The original ADR only addressed Risk 11 (first-query race condition); this amendment closes Lane/Map Open Question #9. Behavior contract: use truncated path as-is, do NOT fire `agent_reached_target` until goal is reached, retry policy stays event-driven (no per-frame requery), zombie behavior at truncated terminus owned by Zombie AI (#17) + Combat (#13/#27). "No zombie permanently stuck" guarantee codified.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Navigation / AI Pathfinding |
| **Knowledge Risk** | MEDIUM-HIGH |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/navigation.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Dedicated 2D `NavigationServer2D` (Godot 4.5 — server is no longer a 3D proxy; API surface unchanged from 4.3 model knowledge but binary path differs, smaller export). RVO2 avoidance is intentionally NOT used (separation steering chosen instead) so 4.5+ avoidance changes are not load-bearing. C# auto-translation rule for `[Signal]` delegate names is load-bearing (snake_case on GDScript side); the inverse rule for plain user methods (NO auto-translation; PascalCase preserved on GDScript side) is also load-bearing. |
| **Verification Required** | (1) Confirm `NavigationServer2D.QueryPath()` returns valid paths against a representative lane TileMapLayer geometry on dev machine. (2) Confirm a `NavigationRegion2D` placed in the Lane scene auto-registers with `GetWorld2D().NavigationMap` and yields a non-zero `Rid`. (3) Microbenchmark: 100 `CharacterBody2D.MoveAndSlide()` calls per frame on dev machine to validate 60fps target before authoring GDD #10. (4) Confirm typed `CrowdAgent` signal argument crosses the marshalling boundary as `CrowdAgent` (not as plain `CharacterBody2D`) when the C# assembly is compiled. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Language Routing Policy — Proposed). Crowd Pathfinding routed to C# per ADR-0003 §2 criterion 1 (>50 entities/frame). All cross-language signals follow ADR-0003's boundary contract. ADR-0001 (Run State / Game Flow — Proposed) is consumed for pause-respect (`state_changed` subscription gates the per-frame loop). |
| **Enables** | GDD #10 (Crowd Pathfinding); the Crowd Pathfinding prototype gating per `design/gdd/systems-index.md` Phase B. Unblocks GDD #17 (Zombie AI) which depends on a stable agent-registration interface. |
| **Blocks** | GDD #17 (Zombie AI) cannot author until the agent-registration contract is locked. GDD #10 cannot author. The Crowd Pathfinding prototype (systems-index Phase B) cannot start. |
| **Ordering Note** | Sits after ADR-0003 (language) and ADR-0001 (run-state) in the ADR-authoring sequence: 0003 → 0001 → 0002. Wave & Spawn (#18, also C#) and Placement & Grid (#25, GDScript) become consumers of the agent-registration interface defined here. |

## Context

### Problem Statement

The concept targets 100+ simultaneous zombies on lane-shaped tower-defense maps. Without a written architecture, three concrete failure modes are baked in by the time GDD authoring begins:

1. **Per-frame query storm.** If each Zombie AI (#17) queries its own path every frame, 100 agents × 60 fps = 6,000 `NavigationServer2D` queries/sec. Documented community guidance for Godot 4.x crowd RTS / TD strongly cautions against per-agent queries at this scale.
2. **Marshalling explosion.** If pathfinding lives in GDScript and per-agent velocities cross the boundary by signal, ADR-0003's `unbatched_csharp_to_gdscript_signal_emission` rule is violated immediately at peak load.
3. **Stale paths after wall placement.** A naive flow-field that rebuilds on a periodic timer leaves zombies walking into walls placed 0.4s ago. The architecture must subscribe to placement events, not poll.

The systems-index lists Crowd Pathfinding (#11) as an MVP **bottleneck** and a **High-Risk Technical** system: *"100+ zombies @ 60 fps in Godot 4.6 is feasible but not automatic."* This ADR exists to choose the architecture **before** the prototype phase so the prototype validates the chosen approach rather than discovering it.

### Constraints

- **Solo dev, C# learning runway is the prototype phase per ADR-0003.** Architecture must be implementable without exotic patterns or native bindings.
- **Performance budget**: 60 fps / 16.6 ms total. Crowd Pathfinding's allocation: ≤2.0 ms/frame at 100 agents (informal target; refined in GDD #10 after prototype).
- **Run State (ADR-0001)**: Manager must NOT advance velocities in `RUN_PAUSED`, `WAVE_RESULTS`, `CARD_ROLL`, `MAIN_MENU`, `CHAMPION_SELECT`, `RUN_LOADING`, `RUN_RESULTS`. Velocity update gated by `current_state == WAVE_ACTIVE`.
- **Forbidden patterns from `docs/registry/architecture.yaml`**:
  - `unbatched_csharp_to_gdscript_signal_emission` — no per-agent per-frame signals from C# manager to GDScript.
  - `string_based_signal_connection` — typed Callable form only.
  - `gdextension_in_mvp_v1` — no godot-cpp custom flow-field at native level.
  - `caching_game_state_across_frames` — manager reads `GameStateMachine.current_state` fresh or via subscription.
  - `csharp_signal_pascalcase_in_gdscript_connect` — `[Signal]` delegate names auto-translate to snake_case in GDScript; PascalCase access from GDScript is forbidden.
- **Map model**: Tower-defense maps are mostly static during a wave. Walls (#27) and Placeable Units (#24) modify navigable geometry between waves and rarely mid-wave. The architecture must treat map-change as a rare event, not a steady-state condition.

### Requirements

- 100+ agents @ 60 fps with per-frame velocity update inside the WAVE_ACTIVE inner loop.
- Path refresh must complete within one frame for any single map-change event with ≤500 cells of changed geometry.
- Agent registration / deregistration must be cheap: zombie spawn / death events occur in bursts at wave start and continuously throughout a wave.
- Agent-on-agent crowding must look acceptable at MVP visual fidelity — zombies SHOULD clump but should not perfectly overlap.
- Pause-aware: in `RUN_PAUSED`, all agents freeze (no per-frame velocity update).
- Test Harness (System 45) must construct a deterministic agent layout headlessly and assert all agents reach the goal within a target frame budget — without requiring `_PhysicsProcess` to tick.

## Decision

**Hybrid pathfinding architecture: a single C# `CrowdManager` autoload owns `NavigationServer2D` path queries on event-driven map-change signals; per-agent C# `CrowdAgent : CharacterBody2D` holds a cached waypoint list and computes velocity each frame in a C# inner loop with simple separation steering. GDScript Zombie AI (#17) registers / deregisters agents and sets target positions via typed C# methods at state-change boundaries — never per frame.**

### Three Pillars

1. **Path query timing** — `NavigationServer2D.QueryPath()` runs ONLY on map-change events (`Placement.placement_changed`, `Wall.wall_destroyed`, `Lane.geometry_baked`). Wave-active steady state has zero path queries. Requeries are batched via `CallDeferred` so multiple events in a single frame collapse into one query batch. The first query after any geometry change is gated on `NavigationServer2D.map_changed` (the bake-complete signal) — not on the upstream geometry-change event alone — because Godot defers nav-mesh rebuild by one frame and a query before the rebuild returns a stale path.
2. **Velocity computation** — Inner per-frame loop runs in C# over a contiguous list of `CrowdAgent` references; reads cached waypoints, computes `direction_to(next_waypoint)`, applies separation steering against N nearest neighbors via spatial hash, normalizes, scales by `MoveSpeed`, sets the `Velocity` field on the agent. All in C#; no boundary crossing.
3. **Cross-language boundary** — Zombie AI (GDScript) calls C# methods on `CrowdAgent` only at state transitions: `Register(target)`, `SetTarget(new_target)`, `Deregister()`. C# emits to GDScript only on rare events: `agent_reached_target` and `path_invalidated`. **All user-defined C# methods preserve PascalCase across the boundary; only `[Signal]` delegate names auto-translate to snake_case.**

### Class Topology

```
┌──────────────────────────────────────────────────────────────────────┐
│ Zombie scene                                                         │
│   • Root: CrowdAgent.cs (CharacterBody2D, C#)                        │
│   • Child Node2D: zombie_ai.gd (GDScript)                            │
│       - State machine: SPAWNING, MOVING, ATTACKING, DYING            │
│       - On SPAWNING→MOVING: agent.Register(goal_position)            │
│       - On any→DYING:       agent.Deregister()                       │
│       - Connects to CrowdManager.agent_reached_target (snake_case)   │
│   • Visual children, hitbox, etc.                                    │
└────────────────────────────▲─────────────────────────────────────────┘
                             │ Register / SetTarget / Deregister
                             │ (typed C# method calls; PascalCase
                             │  preserved across GDScript boundary)
                             │
                             │ agent_reached_target signal (typed)
                             ▼
┌──────────────────────────────────────────────────────────────────────┐
│ CrowdManager.cs (Autoload Node — load order AFTER GameStateMachine)  │
│                                                                      │
│  Owns:                                                               │
│    • _agents:      List<CrowdAgent>                                  │
│    • _pathCache:   Dictionary<int, Vector2[]>  (per-goal-zone path)  │
│    • _spatialHash: SpatialHash2D  (for separation queries)           │
│    • _navMap:      Rid (queried lazily; see "Map Rid Acquisition")   │
│    • _waveActive:  bool (mirrors GameStateMachine WAVE_ACTIVE)       │
│    • _registerQueue / _deregisterQueue: drained at frame start to    │
│      avoid mutate-during-iterate during _PhysicsProcess              │
│                                                                      │
│  Subscribes:                                                         │
│    • Placement.placement_changed         → invalidate + requery      │
│    • Wall.wall_destroyed                 → invalidate + requery      │
│    • LaneSystem.geometry_baked           → initial bake + map RID    │
│    • NavigationServer2D.map_changed      → fire pending requery      │
│    • GameStateMachine.state_changed      → set _waveActive flag      │
│                                                                      │
│  Per-frame (only when _waveActive == true):                          │
│    1. Drain register/deregister queues                               │
│    2. Update spatial hash from agent positions                       │
│    3. For each agent:                                                │
│         waypoint   = _pathCache[agent.GoalZoneId][agent.WaypointIdx] │
│         desired    = (waypoint - pos).Normalized()                   │
│         separation = ComputeSeparation(agent, _spatialHash)          │
│         agent.Velocity = (desired + separation*W).Normalized()       │
│                          * agent.MoveSpeed                           │
│                                                                      │
│  Public C# API:                                                      │
│    • void Register(CrowdAgent agent, Vector2 target)                 │
│    • void SetTarget(CrowdAgent agent, Vector2 target)                │
│    • void Deregister(CrowdAgent agent)                               │
│    • void UpdateVelocitiesForTest(float delta)  // headless tests    │
└──────────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────────┐
│ NavigationServer2D (engine; dedicated 2D server in Godot 4.5+)       │
│                                                                      │
│  Map RID source: NavigationRegion2D node embedded in Lane scene      │
│    auto-registers a map; CrowdManager fetches via                    │
│    laneRoot.GetWorld2D().NavigationMap (Rid)                         │
│                                                                      │
│  Called by CrowdManager only on map-change events:                   │
│    var query = new NavigationPathQueryParameters2D();                │
│    query.Map = _navMap;                  // type: Godot.Rid          │
│    query.StartPosition = goalZoneCenter; // queried IN REVERSE       │
│    query.TargetPosition = spawnZoneCenter;                           │
│    var result = new NavigationPathQueryResult2D();                   │
│    NavigationServer2D.QueryPath(query, result);                      │
│    _pathCache[goalZoneId] = result.Path;  // C# Vector2[]            │
└──────────────────────────────────────────────────────────────────────┘
```

**Why query in reverse (goal → spawn)**: Multiple agents share a goal but enter from different points along the path. By computing the path FROM the goal TO the spawn zone once, every agent on that lane uses the same waypoint sequence (starting from whichever waypoint is closest to its current position) — a per-lane shared path, not per-agent.

### Map Rid Acquisition

The navigation map `Rid` is NOT created manually by `CrowdManager`. Instead:

1. The Lane / Map (#7) scene contains one `NavigationRegion2D` node with a baked `NavigationPolygon`. This auto-registers a navigation map with `GetWorld2D()`.
2. On `LaneSystem.geometry_baked()`, the lane root node calls `CrowdManager.SetNavMap(laneRoot.GetWorld2D().NavigationMap)`. The `Rid` is now valid.
3. CrowdManager subscribes to `NavigationServer2D.map_changed` (the bake-complete signal). The first path query for any goal-zone is deferred until `map_changed` has fired — guarantees the navmesh is rebuilt before query.
4. On scene change (RUN_RESULTS → MAIN_MENU), `CrowdManager` clears `_navMap` to a default `Rid` (invalid) and clears `_pathCache`. New runs re-bake.

This means `CrowdManager` does NOT call `NavigationServer2D.MapCreate()` or build polygon data programmatically. The Lane scene's `NavigationRegion2D` is the authoritative source of map geometry; CrowdManager is a consumer.

### Cross-Language Boundary Contract

Per ADR-0003, the boundary rule is *signals over direct method calls; GDScript orchestrates*. For Crowd Pathfinding the per-frame work is too tight for signals, so the contract is:

- **GDScript → C# (rare, state-transition only)**: typed C# method calls on `CrowdAgent` and `CrowdManager`. Each call is a Variant marshall — at MVP rates (one zombie spawn = one `Register()`, one `SetTarget()` on path-target change), this is well within budget.
- **C# → GDScript (rare events only)**: typed `[Signal]` delegates emitted ONCE per event:
  - `[Signal] public delegate void AgentReachedTargetEventHandler(CrowdAgent agent);` → GDScript `agent_reached_target(agent: CrowdAgent)`
  - `[Signal] public delegate void PathInvalidatedEventHandler(int goalZoneId);` → GDScript `path_invalidated(goal_zone_id: int)`
- **C# → C# (per-frame inner loop)**: NEVER crosses the boundary. The manager iterates its own agents and writes to their fields directly — no Variant marshalling.

This is consistent with ADR-0003's *"any C# hot-path emitting to GDScript more than ~50 times per frame must batch"* — Crowd Pathfinding emits to GDScript ~zero times per frame in steady state.

**Naming-rule reminder (load-bearing)**: In Godot 4.6.2, the C# binding generator auto-translates `[Signal]` delegate names from PascalCase + `EventHandler` suffix to snake_case for GDScript access. **This auto-translation does NOT apply to plain user-defined C# methods.** GDScript callers use:
- For signals: `manager.agent_reached_target.connect(_on_agent_reached_target)` (snake_case, like ADR-0001's `wave_complete`)
- For methods: `agent.Register(goal_position)`, `agent.SetTarget(new_goal)`, `agent.Deregister()` (PascalCase, preserved verbatim)

### Path Query Trigger Set

Path queries fire on these signals only:

| Signal | Source | Action |
|---|---|---|
| `placement_changed(cell)` | Placement & Grid (#25) | Mark all paths invalid; queue requery |
| `wall_destroyed(cell)` | Wall / Fortification (#27) | Mark all paths invalid; queue requery |
| `geometry_baked()` | Lane / Map (#7) | Set `_navMap` Rid; queue initial requery |
| `map_changed(map_rid)` | NavigationServer2D | Fire any pending requery (ensures fresh navmesh) |
| `state_changed(_, RUN_PAUSED)` | GameStateMachine (ADR-0001) | Set `_waveActive = false`; cease per-frame velocity update |
| `state_changed(RUN_PAUSED, _)` | GameStateMachine | Set `_waveActive = (new_state == WAVE_ACTIVE)` |

Path requery is deferred via `CallDeferred("_RequeryAllPaths")`, then gated on the `map_changed` signal. Worst case (10 walls placed in one frame): one requery executed in the frame after `map_changed` fires, not ten.

### Separation Steering (NOT RVO2)

Agent-on-agent collision uses simple separation steering, not Godot's built-in RVO2:

```csharp
// Inside CrowdManager._UpdateVelocities, per agent
Vector2 separation = Vector2.Zero;
int neighborCount = 0;
foreach (var other in _spatialHash.Query(agent.Position, NeighborRadius))
{
    if (other == agent) continue;
    Vector2 away = agent.Position - other.Position;
    float distSq = away.LengthSquared();
    if (distSq < NeighborRadiusSq && distSq > 0.001f)
    {
        separation += away / distSq;  // weight by inverse-square distance
        neighborCount++;
    }
}
if (neighborCount > 0)
    separation = separation.Normalized();

Vector2 desired = (waypoint - agent.Position).Normalized();
agent.Velocity = (desired + separation * SeparationWeight).Normalized() * agent.MoveSpeed;
```

`NeighborRadius` and `SeparationWeight` are tuning knobs exposed via `CrowdManager` `[Export]` properties.

### Register/Deregister Mid-Frame Safety

`Register()` and `Deregister()` enqueue mutations rather than mutating `_agents` directly. The queue is drained at the **top** of `_PhysicsProcess` before any iteration. This prevents a GDScript signal handler from triggering `agent.Deregister()` mid-loop, which would mutate the collection during iteration.

```csharp
public void Register(CrowdAgent agent, Vector2 target)
{
    agent.GoalZoneId = _ResolveGoalZone(target);
    _registerQueue.Enqueue(agent);
}

public void Deregister(CrowdAgent agent)
{
    _deregisterQueue.Enqueue(agent);
}

public override void _PhysicsProcess(double delta)
{
    if (!_waveActive) return;
    while (_deregisterQueue.TryDequeue(out var d)) _agents.Remove(d);
    while (_registerQueue.TryDequeue(out var r))   _agents.Add(r);
    // ... velocity update loop ...
}
```

### Static Instance Accessor and Cleanup

`CrowdManager` exposes a static `Instance` for in-process C# convenience access (avoids `GetNode<CrowdManager>("/root/CrowdManager")` per call site). `_ExitTree()` clears it to prevent a stale reference across scene reloads in the roguelite run-reset flow:

```csharp
public partial class CrowdManager : Node
{
    public static CrowdManager Instance { get; private set; }

    public override void _Ready()    { Instance = this; /* subscribe... */ }
    public override void _ExitTree() { if (Instance == this) Instance = null; }
}
```

GDScript callers use the autoload path (`/root/CrowdManager`) directly via signal connection; the `Instance` accessor is C#-internal only.

### Wall-Block No-Path Fallback (amendment 2026-05-02 — applied per Lane/Map R2.1 / `/propagate-design-change`)

> **Source**: `design/gdd/lane-map-system.md` R2.1 Section C Rule 9 + Section E Edge Cases + Section F Dependencies + Open Question #9; locked decision `DD#3 = Idempotent overwrite` 2026-05-02.

Lane/Map's Section C Rule 9 ("walls may freely block all paths") accepts that a wall mutation can legitimately leave **zero path** from a zombie's current cell to its goal. The original ADR-0002 only addressed the race condition between bake completion and first query (Risk 11 — "first path query before navmesh rebuilt → empty path"), NOT the case where a wall mutation legitimately blocks the lane. CrowdManager owns the no-path fallback behavior; this section is the contract.

#### Behavior when `query_path()` returns a path that does not reach the goal

Godot's `NavigationServer2D` with `NavigationPathQueryParameters2D` returns a path that ends at the closest navmesh point reachable from the start when the goal is fully obstructed. CrowdManager treats this as the canonical no-path case:

1. **Use the truncated path as-is**. The agent paths to the closest reachable cell adjacent to the obstructing wall and stops there (terminal waypoint reached → `Velocity = Vector2.Zero`). CrowdManager does NOT mark the agent as "stuck" or "errored" — the truncated path IS the correct path under Lane/Map Rule 9.
2. **Do NOT fire `agent_reached_target`** (the agent did not reach its registered goal — it reached a waypoint adjacent to the obstruction). Agents queryable via `IsAtGoal: bool` flag (false when only at truncated terminus).
3. **What the zombie does next is owned by Zombie AI (#17) + Combat (#13/#27)**, NOT CrowdManager. Per Lane/Map's Edge Case prose: "Zombies in the lane will arrive at the closest reachable cell to the goal and engage the wall via Combat." CrowdManager's role ends at "moved the agent to the truncated path's end and stopped"; the wall-attack behavior lives in Zombie AI's GDD when authored.

#### Retry policy (event-driven only — NEVER per-frame)

Once a CrowdAgent's path is truncated, CrowdManager does NOT requery the path on every frame. Per-frame requery would burn the per-frame budget for no signal value (the obstruction will not move until a wall mutation event). Requeries fire **only** on:

- `placement_changed` (a tower/unit was placed or removed)
- `wall_destroyed` (a wall's HP hit 0; Lane/Map has called `remove_wall_outline` and re-baked)
- `geometry_baked` (any other geometry change)

Followed by `NavigationServer2D.map_changed` (the bake-complete signal) gating the actual `query_path()` call. The existing Path Query Trigger Set covers these — this amendment makes explicit that the same trigger set serves the no-path-recovery case (no separate "stuck zombie" requery event needed).

#### "No zombie permanently stuck" guarantee

When `wall_destroyed` fires (because zombies attacking the wall have depleted its HP per Combat), Lane/Map calls `remove_wall_outline` → re-bakes → `geometry_baked` → `NavigationServer2D.map_changed` → CrowdManager's deferred requery fires for the affected lane → the path now reaches the goal → agent's `Velocity` updates on the next per-frame cycle. AC for this behavior is owned by Wall/Fortification's GDD when authored (per Lane/Map R2.1 Section F cross-system AC re-authoring tracker — replaces the deleted Lane/Map AC-LM-23). The guarantee is: no zombie remains at a truncated terminus after the obstruction is removed and `map_changed` has fired.

#### Implementation note

Track per-agent state via a `bool _isAtTruncatedTerminus` flag on `CrowdAgent`, set in the velocity-update loop when the agent reaches the path's terminal waypoint AND that waypoint is NOT the registered goal. Clear the flag on the next successful path query that returns a path reaching the goal. The flag is C#-internal; not exposed across the language boundary (zombie behavior at truncated terminus is owned by Zombie AI, which observes `Velocity == Vector2.Zero` directly via the `agent_reached_target` non-emission).

### Key Interfaces

```csharp
// CrowdAgent.cs (CharacterBody2D, root of every Zombie scene)
public partial class CrowdAgent : CharacterBody2D
{
    [Export] public float MoveSpeed = 60.0f;
    [Export] public int GoalZoneId = 0;
    public int WaypointIndex { get; internal set; }
    public bool IsRegistered { get; internal set; }

    // Convenience wrappers — call into CrowdManager.Instance
    public void Register(Vector2 target)   => CrowdManager.Instance.Register(this, target);
    public void SetTarget(Vector2 target)  => CrowdManager.Instance.SetTarget(this, target);
    public void Deregister()               => CrowdManager.Instance.Deregister(this);

    public override void _PhysicsProcess(double delta)
    {
        // Velocity is set by CrowdManager._UpdateVelocities; this just drives MoveAndSlide.
        if (IsRegistered) MoveAndSlide();
    }
}

// CrowdManager.cs (Autoload Node)
public partial class CrowdManager : Node
{
    public static CrowdManager Instance { get; private set; }

    [Export] public float NeighborRadius = 24.0f;
    [Export] public float SeparationWeight = 0.6f;

    [Signal] public delegate void AgentReachedTargetEventHandler(CrowdAgent agent);
    [Signal] public delegate void PathInvalidatedEventHandler(int goalZoneId);

    public void SetNavMap(Rid navMap);
    public void Register(CrowdAgent agent, Vector2 target);
    public void SetTarget(CrowdAgent agent, Vector2 target);
    public void Deregister(CrowdAgent agent);
    public void UpdateVelocitiesForTest(float delta);  // headless test entry point
}
```

GDScript Zombie AI accesses these as follows. Note: methods are PascalCase (no auto-translation); signal accessors are snake_case (auto-translation applies to `[Signal]` delegates per Godot 4.6.2 binding rules):

```gdscript
# zombie_ai.gd — attached to a child Node2D under the Zombie scene root.
extends Node2D

@onready var agent: CrowdAgent = get_parent() as CrowdAgent

func _ready() -> void:
    assert(agent != null, "zombie_ai.gd parent is not a CrowdAgent — check scene composition")
    CrowdManager.agent_reached_target.connect(_on_agent_reached_target)

func _enter_combat(goal: Vector2) -> void:
    agent.Register(goal)            # PascalCase preserved (user method)

func _on_death() -> void:
    agent.Deregister()              # PascalCase preserved

func _on_agent_reached_target(reached: CrowdAgent) -> void:
    if reached != agent: return
    # zombie reached its goal — apply damage, despawn, etc.
```

## Alternatives Considered

### Alternative A: Per-agent NavigationAgent2D + RVO2 (idiomatic Godot)

- **Description**: Each zombie scene contains a `NavigationAgent2D` child node. Each agent queries its own path via `target_position`; uses RVO2 avoidance via `velocity_computed` signal.
- **Pros**: Lowest custom code; Godot tutorial-canonical; RVO2 avoidance is mathematically correct.
- **Cons**:
  - 100 NavigationAgent2D nodes = 100 internal RVO2 agent registrations; per-frame neighbor query is O(N²) worst case.
  - Per-agent path queries — no shared path across agents on same lane.
  - GDScript-only zombies = zombie loop runs in interpreted code; community profiling reports show this hits the ceiling well below 100 agents at 60 fps in 2024–25 Godot benchmarks.
  - The "register one NavigationAgent2D per zombie" pattern is documented to be problematic above ~50 agents; community recommendation for crowd RTS / TD is "shared path manager + cheap per-agent steering" — exactly Option C.
- **Rejection Reason**: Architecturally guarantees the failure modes the systems-index High-Risk row warns about. Idiomaticity is not worth a pre-known performance cliff.

### Alternative B: Custom flow-field grid in C#

- **Description**: A 2D grid of cells, each storing a `Vector2` direction toward the goal. Rebuilt via BFS / wavefront on every map-change. Agents read O(1) per frame.
- **Pros**: Theoretically lowest per-agent cost. Tower-defense classic. Handles arbitrary numbers of agents trivially since per-agent cost is O(1) array read.
- **Cons**:
  - Cell-resolution tradeoff: too coarse → zombies walk through wall corners; too fine → rebuild cost explodes (e.g., 64×32 grid is 2K cells; 256×128 is 32K cells).
  - Loses navmesh's correctness on arbitrary-shape geometry — flow-field on a grid forces "everything fits a grid", which is fine for tower defense but bakes a constraint into MVP that V1 maps may want to escape.
  - Custom code surface: BFS implementation, cell-to-world transform, edge-case handling at goal boundaries. ~300 lines of new C# vs. ~50 lines for `NavigationServer2D` wrapper.
  - Godot 4.5's dedicated 2D nav server made `NavigationServer2D` queries materially cheaper than they used to be — much of flow-field's "I'm avoiding nav server cost" rationale shrinks.
- **Rejection Reason**: Solves a problem we don't have (per-agent cost is not the bottleneck if we cache the path) at the cost of 300+ lines of custom code that `NavigationServer2D` already provides. Reconsider only if profiling shows shared-path queries cost more than expected.

### Alternative D: AStar2D + custom local steering

- **Description**: Use Godot's `AStar2D` class on a grid graph; query paths per agent. Custom steering on top.
- **Pros**: Simpler than `NavigationServer2D` for grid-only maps; well-known API.
- **Cons**:
  - Reinvents `NavigationServer2D`'s polygon-navmesh capability with a less-flexible grid.
  - Loses the dedicated 2D server's optimization in Godot 4.5+.
  - Custom steering still required (same code as Option C).
  - Per-agent queries have the same scaling problem as Option A.
- **Rejection Reason**: Strictly inferior to Option C: same custom-code surface (steering) but with a less-capable underlying pathfinder.

## Consequences

### Positive

- **One pathfinding owner** — `CrowdManager` autoload is the single source of agent state and path cache; no per-system reinvention.
- **Steady-state cost dominated by velocity update only** — at 100 agents the inner loop is target ~50 µs (refined by prototype). Zero path queries during WAVE_ACTIVE.
- **Pause-respecting by construction** — manager subscribes to `GameStateMachine.state_changed`; no per-system pause checks scattered through Zombie AI.
- **Marshalling cost capped** — boundary crossings are register / set_target / deregister (per-zombie-life events, ~1–100/sec at burst). C#→GDScript signals only on agent-reached-target events (~1–3/sec/agent dying or reaching goal).
- **Test Harness friendly** — manager exposes `Register()`, `SetTarget()`, and `UpdateVelocitiesForTest(delta)` as plain C# methods; headless test can build deterministic agent layouts and step the simulation without `_PhysicsProcess` ticking.
- **`NavigationServer2D`'s strength preserved** — arbitrary lane geometry, including curved paths and concave corridors that pure grids handle poorly.

### Negative

- **One autoload added** — `CrowdManager`. Combined with `GameStateMachine` (ADR-0001), the project now has two autoloads. Project Settings autoload list must place `CrowdManager` AFTER `GameStateMachine` so the latter is `_Ready()` first.
- **Composition-heavy zombie scene** — Zombie root must be `CrowdAgent.cs` (CharacterBody2D, C#); `zombie_ai.gd` lives as a child Node2D with a script. Solo dev may instinctively reach for "one root with everything on it" pattern that doesn't fit here.
- **Path cache invalidation is global, not per-region** — any placement event invalidates ALL goal-zone paths. Cheap to recompute (<1 ms expected for typical lane); coarse but simple.
- **No RVO2** — separation steering is a step down in collision quality vs. RVO2. Acceptable for "hordes of zombies SHOULD clump"; revisit if Champion movement requires careful single-agent avoidance (Champion is not a `CrowdAgent`).
- **Custom spatial hash** — adds ~80 lines of C# for the spatial-hash structure used by separation steering.
- **Two naming rules at the boundary** — methods preserve PascalCase in GDScript; signals auto-translate to snake_case. Easy to mis-apply; documented in the Cross-Language Boundary Contract section above. Control manifest will surface this.

### Risks

1. **Risk: `NavigationServer2D` path query cost exceeds estimate at 64×32 grid lane.**
   - **Mitigation**: Benchmark in prototype — issue 4 path queries (one per goal zone) on dev-machine map, measure ms. If >2 ms, fall back to flow-field for the affected goal only (Option B becomes a per-goal opt-in, not a project-wide architecture change).

2. **Risk: Separation steering produces visible jitter or "stuck pairs" of zombies.**
   - **Mitigation**: Tuning knobs (`NeighborRadius`, `SeparationWeight`) callable at runtime via debug overlay. If tuning fails, escalate to RVO2 for a subset of agents (mini-bosses) only.

3. **Risk: 100 `CharacterBody2D.MoveAndSlide()` calls per frame exceed budget.**
   - **Mitigation**: `MoveAndSlide()` is C++ inside the engine; the cost is collision-shape pair tests, not script. Verify in prototype with 100 agents. If problematic, switch a subset of agents to "kinematic ghost" (just position update, no `MoveAndSlide`) — they accept that they may overlap walls slightly during fast movement.

4. **Risk: Map-change invalidation storm during aggressive wall placement.**
   - **Mitigation**: Path requery is deferred via `CallDeferred` AND gated on `NavigationServer2D.map_changed`, so multiple events in one frame batch into one requery executed after the navmesh has rebuilt. Worst case (10 walls placed simultaneously): one requery, not ten.

5. **Risk: Agent registration / deregistration during wave-start spike floods Variant marshall.**
   - **Mitigation**: Wave & Spawn (#18) is C# batching — it can call `CrowdManager.Register()` in C#-native iteration without crossing the boundary. The marshalling cost is paid only by GDScript Zombie AI script if it instantiates zombies one-by-one (a code-smell anyway; spawning is Wave System's job).

6. **Risk: `CrowdManager.Instance` static is an autoload-coupling pattern.**
   - **Mitigation**: `CrowdManager` is an explicit autoload in Project Settings. GDScript consumers connect to its signals via the autoload path; the static `Instance` accessor is C#-internal only. `_ExitTree()` clears `Instance` so scene reloads in the roguelite run-reset flow do not leave a stale reference.

7. **Risk: Test Harness can't drive `CharacterBody2D` headlessly because physics doesn't tick without a SceneTree.**
   - **Mitigation**: `CrowdManager.UpdateVelocitiesForTest(float delta)` runs the velocity update without requiring `_PhysicsProcess`. Test harness instantiates agents, registers them, calls `UpdateVelocitiesForTest` in a loop, asserts position progression. `MoveAndSlide()` itself is skipped in tests — agents move via direct position write inside the test variant.

8. **Risk: Zombie root being `CrowdAgent.cs` makes Zombie AI editing C#-flavored.**
   - **Mitigation**: Zombie AI lives in `zombie_ai.gd` as a child Node2D — the C# root is invisible to the gameplay-coding flow as long as the GDScript writer uses `get_parent() as CrowdAgent` to address the agent and only calls the documented public methods. Document this convention in GDD #17 (Zombie AI) and the control manifest.

9. **Risk: Typed `CrowdAgent` argument in `[Signal]` delegate is silently downgraded to `CharacterBody2D` if the C# assembly is not compiled before the scene loads.**
   - **Mitigation**: A correctly configured `.csproj` (per ADR-0003 §`.csproj setup prerequisite`) ensures the C# assembly is built before any scene references it. CI must `godot --headless --import` (project-open step) before `dotnet build`, then run `dotnet build` before any scene-loading test. The runtime guard `assert(agent != null, ...)` catches the failure case in dev.

10. **Risk: GDScript writer uses snake_case for a user-defined C# method (e.g., `agent.register(goal)`) and it silently resolves to a different / non-existent method.**
    - **Mitigation**: Register a forbidden pattern (`csharp_method_snakecase_in_gdscript_call`) alongside the existing inverse pattern (`csharp_signal_pascalcase_in_gdscript_connect`). The two together codify the boundary naming rule: signals auto-translate to snake_case; methods preserve PascalCase. The control manifest surfaces this in the C#-boundary section.

11. **Risk: First path query after `geometry_baked` fires before navmesh is rebuilt — returns empty path.**
    - **Mitigation**: Requeries gated on `NavigationServer2D.map_changed` (the bake-complete signal), not on the upstream geometry-change event alone. Documented in Path Query Trigger Set.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| Crowd Pathfinding (10) | "100+ zombies @ 60 fps in Godot 4.6 is feasible but not automatic" (systems-index High-Risk Technical) | Defines the hybrid architecture and locks the C# manager autoload, per-agent `CrowdAgent` class, `NavigationServer2D` query trigger set, and separation steering kernel. Prototype (per systems-index Phase B) validates the choice rather than discovering it. |
| Zombie / Enemy AI (17) | "depends on: Crowd Pathfinding (11), Damage & Health (13)" | `CrowdAgent` + `CrowdManager` interfaces are the contract Zombie AI consumes. `zombie_ai.gd` subscribes to `agent_reached_target`; calls `Register()` / `SetTarget()` / `Deregister()` at state transitions only. |
| Wave & Spawn (18) | "Instantiation spikes at wave start. Use object pooling" (Performance Watchlist) | Wave & Spawn is C# (per ADR-0003); it can call `CrowdManager.Register()` directly for pooled zombies without crossing the boundary, avoiding marshalling spikes at wave start. |
| Lane / Map (7) | "Structural map definition. Bottleneck." | Lane / Map embeds a `NavigationRegion2D`; emits `geometry_baked` once at run start; `CrowdManager` subscribes and acquires `_navMap` Rid. Lane / Map owns the geometry; `CrowdManager` owns the path cache derived from it. |
| Placement & Grid (25) | "depends on: Lane / Map, Placeable Unit, Resource / Economy" | Emits `placement_changed(cell)` on each placement; `CrowdManager` subscribes and invalidates path cache. Single-direction signal contract — Placement does not depend on Crowd Pathfinding. |
| Wall / Fortification (27) | "depends on: Lane / Map, Damage & Health, Resource / Economy" | Emits `wall_destroyed(cell)` on destruction; `CrowdManager` subscribes. Walls block paths via `NavigationRegion2D` modification (Lane / Map's responsibility); `CrowdManager` only re-queries. |
| Run State (8) | 9-state enum; pause respect (ADR-0001) | `CrowdManager` subscribes to `state_changed`; sets `_waveActive = (new_state == WAVE_ACTIVE)` and gates the per-frame velocity update on this flag. No per-system pause-checking required by consumers. |
| Test Harness (45) | "Headless run runner + deterministic RNG + fixture loader" (systems-index) | `CrowdManager.UpdateVelocitiesForTest(delta)` exposes the kernel for headless testing. Deterministic positions in / deterministic positions out — RNG-free at this layer. |

## Performance Implications

- **CPU**: Per-frame steady state at 100 agents — target ≤ 2.0 ms/frame. Components: spatial hash update (~0.3 ms), velocity compute loop (~0.6 ms — read waypoint, normalize, separation), `MoveAndSlide()` × 100 (~0.8 ms — C++ inside engine). Path queries during WAVE_ACTIVE: 0. Path queries on placement event: ~1 ms for full requery batch (deferred to next frame after `map_changed` fires; doesn't compound with the same frame's other work).
- **Memory**: Path cache: ~16 bytes/`Vector2` × ~50 waypoints/lane × 4 lanes ≈ 3 KB. Spatial hash: ~50 KB at 100 agents. Negligible vs. 2 GB ceiling.
- **Load Time**: One-time `NavigationServer2D` map setup at run start (handled by Lane scene's `NavigationRegion2D`): ~5–15 ms (per Godot benchmarks for typical TileMapLayer geometry). Within the RUN_LOADING budget (~500 ms target).
- **Network**: N/A — single-player.

## Migration Plan

1. **Pre-prototype verification (in C# learning-runway phase)**:
   - Confirm `partial` C# class compilation, autoload registration, and `NavigationServer2D.QueryPath()` round-trip on dev machine. Per ADR-0003 Migration Plan §1.
   - Confirm `CharacterBody2D.MoveAndSlide()` callable from C# and produces identical behavior to GDScript version.
   - Confirm `NavigationRegion2D` in scene auto-registers with `GetWorld2D().NavigationMap`.
   - Confirm typed `CrowdAgent` signal argument crosses the marshalling boundary as `CrowdAgent` (not `CharacterBody2D`) when the C# assembly is built before the scene loads.
2. **Prototype (per systems-index Phase B)**: Implement the manager + 100 agents on a test scene; verify 60 fps with separation steering enabled. Tune `NeighborRadius` and `SeparationWeight` until visual quality is acceptable. **This prototype is the validation gate for this ADR.**
3. **First implementation story** (Logic): `CrowdAgent.cs` with public methods, `CrowdManager.cs` with `Register` / `SetTarget` / `Deregister` + per-frame velocity loop (separation only, no path cache yet). Test: 100 agents move toward a static target at 60 fps.
4. **Second implementation story** (Logic): `NavigationServer2D` path-query subsystem; `SetNavMap(Rid)` API; `map_changed` gating. Test: query a single goal-zone path on a representative lane, assert waypoints reach goal.
5. **Third implementation story** (Integration): Wire `placement_changed` / `wall_destroyed` / `state_changed` subscriptions; verify map-change invalidation produces fresh paths within one frame after `map_changed`.
6. **Fourth implementation story** (Integration): Wire Zombie AI (#17) — only after GDD #17 is authored. Test: 100 zombies on a real lane reach goal under 60 fps.
7. **Project Settings update**: Set autoload order so `CrowdManager` loads after `GameStateMachine`. Update CI's autoload-order check (if/when added by `/test-setup`).
8. **Control manifest update**: Add to the C#-boundary section:
   - *"Zombie scene root must be `CrowdAgent.cs`; gameplay scripts use `get_parent() as CrowdAgent` to address the agent."*
   - *"User-defined C# methods preserve PascalCase across the GDScript boundary. Use `agent.Register(...)` not `agent.register(...)`."*
   - *"`[Signal]` delegate names auto-translate to snake_case in GDScript. Use `manager.agent_reached_target.connect(...)` not `manager.AgentReachedTarget.connect(...)` (latter banned by `forbidden_patterns: csharp_signal_pascalcase_in_gdscript_connect`)."*

## Validation Criteria

This ADR is correct if all hold by end of MVP:

- 100 zombies on the MVP 2-lane map maintain ≥60 fps on the dev machine in WAVE_ACTIVE for at least 90% of frames in a representative wave (asserted in playtest log).
- Path requery on placement event completes within one frame after `map_changed` at the MVP map's typical placement count (≤8 placements per wave-prep phase).
- Zero per-frame Variant marshalling occurs in WAVE_ACTIVE (asserted by code review of `_PhysicsProcess` in `CrowdManager` — no GDScript-targeted signals fire from inner loop).
- Test Harness drives ≥10 deterministic agent layouts headlessly without modifying `CrowdManager`.
- Agents freeze in `RUN_PAUSED` state (asserted by integration test: pause during WAVE_ACTIVE; assert agent positions unchanged for 30 frames).
- Separation steering keeps zombie clump rate at "looks correct" — no hard threshold; gameplay director sign-off required.
- Typed `CrowdAgent` signal argument resolves correctly across the boundary on both dev and CI (asserted by integration test that subscribes from GDScript and asserts `arg is CrowdAgent`).

This ADR is incorrect (warrants superseding ADR) if any of:

- Path query cost on map-change exceeds 5 ms — would push toward Option B (flow-field) for hot lanes.
- Separation steering produces unfixable visual jitter — would push toward RVO2 (Option A subset) for affected agent types.
- 100 agents at 60 fps cannot be hit on dev machine even after profiling — would push toward GDExtension (forbidden by ADR-0003 in MVP/V1; would itself require a superseding ADR-0003 amendment first).
- The static `Instance` accessor causes scene-reload bugs in the run-reset flow that `_ExitTree` cleanup does not fix — would push toward dropping the static accessor in favor of `GetNode<CrowdManager>("/root/CrowdManager")` everywhere.

## Related Decisions

- **ADR-0003 (Language Routing Policy — Proposed)** — Crowd Pathfinding routed to C# per criterion 1 (>50 entities/frame). Cross-language signal/method-call rules followed verbatim. The boundary naming rules (signals → snake_case, methods → PascalCase) jointly refine ADR-0003's Cross-Language Boundary Contract: ADR-0003 line 95's method example was corrected to PascalCase form (`BuildModifier.ComputeStats(input)`) during the 2026-04-28 architecture review, and ADR-0002's `csharp_method_snakecase_in_gdscript_call` forbidden_pattern (combined with ADR-0001's inverse `csharp_signal_pascalcase_in_gdscript_connect`) codifies the full boundary naming rule going forward.
- **ADR-0001 (Run State / Game Flow — Proposed)** — `state_changed` signal subscription gates per-frame velocity update; pause respect is delegated to the manager. Forbidden pattern `csharp_signal_pascalcase_in_gdscript_connect` registered by ADR-0001 is the inverse of the new pattern this ADR proposes (`csharp_method_snakecase_in_gdscript_call`); together they codify the full boundary naming rule.
- **ADR-006 (Save Schema — pending)** — Crowd Pathfinding has no persistent state by design (agents are transient; recreated on `RUN_LOADING`). No save schema entries.
- **ADR-007 (Effect Composition Taxonomy — pending, inside Build/Modifier GDD)** — orthogonal; modifier effects on movement speed (`agent.MoveSpeed`) are the only intersection. Build/Modifier writes to `agent.MoveSpeed` via the standard `ModifierTarget` contract (ADR-005 inside Champion GDD), not via Crowd Pathfinding's API.
- `design/gdd/systems-index.md` — Crowd Pathfinding (System 11) row, Layer 1 dependency, High-Risk Systems table, Performance Watchlist entry.
- `docs/engine-reference/godot/modules/navigation.md` — `NavigationServer2D` and `NavigationAgent2D` reference patterns.
- `docs/registry/architecture.yaml` — registry entries this ADR will add: `CrowdManager` state ownership of agent registry; `agent_reached_target` and `path_invalidated` interface contracts; `CrowdAgent : CharacterBody2D` as the canonical zombie-root API decision; `nav_map_acquisition_via_navigationregion2d_node` API decision; forbidden pattern `csharp_method_snakecase_in_gdscript_call`.
