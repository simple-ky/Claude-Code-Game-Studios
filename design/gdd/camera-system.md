# Camera System

> **Status**: Designed (2026-05-23 — all 11 sections complete; pending `/design-review` in fresh session)
> **Author**: User + game-designer + technical-artist + qa-lead (Section H audit, 2026-05-23)
> **Last Updated**: 2026-05-23
> **Implements Pillar**: Pillar 2 (Satisfying Kills — screen shake delivery), Pillar 4 (Low Skill Floor — battlefield always readable)
> **Review Mode**: lean (per `production/review-mode.txt` or default)

## Overview

The Camera System is a top-down GDScript `Camera2D` that frames *Last Stand: Champions*' battlefield. It follows the player's Champion with configurable position-smoothing lag, keeping the hero readable mid-combat without snapping on every input change. Hard world-space limits prevent the camera from revealing geometry outside the active map's navigable area. On the Juice side, the Camera exposes a `shake()` method that the Juice / Feedback Pipeline calls on every kill, crit, or boss hit; internally, it applies `offset`-based displacement via a `Tween` with `set_ignore_time_scale(true)` so shake recovery runs at wall-clock speed even during global hit-stop slow-mo. The Camera carries no game-state logic: it reads the Champion's position as its follow target and executes Juice-issued shake recipes — nothing more.

## Player Fantasy

**"Your Eyes Never Leave the Fight"**

The Camera System is infrastructure the player never thinks about. Its success is felt as *absence* — no moment of "wait, where am I?", no threshold where a lane goes off-screen and a zombie leaks unseen, no kill-shake that knocks the aim off a critical target. The battlefield is always exactly where the player needs it: the Champion drifts toward the screen edge and the world drifts with them, smooth as a steady breath. Two lanes stay readable at any wave density. When death erupts, the screen kicks — short, sharp, never in the way. The Camera's job is to make the player feel like a commander who sees everything and misses nothing.

**Pillar alignment**:
- **Pillar 4 (Low Skill Floor, High Expression Ceiling)**: A camera that hides action is an invisible skill gate — players penalized for a zombie they never saw, not a decision they made badly. This system makes readability a promise: the active lane is always in frame, the buildable strip is always visible between waves, and the Champion's position is never the reason a player says "I didn't see it coming."
- **Pillar 2 (Satisfying Kills, Always)**: Juice delivers kill-feel through VFX, audio, and hit-stop. The Camera supports this by staying out of the way — a restraint that makes the world-shake on boss kills land *harder* because the world was steady just moments before.

## Detailed Design

### Core Rules

**Rule 1. Camera2D is a child node of the Champion scene.** The `Camera2D` is owned by the Champion scene and follows its parent's position automatically via Godot's node hierarchy. No separate camera controller, autoload, or `RemoteTransform2D` is used at MVP. When the Champion scene is freed (run ends), the Camera is freed with it. On run restart a new Champion+Camera is instantiated fresh.

**Rule 2. Zoom is fixed at 0.75x for all run states.** `Camera2D.zoom = Vector2(cam_zoom, cam_zoom)` where `cam_zoom = 0.75` (tuning knob). This renders a 96 px cell at ~72 px on screen. At this zoom, the Steam Deck viewport (1,280×800) shows **1,707 × 1,067 px** of world space. No zoom transitions occur during gameplay; a fixed zoom means the player's spatial calibration (tower placement measurements, aiming distances) never shifts mid-session.

**Rule 3. The X-axis is locked to the map's horizontal center.** Both lanes together span ~960 px of world width (2 × 5 cells × 96 px). At 0.75x zoom the viewport shows 1,707 px wide — the entire lane corridor fits with ~373 px of margin on each side. `Camera2D.position.x` is pinned to the map's horizontal midpoint once at `RUN_LOADING` and never updates. No horizontal following logic is needed or implemented.

**Rule 4. The Y-axis follows the Champion with speed-capped smooth tracking.** `Camera2D.position_smoothing_enabled = true`, `position_smoothing_speed = cam_follow_speed` (default 10.0). The camera's Y position tracks the Champion's Y with a velocity-capped lag. At `cam_follow_speed = 10`, the error halves in ~70ms — responsive but not snapping on every input change. This is the only axis that moves during a run.

**Rule 5. During `WAVE_PREP`, a Y-axis bias offset is applied.** A smooth tween over `cam_offset_transition_s` (default 0.4 s, `set_ignore_time_scale(true)`) moves the camera's follow anchor `cam_prep_y_offset_cells` cells (default 2 cells = 192 px) toward the spawn end of the lane. The player sees more of the approach corridor above the buildable strip — useful for planning placements against the incoming threat direction. When `WAVE_PREP` ends and `WAVE_ACTIVE` begins, the offset tweens back to `Vector2.ZERO` over the same duration.

**Rule 6. World-space bounds cap Y movement with an inward safety margin.** Hard limits prevent the camera from revealing off-map geometry:
- `limit_top` = `spawn_zone_north_edge_px` + `_safety_margin_px`
- `limit_bottom` = `goal_zone_south_edge_px` − `_safety_margin_px`
- `_safety_margin_px` = `(viewport_height / cam_zoom) / 2` (computed once at `RUN_LOADING`)

At Steam Deck defaults: safety margin = (800 / 0.75) / 2 ≈ **533 px** ≈ 5.6 cells. The camera only reaches this limit if the Champion walks within ~5.6 cells of the map edge — the spawn zone entry or the goal zone boundary — which is out of the active play area during normal combat. The hard-clip at the boundary is therefore invisible during typical play.

**Rule 7. The Camera exposes a `shake(amplitude_px: float, frequency: float)` method.** This is the only interface Juice / Feedback Pipeline (#9) uses to trigger camera feedback. (`duration_ms` was removed — shake duration is fully determined by `cam_trauma_decay_rate`; see Formula D.8.) Internally:
- Each call adds `amplitude_px / cam_shake_max_amplitude_px` to a `_trauma` float (clamped [0, 1]).
- Each `_process` frame: `_trauma` decreases by `cam_trauma_decay_rate × delta` (default 1.5/sec).
- `Camera2D.offset` is set each frame to a random 2D unit vector scaled by `cam_shake_max_amplitude_px × _trauma²`.
- The random direction changes at `frequency` Hz (a Tween-driven step function).
- The direction-step Tween uses `set_ignore_time_scale(true)` so directional resampling runs at wall-clock speed during hit-stop. However, the `_trauma` decay in `_process` uses engine-provided `delta` (scaled by `Engine.time_scale`). This is intentional: during hit-stop (`Engine.time_scale = 0.05`), trauma barely decays and the shake holds position during the slow-motion window, then fades normally once time returns to 1.0×.
- `offset` is used exclusively — `position` is never touched by the shake system.

The per-event amplitude values (kill: 3 px, crit: 5 px, boss kill: 8 px) are authored in Juice's `JuiceProfile.tres` files — Camera only enforces the `cam_shake_max_amplitude_px` cap (default 12 px). *(See Tuning Knobs for Reduce Motion accessibility halving.)*

**Rule 8. `shake()` calls arriving during `RUN_PAUSED` or `MAIN_MENU` are silently dropped.** The Camera checks `GameStateMachine.current_state` at the top of the `shake()` method. Shake is valid during `WAVE_ACTIVE`, `WAVE_PREP` (ambient feedback only), `RUN_VICTORY`, and `RUN_DEFEAT`.

**Rule 9. Camera state is initialized once during `RUN_LOADING`.** After `LaneSystem.geometry_baked()` fires, the Camera reads the active map's spawn and goal zone extents, computes `_safety_margin_px`, pins `Camera2D.position.x` to the map center, sets zoom, and enables position smoothing. Before this event, the Camera is dormant.

---

### States and Transitions

| Run State | Camera Behavior |
|---|---|
| `MAIN_MENU`, `RUN_LOADING` (pre-bake) | Camera node not yet active |
| `RUN_LOADING` (post-`geometry_baked()`) | Bounds set; zoom set; X pinned; `_trauma = 0`; dormant until Champion spawned |
| `WAVE_PREP` | Y-offset `cam_prep_y_offset_cells` tweened in; smooth Y follow; shake enabled |
| `WAVE_ACTIVE` | Y-offset tweened out; smooth Y follow; shake fully enabled |
| `RUN_PAUSED` | Tweens auto-pause (PROCESS_MODE_PAUSABLE); shake calls dropped; `_trauma` does not decay |
| `RUN_VICTORY` / `RUN_DEFEAT` | Y-offset = 0; smooth Y follow; shake enabled (e.g., boss-kill final tremor) |

---

### Interactions with Other Systems

| System | Direction | Data / Event | Interface owner |
|---|---|---|---|
| Champion / Player Controller (#14) | → Camera | Champion's world-space Y position (via node parent–child hierarchy) | Camera reads parent position automatically |
| Juice / Feedback Pipeline (#9) | → Camera | `shake(amplitude_px, duration_ms, frequency)` call | Camera exposes the method; Juice calls it with JuiceProfile parameters |
| Run State / Game Flow (#8) | → Camera | `state_changed(from, to)` signal → drives Y-offset tween (WAVE_PREP ↔ WAVE_ACTIVE) and shake suppression (RUN_PAUSED) | Camera subscribes to GameStateMachine.state_changed |
| Lane / Map System (#7) | → Camera | `LaneSystem.geometry_baked()` signal → Camera reads map extents (spawn_zone, goal_zone) to set world bounds | Lane/Map fires; Camera reads once |
| Input System (#1) | ← Camera | `get_viewport().get_canvas_transform()` incorporates Camera2D zoom automatically for `cursor_world_pos_transform` | Godot viewport — automatic, no explicit interface |

## Formulas

### D.1 — Viewport World Extent

The `viewport_world_extent` formula is defined as:

`viewport_world_width_px  = viewport_width_px  / cam_zoom`
`viewport_world_height_px = viewport_height_px / cam_zoom`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Viewport width | `viewport_width_px` | int | 1–7680 | Horizontal pixel dimension of the game viewport |
| Viewport height | `viewport_height_px` | int | 1–4320 | Vertical pixel dimension of the game viewport |
| Camera zoom | `cam_zoom` | float | 0.1–4.0 | Camera2D zoom scalar applied to both axes (tuning knob, default 0.75) |
| World width | `viewport_world_width_px` | float | >0 | World-space horizontal extent visible through the viewport |
| World height | `viewport_world_height_px` | float | >0 | World-space vertical extent visible through the viewport |

**Output Range:** Both outputs strictly positive. Not clamped here; Camera2D world-bounds limits (Formula D.6) separately constrain how far the camera can travel within those extents.

**Example** (Steam Deck 1280×800, `cam_zoom = 0.75`):
```
viewport_world_width_px  = 1280 / 0.75 = 1706.67 px  ← the Section C "~1,707 px" figure
viewport_world_height_px =  800 / 0.75 = 1066.67 px  ← the Section C "~1,067 px" figure
```

---

### D.2 — Lane Corridor Fit Check

The `lane_corridor_margin` formula is defined as:

`lane_corridor_total_px  = lane_count × lane_width_cells × cell_size_px`
`lane_corridor_margin_px = (viewport_world_width_px − lane_corridor_total_px) / 2`

Evaluated once at `RUN_LOADING` as a sanity assertion. If `lane_corridor_margin_px ≤ 0`, the lane corridor overflows the viewport and the X-lock design is broken — the run aborts to `MAIN_MENU` with a configuration error.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Lane count | `lane_count` | int | 2–3 | Number of parallel lanes (MVP = 2, V1 max = 3) |
| Lane width | `lane_width_cells` | int | 3–7 | Width of each lane in cells (MVP = 5) |
| Cell size | `cell_size_px` | int | 96 | World-space pixel size of one cell (locked constant, registry: `cell_size_px`) |
| World width | `viewport_world_width_px` | float | >0 | From Formula D.1 |
| Lane corridor total | `lane_corridor_total_px` | int | >0 | Total pixel width of all lanes combined |
| Per-side margin | `lane_corridor_margin_px` | float | must be >0 | World-space margin on each side between the lane corridor edge and the visible boundary |

**Output Range:** Must be positive. At MVP defaults (2 × 5 × 96 = 960 px corridor, 1706.67 px world width): 373.3 px per side. At V1 max (3 × 5 × 96 = 1440 px corridor): 133.3 px per side — still positive, but narrow enough to assert explicitly at `RUN_LOADING`.

**Example** (MVP: 2 lanes × 5 cells × 96 px, Steam Deck):
```
lane_corridor_total_px  = 2 × 5 × 96 = 960 px
lane_corridor_margin_px = (1706.67 − 960) / 2 = 373.3 px per side  ✓
```

---

### D.3 — Y-Axis Tracking Half-Life

The `cam_tracking_half_life` formula characterizes the exponential lag of the Y-axis smooth-follow:

`cam_tracking_half_life_s = ln(2) / cam_follow_speed`

Underlying continuous model: `error(t) = error₀ × e^(−cam_follow_speed × t)`, where `error(t)` is the remaining Y distance between camera and Champion target at elapsed time `t` seconds.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Follow speed | `cam_follow_speed` | float | 0.1–100.0 | `Camera2D.position_smoothing_speed` coefficient; controls how fast positional error decays per second (tuning knob, default 10.0) |
| Initial error | `error₀` | float | 0–unbounded | Y-axis distance between camera and Champion at the moment a position step-change occurs |
| Elapsed time | `t` | float | ≥ 0 | Seconds since the step change |
| Remaining error | `error(t)` | float | ≥ 0 | Y-axis distance gap remaining at time `t` |
| Half-life | `cam_tracking_half_life_s` | float | >0 | Time in seconds for the positional gap to halve, regardless of initial magnitude |

**Output Range:** Strictly positive. At the default `cam_follow_speed = 10.0`: half-life ≈ 69.3 ms (the Section C "~70 ms" figure is a correct rounding).

**Implementation note:** Godot's `Camera2D.position_smoothing` uses discrete Euler integration (each frame advances the error by `cam_follow_speed × delta`). At 60 fps the discrete half-life is ~63 ms — marginally faster than this formula's 69 ms. The difference is a known approximation artifact; expect the live feel to be slightly snappier than this formula predicts.

**Example** (`cam_follow_speed = 10.0`):
```
cam_tracking_half_life_s = ln(2) / 10.0 ≈ 0.0693 s ≈ 69 ms
```

---

### D.4 — WAVE_PREP Y-Offset

The `cam_wave_prep_offset` formula is defined as:

`cam_prep_offset_px = cam_prep_y_offset_cells × cell_size_px`

The offset is applied as a Tween using `TRANS_SINE, EASE_IN_OUT` over `cam_offset_transition_s` seconds with `set_ignore_time_scale(true)`, so the transition runs at wall-clock speed regardless of `Engine.time_scale`.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Offset cells | `cam_prep_y_offset_cells` | int | 0–5 | Cells to shift the camera toward the spawn end during WAVE_PREP (tuning knob, default 2) |
| Cell size | `cell_size_px` | int | 96 | World-space pixel size of one cell (locked constant) |
| Transition time | `cam_offset_transition_s` | float | 0.05–2.0 | Duration of the tween animating the offset on and off (tuning knob, default 0.4 s) |
| Prep offset | `cam_prep_offset_px` | int | 0–480 | Pixel distance the camera's follow anchor shifts toward the spawn end during WAVE_PREP |

**Output Range:** 0 px (disabled) to 480 px at the 5-cell max. Default 192 px. Bounded at the high end by Formula D.6 — if the offset would push the camera past `limit_top`, Camera2D clamps it.

**Example** (`cam_prep_y_offset_cells = 2`, `cell_size_px = 96`):
```
cam_prep_offset_px = 2 × 96 = 192 px
```

---

### D.5 — Y-Axis Safety Margin

The `cam_y_safety_margin` formula is defined as:

`_safety_margin_px = (viewport_height_px / cam_zoom) / 2`

Equivalently: `_safety_margin_px = viewport_world_height_px / 2`.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Viewport height | `viewport_height_px` | int | 1–4320 | Vertical pixel dimension of the game viewport |
| Camera zoom | `cam_zoom` | float | 0.1–4.0 | Camera2D zoom scalar (tuning knob, default 0.75) |
| World height | `viewport_world_height_px` | float | >0 | From Formula D.1 |
| Safety margin | `_safety_margin_px` | float | >0 | Inward world-space pixel margin applied to both top and bottom camera limits |

**Output Range:** Strictly positive. Equal to half the world-space viewport height. This is the geometrically correct inset: the camera center can only reach within half a viewport-height of the map edge, meaning the map boundary coincides exactly with the screen edge at the limit — no off-map geometry is ever revealed.

**Example** (Steam Deck 800px height, `cam_zoom = 0.75`):
```
_safety_margin_px = (800 / 0.75) / 2 = 533.33 px ≈ 5.6 cells at 96 px/cell
```

---

### D.6 — World-Space Camera Bounds

The `cam_world_bounds` formula is defined as:

`limit_top    = spawn_zone_north_edge_px + _safety_margin_px`
`limit_bottom = goal_zone_south_edge_px  − _safety_margin_px`

> **Godot coordinate convention**: In Godot 2D, Y increases downward. "North" (spawn zone) is a smaller Y value; "South" (goal zone) is a larger Y value. `limit_top < limit_bottom` must always hold.

Assigned to `Camera2D.limit_top` and `Camera2D.limit_bottom` once at `RUN_LOADING`, after `LaneSystem.geometry_baked()` fires.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Spawn edge | `spawn_zone_north_edge_px` | float | ≥ 0 | World-space Y coordinate of the northernmost spawn zone edge (read from map data at RUN_LOADING) |
| Goal edge | `goal_zone_south_edge_px` | float | > spawn_zone_north_edge_px | World-space Y coordinate of the southernmost goal zone edge |
| Safety margin | `_safety_margin_px` | float | >0 | From Formula D.5 |
| Top limit | `limit_top` | float | > spawn_zone_north_edge_px | Camera2D.limit_top — northernmost world-space Y the camera center can occupy |
| Bottom limit | `limit_bottom` | float | < goal_zone_south_edge_px | Camera2D.limit_bottom — southernmost world-space Y the camera center can occupy |

**Output Range:** `limit_top < limit_bottom` is a required invariant. At MVP map depth (30 cells = 2880 px world units), the invariant is satisfied with large margin. Required guard: if `goal_zone_south_edge_px − spawn_zone_north_edge_px < 2 × _safety_margin_px`, the bounds would invert — this represents a map shorter than ~11 world cells at Steam Deck defaults and must abort `RUN_LOADING`.

**Example** (map: `spawn_zone_north_edge_px = 0`, `goal_zone_south_edge_px = 3000`, `_safety_margin_px = 533.33`):
```
limit_top    =    0 + 533.33 = 533.33 px
limit_bottom = 3000 − 533.33 = 2466.67 px
```

---

### D.7 — Trauma Accumulation

The `cam_shake_trauma_accumulate` formula is defined as:

`_trauma_new = clamp(_trauma_prev + (amplitude_px / cam_shake_max_amplitude_px), 0.0, 1.0)`

Called once per `shake()` invocation. Updated `shake()` signature — `duration_ms` removed (shake duration is fully determined by `cam_trauma_decay_rate`; see Formula D.8):
`shake(amplitude_px: float, frequency: float)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Previous trauma | `_trauma_prev` | float | [0.0, 1.0] | Trauma level before this call; decays between calls via Formula D.8 |
| Event amplitude | `amplitude_px` | float | (0.0, `cam_shake_max_amplitude_px`] | Requested shake amplitude in world-space pixels, as authored in `JuiceProfile.tres` |
| Amplitude cap | `cam_shake_max_amplitude_px` | float | 1.0–30.0 | Maximum shake displacement in world-space pixels (tuning knob, default 12 px); also the normalization denominator |
| New trauma | `_trauma_new` | float | [0.0, 1.0] | Trauma level after accumulation; clamped so overlapping events cannot exceed 1.0 |

**Output Range:** Always [0.0, 1.0] after the clamp. At default values: kill (3 px) adds 0.25 trauma; crit (5 px) adds ≈0.417; boss kill (8 px) adds ≈0.667. Rapid consecutive events saturate at 1.0 and are silently capped.

**Example** (prior trauma 0.2, crit fires: `amplitude_px = 5`, `cam_shake_max_amplitude_px = 12`):
```
increment   = 5 / 12 = 0.4167
_trauma_new = clamp(0.2 + 0.4167, 0.0, 1.0) = 0.6167
```

---

### D.8 — Trauma Decay

The `cam_shake_trauma_decay` formula is defined as:

`_trauma_new = max(0.0, _trauma_prev − (cam_trauma_decay_rate × delta))`

Evaluated every `_process` frame. **`delta` is the engine-provided frame time, which scales with `Engine.time_scale` during hit-stop.** During hit-stop (`Engine.time_scale = 0.05`), `delta ≈ 0.000833 s` — trauma barely decays, and the shake effectively freezes in position while the slow-motion effect runs. This is intentional: the screen holds the hit during the dramatic slow-mo window, then fades normally once time returns to 1.0×.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Previous trauma | `_trauma_prev` | float | [0.0, 1.0] | Trauma level at the start of this frame |
| Decay rate | `cam_trauma_decay_rate` | float | 0.1–10.0 | Trauma units consumed per second of game time (tuning knob, default 1.5/s) |
| Frame time | `delta` | float | (0.0, 0.1] | Engine-scaled frame time from `_process(delta)`; slows proportionally with `Engine.time_scale` during hit-stop |
| New trauma | `_trauma_new` | float | [0.0, 1.0] | Trauma level after this frame's decay; floored at 0.0 |

**Output Range:** Always [0.0, 1.0]. At `cam_trauma_decay_rate = 1.5` and normal time scale, full trauma (1.0) reaches zero in ~0.667 s (40 frames at 60 fps). A boss-kill event (trauma ≈ 0.667) fades in ~0.44 s (~27 frames).

**Example** (normal play, `_trauma_prev = 0.6167`, `delta = 0.01667 s`, `cam_trauma_decay_rate = 1.5`):
```
_trauma_new = max(0.0, 0.6167 − 1.5 × 0.01667)
            = max(0.0, 0.5917) = 0.5917
```

---

### D.9 — Shake Offset

The `cam_shake_offset_frame` formula is defined as:

`camera_shake_offset = random_unit_vec × cam_shake_max_amplitude_px × _trauma²`

Applied each frame to `Camera2D.offset`. `random_unit_vec` is resampled at the interval from Formula D.10; direction is held between samples while magnitude decays via `_trauma`.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Shake direction | `random_unit_vec` | Vector2 | magnitude = 1.0 | Random 2D unit vector from a uniform circle (`Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()`); resampled per Formula D.10 |
| Amplitude cap | `cam_shake_max_amplitude_px` | float | 1.0–30.0 | Maximum displacement in world-space pixels (tuning knob, default 12 px) |
| Trauma | `_trauma` | float | [0.0, 1.0] | Current trauma level from Formula D.8 |
| Shake offset | `camera_shake_offset` | Vector2 | magnitude ∈ [0, 12] px | World-space pixel displacement applied to `Camera2D.offset` this frame |

**Output Range:** Magnitude from 0 px (zero trauma) to 12 px (full trauma, default cap). The `_trauma²` squaring is intentional: at `_trauma = 0.5`, magnitude is only 25% of maximum (not 50%). This produces rapid settle at low trauma while high-trauma events feel intense — a perceptually nonlinear response on a simple formula.

**Example** (`_trauma = 0.5917`, `cam_shake_max_amplitude_px = 12`, direction sample `(0.6, 0.8)`):
```
_trauma²            = 0.5917² = 0.3501
camera_shake_offset = (0.6, 0.8) × 12 × 0.3501 = (2.52, 3.36) px
```

---

### D.10 — Direction Step Interval

The `cam_shake_direction_step` formula is defined as:

`direction_step_interval_s = 1.0 / frequency`

A new `random_unit_vec` is drawn every `direction_step_interval_s` seconds. The step Tween uses `set_ignore_time_scale(true)` — direction resamples run at wall-clock speed even during hit-stop, maintaining directional jitter during slow-motion.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Frequency | `frequency` | float | 1.0–60.0 Hz | Direction-resample rate, authored per-event in `JuiceProfile.tres` |
| Step interval | `direction_step_interval_s` | float | (0, 1.0] s | Seconds between random direction resamples |

**Output Range:** At `frequency = 5 Hz`: 0.2 s per step (slow, lumbering). At `frequency = 20 Hz`: 0.05 s per step (tight jitter). At `frequency = 30 Hz`: 0.033 s (2 frames at 60 fps).

**Example** (`frequency = 20 Hz`):
```
direction_step_interval_s = 1.0 / 20 = 0.05 s
```

## Edge Cases

Edge cases are grouped by source: **E.1** covers run-state transition seams,
**E.2** covers extreme or illegal inputs to the Section D formulas, and **E.3**
covers broken contracts with dependency systems. Each entry follows the format
**If [condition]: [exact outcome]. [rationale]**.

---

### E.1 — State-Transition Seams

- **If a `shake()` is in progress when the run transitions to `RUN_PAUSED`**:
  the direction-step Tween auto-pauses (`PROCESS_MODE_PAUSABLE`), the `_process`
  callback gates trauma decay off, and `Camera2D.offset` holds its last value.
  On resume to `WAVE_PREP` / `WAVE_ACTIVE`, the Tween and decay resume from the
  frozen state. *Rationale: Godot's pause semantics handle this with no Camera-
  side code — the shake "freezes" exactly as the states table promises.*

- **If `state_changed` fires `WAVE_PREP → WAVE_ACTIVE` while the prep Y-offset
  tween (Rule 5) is still animating in**: kill the in-flight tween via the
  stored tween reference (`_prep_offset_tween.kill()`) before creating the
  reverse tween from the current offset value. *Rationale: without the kill,
  two tweens compete on the same `Camera2D.offset.y` property and last-writer-
  wins per frame produces visible jitter.*

- **If `state_changed` fires `RUN_LOADING → MAIN_MENU` after `geometry_baked()`
  already configured the Camera** (the bake-failure abort path per ADR-0001):
  reset `_trauma = 0`, `Camera2D.offset = Vector2.ZERO`, snap any offset back
  to zero, kill all in-flight tweens, and disconnect from
  `GameStateMachine.state_changed`. The Camera is then freed with the Champion
  scene during MAIN_MENU teardown. *Rationale: leaving the Camera initialized
  while the rest of the run unwinds risks shake signals firing into a half-
  configured state on the next run start.*

- **If `state_changed` fires `WAVE_ACTIVE → RUN_VICTORY` (or `→ RUN_DEFEAT`)
  while `Camera2D.offset.y` is non-zero**: snap the offset to zero with no
  tween (set directly, no animation). *Rationale: under Rule 5 the offset
  should already be zero by this transition, but if a race leaves a residual
  value, a smooth tween in a non-gameplay state adds no value — the player is
  no longer in a position to be reacting to the offset.*

- **If `state_changed` fires `WAVE_ACTIVE → RUN_PAUSED` while `_trauma > 0`**:
  `_trauma` does not decay during pause and `Camera2D.offset` holds (Rule 8).
  On unpause, decay resumes from the frozen value. *Player-experienced
  behavior: a kill-shake mid-flight when the player paused resumes — it does
  not restart from zero or jump to completion. This is intentional: pausing
  must not erase visual feedback for an in-progress event.*

- **If `shake()` is called during `RUN_LOADING` (before `geometry_baked()` has
  fired)**: silently dropped. *Rationale: Rule 8 enumerates RUN_PAUSED and
  MAIN_MENU as drop states; this extends the rule because the Camera is
  dormant in RUN_LOADING (`_trauma` and offset are uninitialized). The state
  check at the top of `shake()` allows the call only in WAVE_PREP,
  WAVE_ACTIVE, RUN_VICTORY, or RUN_DEFEAT.*

- **If two `shake()` calls arrive in the same `_process` frame** (e.g., two
  kills land on the same tick): D.7 runs twice; each call's increment is added
  to `_trauma` and the clamp at 1.0 protects against overflow. The
  *last-arriving* call's `frequency` parameter wins for the direction-step
  Tween (it resets the resampling timer). *Rationale: the clamp in D.7 is the
  intended saturation mechanism — overlapping high-intensity events produce a
  single combined shake at the cap, not stacked shakes.*

---

### E.2 — Formula Boundary Inputs

- **If `cam_zoom = 0`**: D.1 and D.5 divide by zero. At `RUN_LOADING`, before
  computing bounds, assert `cam_zoom > 0`; if violated, abort to MAIN_MENU
  with a configuration error. *Rationale: Section G locks
  `cam_zoom ∈ [0.1, 4.0]`, so this is a guard against data corruption or a
  malformed level pack — it should never reach runtime in a shipped build.*

- **If `viewport_width_px ≤ 0` or `viewport_height_px ≤ 0` at `RUN_LOADING`**
  (e.g., window minimized during startup): defer the bake-time bounds
  computation until `Window.size_changed` fires with positive values. Run
  State remains in RUN_LOADING during the deferral. If the deferral exceeds
  `bake_total_budget_ms = 500`, the run aborts to MAIN_MENU per ADR-0001.
  *Rationale: a degenerate viewport at the moment of bounds computation would
  set `_safety_margin_px = 0` and silently disable the off-map-geometry
  guard — better to delay until the viewport is real.*

- **If the viewport is resized AFTER `RUN_LOADING`** (e.g., the player toggles
  fullscreen or resizes the window mid-run): bounds and `_safety_margin_px`
  are NOT recomputed; the values from Rule 9 remain in effect for the run's
  duration. The player may see a sliver of off-map geometry near the spawn or
  goal edges if they enlarge the window, or excess inset if they shrink it.
  *Rationale: MVP scope intentionally avoids dynamic bounds recomputation
  (an Open Question for V1, where `Window.size_changed` could trigger a
  recompute). Players who change window size mid-run accept the cosmetic
  drift.*

- **If `frequency ≤ 0` is passed to `shake()`**: clamp at the top of
  `shake()`: `frequency = max(1.0, frequency)`. *Rationale: D.10's
  `1.0 / frequency` would divide by zero; Section G locks `frequency ∈ [1.0,
  60.0]` for authored profiles, but this runtime clamp catches a malformed
  `JuiceProfile.tres` without crashing.*

- **If `amplitude_px = 0` is passed to `shake()`**: D.7 increment = 0,
  `_trauma` unchanged, `Camera2D.offset` unchanged — silent no-op.
  *Rationale: useful for Juice authoring — a profile entry can intentionally
  ship with amplitude 0 to disable shake for a specific event without
  conditional logic at the call site.*

- **If `amplitude_px > cam_shake_max_amplitude_px = 12 px`** (e.g., a Juice
  authoring error sets `amplitude_px = 50`): D.7's clamp caps `_trauma` at
  1.0; D.9's output magnitude is then bounded by
  `cam_shake_max_amplitude_px × _trauma² = 12 px`. The player sees a
  saturated 12 px shake regardless of the requested amplitude — no error, no
  crash, just a hard cap. *Rationale: this is the protection
  `cam_shake_max_amplitude_px` exists to provide; the cap is a feature, not a
  bug.*

- **If `amplitude_px` is NaN or negative**: defensive clamp at the top of
  `shake()`: `amplitude_px = clamp(amplitude_px, 0.0, cam_shake_max_amplitude_px)`
  AND explicit `is_nan()` early-return that drops the call. *Rationale:
  Godot's `clamp()` does not sanitize NaN — NaN propagates through arithmetic
  and would poison `_trauma`. The early-return is necessary for NaN; the
  clamp handles negative.*

- **If `cam_prep_y_offset_cells × cell_size_px` would push the camera past
  `limit_top`** (e.g., a tuning combination of 5 cells × 96 px = 480 px
  against a tight map): `Camera2D` natively clamps `position` to
  `[limit_top, limit_bottom]`. The player sees the offset partially applied —
  the camera moves toward the spawn end and stops at the hard limit, with no
  visual error. *Rationale: D.4 already notes this; restated here so QA
  knows to test the boundary case.*

- **If the lane corridor overflows the viewport width (D.2:
  `lane_corridor_margin_px ≤ 0`)**: abort `RUN_LOADING` to MAIN_MENU with a
  configuration error. The player sees the loading screen replaced with the
  main menu and an error toast/dialog (UI Requirements section to detail).
  *Rationale: this is a design-time data error — e.g., a future level pack
  ships with 4 lanes when the X-lock design only supports 2–3 — not a
  runtime player action. The MVP value of `2 × 5 × 96 = 960 px` against the
  Steam Deck `1707 px` world width has 373 px margin, well clear of the
  invariant.*

- **If the map height inverts the bounds (D.6:
  `goal_zone_south_edge_px − spawn_zone_north_edge_px < 2 × _safety_margin_px`)**:
  abort `RUN_LOADING` to MAIN_MENU. *Rationale: at Steam Deck defaults
  (`_safety_margin_px = 533 px`), this triggers for maps shorter than ~11
  cells of depth. MVP maps are 30 cells deep (`lane_depth_cells_mvp = 30`),
  so this only fires on a misconfigured level pack — same pattern as the
  lane corridor case above.*

---

### E.3 — Contract Failures (Dependency Systems)

- **If `LaneSystem.geometry_baked()` never fires** (Lane/Map bake hangs or
  errors silently): the Camera remains dormant; no bounds, no zoom, no X-pin
  are set. The run cannot transition out of RUN_LOADING. *Resolution: owned
  by the Lane/Map bake budget — `bake_total_budget_ms = 500` triggers a
  Run State abort to MAIN_MENU per ADR-0001 amendment. The Camera takes no
  compensating action; it is freed during the abort teardown.*

- **If `LaneSystem.geometry_baked()` fires more than once during a single
  run** (e.g., a mid-wave re-bake re-fires the same signal): the Camera
  ignores all calls after the first via a `_initialized: bool` guard set in
  the Rule 9 handler. *Rationale: without the guard, a future change to
  bounds (e.g., V1 dynamic resize) would silently re-pin position or re-
  apply zoom mid-run. The guard locks the contract: Camera initializes
  exactly once per run.*

- **If `LaneSystem.geometry_baked()` fires AFTER `state_changed` already
  transitioned to MAIN_MENU** (a delayed bake completes during the abort):
  the Camera's bake-handler checks `GameStateMachine.current_state` at the
  top; if not RUN_LOADING, the signal is ignored. The Camera is freed with
  the Champion scene during MAIN_MENU teardown. *Rationale: the abort path
  is racy by nature; a late signal must be inert.*

- **If the Champion node is freed mid-run** (during a death sequence): the
  Camera is freed with the Champion per Rule 1 (parent-child hierarchy).
  **MVP contract**: the Champion is NOT freed until the
  `RUN_DEFEAT → MAIN_MENU` transition; the death animation, hit-stop
  window, and the RUN_DEFEAT state all run on the still-alive Champion
  node. On the `RUN_DEFEAT → MAIN_MENU` transition the pair is freed
  together; a new Champion+Camera is instantiated on the next RUN_LOADING.
  *Rationale: keeping the Camera alive through RUN_DEFEAT preserves the
  final-blow shake feedback the player needs to see.*

- **If the Champion is never spawned after `RUN_LOADING` completes** (a
  Run State / Champion bug, would not occur in a shipped build): at
  `_ready`, if `get_parent()` is not a Champion node (verified via
  `is_in_group("champion")`), log an error to `production/qa/evidence/` and
  remain dormant. *Rationale: the Camera does not crash on a broken
  contract; it produces no shake and no follow, surfacing the upstream bug
  via the log without taking down the run.*

- **If the Champion is teleported to a world Y outside the camera bounds**
  (a V1 ability that ports the Champion to spawn-end mid-wave): smooth
  Y-tracking (Rule 4) begins toward the new Y, but
  `Camera2D.limit_top/limit_bottom` clamps the camera center. The player
  sees the Champion drift toward the screen edge and then off-screen while
  the camera holds at its hard limit. *Rationale: the boundary invariant
  (no off-map geometry revealed) takes priority over keeping the Champion
  centered. MVP has no teleport mechanic; this contract holds for V1
  abilities.*

- **If `shake()` is called via a deferred call after the Camera has been
  freed** (e.g., a boss-kill VFX timer fires `shake()` but the Champion was
  freed on the same frame by a wave end): a direct method call on a freed
  instance is a null-reference error in Godot. *Mitigation owned by Juice
  GDD #9*: Juice holds a `WeakRef` to the Camera or talks to it via a
  service-locator that returns null safely. **This contract decision is
  flagged in Section H (Open Questions) for resolution when Juice GDD is
  authored.** The Camera itself takes no compensating action; its lifecycle
  is owned by the Champion scene.

## Dependencies

Five direct dependencies. Two are **hard** (system cannot initialize or
function without them) and three are **soft** (system degrades gracefully
when they are absent or misbehaving). All five are already named in
Section C's *Interactions with Other Systems* table; this section adds
direction, hardness, interface field, and bidirectional consistency status
against each dependency's GDD.

### F.1 — Dependency Table

| # | System | Direction | Hardness | Interface contract | GDD Status | Bidirectional check |
|---|---|---|---|---|---|---|
| #7 | Lane / Map | ← (Camera reads) | **Hard** | `LaneSystem.geometry_baked()` signal fires after all MVP lanes bake. Camera reads spawn-zone northernmost Y and goal-zone southernmost Y from map data at that moment (Rule 9, D.5, D.6). | **Approved** (R2.1, 2026-05-02) | ✅ Bidirectional. Lane/Map's Open Question #1 ("expose `camera_bounds: Rect2`?") is **resolved here**: Camera derives bounds independently from lane geometry per Rule 6 + D.6. Lane/Map does NOT need to add a `camera_bounds` field. *(Resolution to be propagated to Lane/Map Section: Open Questions on next revision pass.)* |
| #8 | Run State / Game Flow | ← (Camera subscribes) | **Hard** | `GameStateMachine.state_changed(from, to)` signal drives: (1) Y-offset tween in/out at `WAVE_PREP ↔ WAVE_ACTIVE` (Rule 5), (2) shake suppression in `RUN_PAUSED` / `MAIN_MENU` (Rule 8), (3) bake-failure abort cleanup at `RUN_LOADING → MAIN_MENU` (E.1 third bullet). Camera publishes nothing back. | **Approved** (R3, 2026-05-01) | ✅ One-directional by design — Run State GDD does not mention Camera (correct: Run State owns the state machine, Camera is one of many subscribers and Run State does not need to know which). |
| #1 | Input | — (no runtime dependency) | **Soft (transitive)** | Input reads `get_viewport().get_canvas_transform()` each `_process` to compute `cursor_world_pos_transform` (Input D.1). The viewport canvas transform automatically incorporates Camera2D zoom and position, so Camera's `cam_zoom = 0.75` is reflected in cursor world-position without any explicit interface. Camera takes no action for Input. | **Designed** (2026-05-16; pending `/design-review`) | ✅ Camera-side: matches Input GDD line 357 (Input → Camera classified "Soft — degrades to identity-transform if no camera present, doesn't crash"). **⚠️ Stale text in Input GDD line 182** says "InputBus calls `get_viewport().get_camera_2d()`" — superseded by Input's own D.1 (line 196) + systems-designer note (line 213) which correctly use `get_canvas_transform()`. Flag for Input GDD touch-up via `/propagate-design-change` (not Camera's edit to make). |
| #14 | Champion / Player Controller | ← (Camera reads parent) | **Hard** | Camera2D is a child node of the Champion scene (Rule 1); inherits Champion's world transform automatically via Godot's parent-child hierarchy. Camera also reads `get_parent().is_in_group("champion")` once at `_ready` for contract validation (E.3 fifth bullet). | **Not Started** (provisional) | ⚠️ Provisional contracts Champion #14 must honor when authored: (1) Champion scene contains a Camera2D child node, (2) Champion is in group `"champion"`, (3) Champion is NOT freed until the `RUN_DEFEAT → MAIN_MENU` transition (E.3 fourth bullet — preserves final-blow shake feedback through the death-state window). |
| #9 | Juice / Feedback Pipeline | ← (Camera receives) | **Soft** | Juice calls `Camera.shake(amplitude_px: float, frequency: float)` (Rule 7; signature locked, `duration_ms` removed per D.7 — decay-driven duration). Per-event amplitudes are authored in `JuiceProfile.tres` and must respect the `cam_shake_max_amplitude_px = 12 px` cap (Rule 7, D.7, registry). Camera silently caps amplitudes that exceed the limit (E.2 sixth bullet) — no error raised, no shake refused. | **Not Started** (provisional) | ⚠️ Provisional contracts Juice #9 must honor when authored: (1) per-event amplitude_px ≤ 12 (default values: kill=3, crit=5, boss=8 in `JuiceProfile.tres`), (2) frequency ∈ [1.0, 60.0] Hz, (3) **Juice owns the freed-Camera mitigation** — Juice holds a `WeakRef` to the Camera or talks to it via a service-locator that returns `null` safely, so that a `shake()` call deferred past a wave-end Champion-free does not raise a null-reference error (E.3 seventh bullet). The Camera itself takes no compensating action; its lifecycle is owned by the Champion scene. |

### F.2 — Direction-of-Flow Summary

Camera is **read-only at runtime** in five senses:
1. **Reads** Champion position (via node-tree inheritance — no signal).
2. **Reads** map geometry once at `geometry_baked` (via signal payload).
3. **Reads** run state changes (via signal subscription).
4. **Reads** shake events (via direct method call from Juice).
5. **Reads** viewport (Input reads canvas transform — Camera is the passive provider via Camera2D's automatic registration with the active viewport).

Camera **publishes nothing**. No GDD subscribes to a Camera-emitted signal at MVP. This intentional asymmetry keeps Camera in the lowest-coupling tier — the system can be modified, reskinned, or replaced (e.g., a V1 "cinematic Champion select" camera) without rippling into other GDDs.

### F.3 — Hard vs Soft Dependency Failure Modes

| Dependency | Hardness | Failure mode if dependency is broken |
|---|---|---|
| Lane/Map #7 | Hard | No `geometry_baked` → Camera never initializes → run aborts to MAIN_MENU per ADR-0001 bake gate (E.3 first bullet). |
| Run State #8 | Hard | No state-change signal → Y-offset never tweens, shake never suppresses → game becomes unplayable but does not crash. ADR-0001 is the load-bearing decision. |
| Champion #14 | Hard | No Champion node → Camera2D never attached → no follow target → Camera remains dormant; the dormant-on-broken-contract behavior is the deliberate safe-failure mode (E.3 fifth bullet, logs to `production/qa/evidence/`). |
| Input #1 | Soft | Input fails → no cursor world-position → other systems (Placement #25, Wall #27) fail downstream, not Camera. Camera continues to follow Champion and render shake correctly. |
| Juice #9 | Soft | Juice fails → no `shake()` calls → Camera offset stays at zero, follow continues normally. Game is playable but feels flat. |

### F.4 — Downstream Effects (Camera → other systems)

Camera does not formally publish signals, but its **observable side-effects** affect downstream systems:

| Downstream | What they observe | How |
|---|---|---|
| Placement & Grid #25 | Cursor world-position is correct under Camera zoom (0.75x) | Transitive via Input's `cursor_world_pos_transform` using viewport canvas transform |
| Wall / Fortification #27 | Same as above | Same path |
| Lane / Map #7 mutation API | Same as above (`world_pos: Vector2` argument) | Same path |
| HUD #29 *(when authored)* | HUD elements that anchor to world-space coordinates (e.g., damage numbers) must use Camera-aware projection | Owned by HUD GDD; Camera exposes no helper API |

### F.5 — Cross-System Invariants This GDD Locks

1. **Camera initializes exactly once per run** — the `_initialized` guard (E.3 second bullet) prevents double-initialization even if `geometry_baked` re-fires. Re-bakes do NOT re-configure Camera bounds, zoom, or X-pin.
2. **Viewport resize during a run does NOT recompute bounds** (E.2 third bullet) — V1 may revisit; flagged in Section H Open Questions.
3. **Champion lifecycle owns Camera lifecycle** — Camera is freed iff Champion is freed (Rule 1). Champion #14 must guarantee the death-window contract (alive through RUN_DEFEAT).
4. **`shake()` is the ONLY public mutator** — no other system writes to `Camera2D.offset`, `position`, `limit_*`, or `zoom`. Juice is the sole caller of `shake()`.

## Tuning Knobs

Eight Camera-owned knobs. Each is exposed for designer tuning at MVP via an
exported variable on the Camera scene's root node (no separate config
resource at MVP — promoted to a `CameraProfile.tres` at V1 if needed). Two
additional knob *categories* are referenced for traceability: a registry-
locked constant Camera consumes (`cell_size_px`) and Juice-owned per-event
amplitudes Camera receives via `shake()`.

### G.1 — Camera-Owned Knobs

| Knob | Default | Safe Range | Section ref | What breaks if too low | What breaks if too high | Interacts with |
|---|---|---|---|---|---|---|
| `cam_zoom` | 0.75 | [0.1, 4.0] | C.Rule 2 | <0.5: world too small, lane corridor visually thin, kill-feedback (3 px shake) imperceptible. <0.1 violates D.1 / D.5 divide-by-zero guard (E.2 first bullet). | >1.5: world too large, two lanes can no longer both fit in viewport (D.2 margin → negative, RUN_LOADING aborts). | D.1 (sets viewport world extent), D.2 (corridor fit check), D.5 (safety margin scales with 1/zoom), D.6 (bounds shift). Changing this knob mid-design is high-impact — every other Camera value reshapes. **Do not change after Art Bible pixel-scale lock.** |
| `cam_follow_speed` | 10.0 | [0.1, 100.0] | C.Rule 4, D.3 | <2.0: half-life >350 ms — camera drags behind Champion noticeably, feels sluggish. | >30.0: half-life <23 ms — camera snaps on every micro-input, breaks Pillar 4 readability promise. | D.3 (sets tracking half-life). Independent of all other Camera knobs. Player-tunable via Settings #42 candidate at VS (Open Question). |
| `cam_prep_y_offset_cells` | 2 | [0, 5] | C.Rule 5, D.4 | 0: prep-phase preview disabled (no spawn-side bias). Defensible as accessibility option. | >5: offset exceeds 480 px → Camera2D auto-clamps against `limit_top` (D.4, E.2 eighth bullet). Player sees partial offset; not a crash, but the knob ceases to scale linearly. | D.4 (sets offset px), D.6 (bounds may clip). Player-perceived feel — paired with `cam_offset_transition_s` for total prep-phase visual cadence. |
| `cam_offset_transition_s` | 0.4 | [0.05, 2.0] | C.Rule 5, D.4 | <0.1: prep-offset snaps in instantly, disorienting. | >1.0: transition outlasts the player's planning window; offset still animating in when wave starts, then immediately starts animating out. | D.4 (tween duration). Paired with `cam_prep_y_offset_cells` for prep-phase cadence. Independent of run-state durations (WAVE_PREP duration is Run State / Wave System tuning, not Camera's). |
| `cam_shake_max_amplitude_px` | **12** *(registry-locked)* | [1.0, 30.0] | C.Rule 7, D.7, D.9, **registry: `cam_shake_max_amplitude_px`** | <3: kill-shake (3 px) saturates trauma to 25%; crit/boss values authored in JuiceProfile become indistinguishable. Breaks Pillar 2's "boss kill feels different from regular kill" promise. | >24: full-trauma shake (~24 px) is large enough to lose the Champion mid-shake — breaks Pillar 4 readability during peak feedback moments. | D.7 (trauma normalization denominator), D.9 (output magnitude cap). **Critical pairing**: any change to this cap requires re-tuning the JuiceProfile per-event amplitudes (Juice #9's responsibility), otherwise the trauma curve flattens or saturates inappropriately. |
| `cam_trauma_decay_rate` | 1.5 | [0.1, 10.0] | C.Rule 7, D.8 | <0.5: full-trauma shake takes >2 seconds to fade — feels like the camera is broken, especially under hit-stop. | >5.0: full-trauma shake fades in <200 ms — kill-feel evaporates, Pillar 2 fails. | D.8 (decay arithmetic). Critical pairing with hit-stop: during hit-stop (`Engine.time_scale = 0.05`), decay slows proportionally — see D.8's intentional behavior. Juice #9 owns hit-stop time-scale; do not tune this knob to compensate for hit-stop weirdness. |
| `reduce_motion_amplitude_multiplier` | 1.0 *(off)* / 0.5 *(on)* | {0.0, 0.5, 1.0} discrete | C.Rule 7 parenthetical | 0.0: shake fully disabled — Pillar 2 visual feedback lost for this accessibility tier. **Accessibility requirement: do not silently force 0.0 — this is a player-toggled choice.** | 1.0 is the un-reduced default; values >1.0 would amplify shake and violate the accessibility intent. | All shake math (D.7, D.9). Applied via Juice #9 *before* `shake()` is called — Juice scales the per-event amplitude_px down by this factor when Accessibility System #43 reports Reduce Motion enabled. The Camera itself does not apply this multiplier; it sees a smaller amplitude_px and treats it normally. Tracked in Open Questions until Accessibility GDD lands. |
| `_safety_margin_px` *(derived, not adjustable)* | computed | output of D.5 | C.Rule 6, D.5, D.6 | — | — | Not a knob in the conventional sense — fully determined by `cam_zoom` × `viewport_height_px`. Listed here so designers know it exists and that adjusting `cam_zoom` reshapes the off-map-clip margin. |

### G.2 — Knobs Owned Elsewhere That Camera Consumes

| Knob | Owner | Camera's relationship | Why list it here |
|---|---|---|---|
| `cell_size_px = 96` | Lane / Map #7 (**registry-locked**) | Camera reads it in D.2 (corridor fit), D.4 (prep offset in pixels), D.5 (safety margin cell count). Read-only — Camera never modifies. | Pipeline-binding constant (per registry note). Camera's calculations would silently misalign with the rendered lane corridor if this value drifted; tracking here prevents the inevitable "why is my corridor off-screen" surprise. |
| `lane_count_mvp = 2` | Lane / Map #7 (**registry-locked**) | Camera reads it in D.2 (corridor width). | Same as above. |
| `lane_width_cells_mvp = 5` | Lane / Map #7 (**registry-locked**) | Camera reads it in D.2. | Same as above. |
| Per-event `amplitude_px` (kill=3, crit=5, boss=8) | Juice / Feedback Pipeline #9 (provisional — `JuiceProfile.tres`) | Camera receives these via `shake(amplitude_px, frequency)` calls. Camera enforces only the cap (`cam_shake_max_amplitude_px = 12`); it does not validate the relative ordering of event amplitudes. | Listed because the *feel* of kill / crit / boss-kill differentiation lives at the intersection of these Juice-owned values and Camera's `cam_shake_max_amplitude_px` cap. Tuning one without the other produces flat or saturated kill-feel — both GDDs share the perceptual outcome. |
| Per-event `frequency` (e.g., 20 Hz) | Juice / Feedback Pipeline #9 (provisional — `JuiceProfile.tres`) | Camera receives via `shake()`; clamps `frequency = max(1.0, frequency)` defensively (E.2 fourth bullet). | Same as above. |

### G.3 — Tuning Pairs to Test Together

When playtesting kill-feel or readability, these pairs must be exercised
*together* — tuning one in isolation can mask a regression in the other.

1. **`cam_shake_max_amplitude_px` ↔ JuiceProfile per-event amplitudes**:
   the cap and the per-event values must be tuned together. If the cap is
   lowered to 8 but kill=3 / crit=5 / boss=8 stay, all events saturate or
   compress; the feel of differentiation collapses.
2. **`cam_trauma_decay_rate` ↔ `Engine.time_scale` during hit-stop**:
   intentional coupling per D.8. Juice owns time_scale tuning; do not
   compensate Camera's decay rate to fix a perceived hit-stop length
   problem.
3. **`cam_prep_y_offset_cells` ↔ `cam_offset_transition_s`**: the
   prep-phase cadence — how far the camera bias goes, and how long it takes
   to get there. Halving one and doubling the other produces visibly
   different feel even though the total animation envelope shifts the same
   amount of pixels.
4. **`cam_zoom` ↔ `lane_corridor_total_px`**: zoom changes alter the
   viewport world-width, which alters whether the lane corridor fits
   (D.2). Designers MUST re-check D.2's `lane_corridor_margin_px > 0`
   invariant after touching either value.

### G.4 — Locked / Do-Not-Tune

These are knobs in name only — values locked by registry, ADR, or
cross-system contract. Treat as constants:

- `cam_shake_max_amplitude_px = 12` (registry-locked; Juice #9 reads this).
- The `frequency ∈ [1.0, 60.0]` clamp in `shake()` (E.2 fourth bullet) is a
  defensive runtime guard, not a tunable range. Authoring outside this
  range in `JuiceProfile.tres` is a Juice authoring error.
- All six Section D formulas. Tweaking the math (e.g., changing `_trauma²`
  to `_trauma³` in D.9) is a design change, not a tuning change — requires
  a new GDD revision and `/design-review`.

## Visual/Audio Requirements

Camera produces visible motion (smooth Y-follow, prep-phase Y-bias tween,
shake offset) and *consumes* audio cues authored elsewhere — but it owns
**none of the art-direction choices** for any of this.

- **Smooth Y-follow feel**: a Pillar 4 readability concern. Tunable via
  `cam_follow_speed` (G.1). Reference feel: "steady breath, never snaps."
  No audio.
- **Prep-phase Y-bias**: a planning-phase preview affordance (G.1
  `cam_prep_y_offset_cells`, `cam_offset_transition_s`). No dedicated
  audio cue from Camera; Run State / Wave System may pair the transition
  with a prep-phase ambient cue (their GDDs to specify).
- **Screen-shake**: the visible motion is here; the *art direction* (what
  shake feels like a kill vs a crit vs a boss kill, what frequency reads
  as "snappy" vs "lumbering") lives in **Juice / Feedback Pipeline #9**.
  Per-event `amplitude_px` and `frequency` are authored in
  `JuiceProfile.tres`. Camera is the mechanical executor — it applies the
  math (D.7–D.10) to whatever values Juice supplies, capped at
  `cam_shake_max_amplitude_px = 12`. **When Juice #9 GDD is authored, its
  Visual/Audio section owns the art direction; cross-reference it here.**
- **Hit-stop interaction**: D.8 documents the intentional behavior — trauma
  decays slowly during `Engine.time_scale = 0.05`, holding the shake during
  the slow-motion window. The hit-stop feel itself is Juice-authored;
  Camera honors it.

No Camera-owned asset specs are needed at MVP — there is no sprite,
particle, or audio file Camera ships. The "art" Camera produces is the
*absence* of camera-induced art: no overlay, no tint, no lens flare.

> **📌 Asset Spec**: Not applicable. Camera produces no shippable assets.
> When `/asset-spec system:camera-system` is run, expect "No assets
> required for this system" output.

## UI Requirements

Camera has **no UI of its own** — no menu, HUD widget, button, panel, or
visible chrome. The one UI-adjacent surface in this GDD is the error
toast/dialog referenced in E.2 (lane-corridor-overflow and inverted-bounds
cases at `RUN_LOADING`), and that surface is **owned by Run State #8 + a
future Error UI system** (not yet in the systems index), not by Camera.

- **Settings UI**: Two Camera knobs are candidates for player exposure via
  Settings #42 at VS — `cam_follow_speed` (camera responsiveness) and the
  Reduce Motion toggle (binds to `reduce_motion_amplitude_multiplier` via
  Juice). Settings #42 owns the UI; Camera exposes the underlying values.
  Tracked in Section: Open Questions.
- **Accessibility UI**: Reduce Motion's player-facing surface lives in
  Accessibility #43 (Alpha tier). Camera exposes no UI for this.
- **In-game indicators**: None. The Camera does not render arrows,
  off-screen markers, edge-of-view warnings, or any other UI. If a future
  feature requires "you cannot see that lane right now" feedback (e.g., a
  V1 3-lane configuration where one lane could fall off-screen), it would
  belong in HUD #29 or a dedicated alert system — not in Camera.

> **📌 UX Flag — Camera**: No UI ownership at MVP. **No `/ux-design` pass
> needed for this system.** Settings exposure (above) is tracked under
> Settings #42 + Accessibility #43; Camera surfaces no widgets directly.

## Acceptance Criteria

23 acceptance criteria covering 9 Core Rules, 10 Formulas, 24 Edge Cases,
4 cross-system invariants, and the 0.5 ms/frame performance budget. Audited
by `qa-lead` (2026-05-23) — 22 ACs recommended + 1 added inline per gap
review (AC-CAM-24 for residual-offset snap on victory/defeat). 14 ACs are
BLOCKING (Logic + Integration) and require passing automated tests before
the Camera story can be marked Done. 4 ACs are DEFERRED until Champion #14
or Juice #9 GDDs are authored. An "Implementation Hooks" subsection at the
end captures testability constraints the implementing programmer must
honor.

### AC-CAM-01 — Fixed zoom at 0.75x

**Type:** Logic (BLOCKING)

- **GIVEN** the Camera is initialized at `RUN_LOADING`
- **WHEN** `Camera2D.zoom` is read immediately after initialization completes
- **THEN** `Camera2D.zoom == Vector2(0.75, 0.75)` and the value remains unchanged through `WAVE_PREP`, `WAVE_ACTIVE`, `RUN_PAUSED`, `RUN_VICTORY`, `RUN_DEFEAT`

### AC-CAM-02 — X-axis locked to map horizontal center

**Type:** Logic (BLOCKING)

- **GIVEN** a map is baked with a known horizontal midpoint X
- **WHEN** the Champion moves to Y positions spanning the full map depth
- **THEN** `Camera2D.position.x` equals the map horizontal midpoint at every sampled frame; it never deviates

### AC-CAM-03 — Y-axis smooth-follow converges within half-life

**Type:** Logic (BLOCKING)

- **GIVEN** `cam_follow_speed = 10.0` and the Champion steps instantaneously to a Y position `E` pixels away
- **WHEN** 70 ms of simulation time elapses (using injected delta, not wall-clock)
- **THEN** the remaining Y error is ≤ `0.5 × E` (i.e., the error has halved, per D.3 half-life ≈ 69 ms); at 60 fps the discrete error falls to ≤ `0.5 × E` within 4 frames of the formula-predicted half-life window

### AC-CAM-04 — Viewport world extent formula (D.1)

**Type:** Logic (BLOCKING)

- **GIVEN** `viewport_width_px = 1280`, `viewport_height_px = 800`, `cam_zoom = 0.75`
- **WHEN** D.1 is evaluated
- **THEN** `viewport_world_width_px == 1706.67 px` (±0.01 px floating-point tolerance) AND `viewport_world_height_px == 1066.67 px` (±0.01 px)

### AC-CAM-05 — Lane corridor fit check (D.2) passes for MVP and aborts on overflow

**Type:** Logic (BLOCKING)

- **GIVEN** MVP defaults: `lane_count = 2`, `lane_width_cells = 5`, `cell_size_px = 96`, `cam_zoom = 0.75`, viewport 1280×800
- **WHEN** D.2 is evaluated at `RUN_LOADING`
- **THEN** `lane_corridor_margin_px == 373.33 px` (±0.01 px) and initialization succeeds

**AND**

- **GIVEN** a configuration where `lane_count = 4` (overflow case, `margin_px ≤ 0`)
- **WHEN** `RUN_LOADING` evaluates D.2
- **THEN** the run aborts to `MAIN_MENU` before reaching `WAVE_PREP`; no play state is entered

### AC-CAM-06 — Safety margin and world bounds computed correctly (D.5, D.6)

**Type:** Logic (BLOCKING)

- **GIVEN** viewport height 800 px, `cam_zoom = 0.75`, map with `spawn_zone_north_edge_px = 0`, `goal_zone_south_edge_px = 3000`
- **WHEN** D.5 and D.6 are evaluated
- **THEN** `_safety_margin_px == 533.33` (±0.01), `limit_top == 533.33` (±0.01), `limit_bottom == 2466.67` (±0.01), and `limit_top < limit_bottom` holds

**AND**

- **GIVEN** a map where `goal_zone_south_edge_px − spawn_zone_north_edge_px < 2 × _safety_margin_px` (inverted bounds case)
- **WHEN** `RUN_LOADING` evaluates D.6
- **THEN** the run aborts to `MAIN_MENU`

### AC-CAM-07 — WAVE_PREP Y-offset tween applies correct pixel displacement (D.4)

**Type:** Integration (BLOCKING)

- **GIVEN** `cam_prep_y_offset_cells = 2`, `cell_size_px = 96`, `cam_offset_transition_s = 0.4`
- **WHEN** `state_changed` fires `RUN_LOADING → WAVE_PREP` (or `WAVE_ACTIVE → WAVE_PREP`)
- **THEN** after the tween completes, the camera's Y follow anchor is displaced exactly 192 px toward the spawn end (±1 px); the tween uses `TRANS_SINE, EASE_IN_OUT` and completes in `cam_offset_transition_s` seconds; the Tween was created with `set_ignore_time_scale(true)`

**AND**

- **WHEN** `state_changed` fires `WAVE_PREP → WAVE_ACTIVE`
- **THEN** the offset tweens back to `Vector2.ZERO` over the same duration; after tween completes, `Camera2D.offset.y == 0` (±1 px for rounding)

**Subnote (E.2 eighth bullet)**: if `cam_prep_y_offset_cells × cell_size_px` exceeds the available headroom against `Camera2D.limit_top`, Camera2D auto-clamps; verify on a tight map at `cam_prep_y_offset_cells = 5` that the camera does NOT reveal off-map geometry, even though the requested offset is unreachable.

### AC-CAM-08 — In-flight prep-offset tween is killed before reverse tween starts

**Type:** Integration (BLOCKING)

- **GIVEN** a `WAVE_ACTIVE → WAVE_PREP` transition that starts the prep-offset tween
- **WHEN** `state_changed` fires `WAVE_PREP → WAVE_ACTIVE` while the tween is still animating (i.e., before `cam_offset_transition_s` has elapsed)
- **THEN** the in-flight tween is killed via `_prep_offset_tween.kill()` before the reverse tween is created; no two tweens compete on `Camera2D.offset.y`; the camera reaches `offset.y == 0` within `cam_offset_transition_s` of the interrupt, without jitter or oscillation

### AC-CAM-09 — Trauma accumulation formula (D.7)

**Type:** Logic (BLOCKING)

- **GIVEN** `_trauma_prev = 0.2`, `amplitude_px = 5`, `cam_shake_max_amplitude_px = 12`
- **WHEN** `shake(amplitude_px: 5, frequency: 20)` is called once
- **THEN** `_trauma_new == clamp(0.2 + 5/12, 0.0, 1.0) == 0.6167` (±0.0001)

**AND**

- **GIVEN** `_trauma_prev = 0.9`, `amplitude_px = 5` (overflow case)
- **WHEN** `shake(5, 20)` is called
- **THEN** `_trauma_new == 1.0` (clamped, not 1.317)

### AC-CAM-10 — Trauma decay formula (D.8)

**Type:** Logic (BLOCKING)

- **GIVEN** `_trauma_prev = 0.6167`, `cam_trauma_decay_rate = 1.5`, `delta = 0.01667`
- **WHEN** one `_process` frame runs with injected delta
- **THEN** `_trauma_new == max(0.0, 0.6167 − 1.5 × 0.01667) == 0.5917` (±0.0001)

**AND**

- **GIVEN** `_trauma_prev = 0.01`, `cam_trauma_decay_rate = 1.5`, `delta = 0.01667`
- **WHEN** one `_process` frame runs
- **THEN** `_trauma_new == 0.0` (floored, not negative)

### AC-CAM-11 — Shake offset magnitude obeys quadratic trauma scaling (D.9)

**Type:** Logic (BLOCKING)

- **GIVEN** `_trauma = 0.5`, `cam_shake_max_amplitude_px = 12`
- **WHEN** `camera_shake_offset` magnitude is computed
- **THEN** magnitude == `12 × 0.5² = 3.0 px` (not 6.0 px; the `_trauma²` squaring is the test)

**AND**

- **GIVEN** `_trauma = 1.0`
- **WHEN** offset magnitude is computed
- **THEN** magnitude == `12 px` (cap, i.e., `12 × 1.0² = 12`)

### AC-CAM-12 — Direction step interval formula (D.10)

**Type:** Logic (BLOCKING)

- **GIVEN** `frequency = 20 Hz` passed to `shake()`
- **WHEN** the direction-step Tween is created
- **THEN** the Tween fires each callback every `1.0 / 20 = 0.05 s` (±0.001 s); the Tween uses `set_ignore_time_scale(true)`

**AND**

- **GIVEN** `frequency = 0` (invalid input)
- **WHEN** `shake(amplitude_px: 5, frequency: 0)` is called
- **THEN** frequency is clamped to `max(1.0, 0) = 1.0` before the Tween is created; no division by zero occurs

### AC-CAM-13 — `shake()` calls suppressed in invalid states

**Type:** Integration (BLOCKING)

- **GIVEN** the game is in `RUN_PAUSED` or `MAIN_MENU`
- **WHEN** `shake(amplitude_px: 8, frequency: 20)` is called
- **THEN** `_trauma` is unchanged; `Camera2D.offset` is unchanged; the call returns silently without error

**AND**

- **GIVEN** the game is in `RUN_LOADING` (before `geometry_baked` fires)
- **WHEN** `shake(8, 20)` is called
- **THEN** same silent drop; `_trauma == 0`, `offset == Vector2.ZERO`

### AC-CAM-14 — Camera initializes exactly once per run (`_initialized` guard)

**Type:** Integration (BLOCKING)

- **GIVEN** the Camera has already initialized in response to the first `geometry_baked` signal
- **WHEN** a second `geometry_baked` signal fires (simulated re-bake)
- **THEN** Camera bounds, zoom, and X-pin are NOT re-applied; `Camera2D.limit_top`, `limit_bottom`, `position.x`, and `zoom` retain their first-initialization values unchanged

### AC-CAM-15 — Camera abort cleanup on `RUN_LOADING → MAIN_MENU`

**Type:** Integration (BLOCKING)

- **GIVEN** `geometry_baked` has already fired and Camera is initialized, and a tween may be in progress
- **WHEN** `state_changed` fires `RUN_LOADING → MAIN_MENU` (bake-failure abort path)
- **THEN** `_trauma == 0`, `Camera2D.offset == Vector2.ZERO`, all in-flight tweens are killed (no active Tween callbacks), and Camera disconnects from `GameStateMachine.state_changed` before the Champion scene is freed

### AC-CAM-16 — Trauma held during pause; resumes from frozen value

**Type:** Integration (BLOCKING)

- **GIVEN** `_trauma = 0.6` and a shake is in progress during `WAVE_ACTIVE`
- **WHEN** `state_changed` fires `WAVE_ACTIVE → RUN_PAUSED`
- **THEN** `_trauma` stops decaying (remains at approximately the frozen value across multiple engine frames while paused)

**AND**

- **WHEN** `state_changed` fires `RUN_PAUSED → WAVE_ACTIVE`
- **THEN** decay resumes from the frozen value (not from 0, not from 1.0); `_trauma` continues decreasing on the first frame post-resume

### AC-CAM-17 — Dual same-frame `shake()` calls accumulate correctly

**Type:** Logic (BLOCKING)

- **GIVEN** `_trauma_prev = 0.0` and two kill events fire on the same `_process` frame (`amplitude_px = 3` each)
- **WHEN** both `shake(3, 20)` calls execute before `_trauma` decays
- **THEN** `_trauma == clamp(0 + 3/12 + 3/12, 0, 1) == 0.5`; the second call's `frequency` wins for the direction-step Tween interval; no crash or undefined behavior

### AC-CAM-18 — NaN, negative, and zero amplitude defensive guards

**Type:** Logic (BLOCKING)

- **GIVEN** `amplitude_px = NaN`
- **WHEN** `shake(NaN, 20)` is called
- **THEN** the call returns before modifying `_trauma` (early-return on `is_nan()` check); `_trauma` is unchanged; no NaN propagates into `Camera2D.offset`

**AND**

- **GIVEN** `amplitude_px = -5`
- **WHEN** `shake(-5, 20)` is called
- **THEN** `amplitude_px` is clamped to `0.0`; `_trauma` is unchanged (zero increment); no crash

**AND** *(E.2 fifth bullet — silent no-op subcase)*

- **GIVEN** `amplitude_px = 0`
- **WHEN** `shake(0, 20)` is called
- **THEN** `_trauma` and `Camera2D.offset` are both unchanged; the call returns silently; the direction-step Tween is NOT created (no needless tween churn for zero-amplitude calls)

### AC-CAM-19 — Smooth Y-follow feel at default settings *(DEFERRED)*

**Type:** Visual/Feel (ADVISORY)
**DEFERRED until:** Champion #14 GDD authored AND playable build exists.

- **GIVEN** `cam_follow_speed = 10.0` and the Champion moving at normal combat speeds
- **WHEN** a QA tester plays a full wave on the Tier-2 primary reference (Steam Deck OLED)
- **THEN** the camera follows without visible snapping on micro-inputs; the battlefield remains readable mid-movement; no tester describes the camera as "lagging behind" or "snapping"; screenshot evidence filed to `production/qa/evidence/cam-follow-feel-[date].png`

### AC-CAM-20 — Prep-phase camera bias feel *(DEFERRED)*

**Type:** Visual/Feel (ADVISORY)
**DEFERRED until:** Champion #14 GDD authored AND playable build exists with both WAVE_PREP and WAVE_ACTIVE states operational.

- **GIVEN** `cam_prep_y_offset_cells = 2`, `cam_offset_transition_s = 0.4`
- **WHEN** the game transitions to `WAVE_PREP` and the player observes the camera shift
- **THEN** the player can see more of the spawn-end approach corridor without the shift feeling disorienting; the tween reads as a smooth, deliberate pan, not a snap; lead sign-off filed to `production/qa/evidence/cam-prep-feel-[date].png`

### AC-CAM-21 — Shake intensity differentiates kill / crit / boss-kill *(DEFERRED)*

**Type:** Visual/Feel (ADVISORY)
**DEFERRED until:** Juice #9 GDD authored AND `JuiceProfile.tres` is populated.

- **GIVEN** kill (`amplitude_px = 3`), crit (`amplitude_px = 5`), and boss-kill (`amplitude_px = 8`) events authored in `JuiceProfile.tres` with `cam_shake_max_amplitude_px = 12`
- **WHEN** a QA tester triggers all three event types in sequence
- **THEN** the player perceives three visually distinct shake intensities; boss-kill is noticeably more intense than crit, which is noticeably more intense than kill; no event feels like "no shake at all"; screenshot/video evidence filed to `production/qa/evidence/cam-shake-differentiation-[date]`

### AC-CAM-22 — Tuning knob defaults pass smoke check

**Type:** Config/Data (ADVISORY)

- **GIVEN** the Camera scene exported variables are set to their GDD defaults: `cam_zoom = 0.75`, `cam_follow_speed = 10.0`, `cam_prep_y_offset_cells = 2`, `cam_offset_transition_s = 0.4`, `cam_shake_max_amplitude_px = 12`, `cam_trauma_decay_rate = 1.5`
- **WHEN** the smoke-check script reads the Camera scene's exported properties
- **THEN** all six values match the GDD Section G defaults (exact equality for int/discrete values; ±0.001 for floats); no value is outside its declared safe range

### AC-CAM-23 — Camera frame budget: ≤ 0.5 ms per frame including shake math and smoothing

**Type:** Logic (BLOCKING — performance gate)

- **GIVEN** the Camera running during `WAVE_ACTIVE` with `_trauma = 1.0` (worst-case: full shake active) and the Champion moving
- **WHEN** measured over 300 consecutive frames on Tier-2 primary (Steam Deck OLED), profiler OFF, `Time.get_ticks_usec()` instrumentation around `_process`, results logged to `production/qa/evidence/cam-perf-[date]-steamdeck.md`
- **THEN** p95 Camera `_process` time ≤ 500 µs (0.5 ms); no single sampled frame exceeds 1.0 ms

Note: Camera is a Foundation/Core system. Its budget is 0.5 ms out of the 16.6 ms total frame budget — approximately 3% of the frame. This ceiling allows other foundation systems to share the frame without crowding.

### AC-CAM-24 — Residual offset snaps to zero on victory or defeat

**Type:** Integration (BLOCKING)

- **GIVEN** `Camera2D.offset.y` is non-zero (e.g., the prep-offset tween was interrupted mid-animation by a wave-ending hit)
- **WHEN** `state_changed` fires `WAVE_ACTIVE → RUN_VICTORY` (or `WAVE_ACTIVE → RUN_DEFEAT`)
- **THEN** `Camera2D.offset.y == 0` within one frame of the transition, applied directly (no tween animation); any in-flight prep-offset tween is killed; `_trauma` continues normal decay (shake remains valid during RUN_VICTORY/RUN_DEFEAT per Rule 8 states table)

### Implementation Hooks — Testability Constraints for Programmers

These are non-negotiable constraints on the implementation, surfaced by
`qa-lead` (2026-05-23) during the Section H audit. Honoring them is what
makes the ACs above independently testable.

1. **Injectable delta for D.3 and D.8 tests.** The Camera's `_process(delta)`
   must accept the delta as a parameter and feed both the position-smoothing
   step (D.3) and trauma decay (D.8) from that injected value — not from
   `Engine.get_process_delta_time()` or any other wall-clock source. AC-CAM-03
   and AC-CAM-10 specify *injected delta* explicitly; the test fixture cannot
   construct deterministic timing without this. Recommended pattern: a
   `_process_with_delta(delta: float)` internal method called by `_process` —
   tests call the internal method directly with synthetic deltas.

2. **Observable boundary, not assignment.** AC-CAM-06 asserts the computed
   values of `limit_top` and `limit_bottom`. Do NOT pass the AC by only
   testing the variable assignment. A separate integration test must drive
   Champion to a Y coordinate beyond `limit_bottom` and assert that
   `Camera2D.global_position.y < limit_bottom` — i.e., the engine actually
   clamps the camera. Testing the assignment is necessary but insufficient.

3. **States table behavior must remain discrete.** AC-CAM-07, AC-CAM-08,
   AC-CAM-13, AC-CAM-15, and AC-CAM-16 cover distinct state-transition
   behaviors. Do NOT merge them into a single "camera state machine works"
   test. Each AC owns one signal-driven contract; merging them obscures
   which contract broke when a test fails.

4. **Visual/Feel ACs require perceptual differentiators.** AC-CAM-19, -20,
   -21 are ADVISORY and Visual/Feel, but their THEN clauses contain explicit
   pass/fail language ("player perceives three visually distinct shake
   intensities", "no tester describes the camera as lagging"). Do NOT
   soften these to "shake behaves as expected" during sprint-pressure
   editing — that converts the AC to untestable and downgrades the gate.

5. **D.3 discrete-vs-continuous half-life tolerance.** The formula's
   theoretical 69 ms half-life and Godot's discrete Euler integration's
   ~63 ms half-life differ by ~6 ms. AC-CAM-03 tolerates this by asserting
   "the error has halved within 4 frames of the formula-predicted half-life
   window". Do not tighten this tolerance further without re-running the
   math against Godot's actual `Camera2D.position_smoothing` source.

### AC Test-Type Distribution

| Type | Count | Gate | Location |
|---|---|---|---|
| Logic | 11 | BLOCKING | `tests/unit/camera/` |
| Integration | 7 | BLOCKING | `tests/integration/camera/` |
| Visual/Feel | 3 (all DEFERRED) | ADVISORY | `production/qa/evidence/` |
| Config/Data | 1 | ADVISORY | `production/qa/smoke-[date].md` |
| Performance | 1 | BLOCKING | `production/qa/evidence/` |
| **Total** | **23** | **20 BLOCKING / 3 ADVISORY** | — |

(Of the 3 ADVISORY DEFERRED Visual/Feel ACs, AC-CAM-21 also implicitly
verifies the Juice #9 freed-Camera contract — the test cannot execute the
`shake()` calls without Juice's WeakRef-or-service-locator mitigation in
place. Juice GDD #9 must add its own Section H AC to formally cover that
mitigation.)

## Open Questions

10 items deferred during Sections A–H authoring. Each entry names the
**trigger** (where it surfaced), the **owner** (who resolves it), the **gate**
(when it must be resolved by), and the **plain-English impact** (what the
player or product loses if left unresolved). Items are NOT blockers for the
Camera GDD itself — the GDD ships as Designed pending `/design-review` even
with all 10 unresolved.

### Q1. Viewport-resize bounds recompute (MVP-out, V1-in?)

- **Trigger:** E.2 third bullet; F.5 invariant #2.
- **Owner:** Camera GDD V1 revision.
- **Gate:** V1 planning.
- **Plain-English impact:** At MVP, if a player toggles fullscreen or resizes the window mid-run, the camera will briefly show a sliver of off-map geometry near the spawn or goal edge (if they enlarged the window) or extra inset (if they shrank it). The cosmetic drift is bounded — it does not crash, leak gameplay information, or affect input/aim accuracy. V1 may add a `Window.size_changed` listener to recompute bounds without reloading the run; MVP intentionally skips this complexity. **Resolution:** decide at V1 whether the cosmetic drift is acceptable for the launch product or whether the recompute is mandatory.

### Q2. `cam_follow_speed` player-tunable via Settings #42?

- **Trigger:** G.1 (camera follow speed row), UI Requirements (Settings UI bullet).
- **Owner:** Settings #42 GDD when authored.
- **Gate:** Settings #42 design phase (VS milestone).
- **Plain-English impact:** Camera responsiveness is a personal-preference knob — some players prefer a snappier camera; others want it lazier. At MVP, only a designer can adjust it. At VS, Settings #42 may surface a slider labeled something like "Camera Smoothing" with the GDD's safe range. **Resolution:** Settings #42 design decides whether to expose; Camera GDD requires no change either way.

### Q3. Reduce Motion accessibility binding

- **Trigger:** Rule 7 parenthetical; G.1 `reduce_motion_amplitude_multiplier` row.
- **Owner:** Accessibility #43 GDD when authored.
- **Gate:** Alpha tier.
- **Plain-English impact:** The shake math hook is in place — when the player toggles "Reduce Motion" in Settings, Juice scales the per-event `amplitude_px` down (default 0.5×) before calling `Camera.shake()`. Camera does the same arithmetic; it just sees smaller numbers. The UI toggle itself is owned by Accessibility #43. **Resolution:** Accessibility #43 decides the discrete values (off / on / off-completely), the UI surface, and whether 0.5× is the right default. Camera honors whatever Juice sends.

### Q4. Lane/Map Open Question #1 resolution propagation

- **Trigger:** F.1 row for #7.
- **Owner:** producer (via `/propagate-design-change`).
- **Gate:** Next Lane/Map GDD revision pass.
- **Plain-English impact:** Lane/Map GDD's Open Questions section currently lists "Does Lane/Map expose `camera_bounds: Rect2`, or does Camera derive bounds from lane geometry independently?" as open. This Camera GDD answers it: Camera derives independently. Until that resolution is propagated back, Lane/Map's Open Questions section is stale. **Resolution:** run `/propagate-design-change` (or a small targeted edit) to mark Lane/Map Open Question #1 as resolved with a backreference to Camera Section F.1.

### Q5. Input GDD line 182 stale `get_camera_2d()` reference

- **Trigger:** F.1 row for #1.
- **Owner:** producer or `/propagate-design-change`.
- **Gate:** Next Input GDD touch-up (or as part of `/design-review` on Input #1).
- **Plain-English impact:** Cosmetic documentation bug. The text says InputBus calls `get_viewport().get_camera_2d()` — but the actual D.1 formula uses `get_canvas_transform()` (corrected during Input GDD R2 inline-fix pass). A reader of Input GDD line 182 sees a contradiction with line 196. **Resolution:** Input GDD line 182 needs the same `get_canvas_transform()` text the formula uses. Not Camera's edit to make.

### Q6. Juice #9 freed-Camera mitigation pattern (`WeakRef` vs service-locator)

- **Trigger:** E.3 seventh bullet; F.1 row for #9.
- **Owner:** Juice / Feedback Pipeline #9 GDD.
- **Gate:** Juice #9 design phase.
- **Plain-English impact:** A deferred `shake()` call (e.g., from a boss-kill VFX timer) can fire after the Camera node has been freed during a wave-end teardown. In Godot, calling a method on a freed instance is a null-reference crash. Either Juice keeps a `WeakRef` (and silently no-ops if the target is gone), or Juice goes through a service-locator that returns `null` safely. Both work; the choice affects Juice's internal structure, not Camera. **Resolution:** Juice #9 GDD's Section H must include an AC for whichever pattern is chosen.

### Q7. V1 promotion of tuning knobs to `CameraProfile.tres`

- **Trigger:** G section intro paragraph.
- **Owner:** Camera GDD V1 revision (or VS if a strong case emerges earlier).
- **Gate:** V1 planning (or first request to swap knob bundles between camera modes — e.g., a "cinematic Champion Select" camera).
- **Plain-English impact:** At MVP, designer-tunable values live on the Camera scene's root node as exported variables (one Camera, one set of knobs). At V1, if multiple Camera "profiles" emerge (cinematic, gameplay, photo-mode), promoting to a `CameraProfile.tres` resource lets designers swap whole knob sets at once. The promotion does not change any runtime behavior — it's authoring ergonomics. **Resolution:** decide at V1 whether the multi-profile use case is real enough to justify the indirection.

### Q8. AC-CAM-13 fixture: split pre-bake vs post-bake `RUN_LOADING` drop?

- **Trigger:** Section H, qa-lead audit coverage gap #4.
- **Owner:** Implementing programmer + qa-tester at Camera story-readiness.
- **Gate:** Camera story-readiness review.
- **Plain-English impact:** AC-CAM-13 currently merges two cases (`shake()` during `RUN_LOADING` before `geometry_baked` fires vs during `RUN_PAUSED` / `MAIN_MENU`). Whether the test fixture can distinguish these depends on how the test harness simulates the pre-bake state. If the fixture cannot distinguish, the AC stays merged. If it can, splitting clarifies which contract broke if a future regression fires the call in only one of the two windows. **Resolution:** programmer decides at story authoring; document in story acceptance.

### Q9. D.3 / D.8 injectable-delta interface shape

- **Trigger:** Section H "Implementation Hooks" #1 (qa-lead).
- **Owner:** Implementing programmer + godot-gdscript-specialist at Camera story-readiness.
- **Gate:** Camera story-readiness review.
- **Plain-English impact:** Two of the AC-CAM math tests (AC-CAM-03 for follow half-life, AC-CAM-10 for trauma decay) need deterministic timing — the test injects an exact `delta` value rather than reading wall-clock. The Camera implementation must expose a callable hook (e.g., a `_process_with_delta(delta)` method) that the test can drive directly. The exact method name and signature is implementation detail, but it must exist. **Resolution:** programmer + specialist agree on the hook shape during Camera story authoring; document in code per project standards.

### Q10. `LaneSystem.geometry_baked` payload — exact spawn/goal edge field names

- **Trigger:** F.1 row for #7 ("exact field name TBD when Lane/Map's payload is locked in implementation").
- **Owner:** Implementing programmer at Camera story-readiness; cross-reference Lane/Map story #2 outputs.
- **Gate:** Camera story-readiness OR Lane/Map story implementation (whichever lands first).
- **Plain-English impact:** Camera needs to read the northernmost spawn-zone Y and southernmost goal-zone Y from the geometry-baked payload. Lane/Map's GDD names `spawn_zone_center: Vector2` and `goal_zone_center: Vector2` per-lane; whether those need to be combined with a `spawn_zone_radius` to derive the northern edge, or whether Lane/Map ships a dedicated `spawn_zone_north_edge_px` field, depends on Lane/Map's implementation. **Resolution:** decided when one of the two stories is in implementation; the other story aligns to whichever field shape lands first.
