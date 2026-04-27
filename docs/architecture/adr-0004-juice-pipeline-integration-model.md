# ADR-0004: Juice Pipeline Integration Model

## Status
Proposed

## Date
2026-04-27

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Animation + Audio + Rendering (cross-cutting) — Tween, AudioStreamPlayer pooling, GPUParticles2D pooling, camera shake, `Engine.time_scale`, `process_mode` |
| **Knowledge Risk** | LOW — Tween API stable since 4.0 (with `set_ignore_time_scale` long-available); AudioStreamPlayer no breaking changes 4.4–4.6; GPUParticles2D stable (one 4.4 change: `restart()` gained `keep_seed` param). AnimationMixer base class change (4.3) does not touch hit-stop or juice paths. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/animation.md`; `docs/engine-reference/godot/modules/audio.md`; `docs/engine-reference/godot/breaking-changes.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `GPUParticles2D.restart(keep_seed=false)` parameter (added 4.4) — used in pool reuse. All other APIs (Tween, `Engine.time_scale`, `ProcessMode`, `AudioStreamPlayer`, `AudioServer`, `GPUParticles2D`, `Camera2D`) predate the LLM cutoff. |
| **Verification Required** | (1) Confirm `Tween.set_ignore_time_scale(true)` in 4.6.2 actually decouples a Tween from `Engine.time_scale` slow-mo (regression test). (2) Confirm `GPUParticles2D.restart(keep_seed=false)` produces visually varied splatter per pool reuse. (3) Confirm `get_tree().create_timer(duration, true, false, true)` ignore-time-scale flag works as documented in 4.6.2. (4) Confirm `HitEvent : RefCounted` argument marshals correctly across the C# → GDScript signal boundary when the C# assembly is built before scene load. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Run State / Game Flow — pause integration); ADR-0003 (Language Routing Policy — C# signal subscription rules and cross-language boundary contract) |
| **Enables** | GDD #9 (Juice / Feedback Pipeline); GDD #13 (Damage & Health) signal contract; GDD #35 (Damage Number / Kill Feedback) — all share the `damage_dealt` signal payload |
| **Blocks** | GDD #9 cannot be authored until this ADR is Accepted; GDD #13's signal-emission contract section depends on this; GDD #35 depends on the `HitEvent` payload locked here |
| **Ordering Note** | Author and Accept BEFORE GDD #9 and BEFORE GDD #13's signal contract section is locked. Can be authored in parallel with ADR-0006 (Save Schema) since Juice owns no persisted state. |

## Context

### Problem Statement

The Juice / Feedback Pipeline (System 9) must deliver **Pillar 2 — "Satisfying Kills, Always"** by orchestrating hit-stop, screen-shake, particles, and layered SFX on every damage event in the game. The game-concept document explicitly warned: *"If built per-weapon, becomes unmaintainable."* With 4 Champions × ~20 weapon/ability variants × 5+ zombie types × multiple event types (hit, crit, kill, boss-hit), a per-call-site implementation produces hundreds of drifting copies. The architecture for this system must therefore decide:

1. Where dispatch lives (centralized vs distributed) and how it is invoked.
2. How per-weapon / per-ability juice characteristics are authored (data vs code).
3. How hit-stop is implemented (global slow-mo vs per-actor freeze vs hybrid).
4. The signal contract from Damage & Health (System 13) that Juice subscribes to.
5. Pause-model integration with Run State (ADR-0001).
6. Performance budget at 100+ simultaneous hit events on screen.

This decision must lock before GDD #9 (Juice) and before GDD #13's signal-emission contract section, because both consume this contract.

### Constraints

- **Engine**: Godot 4.6.2; physics is Jolt (default in 4.6); rendering is Forward+ on Windows.
- **Concept warning**: Per-weapon Juice code is forbidden — must be reusable.
- **Cross-language boundary**: Damage & Health is C# hot-path; Juice is GDScript orchestration. Per ADR-0003 `cross_language_boundary` registry contract, Juice subscribes to C# signals via the snake_case auto-translated name; user-defined C# properties are accessed at their declared PascalCase name (registry forbidden pattern: `csharp_method_snakecase_in_gdscript_call`).
- **Signal-flood ban**: `unbatched_csharp_to_gdscript_signal_emission` is forbidden (>50 emissions/frame). Damage & Health emits ONE consolidated signal per damage event, not per frame.
- **Pause-model**: ADR-0001's `pause_implementation` API decision rules. Juice's hit-stop must not conflict with `RUN_PAUSED` state.
- **Performance**: 60 fps target; 16.6 ms total frame budget; 100+ zombies on screen target (per Crowd Pathfinding ADR-0002); peak load is ~10–20 hits/second across all lanes during normal play.
- **Solo first-time dev**: Must be designer-tunable without code changes.

### Requirements

- Must support Pillar 2 ("Satisfying Kills, Always") at 100+ simultaneous on-screen zombies, including off-screen kills which must remain audibly satisfying.
- Must consolidate per-weapon / per-ability variation into ONE code path with data-driven recipes.
- Must integrate with the C#-emitted Damage & Health signal without violating `unbatched_csharp_to_gdscript_signal_emission` and without `HitEvent` argument silently downgrading to bare `RefCounted` at runtime.
- Must respect `RUN_PAUSED` — in-flight hit-stop and shake must halt cleanly on pause and resume cleanly.
- Must pool all instantiated artifacts (particle emitters, AudioStreamPlayers, damage-number Labels) — the Performance Watchlist explicitly mandates this.
- Must allow simultaneous per-actor hit-stops without one's freeze cancelling another's.
- Must keep UI, music, and pause-mode-ALWAYS systems running at wall-clock speed during global hit-stop (slow-mo applies to world only, not interface).
- Must produce ≤ 0.5 ms/frame of CPU work in Juice's own dispatch + tween-update path at peak load (excludes particle GPU cost and SFX synthesis cost — those are owned by VFX and Audio Bus systems' own budgets).

## Decision

### Chosen approach

A **centralized `Juice` autoload** (GDScript) subscribes to a single batched signal from Damage & Health (C#). The Juice autoload reads a `JuiceProfile.tres` Resource per damage event and dispatches the recipe across Camera, VFX, and Audio. Hit-stop is **hybrid** — per-actor `process_mode = PROCESS_MODE_DISABLED` for normal hits; global `Engine.time_scale = 0.05` slow-mo for kills, crits, and boss-hits. Per-weapon / per-ability variation is authored entirely in `.tres` data files, never in code. Hit-impact SFX is **non-positional** `AudioStreamPlayer` on the `SFX` bus to satisfy Pillar 2 ("Satisfying Kills, *Always*" — off-screen kills must remain audible at full SFX-bus level).

### Architecture Diagram

```
┌─────────────────────┐        damage_dealt(hit_event: HitEvent)
│ Damage & Health     │────────────────────────────────────────┐
│ (C# hot-path)       │  signal, batched (≤50/frame; one per   │
└─────────────────────┘  resolved damage event)                │
                                                                ▼
                                                  ┌─────────────────────────┐
                                                  │   Juice (autoload,      │
                                                  │   GDScript)             │
                                                  │                         │
                                                  │ assert(hit_event is     │
                                                  │   HitEvent, ...)        │
                                                  │ profile = JuiceLibrary  │
                                                  │   .get_profile(...)     │
                                                  │ _run_recipe(...)        │
                                                  └────────────┬────────────┘
                              ┌─────────────────────┬──────────┴──────┬─────────────────────┐
                              ▼                     ▼                 ▼                     ▼
                      ┌──────────────┐    ┌───────────────────┐  ┌──────────────┐   ┌──────────────────┐
                      │ Camera       │    │ VFX / Particles   │  │ Audio Bus    │   │ Hit-stop branch  │
                      │ (shake hook) │    │ (pooled GPU       │  │ (pooled non- │   │                  │
                      │ shake-recov  │    │  Particles2D,     │  │ positional   │   │ is_kill || crit  │
                      │ Tween uses   │    │  restart with     │  │ AudioStream- │   │ || is_boss       │
                      │ ignore_time_ │    │  keep_seed=false) │  │ Player; pool │   │  → GLOBAL slow-  │
                      │ scale=true   │    │                   │  │ size 16)     │   │    mo (Engine.   │
                      └──────────────┘    └───────────────────┘  └──────────────┘   │    time_scale)   │
                                                                                     │ else             │
                                                                                     │  → PER_ACTOR     │
                                                                                     │    process_mode= │
                                                                                     │    DISABLED via  │
                                                                                     │    real-time     │
                                                                                     │    SceneTreeTimer│
                                                                                     │                  │
                                                                                     │ Mutex: skip      │
                                                                                     │ per-actor if     │
                                                                                     │ global active    │
                                                                                     └──────────────────┘
```

### Key Interfaces

#### 1. Damage & Health → Juice signal contract

C# producer:

```csharp
// res://src/damage_health/damage_system.cs
public partial class DamageSystem : Node
{
    [Signal]
    public delegate void DamageDealtEventHandler(HitEvent hitEvent);

    // Emitted ONCE per resolved damage event (not per-frame health update).
    // Batching guarantee: per-frame health-recompute on the same target does
    // NOT re-emit; only discrete damage applications emit. Expected upper
    // bound: ≤50 emissions/frame at peak (compliant with registry forbidden
    // pattern: unbatched_csharp_to_gdscript_signal_emission).
}

public partial class HitEvent : RefCounted
{
    public Node2D Target { get; set; }
    public float Amount { get; set; }
    public bool IsKill { get; set; }
    public bool IsCrit { get; set; }
    public bool IsBoss { get; set; }
    public StringName ProfileId { get; set; }
    public Vector2 ImpactPosition { get; set; }
    public Vector2 ImpactDirection { get; set; }
}
```

GDScript-side connection (snake_case signal name; **PascalCase property names**):

```gdscript
# res://autoload/juice.gd — in _ready():
DamageSystem.damage_dealt.connect(_on_damage_dealt)

func _on_damage_dealt(hit_event: HitEvent) -> void:
    # Guard against silent C#-assembly-not-loaded downgrade.
    # If the assembly was not built before scene load, hit_event arrives as
    # bare RefCounted with no properties — every property read returns null.
    assert(hit_event is HitEvent, "HitEvent marshalling failed — verify C# assembly is built before scene load (see Migration Plan §1)")

    # PascalCase property access — required because Godot 4.6.2 auto-translates
    # only [Signal] delegate names, not user-defined C# property names.
    # Registry forbidden_pattern: csharp_method_snakecase_in_gdscript_call.
    var profile := JuiceLibrary.get_profile(hit_event.ProfileId)
    _run_recipe(profile, hit_event)
```

**Critical naming rules** (cross-references to registry forbidden patterns):

- Signal: `damage_dealt` (snake_case). Never `DamageDealt` from GDScript — see `csharp_signal_pascalcase_in_gdscript_connect`.
- Properties: `hit_event.Amount`, `hit_event.IsCrit`, `hit_event.ProfileId` (PascalCase). Never `hit_event.amount` from GDScript — see `csharp_method_snakecase_in_gdscript_call`.
- Connection form: typed Callable (`damage_dealt.connect(_on_damage_dealt)`). Never string-based — see `string_based_signal_connection`.

#### 2. JuiceProfile resource

```gdscript
# res://src/juice/juice_profile.gd
class_name JuiceProfile
extends Resource

# Hit-stop
@export var hit_stop_duration_ms: float = 50.0  # 0.0 = no hit-stop
@export var hit_stop_scope: HitStopScope = HitStopScope.PER_ACTOR

# Camera shake
@export var shake_amplitude: float = 0.0  # pixels
@export var shake_duration_ms: float = 0.0
@export var shake_frequency: float = 30.0  # Hz

# Particles (pooled GPUParticles2D)
@export var hit_particle: PackedScene = null   # null = no particles
@export var kill_particle: PackedScene = null  # null = use hit_particle on kill

# Audio (pooled non-positional AudioStreamPlayer on SFX bus)
@export var hit_sfx: AudioStream = null
@export var crit_sfx: AudioStream = null   # null = use hit_sfx with +6 dB
@export var kill_sfx: AudioStream = null   # null = use hit_sfx
@export var sfx_pitch_jitter: float = 0.05  # ±5% pitch randomization per shot

enum HitStopScope { NONE, PER_ACTOR, GLOBAL }
```

**Default scope rules** (when `hit_stop_scope` is left at PER_ACTOR — the default):

- Normal hit → `PER_ACTOR` with `hit_stop_duration_ms` as authored.
- `IsCrit == true` OR `IsKill == true` (non-boss target) → `PER_ACTOR` with extended duration (~80 ms).
- `IsBoss == true` AND (`IsKill == true` OR `IsCrit == true`) → `GLOBAL`.

Profile authors can override per weapon/ability — when `hit_stop_scope` is set explicitly to `GLOBAL` or `NONE`, the profile's choice wins regardless of event flags.

**Resource duplication note** (per `deprecated-apis.md` 4.5 advisory): if pool initialization needs per-instance copies of nested Resources (e.g., a `JuiceProfile` containing a unique `AudioStream` per pool slot), use `duplicate_deep()` rather than `duplicate()`. For shared read-only Resources, no duplication is needed — the pool indexes the original resource by `ProfileId`.

#### 3. Juice autoload public API

```gdscript
# res://autoload/juice.gd
extends Node
# AutoLoad name: "Juice"
# process_mode = PROCESS_MODE_PAUSABLE (default — pauses with the tree on RUN_PAUSED)

# Damage-driven juice (preferred path) goes through the signal subscription.
# These public methods exist for non-damage events that still need Juice
# (UI button confirms, ability cast feedback before damage resolves).
func play_profile(profile_id: StringName, world_position: Vector2) -> void
func freeze_actor(actor: Node2D, duration_ms: float) -> void
func global_hit_stop(duration_ms: float, slowmo_factor: float = 0.05) -> void
```

#### 4. Tween rules during hit-stop (mandatory)

`Engine.time_scale = 0.05` during global hit-stop slows EVERY active Tween by default in Godot 4.6.2. This is a silent design failure if not explicitly handled — UI fades, damage-number fly-ups, and music cross-fades would all turn into 5%-speed molasses for ~80 ms on every kill, reading as a frame-rate stutter instead of juice.

**Rule (mandatory, enforced at code review)**:

| Tween category | `set_ignore_time_scale(true)` required? | Examples |
|----------------|-----------------------------------------|----------|
| **UI / HUD / interface** | YES | Damage-number fly-ups, HUD fades, card-roll UI transitions, screen-shake recovery lerp |
| **Cross-system real-time** | YES | Audio cross-fades, music transitions |
| **World-space actor** | NO (intentionally slowed) | Enemy hit-flash tint, weapon recoil interpolation, projectile ease-out |

```gdscript
# Correct — UI tween that must run at wall-clock speed:
var tween := create_tween()
tween.set_ignore_time_scale(true)
tween.tween_property(damage_number, "position:y", target_y, 0.6)

# Correct — world tween that participates in slow-mo:
var hit_flash := create_tween()  # ignore_time_scale defaults to false
hit_flash.tween_property(zombie, "modulate", Color.WHITE, 0.05)
```

#### 5. Per-actor hit-stop implementation

```gdscript
func _freeze_actor(actor: Node2D, duration_ms: float) -> void:
    if _global_hit_stop_active:
        return  # Mutex: global supersedes per-actor (see Risks)
    actor.process_mode = Node.PROCESS_MODE_DISABLED
    # Real-time timer (4th arg = ignore_time_scale=true) so the restore is not
    # affected by a global hit-stop firing on a subsequent frame.
    var t := get_tree().create_timer(duration_ms / 1000.0, true, false, true)
    t.timeout.connect(func() -> void:
        if is_instance_valid(actor):
            actor.process_mode = Node.PROCESS_MODE_INHERIT
    )
```

Note: `process_mode = PROCESS_MODE_DISABLED` freezes the actor's `_process`, `_physics_process`, and child `AnimationPlayer` (via inheritance). `GPUParticles2D` children of a frozen actor keep emitting — explicitly accepted for MVP (the visual reads as "frozen body, particles still flying"). Jolt physics (4.6 default) integrates the disabled body as inactive at the next physics tick — safe.

#### 6. Global hit-stop implementation

```gdscript
func _global_hit_stop(duration_ms: float, slowmo_factor: float = 0.05) -> void:
    _global_hit_stop_active = true
    Engine.time_scale = slowmo_factor
    var t := get_tree().create_timer(duration_ms / 1000.0, true, false, true)  # ignore_time_scale
    await t.timeout
    Engine.time_scale = 1.0
    _global_hit_stop_active = false
```

Mutex flag `_global_hit_stop_active` prevents per-actor freezes from being scheduled while a global hit-stop is active (see Risks: "Global hit-stop + per-actor hit-stop interaction").

#### 7. Pause integration

```gdscript
func _on_state_changed(from: int, to: int) -> void:
    if to == GameState.RUN_PAUSED:
        _abort_active_hit_stop()
    # On resume, no action needed — paused-tree Tweens auto-resume; per-actor
    # frozen actors stay frozen (the SceneTreeTimer was created with
    # ignore_time_scale=true but pauses with the tree at PAUSABLE process_mode).

func _abort_active_hit_stop() -> void:
    if _global_hit_stop_active:
        Engine.time_scale = 1.0
        _global_hit_stop_active = false
    for actor in _frozen_actors:
        if is_instance_valid(actor):
            actor.process_mode = Node.PROCESS_MODE_INHERIT
    _frozen_actors.clear()
```

UI and Audio Bus systems must set their own `process_mode = PROCESS_MODE_ALWAYS` independently — that is their concern, not Juice's. Documented in GDD #29 (HUD) and System 3 (Audio Bus).

### Pooling rules (mandatory)

- **Particle emitters**: pre-instantiated pool of `GPUParticles2D` per `JuiceProfile.hit_particle` scene, sized to ~50 emitters per profile (covers peak ~10–15 simultaneous on-screen). Pool eviction = oldest-first when exhausted. Reuse via `restart(keep_seed=false)` (4.4 API) so each splatter pattern looks visually different.
- **AudioStreamPlayers (non-positional)**: shared pool of 16 `AudioStreamPlayer` nodes on bus `SFX`. Lookup by `not playing` (per `audio.md` engine-reference pattern). Pool exhaustion = drop the new SFX silently — never queue (queueing produces audible stutter).
- **Damage-number Labels**: deferred to GDD #35 (owns Damage Number / Kill Feedback). This ADR locks the signal contract; that GDD owns the pooled-`Label` or `MultiMeshInstance2D` choice.

## Alternatives Considered

### Alternative A: Distributed call-sites — every weapon/ability calls `Juice.hit(profile)` directly
- **Description**: Each weapon and ability script invokes `Juice.play_profile(...)` after applying damage. No signal subscription.
- **Pros**: Simple to follow on a single weapon's code path; no contract negotiation between Damage & Health and Juice.
- **Cons**: Duplicates the call site. Every new weapon must remember to invoke Juice. Easy to forget on edge paths (DoT ticks, environmental damage, ability splash). Adds cross-system call coupling.
- **Rejection Reason**: Re-creates the per-weapon coupling the concept warned against. The whole point of an ADR for Juice is to centralize dispatch — distributed call-sites defeat the purpose.

### Alternative B: EventBus autoload aggregating multiple publishers
- **Description**: A separate `EventBus` autoload aggregates damage events (and others — pickups, ability casts, deaths). Juice subscribes to EventBus, not directly to Damage & Health.
- **Pros**: Decouples publishers from subscribers; new event types can be added without touching consumers.
- **Cons**: ADR-0001's `state_machine_pattern` decision explicitly rejects EventBus aggregation: *"central EventBus autoload aggregating multiple publishers ... over-engineered for this topology and would slow solo-dev iteration."* The same logic applies — exactly one publisher (Damage & Health) for damage Juice; an EventBus middleman doubles the wiring for no gain.
- **Rejection Reason**: Conflicts with the established `state_machine_pattern` precedent (registry api_decisions). Direct subscription to the Damage & Health autoload is the established pattern.

### Alternative C: Pure-global hit-stop via `Engine.time_scale` for every hit
- **Description**: Every hit triggers `Engine.time_scale = 0.05` for ~50–80 ms. Simpler — one mechanism for all hit-stop.
- **Pros**: One implementation; no branching logic; no per-actor freeze tracking.
- **Cons**: Music, UI, and any `process_mode = ALWAYS` system must be carefully set up to NOT slow with `Engine.time_scale` — easy to forget on a new UI screen. Worse: at peak (100+ zombies, ~10–15 hits/second), the screen is constantly slow-mo, which the player perceives as a stuttering frame rate, not as juice.
- **Rejection Reason**: Polish ceiling is too low. AAA references (Hades, Hyper Light Drifter) all use hybrid for this exact reason.

### Alternative D: Pure per-actor hit-stop via `process_mode = DISABLED`
- **Description**: Every hit freezes the hit actor only. World never slows.
- **Pros**: No global pause concerns; UI and music unaffected; multiple simultaneous hits stack independently.
- **Cons**: Loses "the moment" on kills, crits, and boss-hits. The game becomes mechanically responsive but emotionally flat at peak beats — the boss-kill moment doesn't read as different from a grunt-kill.
- **Rejection Reason**: Pillar 2 ("Satisfying Kills, ALWAYS") implies the moment must read at multiple intensities. Pure per-actor caps the ceiling.

### Alternative E: Hardcoded constants in Juice autoload (no Resources)
- **Description**: Juice contains a `Dictionary` of weapon-id → tuning constants in code.
- **Pros**: Slightly faster lookup; no `.tres` files to author.
- **Cons**: Designer must edit code to retune Juice — kills hot-reload; couples balance to programmer time. Concept's solo-dev productivity goal makes this unworkable.
- **Rejection Reason**: Resources are the standard Godot pattern for designer-tunable data. The Resource cost is one-time scene authoring; benefits compound across every retune cycle.

### Alternative F: Positional `AudioStreamPlayer2D` for hit SFX
- **Description**: Use spatial 2D audio for hit-impact SFX so off-screen hits attenuate by distance.
- **Pros**: Tactical audio readability — players can hear *where* off-screen pressure is coming from.
- **Cons**: Off-screen kills become quieter. Pillar 2 is "Satisfying Kills, **Always**" — the *always* word is load-bearing. A kill across the map fading to near-silent directly fights the pillar. Engine reference's own `audio.md` pool example uses non-positional `AudioStreamPlayer` for this reason. Genre convention (Vampire Survivors, Hades, Risk of Rain 2) is non-positional impact SFX.
- **Rejection Reason**: Pillar 2 wins. Reserve `AudioStreamPlayer2D` for ambient/environmental sound (footsteps, zone ambient, machinery hum) where positional behavior enhances immersion without competing with kill-feel.

## Consequences

### Positive

- Single dispatch path means a new weapon/ability/zombie-type only needs a new `JuiceProfile.tres`, no Juice code changes.
- Hybrid hit-stop matches AAA polish references at no additional architectural cost vs Alternative C/D.
- 0.5 ms/frame budget at peak load means Juice never becomes the bottleneck — Crowd Pathfinding (ADR-0002) and Damage & Health stay the dominant frame-time consumers.
- Resource-driven recipes mean the entire game's hit-feel can be retuned in the editor without rebuilding.
- Pooling rules locked here prevent the Performance Watchlist regression (naive `instantiate()` per kill).
- Direct subscription to Damage & Health (no EventBus middleman) preserves the autoload-coupling discipline established by ADR-0001's `state_machine_pattern`.
- Non-positional hit-SFX preserves Pillar 2 satisfaction for off-screen kills.
- `Tween.set_ignore_time_scale(true)` rule prevents the silent UI-slow-mo failure mode at every kill.

### Negative

- Designer must author one `JuiceProfile.tres` per weapon/ability — adds asset count (~20–40 `.tres` files at MVP).
- Profile lookup adds a Dictionary dereference per damage event (~0.001 ms — well within budget but not free).
- Hybrid hit-stop branching adds a small decision-tree at dispatch time. Code is simple but is one more thing to test.
- Per-actor `process_mode = DISABLED` does NOT freeze the actor's currently-playing `GPUParticles2D` children — those keep emitting. Acceptable for MVP. If unacceptable in playtest, requires a follow-up tween-driven `speed_scale=0.0` on the actor's particle emitters.
- Loss of tactical audio readability (no positional cue for off-screen pressure). Mitigated by visual lane-pressure indicators on the HUD (deferred to GDD #29).
- Every UI/HUD Tween authored in the project must remember to call `set_ignore_time_scale(true)`. This is a checklist burden; enforced at code review and via `/code-review` against this ADR.

### Risks

- **Risk: Tween time-scale bleed (silent failure)**. Active Tweens (damage numbers, UI fades, camera shake recovery) will proportionally slow during global `Engine.time_scale` hit-stop unless `set_ignore_time_scale(true)` is explicitly set. Per-system Tween authoring that omits this flag will produce visually broken hit-stop on every kill — UI freezes for 80 ms each time, reading as a frame-rate stutter. **Mitigation**: mandatory checklist item ("UI/HUD/cross-system Tweens MUST call `set_ignore_time_scale(true)`") in every implementation story for systems creating Tweens. Code review enforces. Test Harness regression test asserts that during a simulated global hit-stop, a tagged "real-time" Tween completes in expected wall-clock duration ±10%.

- **Risk: HitEvent silent downgrade on cold start**. If the Godot editor or test runner loads a scene before `dotnet build` completes, `HitEvent` arguments arriving in GDScript will be plain `RefCounted` with no properties accessible. All `hit_event.Amount` reads return `null` silently, producing no visible error but zero-magnitude juice (no shake, no sound, no particles). **Mitigation**: runtime `assert(hit_event is HitEvent, ...)` in `_on_damage_dealt`. CI gate ordering: `dotnet build` → `godot --headless` (same step already in ADR-0003 Migration Plan §1).

- **Risk: Global hit-stop + per-actor hit-stop interaction**. If both fire in the same frame on the same target (e.g., a crit on a boss that also qualifies for per-actor freeze), `Engine.time_scale = 0.05` is set AND the actor gets `PROCESS_MODE_DISABLED` simultaneously. Without coordination, the per-actor restore timer can race with the global hit-stop's restore. **Mitigation**: explicit priority rule — global hit-stop supersedes per-actor (mutex flag `_global_hit_stop_active` blocks new per-actor freezes while global is active). `_abort_active_hit_stop` clears both global state AND any frozen actors on `RUN_PAUSED` entry. Test Harness regression: simulate boss-crit during global hit-stop, assert no actor remains frozen after global hit-stop ends.

- **Risk: AudioStreamPlayer pool exhaustion at peak**. 16-player pool may be too small with 100+ zombies + Champion shooting + ability bursts. **Mitigation**: pool size is a tuning knob (`Juice.sfx_pool_size`); increase if profiling shows audio drops. Drop-on-exhaust is the failure mode — never queue (queueing produces audible stutter).

- **Risk: Damage & Health forgets to set `IsKill` on the killing blow**. Juice cannot know it was a kill, no kill-juice fires. **Mitigation**: GDD #13 (Damage & Health) must include the test "killing-blow event has `IsKill == true`" as Acceptance Criterion. Test Harness (System 45) headless test asserts this.

- **Risk: AoE ability emission flood (>50/frame)**. If a future ability hits 100+ zombies in a single frame (e.g., an ultimate AoE), `damage_dealt` fires 100 times that frame, violating registry forbidden pattern `unbatched_csharp_to_gdscript_signal_emission` (>50/frame threshold). **Mitigation**: Damage & Health enforces ≤50 emissions/frame as a system-level invariant. If any ability exceeds this, the contract evolves to `damage_dealt_batch(Array[HitEvent])` — a single emission per frame carrying all batched events. This evolution is not required for MVP card pool. Test Harness asserts ≤50 emissions per frame across all gameplay scenarios.

- **Risk: AudioStreamPlayer2D positional creep**. A future ADR or implementation story may reflexively reach for `AudioStreamPlayer2D` for "spatial realism" without recognizing the Pillar 2 conflict. **Mitigation**: registered as forbidden pattern (see Registry Updates) — `positional_audio_for_impact_sfx` flagged so any future use of `AudioStreamPlayer2D` for hit SFX trips review.

- **Risk: `GPUParticles2D.restart(keep_seed)` default behavior change in 4.4**. Pool reuse code calling `.restart()` without explicit `keep_seed: false` may use the new default, potentially producing visually identical splatter on every reuse. **Mitigation**: pool implementation explicitly passes `keep_seed: false`. Verified in implementation story.

- **Risk: `process_mode = DISABLED` mid-MoveAndSlide**. A zombie disabled mid-`_physics_process` skips its `MoveAndSlide()` for the freeze duration. At 50 ms this is invisible. At longer durations, Jolt's collision integration could miss interactions. **Mitigation**: max per-actor freeze duration is bounded at 100 ms in `JuiceProfile` schema validation. Longer durations require explicit override.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| GDD #9 (Juice / Feedback Pipeline) | "Hit-stop, screen-shake, particles, sound layering as a reusable system" — game concept p.302 | Centralized Juice autoload + JuiceProfile resources is the reusable system contract |
| GDD #9 | "Per-Champion calibrated screen shake" — concept Core Loop p.134 | `JuiceProfile.shake_amplitude` and `shake_duration_ms` are per-profile, so a sniper-Champion profile uses small shake while a berserker-Champion profile uses heavy shake |
| GDD #9 | "Pillar 2: Satisfying Kills, *Always*" | Non-positional `AudioStreamPlayer` ensures off-screen kills register at full SFX-bus volume; hybrid hit-stop ensures kill moments read distinctly from grunt hits |
| GDD #13 (Damage & Health) | Signal-emission policy — "emit only on state transitions" — registry forbidden pattern `unbatched_csharp_to_gdscript_signal_emission` | This ADR locks `damage_dealt` as a single batched signal per damage event with ≤50 emissions/frame bound |
| GDD #35 (Damage Number / Kill Feedback) | Co-consumes the same `damage_dealt` signal stream | This ADR's `HitEvent` payload (`Amount`, `IsCrit`, `ImpactPosition`) is the canonical input for both Juice and Damage Number — same signal, different consumer |

## Performance Implications

- **CPU (Juice dispatch)**: ≤ 0.5 ms/frame at peak load (~10–15 hits/frame). Breakdown:
  - Signal dispatch + `is HitEvent` assertion + Dictionary profile lookup: ~0.05 ms × 15 hits = 0.075 ms
  - Hit-stop tween creation/teardown: ~0.02 ms × 15 hits = 0.3 ms
  - Camera shake update (singleton): ~0.05 ms
  - Pool slot lookup (particles + audio): ~0.01 ms × 15 hits = 0.15 ms
  - **Total: ~0.5 ms** — within budget.
- **CPU (excluded — owned by other systems)**:
  - Particle simulation (GPUParticles2D, GPU-side): owned by VFX system budget
  - SFX synthesis: owned by Audio Bus system budget
  - Damage Number rendering: owned by GDD #35 budget
- **Memory**: ~50 emitters/profile × ~30 profiles × ~2 KB/emitter = ~3 MB. AudioStreamPlayer pool: 16 × ~1 KB = ~16 KB. Total: < 4 MB — well under the 2 GB ceiling.
- **Load Time**: All `JuiceProfile.tres` resources preload at scene load (~30 × ~5 KB = ~150 KB). Negligible.
- **Network**: N/A (single-player V1).

## Migration Plan

No migration — first ADR for the Juice system. Implementation order:

1. Author `JuiceProfile` Resource class. Verify hot-reload behavior in editor.
2. Author `Juice` autoload skeleton (signal subscription stub + assertion guard + Tween rules + mutex flag).
3. **CI gate**: ensure `dotnet build` runs before any `godot --headless` step (same as ADR-0003 Migration Plan §1).
4. Author Damage & Health's `damage_dealt` signal in C# (when GDD #13 is implemented). Lock `HitEvent` schema.
5. Wire pool infrastructure (GPUParticles2D pool, non-positional AudioStreamPlayer pool of 16).
6. Author 1–2 `JuiceProfile.tres` test profiles to validate at prototype stage. Verify `GPUParticles2D.restart(keep_seed=false)` behavior.
7. Validate hybrid hit-stop branch decisions at peak load (Test Harness simulation).
8. Validate Tween `set_ignore_time_scale(true)` behavior with a representative UI Tween during simulated global hit-stop.

## Validation Criteria

- **VC-1**: At 100+ zombies + Champion + Card-Roll UI active, Juice dispatch CPU work stays ≤ 0.5 ms/frame measured by `OS.get_ticks_usec()` profiling around `_on_damage_dealt`.
- **VC-2**: All particle emitters and SFX players are pool-allocated; zero runtime `instantiate()` or `AudioStreamPlayer.new()` from Juice during gameplay (assert via Test Harness scene-tree audit).
- **VC-3**: A `RUN_PAUSED` entry during an active hit-stop cleanly restores `Engine.time_scale = 1.0` AND restores `process_mode = INHERIT` on any frozen actor — verified by Test Harness regression test.
- **VC-4**: A non-existent `profile_id` produces a `print_warning` and a default profile is used; no crash.
- **VC-5**: A new weapon/ability requires zero Juice code changes — only a new `.tres` asset. Asserted by code-review checklist when GDD #15-#17 stories ship.
- **VC-6**: Designer can hot-edit a `JuiceProfile.tres` field and see the change next hit at runtime (Godot Resource hot-reload behavior).
- **VC-7**: A UI Tween created with `set_ignore_time_scale(true)` completes in its specified wall-clock duration (±10%) when global hit-stop is active. A world-actor Tween without the flag completes in `duration / time_scale` (proportional to slow-mo). Asserted via Test Harness Tween-instrumentation regression test.
- **VC-8**: Damage & Health emits ≤50 `damage_dealt` signals per frame across all designed gameplay scenarios. Test Harness fails the run if exceeded.
- **VC-9**: A boss-crit during an in-progress global hit-stop does not result in any actor remaining frozen after global hit-stop ends — mutex correctly skips the per-actor freeze. Test Harness regression test.

## Related Decisions

- **ADR-0001** (Run State / Game Flow) — pause-model dependency; `state_changed` subscription
- **ADR-0002** (Crowd Pathfinding Architecture) — sets the 100+ zombie target this ADR's performance budget assumes
- **ADR-0003** (Language Routing Policy) — defines the C# → GDScript signal subscription rules and forbidden patterns this ADR's contract follows
- **ADR-0006** (Save Schema & Versioning, pending) — `JuiceProfile.tres` are static assets, not persisted state; no save concerns
