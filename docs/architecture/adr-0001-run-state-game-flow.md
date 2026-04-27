# ADR-0001: Run State / Game Flow

## Status
Proposed

## Date
2026-04-25

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Scene Management / State Architecture |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `@abstract` (4.5+) — opportunistic, only if a state-base-class refactor is pursued; not load-bearing. `await signal` (4.0+) for any optional async transition (e.g., `await state_changed`). All APIs used are additive; no migration risk vs. Godot 4.3 model knowledge. |
| **Verification Required** | Confirm autoload `_ready()` runs before any scene-level `_ready()` on dev machine (documented Godot behavior — 5-min sanity check). Confirm autoload's `process_mode = PROCESS_MODE_ALWAYS` (set explicitly in `_ready()`; the default for any Node — autoloads included — is `PROCESS_MODE_INHERIT`) so deferred follow-up work created inside signal handlers (`Tween` instances, `await get_tree().process_frame`, `call_deferred`) continues across `get_tree().paused = true`. Note: signal handlers themselves are direct invocations and fire regardless of process mode; `PROCESS_MODE_ALWAYS` is load-bearing only for these in-handler continuations. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Language Routing Policy — Proposed). Run State must be GDScript orchestration per the language-routing rules; Wave System's C# `WaveComplete` signal connects via typed Callable per the cross-language boundary contract. |
| **Enables** | GDD #1 (Run State / Game Flow). Unblocks 13 consumer GDDs: #2 (Save/Load), #10 (Adaptive Music), #18 (Wave & Spawn), #20 (Resource/Economy), #22 (Card-Roll), #29 (HUD), #32 (Wave Summary UI), #33 (Main Menu & Champion Select), #34 (Run Results UI), #36 (Tutorial), #37 (Meta-Currency), #41 (Leaderboard), #45 (Test Harness). |
| **Blocks** | All MVP epics that need to know "what phase is the game in" — 13 consumer systems above. No consumer GDD authoring or implementation can begin until this ADR is Accepted. |
| **Ordering Note** | ADR-0003 is the only Accepted predecessor. ADR-006 (Save Schema) is downstream — this ADR locks the **shape** of the snapshot Dictionary; ADR-006 will own evolution rules (versioning, migration, persistence policy). Ordering: 0003 → 0001 → 0006. |

## Context

### Problem Statement

The systems index identifies 13 systems that read or react to the game's current phase. Without a single owner for *what phase the game is in* and a contract for *how consumers know when it changes*, every consumer would invent its own state-tracking. Three concrete failures result:

1. **State desync** — HUD shows "Wave 3 PREP" while Wave System has already started spawning enemies, because each system polled a different source of truth.
2. **Transition-blind consumers** — Adaptive Music keeps the combat track playing during card-roll because it never learned the phase changed.
3. **Untestable headless runs** — Test Harness (System 45) can't drive deterministic state sequences in `--headless` simulations because there's no contract to drive against.

Run State is also the bottleneck identified in the systems index High-Risk Systems table: 9+ MVP systems depend on its state enum and event contract. Locking these *before* GDD authoring begins is the explicit reason this ADR is required first in the ADR-authoring sequence (after ADR-0003).

### Constraints

- **Solo developer, GDScript by default** per ADR-0003. No C# in this layer; cross-language signals only at the Wave System boundary.
- **Pillar 4 (low skill floor, expression ceiling)** — pause must work cleanly so players can stop mid-wave to read card descriptions without losing position, build state, or wave progress.
- **Test Harness (System 45) requires deterministic state-driving.** State machine must be drivable from test code without a full scene tree — `GameStateMachine.transition_to()` must be callable directly.
- **Forbidden patterns from `docs/registry/architecture.yaml`**:
  - `string_based_signal_connection` — typed Callable form only.
  - `unbatched_csharp_to_gdscript_signal_emission` — Wave→RunState signals fire on transitions, never per-frame.
- **Save/Load downstream constraint** — snapshot Dictionary must be JSON-serializable with primitive types only (no Object references, no Callables).
- **Performance budget** — 60fps / 16.6ms / 1500 draw calls / 2GB RAM (per `.claude/docs/technical-preferences.md`). Run State has no hot-path role; per-transition allocation budget is generous.

### Requirements

- 9 distinct phases reflecting the concept's core loop: `MAIN_MENU → CHAMPION_SELECT → RUN_LOADING → RUN_PREP → WAVE_ACTIVE → WAVE_RESULTS → CARD_ROLL → RUN_PAUSED → RUN_RESULTS`.
- Transition events fire as typed signals; consumers connect via Callable form.
- Wave System (C# batching) emits one `WaveComplete` signal per wave end; Run State connects to it.
- Pause from any in-run state preserves the prior state and resumes correctly.
- Snapshot publishable on every transition; Save/Load consumes selectively per ADR-006.
- State queries are read-only from consumers; only `GameStateMachine` itself writes its own state.
- Test Harness can drive transitions programmatically in headless mode.
- 9-state enum is JSON-serializable (an `int` value in the snapshot).

## Decision

**Centralized Autoload `GameStateMachine` (GDScript) with a flat 9-state enum, signal-based transition notification, validated transition table, and snapshot-on-every-transition contract. Cross-language entry point: Wave System's C# `WaveComplete` signal connects into the autoload's `_on_wave_complete` Callable per the ADR-0003 boundary contract.**

### State Enum

```gdscript
class_name GameState
enum {
    MAIN_MENU,         # title screen, no run active
    CHAMPION_SELECT,   # picking Champion before run start (debug dropdown at MVP, full UI at VS)
    RUN_LOADING,       # map + Champion + initial card pool loaded; transient (~0.5s)
    RUN_PREP,          # 30-60s pre-wave: place units, repair walls, review build
    WAVE_ACTIVE,       # 2-4 min combat phase; Wave System is in control
    WAVE_RESULTS,      # post-wave summary: kills, time, drops shown (concept "loot" sub-beat)
    CARD_ROLL,         # pick 1 of 3 cards (concept "card-roll" sub-beat, distinct from loot)
    RUN_PAUSED,        # overlay pause; previous_state remembered for resume
    RUN_RESULTS,       # death or victory screen; runs after wave 10 boss or HP=0
}
```

**Why CARD_ROLL is its own state, not folded into WAVE_RESULTS**: The concept's *"30s loot/card-roll"* phase has two distinct sub-beats. WAVE_RESULTS is "show the player what they earned" (kills, time, drops, streak max). CARD_ROLL is "make the build choice" (pick 1 of 3 cards). HUD, Adaptive Music, and Tutorial consumers benefit from reacting differently to each — for example, Adaptive Music can shift to a quieter "decision cue" on CARD_ROLL entry, and Tutorial can highlight only the card slots. The cost is one extra state in the enum and one extra transition (`WAVE_RESULTS → CARD_ROLL`); the gain is one extra reactive hook for every UI/audio/tutorial consumer.

### Transition Diagram

```
                    ┌─────────────────────┐
                    │     MAIN_MENU       │◄─────────────────┐
                    └──────────┬──────────┘                  │
                               ▼                             │
                    ┌─────────────────────┐                  │
                    │  CHAMPION_SELECT    │                  │
                    └──────────┬──────────┘                  │
                               ▼                             │
                    ┌─────────────────────┐                  │
                    │    RUN_LOADING      │                  │
                    └──────────┬──────────┘                  │
                               ▼                             │
                    ┌─────────────────────┐                  │
                ┌──►│      RUN_PREP       │                  │
                │   └──────────┬──────────┘                  │
                │              ▼                             │
                │   ┌─────────────────────┐                  │
                │   │    WAVE_ACTIVE      │                  │
                │   └──────────┬──────────┘                  │
                │              ▼                             │
                │   ┌─────────────────────┐                  │
                │   │   WAVE_RESULTS      │                  │
                │   └──────────┬──────────┘                  │
                │              ▼                             │
                │   ┌─────────────────────┐                  │
                └───┤     CARD_ROLL       │                  │
                    └──────────┬──────────┘                  │
                               │ (wave 10 boss defeat OR HP=0│
                               │  OR explicit quit-to-menu)  │
                               ▼                             │
                    ┌─────────────────────┐                  │
                    │    RUN_RESULTS      │──────────────────┘
                    └─────────────────────┘

  Pause overlay (allowed from RUN_PREP, WAVE_ACTIVE, WAVE_RESULTS, CARD_ROLL):
                    ┌─────────────────────┐
                    │    RUN_PAUSED       │  stores previous_state
                    └──────────▲──────────┘  resumes via transition_to(previous_state)
                               │
                               └── from any in-run state
```

### Signal Contract

```gdscript
# === Canonical transition signals (every transition fires these) ===
signal state_changed(from: int, to: int)     # GameState enum values
signal state_entered(state: int)
signal state_exited(state: int)

# === Convenience signals (derived from state_changed; spare consumers from filtering) ===
signal run_started(champion_id: StringName, map_id: StringName, seed: int)
signal run_ended(outcome: int)               # RunOutcome enum
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int, performance: WavePerformance)
signal card_roll_offered(cards: Array[Resource])  # 3 card resources offered
signal card_picked(card: Resource)
signal run_paused
signal run_resumed

# === Save/Load contract ===
signal state_snapshot_ready(snapshot: Dictionary)
```

The `state_changed` signal is the canonical contract; convenience signals are emitted *alongside* `state_changed` so consumers don't have to filter enum transitions themselves. All consumer connections MUST use the typed Callable form per `forbidden_patterns: string_based_signal_connection`:

```gdscript
# CORRECT (typed Callable)
GameStateMachine.state_changed.connect(_on_state_changed)
GameStateMachine.wave_ended.connect(_on_wave_ended)

# FORBIDDEN (string-based; banned by registry)
GameStateMachine.connect("state_changed", self, "_on_state_changed")
```

### Cross-Language Signal: Wave System (C#) → Run State (GDScript)

Per ADR-0003, Wave System is C# batching / GDScript orchestration. The C# inner loop emits **one** `WaveComplete` signal at end-of-wave (NOT per zombie spawn, NOT per zombie death). Run State's autoload connects via typed Callable:

```gdscript
# In game_state_machine.gd (autoload)
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS  # signal handlers fire while paused
    # Connect to Wave System's C# signal lazily — wave_system autoload may load after us
    call_deferred("_connect_wave_system")

func _connect_wave_system() -> void:
    var wave_system: Node = get_node_or_null("/root/WaveSystem")
    assert(wave_system != null, "WaveSystem autoload not found — check Project Settings autoload order")
    # NOTE: C# [Signal] WaveCompleteEventHandler surfaces to GDScript as `wave_complete`
    # (PascalCase→snake_case auto-translation). The PascalCase `WaveComplete` form is
    # the C#-side accessor only.
    wave_system.wave_complete.connect(_on_wave_complete)

func _on_wave_complete(wave_number: int, performance: WavePerformance) -> void:
    if current_state != GameState.WAVE_ACTIVE:
        push_warning("wave_complete fired in unexpected state: %s" % GameState.keys()[current_state])
        return
    transition_to(GameState.WAVE_RESULTS)
    wave_ended.emit(wave_number, performance)
```

The C# signature on the Wave System side, per ADR-0003 naming conventions:

```csharp
[Signal]
public delegate void WaveCompleteEventHandler(int waveNumber, WavePerformance performance);
```

**Important boundary detail**: Godot 4.6.2 auto-translates the C# `[Signal]` delegate name from PascalCase + `EventHandler` suffix to snake_case for GDScript access. The C# delegate `WaveCompleteEventHandler` exposes:
- C#-side accessor: `EmitSignal(SignalName.WaveComplete, ...)` or the static `WaveComplete` property
- GDScript-side accessor: `wave_system.wave_complete.connect(_on_wave_complete)` (snake_case)

ADR-0003's Cross-Language Boundary Contract states this auto-translation explicitly ("surfaces to GDScript as `health_changed` (snake_case)") and its GDScript-side signal-connection example is the correct snake_case form (`health_component.health_changed.connect(...)`). The inverse rule for user-defined C# methods (PascalCase preserved across the boundary, NO auto-translation) is captured by ADR-0002's `csharp_method_snakecase_in_gdscript_call` forbidden pattern. Together the two halves codify the full boundary naming rule: signals → snake_case in GDScript; methods → PascalCase in GDScript.

Per `forbidden_patterns: unbatched_csharp_to_gdscript_signal_emission`: `wave_complete` MUST fire exactly once per wave at completion. Any per-frame or per-zombie emission is a violation that blows the marshalling budget at peak load (100+ zombies × 60fps = 6000 marshalling events/sec). Wave System's GDD must explicitly state this rule.

### Transition Validation

Transitions are validated against a transition table; invalid transitions are logged with a warning and rejected (no state change occurs). This catches state-machine bugs at runtime in dev builds before they corrupt downstream state.

```gdscript
const VALID_TRANSITIONS: Dictionary = {
    GameState.MAIN_MENU:        [GameState.CHAMPION_SELECT],
    GameState.CHAMPION_SELECT:  [GameState.RUN_LOADING, GameState.MAIN_MENU],
    GameState.RUN_LOADING:      [GameState.RUN_PREP],
    GameState.RUN_PREP:         [GameState.WAVE_ACTIVE, GameState.RUN_PAUSED, GameState.RUN_RESULTS],
    GameState.WAVE_ACTIVE:      [GameState.WAVE_RESULTS, GameState.RUN_PAUSED, GameState.RUN_RESULTS],
    GameState.WAVE_RESULTS:     [GameState.CARD_ROLL, GameState.RUN_RESULTS, GameState.RUN_PAUSED],
    GameState.CARD_ROLL:        [GameState.RUN_PREP, GameState.RUN_RESULTS, GameState.RUN_PAUSED],
    GameState.RUN_PAUSED:       [],   # exits managed by resume() — never via transition_to(); empty here is intentional
    GameState.RUN_RESULTS:      [GameState.MAIN_MENU],
}

func transition_to(next: int) -> bool:
    if next == current_state:
        return false  # no-op
    var allowed: Array = VALID_TRANSITIONS.get(current_state, [])
    if next not in allowed and not _is_pause_resume_pair(current_state, next):
        push_warning("Invalid transition: %s → %s" % [
            GameState.keys()[current_state], GameState.keys()[next]
        ])
        return false
    var prev := current_state
    state_exited.emit(prev)
    current_state = next
    state_entered.emit(next)
    state_changed.emit(prev, next)
    state_snapshot_ready.emit(_build_snapshot())
    return true
```

Pause is special-cased: `pause()` and `resume()` bypass `VALID_TRANSITIONS` because RUN_PAUSED has no fixed entry/exit set — it's reachable from any in-run state and exits to its `previous_state`.

```gdscript
var previous_state: int = -1  # -1 = "not paused"

# IMPORTANT: emission ordering mirrors resume(). All transition signals fire BEFORE
# get_tree().paused is toggled. This ensures consumer nodes (which default to
# PROCESS_MODE_INHERIT) see a consistent unpaused-tree state during their handlers,
# regardless of where in the emit chain they sit. Toggling get_tree().paused first
# would risk a consumer's deferred follow-up work landing in the wrong process state.
func pause() -> void:
    if current_state == GameState.RUN_PAUSED:
        return
    if current_state in [GameState.MAIN_MENU, GameState.CHAMPION_SELECT,
                         GameState.RUN_LOADING, GameState.RUN_RESULTS]:
        return  # pause not meaningful in these states
    previous_state = current_state
    var prev := current_state
    current_state = GameState.RUN_PAUSED
    state_exited.emit(prev)
    state_entered.emit(GameState.RUN_PAUSED)
    state_changed.emit(prev, GameState.RUN_PAUSED)
    state_snapshot_ready.emit(_build_snapshot())
    run_paused.emit()
    get_tree().paused = true                  # tree pause AFTER all emissions

func resume() -> void:
    if current_state != GameState.RUN_PAUSED:
        return
    var restore := previous_state
    previous_state = -1
    current_state = restore
    get_tree().paused = false                 # unpause BEFORE emissions; consumers wake first
    state_exited.emit(GameState.RUN_PAUSED)
    state_entered.emit(restore)
    state_changed.emit(GameState.RUN_PAUSED, restore)
    state_snapshot_ready.emit(_build_snapshot())
    run_resumed.emit()
```

### Save Snapshot Contract

Every transition (including pause/resume) emits `state_snapshot_ready` carrying a JSON-serializable Dictionary. Save/Load decides which snapshots persist; this ADR locks only the shape.

```gdscript
func _build_snapshot() -> Dictionary:
    return {
        "schema_version": 1,                  # ADR-006 owns evolution rules
        "state": current_state,               # int (GameState enum value)
        "previous_state": previous_state,     # int; -1 if not paused
        "current_wave": current_wave,         # int; 0 if not in a run
        "champion_id": String(current_champion_id),  # StringName → String for JSON
        "map_id": String(current_map_id),
        "run_seed": run_seed,                 # int; deterministic RNG seed
        "started_at_unix": run_started_at,    # int; 0 if not in a run
        "elapsed_run_seconds": _elapsed_seconds(),  # computed from run_started_at via Time.get_unix_time_from_system()
    }

# Helper: defined in the same autoload. Implemented as:
#   func _elapsed_seconds() -> float:
#       if run_started_at == 0: return 0.0
#       return Time.get_unix_time_from_system() - run_started_at
```

**Enum stability rule (load-bearing for save migration)**: New `GameState` enum values MUST be **appended** to the enum, never inserted between existing values. Inserting a new state shifts all subsequent values, silently corrupting persisted snapshots whose `state: int` field references the old positions. Any insertion (vs. append) is a schema-breaking change requiring a `schema_version` bump and a migration in ADR-006. The MVP enum has 9 values; new states should be added at index 9 onward.

ADR-006 (Save Schema) will own:
- Whether to persist this snapshot to disk (mid-wave saves vs. only PREP boundaries — likely PREP-only at MVP).
- Versioning + migration rules for `schema_version`.
- Recovery rules for corrupted snapshots.
- File format and encryption (if any).

This ADR locks the shape so ADR-006 has a concrete schema to evolve. Adding a key in a future ADR bumps `schema_version`.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       Consumer Systems (GDScript)                        │
│  HUD, Wave Summary UI, Run Results UI, Tutorial, Adaptive Music,         │
│  Card-Roll, Resource/Economy, Save/Load, Test Harness, Meta-Currency,    │
│  Leaderboard, Main Menu, Champion Select                                 │
│                                                                          │
│   • Connect to GameStateMachine signals via typed Callable (registry)    │
│   • Read-only access to GameStateMachine.current_state allowed           │
│   • MUST NOT cache current_state across frame boundaries                 │
└────────────────────────────────▲─────────────────────────────────────────┘
                                 │ signals (typed Callable, snake_case)
                                 │ + read-only state property
┌────────────────────────────────┴─────────────────────────────────────────┐
│              Autoload: GameStateMachine (GDScript)                       │
│                                                                          │
│   Owns:    current_state, previous_state, current_wave, run_seed,        │
│            current_champion_id, current_map_id, run_started_at           │
│                                                                          │
│   Emits:   state_changed, state_entered, state_exited, run_started,      │
│            run_ended, wave_started, wave_ended, card_roll_offered,       │
│            card_picked, run_paused, run_resumed, state_snapshot_ready    │
│                                                                          │
│   API:     transition_to(GameState) → bool                               │
│            pause() / resume()                                            │
│            current_state (read-only property)                            │
│                                                                          │
│   Validates against VALID_TRANSITIONS table; logs invalid attempts       │
│   process_mode = PROCESS_MODE_ALWAYS (signal handlers fire while paused) │
└────────────────────────────────▲─────────────────────────────────────────┘
                                 │ WaveComplete signal (C# → GDScript)
                                 │ typed Callable; ONCE per wave end
┌────────────────────────────────┴─────────────────────────────────────────┐
│             C# Hot-Path: Wave System (per ADR-0003)                      │
│                                                                          │
│   • Inner loop batches zombie spawning                                   │
│   • [Signal] WaveCompleteEventHandler emits ONCE at wave end             │
│   • NEVER emits per-zombie or per-frame (forbidden_pattern)              │
└──────────────────────────────────────────────────────────────────────────┘
```

### Key Interfaces

- **`GameStateMachine.current_state: int`** — read-only `GameState` enum value. Consumers may read; only `transition_to()`, `pause()`, `resume()` write.
- **`GameStateMachine.transition_to(next: int) -> bool`** — public transition method. Returns `true` on success, `false` on invalid transition (validated against `VALID_TRANSITIONS`).
- **`GameStateMachine.pause() -> void` / `resume() -> void`** — special-cased pause API; remembers `previous_state`; toggles `get_tree().paused`.
- **`signal state_changed(from: int, to: int)`** — primary transition signal; every consumer connects to this OR a convenience signal.
- **`signal state_snapshot_ready(snapshot: Dictionary)`** — Save/Load contract; fires every transition.
- **Convenience signals** — `run_started(champion_id, map_id, seed)`, `run_ended(outcome)`, `wave_started(wave_number)`, `wave_ended(wave_number, performance)`, `card_roll_offered(cards)`, `card_picked(card)`, `run_paused`, `run_resumed`.
- **`enum RunOutcome { VICTORY, DEFEAT, QUIT }`** — passed in `run_ended` signal.
- **`class_name WavePerformance extends Resource`** — `{ kills_total: int, time_seconds: float, hp_remaining_pct: float, streak_max: int }`. Produced by Wave System, passed through by Run State to Wave Summary UI.

## Alternatives Considered

### Alternative 1: Scene-tree-owned `StateManager` Node (no autoload)

- **Description**: Root scene attaches a `StateManager` child node; states are GDScript subclasses or Resource subclasses. Each consumer scene wires up `@onready var state_manager: StateManager = %StateManager`.
- **Pros**:
  - More testable in isolation — each test scene can swap a `MockStateManager`.
  - No autoload coupling; consumers reference the node explicitly.
- **Cons**:
  - Every consumer scene must wire the reference — 13 consumers × 1+ scenes each = 13+ wiring sites that can drift.
  - Test Harness (System 45) needs to instantiate `StateManager` separately per test scene — more boilerplate; loses the "drive the singleton, observe its signals" pattern.
  - Loses the canonical "where does state live?" answer that solo-dev `Grep` relies on.
  - Cross-scene transitions (e.g., MAIN_MENU scene → RUN scene) become awkward because the StateManager dies with the scene unless it's reparented.
- **Rejection Reason**: Tradeoff favors autoload for solo-dev. The "tight coupling" risk of autoload is mitigated by the constraint that consumers connect to signals (not call methods on the autoload), with read-only state queries as the only direct access permitted. The autoload survives scene changes naturally, which is exactly what state machines need.

### Alternative 2: Hierarchical State Machine (HSM)

- **Description**: Top-level: Menu | Run | Pause. Inside Run: Loading | Prep | Wave (Active|Results|CardRoll) | Results.
- **Pros**:
  - Pause-from-any-wave-substate is a free property — HSM resumes to the exact sub-state automatically.
  - Better for richer state hierarchies (e.g., scripted boss intro phases nested inside WAVE_ACTIVE).
- **Cons**:
  - More code per state (parent + child class for each state).
  - More test cases for `/design-review` (every parent × child combination must be covered).
  - More cognitive overhead for solo dev — debugging "what state are we in?" requires walking the hierarchy.
  - The pause-resume property HSM provides for free is achievable in flat enum + `previous_state` field at lower cost.
- **Rejection Reason**: Premature complexity for MVP. Flat enum + `previous_state` already gives the pause-resume property. If V1 needs nested states (e.g., scripted boss phases that must pause Wave but not show pause UI), a follow-up ADR can introduce HSM as a refinement on top of the flat enum — the upgrade path is clean because the public signal contract stays the same.

### Alternative 3: Event Bus pattern (separate event-bus autoload)

- **Description**: A central `EventBus` autoload aggregates events from all publishers; consumers subscribe to topics. Run State publishes "state_changed" to EventBus; consumers receive it via EventBus subscription.
- **Pros**:
  - Maximum decoupling — Run State doesn't know its consumers exist.
  - Pattern scales well to multi-publisher event aggregation.
- **Cons**:
  - One extra hop per event (Run State → EventBus → consumer); tiny but real.
  - State ownership becomes ambiguous — *"who owns the current state?"* answer is harder to find via grep.
  - EventBus topics are typically string-keyed (loses typed signal benefit unless rebuilt with typed signal proxies).
  - Adds an autoload AND removes the typed signal IDE autocomplete affordance.
- **Rejection Reason**: Decoupling is over-engineered for this topology. There are 13 consumers and exactly **one** publisher (Run State itself). EventBus pays off when there are 5+ publishers with overlapping consumers — that's not this project. Direct autoload signals give every consumer typed signatures and full IDE autocomplete with zero indirection.

### Alternative 4: Boolean overlay flag for pause (`is_paused: bool`)

- **Description**: Pause is a boolean flag layered on top of `current_state`, not a separate state. State stays as `WAVE_ACTIVE` during pause; consumers check both `current_state == WAVE_ACTIVE && !is_paused`.
- **Pros**: Simpler enum; one fewer state.
- **Cons**: Every consumer must check both `current_state` AND `is_paused` — easy to miss a check, leading to audio/AI continuing during pause. Loses the "paused is a player-visible game phase" semantics for things like adaptive music (which legitimately wants a pause-specific track or attenuation).
- **Rejection Reason**: Bug-prone for solo dev. Discrete `RUN_PAUSED` state forces the check at the consumer's signal handler — there's no way to forget to handle pause because the state itself fires the signal. Saves one rare consumer bug per month at a one-time cost of one extra enum value.

## Consequences

### Positive

- 13 consumer GDDs author against a single, written contract — no per-system state-tracking inventions; no consistency bugs from divergent local copies.
- Test Harness (System 45) drives `transition_to()` directly; deterministic state sequences in headless mode are trivial — call a sequence of `transition_to()` and observe signals.
- Save/Load (ADR-006) inherits a stable Dictionary shape; only versioning + persistence policy remain to decide there.
- Pause is robust by construction: `previous_state` field guarantees resume correctness in all cases.
- Adaptive Music (System 10) gets clean transition hooks — one signal handler per state covers all music-cue logic.
- Cross-language boundary with Wave System is reduced to **one** signal (`WaveComplete`) firing **once** per wave — well within the marshalling budget per ADR-0003.
- Transition validation table catches state-machine bugs in dev (e.g., a future story accidentally calling `transition_to(RUN_PREP)` from `MAIN_MENU` skipping CHAMPION_SELECT).

### Negative

- **One autoload** added to the project. Future ADRs proposing autoloads must justify against this precedent — healthy discipline, but a real cost-of-future-ADRs.
- **Transition table maintenance**: `VALID_TRANSITIONS` must be updated whenever a state is added (e.g., V1 might add `INTERMISSION_CINEMATIC` between waves). Mitigated by the table being a single 10-line Dictionary in one file.
- **Snapshot fires on every transition** — minor allocation pressure (one Dictionary per transition). At MVP transition rate (~1 per few seconds during a run), this is ~10 transitions/min × 200 bytes ≈ 2 KB/min, negligible. If profiling shows it matters in V1, switch to a pooled Dictionary or reduce snapshot frequency in a follow-up ADR.
- **Convenience signals duplicate state_changed**: emitting `wave_started` alongside `state_changed` is intentional duplication — costs ~1 signal emission per transition, gains every consumer's ergonomics.
- **Pause API is two methods (`pause()` / `resume()`) outside the `transition_to()` flow** — slight API surface inconsistency. Documented in the Decision section's pause subsection.

### Risks

1. **Risk: Autoload load order conflicts with consumer autoloads (e.g., AudioBus, SaveManager).**
   - **Mitigation**: `GameStateMachine._ready()` does no work that requires another autoload to exist — it sets initial state to `MAIN_MENU` and uses `call_deferred("_connect_wave_system")` so the WaveSystem autoload can register first regardless of order. Consumer autoloads connect to GameStateMachine signals lazily on their own `_ready()`. Document the load order rule in the Migration Plan.

2. **Risk: A consumer caches `current_state` in a local variable and acts on stale data.**
   - **Mitigation**: Coding standard already discourages this (gameplay values must be data-driven; see `.claude/docs/coding-standards.md`). Add an explicit rule to the control manifest: *"Never cache `GameStateMachine.current_state` across frame boundaries; always read or subscribe to `state_changed`."* The control manifest will be authored by `/create-control-manifest` after architecture is locked.

3. **Risk: Wave System's C# `WaveComplete` signal name drifts from the GDScript Callable name during refactor.**
   - **Mitigation**: ADR-0003 already specifies `[Signal] public delegate void WaveCompleteEventHandler(...)`. Wave System (System 18) story acceptance criteria will name this signal explicitly. The forbidden_pattern `string_based_signal_connection` ensures rename failures show up at compile time, not runtime — the typed Callable form `wave_system.wave_complete.connect(_on_wave_complete)` (note GDScript-side snake_case auto-translation) breaks at runtime if the C# delegate is renamed without updating the GDScript side. Wave System's GDD acceptance criteria will lock both sides of the name.

4. **Risk: Transition validation rejects a legitimate transition the design didn't anticipate (e.g., emergency quit-to-menu mid-wave).**
   - **Mitigation**: Quit-to-menu is currently modeled as `RUN_RESULTS` (with `outcome=QUIT`). If a future story needs a direct `WAVE_ACTIVE → MAIN_MENU` shortcut, it requires extending `VALID_TRANSITIONS` here — change managed via `/propagate-design-change`. The validation rejects-with-warning behavior (rather than asserting) keeps dev builds running while the issue is investigated.

5. **Risk: `process_mode = PROCESS_MODE_ALWAYS` interaction with `get_tree().paused = true` is subtler than expected.**
   - **Mitigation**: Verification step in Migration Plan §1 — write a 30-line test scene that pauses the tree, fires a signal from a non-paused source, and confirms the autoload's handler runs. Documented Godot 4.x behavior, but worth a 5-minute sanity check on the dev machine before authoring System 13 (Damage & Health), which assumes signal flow continues during pause for the death-screen overlay.

6. **Risk: Pause/resume signal emission ordering relative to `get_tree().paused` toggle.**
   - **Concern**: If `get_tree().paused = true` is set *before* transition signals are emitted, consumer nodes with default `PROCESS_MODE_INHERIT` are paused at the moment their handlers run. Their handlers still fire (signals are direct calls, not pause-gated), but any deferred follow-up work (`call_deferred`, `await get_tree().process_frame`, `Tween` creation) lands in a paused tree and may stall or behave unexpectedly.
   - **Mitigation**: `pause()` emits all transition signals **before** setting `get_tree().paused = true`; `resume()` clears `get_tree().paused = false` **before** emitting transition signals. This consistent "consumers always handle in unpaused-tree state" rule is documented in code comments on the implementation. Unit test (Logic story type) asserts that a `Tween` created inside a `state_changed` handler during pause completes after resume.

7. **Risk: WaveSystem autoload not registered or registered after GameStateMachine's `_connect_wave_system()` runs.**
   - **Mitigation**: `_connect_wave_system()` uses `get_node_or_null("/root/WaveSystem")` and `assert(wave_system != null, ...)`. `call_deferred` ensures the call happens after all autoload `_ready()` calls in the current frame. If the assertion fails in dev, the error message points to Project Settings autoload order. If WaveSystem is ever moved from autoload to scene-node (a future refactor), the timing guarantee breaks silently — the assertion catches the symptom; this ADR's Validation Criteria explicitly require WaveSystem to remain an autoload.

8. **Risk: GameState enum value drift breaking persisted snapshots.**
   - **Concern**: GDScript anonymous enums assign values by declaration order. Inserting a new state between existing values shifts all subsequent ints, silently corrupting saved snapshots that contain old `state: int` references.
   - **Mitigation**: Enum stability rule documented in the Save Snapshot Contract section (states must be **appended**, never inserted; insertion requires `schema_version` bump and migration in ADR-006). Migration Plan §2 unit test asserts that `GameState.MAIN_MENU == 0`, `GameState.CHAMPION_SELECT == 1`, ..., `GameState.RUN_RESULTS == 8` — a regression test that catches insertion at PR review time.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| Run State (8) | "State machine sequencing run phases" (systems-index Layer 0); bottleneck flagged in High-Risk Systems | Defines the 9-state flat enum, validated transition table, signal contract, and snapshot contract. Locks the contract before any consumer GDD is authored. |
| Wave & Spawn (18) | "Run State drives the state machine; Wave System emits 'wave complete' events" (systems-index Pattern 1) | Wave System's C# `WaveComplete` signal connects into GameStateMachine via typed Callable. Transition `WAVE_ACTIVE → WAVE_RESULTS` resolves the event-based coupling. Marshalling rule: ONCE per wave. |
| Card-Roll (22) | Concept: "30s loot/card-roll" between waves; "next card roll always gets slightly better if you survive clean" | Dedicated `CARD_ROLL` state distinct from `WAVE_RESULTS`. `card_roll_offered(cards)` and `card_picked(card)` signals carry the choice; transition `CARD_ROLL → RUN_PREP` advances. |
| HUD (29) | "depends on: Damage & Health, Ability, Resource / Economy, Streak, Run State" | HUD subscribes to `state_changed` to swap between menu HUD, prep HUD, combat HUD, results HUD, paused overlay. One signal handler per state covers the swap. |
| Save / Load (2) | Concept: "Concept warns: corrupted saves kill retention"; ADR-006 will own schema rules | `state_snapshot_ready` Dictionary is the stable contract Save/Load consumes. ADR-006 owns evolution + persistence + corruption recovery. |
| Adaptive Music (10) | "depends on: Audio Bus, Run State" | Music system subscribes to `state_changed` to swap tracks (menu → prep → combat → card-roll decision cue → boss → results). The CARD_ROLL/WAVE_RESULTS split gives the "decision cue" hook concept implies via the loot/card-roll separation. |
| Run Results / Death UI (34) | "depends on: Run State, Meta-Currency" | Triggered by `run_ended(outcome)` signal; reads final snapshot for display (champion played, waves survived, kills, time). |
| Wave Summary UI (32) | "depends on: Wave, Run State" | Triggered by `wave_ended(wave_number, performance)` signal carrying the `WavePerformance` resource produced by Wave System. |
| Main Menu & Champion Select (33) | "depends on: Champion, Meta-Progression, Run State" | Driven by `MAIN_MENU` and `CHAMPION_SELECT` states; `CHAMPION_SELECT → RUN_LOADING` transition fires `run_started(champion_id, map_id, seed)` carrying the selection. |
| Tutorial / Onboarding (36) | Concept: "MVP uses a dev tutorial prompt overlay only" | Tutorial subscribes to `state_entered` and shows context-appropriate prompts on first entry into each state. Light, additive, no per-state code in tutorial. |
| Meta-Currency (37) | "depends on: Save / Load, Run State" | Awards meta-currency on `run_ended(outcome)` regardless of outcome (concept: "Death always grants partial meta-currency"). |
| Leaderboard (41) | "depends on: Save / Load, Run State" | Records run on `run_ended(outcome=VICTORY)` (and optionally other outcomes per V1 design). |
| Test Harness (45) | "Headless run runner + deterministic RNG + fixture loader" (systems-index Layer 1) | Test code calls `GameStateMachine.transition_to()` directly to drive deterministic state sequences in `--headless` mode. `run_seed` is set on `run_started` and is part of the snapshot for replay determinism. |

## Performance Implications

- **CPU**: Negligible. State transitions occur ~1× per few seconds during a run. Signal emission is ~µs per signal (Godot benchmarks). Snapshot Dictionary allocation is ~1µs per transition. Far below the 16.6ms frame budget; far below the 0.1ms-per-system informal soft budget.
- **Memory**: Dictionary snapshot is ~200 bytes per transition; transient (not retained — Save/Load decides what to persist). GDScript reference counting reclaims unreferenced snapshots immediately. Net steady-state overhead: <1KB.
- **Load Time**: Autoload `_ready()` is ~1ms cold start (sets initial state, no I/O, defers Wave System connection). Negligible vs. .NET assembly load (~100–300ms per ADR-0003).
- **Network**: N/A (single-player V1 per concept).

## Migration Plan

This ADR is foundational; no existing code to migrate. Application order:

1. **Pre-implementation verification** (30-minute budget):
   - Confirm autoload `_ready()` runs before any scene-level `_ready()` on dev machine.
   - Confirm autoload `process_mode = PROCESS_MODE_ALWAYS` keeps signal handlers firing while `get_tree().paused = true`.
   - Confirm typed Callable connection (`signal.connect(callable)`) compiles and works in Godot 4.6.2.
   - Confirm enum-as-int serialization to JSON via `JSON.stringify()` round-trips correctly.
2. **First implementation story** (Logic story type per coding standards):
   - Implement `GameStateMachine` autoload with the 9-state enum, `transition_to()`, validation table, `pause()` / `resume()`, and primary signals (`state_changed`, `state_entered`, `state_exited`).
   - Unit tests in `tests/unit/core/run_state_test.gd` covering: every valid transition succeeds; every invalid transition is rejected with warning; pause-resume preserves state from each in-run state; snapshot Dictionary contains all required keys.
3. **Second implementation story**:
   - Add convenience signals (`run_started`, `run_ended`, `wave_started`, `wave_ended`, `card_roll_offered`, `card_picked`, `run_paused`, `run_resumed`).
   - Add `state_snapshot_ready` and `_build_snapshot()`.
   - Unit tests covering: convenience signals fire alongside `state_changed`; snapshot contents stable across transitions.
4. **Third implementation story (after Wave System ADR-002 is Accepted)**:
   - Wire `WaveComplete` (C#) → `_on_wave_complete` (GDScript) connection in `_connect_wave_system()`.
   - Integration test (Integration story type) covering Wave→RunState handoff in headless mode.
5. **Subsequent consumer GDDs**: Each consumer GDD's first implementation story connects to the relevant signals. No consumer story can begin until this ADR is Accepted.
6. **Control manifest update**: When `/create-control-manifest` runs (after architecture phase), add the rule *"Never cache `GameStateMachine.current_state` across frame boundaries"* to the GDScript section.

## Validation Criteria

This ADR is correct if all of the following hold by end of MVP:

- All 13 consumer systems consume at least one `GameStateMachine` signal (no consumer reinvents state-tracking).
- No story logs a "state desync" bug (HUD showing wrong phase, music playing wrong track during card-roll, etc.).
- Pause-resume preserves state across at least 100 dev playtest sessions without exception (asserted in playtest log).
- `transition_to()` rejects at least one invalid transition during dev (proves validation is doing work, not dead code).
- Test Harness drives at least 50 deterministic state sequences in headless mode without `GameStateMachine` modification.
- Cross-language `wave_complete` signal (C# `WaveCompleteEventHandler` → GDScript snake_case) fires exactly once per wave end (asserted in Wave System integration test).
- WaveSystem remains an autoload throughout MVP (asserted by `_connect_wave_system()` runtime guard); any move to scene-node requires a superseding ADR.
- `GameState` enum integer values are stable across builds (regression test asserts `GameState.MAIN_MENU == 0` through `GameState.RUN_RESULTS == 8`).

This ADR is incorrect (warrants a superseding ADR) if any of:

- A second autoload is needed to coordinate run state (would mean state ownership is split — design failure).
- The flat enum can't represent a phase the design later requires (e.g., a scripted boss intro that must pause Wave but not show pause UI) — would push toward HSM as a follow-up ADR.
- The snapshot Dictionary shape changes more than twice during MVP — would mean ADR-006 should have owned the shape from the start, and this ADR over-reached.
- The marshalling cost of the Wave→RunState signal alone (one event per wave) is measurable — would invalidate the ADR-0003 boundary contract, not this ADR specifically, but would force a reconsideration here too.

## Related Decisions

- **ADR-0003 (Language Routing Policy — Proposed)** — Run State is GDScript orchestration; Wave System's C# `WaveComplete` signal connects via typed Callable per ADR-0003 boundary contract.
- **ADR-006 (Save Schema & Versioning — pending)** — owns persistence policy + evolution rules for the snapshot Dictionary defined here.
- **ADR-007 (Effect Composition Taxonomy — inside Build/Modifier GDD, pending)** — orthogonal; card effects don't depend on Run State.
- `design/gdd/systems-index.md` — Run State (System 8) row, Pattern 1 in Circular Dependencies section, High-Risk Systems table entry.
- `design/gdd/game-concept.md` — Core Loop section (the source of the 9-state enum derivation).
- `.claude/docs/technical-preferences.md` — naming conventions for GDScript signals (snake_case past tense), GameStateMachine to use these.
- `docs/registry/architecture.yaml` — registry entries this ADR will add: state ownership of `current_state`, interface contract for `state_changed` and `state_snapshot_ready` signals, no new forbidden patterns.
