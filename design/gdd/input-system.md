# Input System

> **Status**: In Design
> **Author**: user + game-designer + claude (orchestrator)
> **Last Updated**: 2026-05-16
> **Implements Pillar**: Pillar 4 (Low skill floor, high expression ceiling)

## Overview

The Input System is the engine-level translation layer between the player's hands and every gameplay system in *Last Stand: Champions*. It is the one Foundation system the player actually touches every frame — keyboard, mouse, and (optionally) gamepad inputs come in, named **actions** (`action_wave_start`, `action_fire`, `action_ability_primary`, `action_place_unit`, `action_pause`, `action_quit_run`, and a small movement-vector bundle) and a **world-space cursor position** go out, and downstream systems (Player Controller, Weapon, Ability, Placement & Grid, Run State, Settings) consume those without ever touching Godot's raw `Input` singleton directly. This system exists for three reasons: **(1)** to give every consumer a stable, named vocabulary so the Run State GDD's reference to `action_wave_start` (Rule 9) and every future Weapon/Ability button references the same source of truth; **(2)** to make the entire control scheme **remappable from day one**, so Settings (#42 — VS) and Accessibility (#43 — Alpha) can be layered on without retrofitting the data structures; and **(3)** to honor Pillar 4 — "anyone who can aim and click should have fun on run 1" — by guaranteeing input is registered within one frame of the press, with no twitch-window or charge-timing requirement built into the layer itself. Authored as a GDScript autoload per ADR-0003 (Input meets no hot-path criterion in §2 of that ADR — it is orchestration, not computation), the system is intentionally thin: it owns the action map, the screen→world cursor transform, and the gamepad-vs-KBM "current input device" flag; it does not own movement, aim assist, ability scheduling, or placement rules — those belong to their respective downstream consumers.

## Player Fantasy

> *Framing: "Your Side of the Pact" — the player and the game enter a small contract; Input keeps the game's end of it.*

The game asks one thing of you — that you press the button. In return, it promises the press is yours, named, and never lost. Move, fire, place, ready up, pause the run — each one has a key, and that key is the one *you* chose. The horde will test your build, your placements, your nerve. It will never test whether your inputs got through.

**What "the press is yours" means in practice (Pillar 4 commitment)**: every press registers within one frame at 60 fps (≤ 16.6 ms from the OS event to the action firing); no input is held back for a "press window" or "charge timer" at the Input layer; every action can be rebound to any key, button, or mouse button from MVP onward; and the system never silently swallows a press because focus drifted or a menu was open elsewhere.

**What Input is NOT promising (so consumers can promise it correctly)**:

- The *feel* of firing a weapon belongs to **Weapon (#15)** — not Input. Input just publishes the press.
- The *feel* of casting an ability belongs to **Ability (#16)**. Input publishes the action; Ability owns the windup, the VFX trigger, the cooldown.
- The *feel* of movement belongs to **Player Controller (#14)**. Input gives the raw vector; the controller decides what acceleration, drag, and turn-rate make Champion 1 feel different from Champion 2 (Pillar 1).
- The *feel* of placing a wall or unit belongs to **Placement & Grid (#25)** and **Wall/Fortification (#27)**. Input gives the world-space cursor and the click; the consumers own snapping, validation, cost, and cooldown.

Input owns the layer **beneath** every felt thing in this game. Its fantasy is the silent guarantee that lets every Champion, every Card, every Wave feel like *itself*.

## Detailed Design

### Core Rules

1. **Named actions are the only interface to player input.** Every consumer system (Player Controller #14, Weapon #15, Ability #16, Placement & Grid #25, Wall/Fortification #27, Card-Roll #22, HUD #29, Run State #8, all menu UIs) reacts only to actions in the vocabulary table below. No system may call `Input.is_action_pressed("hardcoded_literal")` directly. *Rationale*: this rule is what makes rebinding work at all — if even one consumer grep-finds a raw `KEY_W` reference, that key becomes unrebindable without a code change. It also gives QA one grep (`action_*`) to find every input consumer in the codebase.

2. **Every action supports multi-binding. Every action is rebindable.** The action map uses Godot's `InputMap` directly — no custom binding-set abstraction. `InputMap` already stores `Array[InputEvent]` per action, so multi-binding (e.g., both WASD and Arrow keys firing `action_move_*`) is the default behaviour. Settings (#42) surfaces a full rebind UI for every action by MVP; runtime rebinding uses `InputMap.action_erase_events(action)` + `InputMap.action_add_event(action, new_event)`. The data structure distinguishes "default binding" (shipped via `project.godot` and resettable) from "current binding" (player override, persisted via Save/Load #2). *Rationale*: Pillar 4 commitment (c). Accessibility (#43, Alpha) layers on without retrofitting; the cost of building it correctly at MVP is lower than the cost of retrofit.

3. **One-frame guarantee.** Every named action transitions from "OS input event received" to "action signal emitted" within ≤ 16.6 ms at 60 fps — a single frame. Achieved by the InputBus autoload handling raw events in `_input(event)` (which Godot guarantees runs before `_process` in the same frame — relied upon by Run State E2 to resolve the `action_wave_start`-vs-AFK-ceiling race). No action adds a "press window," "charge timer," or "buffer delay" at the Input layer — those mechanics live in consumers per Rule 12. *Rationale*: Pillar 4 commitment (a). Run State E2 explicitly depends on this ordering.

4. **Hybrid publishing model: signals for one-shot edges, polling for held-state.** Edge events (`action_fire_primary`, `action_ability_primary`, `action_pause`, `action_wave_start`, placement actions, card-pick actions, UI navigation, debug) are published as Godot signals (see Signal Contract below). Held-state queries (`get_movement_vector() -> Vector2`, `is_action_held(action: StringName) -> bool`, `cursor_world_pos: Vector2`) are property/method polls. *Rationale*: signals at edge events keep consumer code reactive and testable (Test Harness #45 emits the signals directly without simulating hardware); polling for continuous state matches Godot's design (`Input.get_vector` exists precisely because movement is continuous) and avoids 60+ emissions/sec for data consumers would just cache.

5. **Cursor world-position is owned by InputBus; transform reads from the Viewport's canvas transform.** InputBus exposes `cursor_world_pos: Vector2` (poll-only, updated every frame in `_process` on the autoload). The screen→world transform uses `get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()` — verified correct for Godot 4.6 per systems-designer review 2026-05-16. **NOTE — do NOT use** `get_viewport().get_camera_2d().get_canvas_transform()`: that returns the Camera2D node's own CanvasItem transform (which omits the camera's *zoom effect on the viewport*) and is also null-unsafe during `RUN_LOADING` before the camera is added to the scene. The viewport-level call correctly composes Camera2D position/zoom/rotation AND is null-safe. The full math (with variable table, output range, and worked example) is in Section D Formula D.1. The Lane/Map GDD's `world_pos: Vector2` field on the mutation API (line 229) reads this value. *Rationale*: centralizing the transform prevents three consumers (Placement #25, Wall #27, future targeting) from each computing it independently with slightly different rounding.

6. **Pause-immune actions remain active during `RUN_PAUSED`.** The InputBus autoload runs at `process_mode = PROCESS_MODE_ALWAYS` — same pattern as `GameStateMachine` (Run State Rule 12). The following actions fire even when the scene tree is paused: `action_pause` (to allow unpause), `action_ui_confirm`, `action_ui_cancel`, `action_ui_navigate_*`. All other actions are gated by InputBus checking `GameStateMachine.current_state` and emitting `action_consumed(action)` instead of `action_just_pressed(action)` when game-world actions arrive during `RUN_PAUSED`. **Poll methods (`get_movement_vector()`, `is_action_held()`) are subject to the same state-gated suppression as signals — they return `Vector2.ZERO` / `false` during suppressed states; without this, a `PROCESS_MODE_ALWAYS` consumer that polls would receive live input during pause and silently bypass the signal-suppression contract.** *Rationale*: Run State Rule 4 requires pause to be reachable from any in-run state; the inverse — pause must be navigable while paused — is what this rule guarantees.

7. **Game input is suppressed while a text field has focus.** When `get_viewport().gui_get_focus_owner()` is a `LineEdit` or `TextEdit` (or any node accepting text input), InputBus suppresses all named game-world actions (movement, fire, ability, placement, wave-start). Only `action_ui_confirm`, `action_ui_cancel`, and `action_ui_navigate_*` remain active. *Rationale*: at MVP this matters for Settings' keybind-entry field; at VS this matters for save-slot naming. Without this rule, typing "WASD" into a save name would move the Champion. Standard UI hygiene.

8. **Modal UI suppression is per-state, centralized in InputBus, enforced by InputBus.** When `GameStateMachine.current_state` is `CARD_ROLL`, only `action_card_pick_*`, `action_pause`, and UI navigation/confirm/cancel actions fire — all game-world actions (movement, fire, ability, placement) are suppressed by InputBus emitting `action_consumed` instead. When state is `RUN_PAUSED`, only `action_pause`, UI navigation/confirm/cancel fire. When state is `RUN_PREP`, all gameplay actions fire normally including `action_wave_start`. When state is `WAVE_ACTIVE`, all gameplay actions fire except `action_wave_start` (already active) and `action_card_pick_*`. *Rationale*: centralizing the suppression policy here prevents the bug where Weapon suppresses fire during pause but Ability does not — every consumer reads the same gate from one place.

9. **Reserved actions must always have at least one binding.** Settings (#42) rebind UI must refuse to save a state where `action_pause`, `action_ui_confirm`, or `action_ui_cancel` have zero bindings. The validation runs at save-time; if violated, show an error and revert to the previous valid state (NOT silently re-insert the default — the player may have deliberately displaced the default; revert is more respectful). All other actions may be left unbound at the player's own risk. *Rationale*: a player who accidentally unbinds pause has no path to the pause overlay, which is the only path to Quit-to-Menu — that's a soft-lock, not a binding choice. Player-welfare guardrail.

10. **Quit-the-application is OS-only — no named action.** No `action_quit_app` exists in the vocabulary. Quitting the process is handled by the OS (Alt-F4, window close, Steam overlay quit). The in-game quit flow is `action_pause` → pause overlay → "Quit to Menu" button (activated by `action_ui_confirm`) → `GameStateMachine.quit_run(QUIT)`. *Rationale*: a dedicated quit key creates accidental-quit risk with no user benefit; Run State already requires quit-from-CARD_ROLL to have a confirm dialog (E20) — input cannot bypass that.

11. **Dual-device tie-breaking: most-recent-input-device wins, applied globally — no debounce at MVP.** InputBus tracks `current_input_device: enum { KBM, GAMEPAD }`. The flag flips the moment any event of the other class fires (event-class inspection in `_input`: `InputEventKey`/`InputEventMouse*` → KBM, `InputEventJoypadButton`/`InputEventJoypadMotion` → GAMEPAD). Emits `input_device_changed(device)` signal on flip. No debounce at MVP. *Rationale*: industry-standard pattern (Hades, Dead Cells, Elden Ring on PC); debounce considered but rejected at MVP because the only failure case (player's hand brushes a connected-but-idle gamepad) is rare on PC and easy to add later if playtesting surfaces it. Tracked as Open Question for V1.

12. **Forgiveness mechanics (input buffering, double-tap detection, sticky aim) live in consumers, not InputBus.** InputBus publishes the raw press as a signal with no buffering window. If Weapon #15 needs an early-press grace (player presses fire 80 ms before reload completes), Weapon owns its own queue. If a future Player Controller wants double-tap dash detection, Player Controller owns it. *Rationale*: D2 decision locked. Putting forgiveness in InputBus would couple it to every consumer's readiness state and create ordering problems with `GameStateMachine`. Consumer-owned forgiveness keeps InputBus stateless about game phase.

13. **Signal handlers set intent; `_physics_process` applies it.** Consumer nodes (Player Controller, Weapon, Ability) connect to InputBus signals via Callable form (`InputBus.action_just_pressed.connect(_on_action_just_pressed)`). The handler **sets an intent flag** (e.g., `_wants_to_fire = true`); the actual state change runs in `_physics_process()` which respects `PROCESS_MODE_PAUSABLE` and won't execute while the tree is paused. Direct state mutation inside the signal handler executes regardless of process mode and will violate the pause contract. *Rationale*: signal handlers are direct invocations in Godot — process mode only gates `_process` / `_physics_process` / `_input`. This is a coding rule, not an engine guarantee, but it's the difference between "movement during pause works" and "movement during pause is silently broken."

14. **LMB context-conflict (fire in combat, place-confirm in placement mode) is resolved by consumers, not InputBus.** InputBus publishes both `action_fire_primary` and `action_place_confirm` on every LMB press (both share the LMB default binding). The consumers (Weapon #15 and Placement & Grid #25) check the relevant state — placement-mode-active vs. placement-mode-idle — and ignore the action when it's not theirs. **The same pattern applies to the Esc key (`action_place_cancel` + `action_pause`); see Edge Case E21 in Section E for the consumer-flag protocol Placement & Grid must implement to prevent Esc from simultaneously cancelling placement AND opening the pause overlay.** *Rationale*: alternative is making InputBus aware of placement state, which creates a circular dependency (Input → Placement → Input). Stateless InputBus is the architectural win.

### Action Vocabulary

| Action | Default KB | Default Mouse | Default Gamepad | Trigger | Owning Consumer(s) |
|---|---|---|---|---|---|
| `action_move_up` | W or ↑ | — | Left stick Y− | held / `pressed` | Player Controller (#14) |
| `action_move_down` | S or ↓ | — | Left stick Y+ | held / `pressed` | Player Controller (#14) |
| `action_move_left` | A or ← | — | Left stick X− | held / `pressed` | Player Controller (#14) |
| `action_move_right` | D or → | — | Left stick X+ | held / `pressed` | Player Controller (#14) |
| `action_fire_primary` | — | LMB | Right Trigger (RT) | `pressed` (held = auto-fire if Weapon supports) | Weapon (#15) |
| `action_ability_primary` | Q | — | Right Bumper (RB) | `just_pressed` | Ability (#16) |
| `action_place_confirm` | — | LMB (placement mode) | South face (A/Cross) | `just_pressed` | Placement & Grid (#25), Wall/Fortification (#27) |
| `action_place_cancel` | Esc (placement mode, first press) | RMB | East face (B/Circle) | `just_pressed` | Placement & Grid (#25) |
| `action_place_rotate` | R | Middle mouse | Right shoulder/back-button | `just_pressed` | Placement & Grid (#25), Wall/Fortification (#27) |
| `action_place_next` | Tab (placement mode) | Mouse wheel up | D-pad right | `just_pressed` | Placement & Grid (#25) |
| `action_place_prev` | — | Mouse wheel down | D-pad left | `just_pressed` | Placement & Grid (#25) |
| `action_unit_select_1` | 1 | — | — (no gamepad binding MVP) | `just_pressed` | Placement & Grid (#25) |
| `action_unit_select_2` | 2 | — | — | `just_pressed` | Placement & Grid (#25) |
| `action_unit_select_3` | 3 | — | — | `just_pressed` | Placement & Grid (#25) |
| `action_unit_select_4` | 4 | — | — | `just_pressed` | Placement & Grid (#25) |
| `action_card_pick_1` | 1 | — | D-pad left | `just_pressed` | Card-Roll (#22) |
| `action_card_pick_2` | 2 | — | D-pad up | `just_pressed` | Card-Roll (#22) |
| `action_card_pick_3` | 3 | — | D-pad right | `just_pressed` | Card-Roll (#22) |
| `action_wave_start` | **Space** *(LOCKED — Run State Rule 9 + E2)* | — | South face (A/Cross) | `just_pressed` | Run State (#8) |
| `action_run_summary` | Tab (non-placement) | — | Select/Back | `just_pressed` (toggle) | HUD (#29) |
| `action_pause` | Esc *(when not in placement mode — see Rule 14 / placement Esc precedence)* | — | Start | `just_pressed` | Run State (#8) |
| `action_ui_confirm` | Enter or Space | LMB | A/Cross | `just_pressed` | All menu/overlay UIs (#33, #34, #42) |
| `action_ui_cancel` | Esc | RMB | B/Circle | `just_pressed` | All menu/overlay UIs |
| `action_ui_navigate_up` | ↑ or W | — | Left stick Y− or D-pad up | `just_pressed` (with repeat) | All menu/overlay UIs |
| `action_ui_navigate_down` | ↓ or S | — | Stick Y+ or D-pad down | `just_pressed` (with repeat) | All menu/overlay UIs |
| `action_ui_navigate_left` | ← or A | — | Stick X− or D-pad left | `just_pressed` (with repeat) | All menu/overlay UIs |
| `action_ui_navigate_right` | → or D | — | Stick X+ or D-pad right | `just_pressed` (with repeat) | All menu/overlay UIs |
| `action_debug_console` | Backtick (`) | — | — | `just_pressed` | Debug Console (DEBUG builds only — stripped in release) |

**Notes on the vocabulary**:

- `action_unit_select_*` and `action_card_pick_*` share keys 1-4. **No collision**: per Rule 8, they fire in mutually exclusive states (placement during `RUN_PREP`; card-pick during `CARD_ROLL`) and InputBus's state-gate suppresses the inactive set.
- Multi-binding (WASD + Arrows on movement; Enter + Space on confirm) is the **demonstration** of Rule 2 — proves the data structure supports it.
- Placement-mode Esc is consumed by `action_place_cancel` first (per Rule 14 conflict resolution at the consumer layer); a second Esc with no active placement triggers `action_pause`.
- All gamepad bindings are **partial-support intent**, not a shipping promise. See Section F (Dependencies) for the gamepad strategy.

### Signal Contract

```gdscript
class_name InputBus extends Node

# === Edge events (Hybrid pipeline — Rule 4) ===
signal action_just_pressed(action: StringName)
signal action_just_released(action: StringName)
signal action_consumed(action: StringName)  # fired when InputBus suppresses (state gate, text field focus)

# === Device-switch event ===
signal input_device_changed(device: int)    # InputDevice enum value

# === Properties (poll-only, no signal) ===
# cursor_world_pos: Vector2          — updated every _process; consumers poll
# current_input_device: int          — enum value; consumers poll or connect input_device_changed

# === Methods (held-state, polled by consumers) ===
# get_movement_vector() -> Vector2   — wraps Input.get_vector(&"action_move_left", ...)
# is_action_held(action: StringName) -> bool
# flush_held_states()                — called by Run State on focus-loss / focus-return
```

Enum definition:

```gdscript
class_name InputDevice
enum {
    KBM,        # Keyboard / Mouse
    GAMEPAD,    # Any SDL3-recognized gamepad (4.5+ backend)
}
```

### States and Transitions

InputBus is *near-stateless* — it owns exactly one piece of mutable state at runtime:

| State Field | Type | Initial | When it changes | Persisted? |
|---|---|---|---|---|
| `current_input_device` | `InputDevice` (KBM/GAMEPAD) | `KBM` | Flips on every input event of the *other* class (Rule 11) | No — runtime only |

There is no game-input "state machine" on InputBus itself. The *suppression* state (which actions fire vs. get `action_consumed`) is computed every event by reading `GameStateMachine.current_state` and `get_viewport().gui_get_focus_owner()`. This is a deliberate design choice — InputBus has zero owned state about game phase, so it cannot disagree with Run State.

A simplified flow of one `_input` cycle:

```
OS event arrives
   │
   ▼
InputBus._input(event)
   │
   ├── Update current_input_device if event class differs (Rule 11)
   │
   ▼
For each action in vocabulary:
   if event.is_action_pressed(action, false):
      │
      ▼
   Check suppression:
      ├── text field focused? → emit action_consumed(action), return
      ├── action ∈ always-allowed list? → emit action_just_pressed(action), return
      ├── GameStateMachine.current_state ∈ suppressing-states for this action?
      │     → emit action_consumed(action), return
      └── otherwise → emit action_just_pressed(action)
```

### Interactions with Other Systems

| Consumer System | What it reads / connects to | What InputBus reads from it | `process_mode` | Suppression behavior |
|---|---|---|---|---|
| **Player Controller (#14)** | Polls `get_movement_vector()` each `_physics_process`; connects to `action_just_pressed`/`action_just_released` for any one-shot movement-related action (none at MVP) | — | `PAUSABLE` | Movement suppressed during `RUN_PAUSED`, `CARD_ROLL`, `WAVE_RESULTS`, `RUN_RESULTS`, `MAIN_MENU`, `CHAMPION_SELECT` (InputBus state gate; PlayerController's own `_physics_process` also halts naturally during scene-tree pause) |
| **Weapon (#15)** | Connects to `action_just_pressed(&"action_fire_primary")`; polls `is_action_held(&"action_fire_primary")` for auto-fire support | — | `PAUSABLE` | Fire suppressed during `RUN_PAUSED`, `CARD_ROLL`, `WAVE_RESULTS`. Also suppressed locally by Weapon when placement mode is active (Rule 14 LMB conflict). |
| **Ability (#16)** | Connects to `action_just_pressed(&"action_ability_primary")` | — | `PAUSABLE` | Ability suppressed in same states as Weapon. Owns its own queue if forgiveness needed (Rule 12). |
| **Placement & Grid (#25)** | Connects to `action_just_pressed` for `action_place_confirm`, `action_place_cancel`, `action_place_rotate`, `action_place_next`, `action_place_prev`, `action_unit_select_1..4`; polls `cursor_world_pos: Vector2` each frame for the placement ghost | InputBus reads no Placement state; Placement maintains its own `is_placement_mode_active` flag visible to Weapon for LMB conflict | `PAUSABLE` | Placement-actions only fire during `RUN_PREP` and `WAVE_ACTIVE` (mid-wave placement per Lane/Map Rule 8); suppressed elsewhere. |
| **Wall / Fortification (#27)** | Reads same placement-input contract as Placement & Grid (#25) | — | `PAUSABLE` | Same as Placement & Grid. Mid-wave cooldown is owned by Wall/Fort, not InputBus. |
| **Card-Roll (#22)** | Connects to `action_just_pressed` for `action_card_pick_1..3` | — | `ALWAYS` *(needs to receive picks during the CARD_ROLL state regardless of any pause sub-state)* | Card-pick actions only fire during `CARD_ROLL` state. |
| **Run State (#8)** | Connects to `action_just_pressed(&"action_wave_start")` → triggers `transition_to(WAVE_ACTIVE)` from `RUN_PREP`. Connects to `action_just_pressed(&"action_pause")` → calls `pause()` (or `resume()` if `current_state == RUN_PAUSED`). Connects to `input_device_changed` (optional, for analytics) | InputBus reads `GameStateMachine.current_state` continuously for the suppression gate (Rule 8) | `ALWAYS` | `action_wave_start` only fires in `RUN_PREP`; `action_pause` always fires per Rule 6. On focus loss/return, Run State calls `InputBus.flush_held_states()` (see Section E). |
| **HUD (#29)** | Connects to `action_just_pressed(&"action_run_summary")` for the Tab-toggle overlay (Run State Rule 11) | — | `ALWAYS` | `action_run_summary` allowed in any in-run state (RUN_PREP, WAVE_ACTIVE, WAVE_RESULTS, CARD_ROLL, RUN_PAUSED — the overlay reads from GameStateMachine snapshot, not from live game). |
| **Settings (#42, VS)** | Calls `InputMap.action_add_event` / `action_erase_events` directly during rebind. Reads action names from this GDD's vocabulary table as the canonical list. Enforces Rule 9 (reserved actions cannot be unbound) at save-time. | — | `ALWAYS` (it's a menu) | UI confirm/cancel/navigate only. |
| **Accessibility (#43, Alpha)** | Reads vocabulary as remap target list; will add post-MVP remap presets (one-handed, hold-to-toggle conversions). Future feature: per-action assist setting (e.g., "hold-to-fire" toggle off → "tap-to-fire"). | — | `ALWAYS` | Same as Settings. |
| **Test Harness (#45)** | Emits `InputBus.action_just_pressed` signals directly via `emit_signal` in headless tests — no hardware required. Calls `InputMap.action_add_event` with synthetic `InputEventKey` instances for deterministic replay. | — | `ALWAYS` | Bypasses the suppression gate by emitting on `GameStateMachine` directly for state-driving tests; uses InputBus signals for input-handling tests. |
| **Camera (#6)** | InputBus calls `get_viewport().get_camera_2d()` once on each `_process` to perform the screen→world cursor transform (Rule 5). | InputBus does NOT publish any camera-control actions at MVP. | n/a | — |
| **Debug Console (non-shipping)** | Connects to `action_just_pressed(&"action_debug_console")` — DEBUG builds only; the action and its binding are guarded by `OS.is_debug_build()` and stripped in release. | — | `ALWAYS` | Only fires in DEBUG builds. |

**Cross-language note (ADR-0003)**: No C# boundary on InputBus at MVP or V1. Wave (#18, C# batching) does not read input directly — it receives its trigger via `GameStateMachine.state_changed(WAVE_ACTIVE)` after Run State consumes `action_wave_start`. Damage & Health (#13, C# hot-path) is event-driven from gameplay code, not input.

## Formulas

Three formulas. All Input-owned. All consumed by downstream systems.

### D.1 — `cursor_world_pos_transform` (screen→world cursor)

The `cursor_world_pos_transform` formula is defined as:

```
canvas_transform = get_viewport().get_canvas_transform()
mouse_screen_pos = get_viewport().get_mouse_position()
cursor_world_pos = canvas_transform.affine_inverse() * mouse_screen_pos
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `mouse_screen_pos` | `Vector2` | viewport pixels | `[0, viewport_size]` componentwise | Viewport-relative mouse position from `get_viewport().get_mouse_position()` |
| `canvas_transform` | `Transform2D` | engine value | engine-managed | Viewport canvas transform — combines active Camera2D position, zoom, and rotation. Retrieved once per `_process`. Null-safe — always valid as long as a Viewport exists; **does not require the Camera2D node to be present** |
| `cursor_world_pos` | `Vector2` | world units (pixels at zoom=1) | `(−∞, +∞)` componentwise | World-space mouse position; consumed by Placement & Grid (#25), Wall/Fortification (#27), Lane/Map mutation API (`world_pos` argument) |

**Output Range:** `(−∞, +∞)` componentwise, unbounded by this formula. Camera2D limit properties are the practical constraint at runtime; consumers (Placement, Wall) are responsible for clamping to their own valid regions. Values outside the map bounding box are legal outputs and must not crash consumers.

**Example:** Viewport 1920×1080, mouse at center (960, 540), Camera2D centered on world point (640, 960), zoom = 1, no rotation. The viewport's canvas transform encodes camera centering at scale 1. `canvas_transform.affine_inverse() * (960, 540) = (640, 960)` — the cursor at viewport center lands on the world point the camera is centered on. ✓

**Implementation note** (resolves null-camera concern from systems-designer review 2026-05-16): the formula uses `get_viewport().get_canvas_transform()` directly — NOT `get_viewport().get_camera_2d().get_canvas_transform()`. The former is null-safe and correctly composes Camera2D zoom; the latter can fail during `RUN_LOADING` if the camera has not yet been added to the scene, and would return zoom-incorrect results when it does succeed.

**Registry**: This formula will be registered in `design/registry/entities.yaml` under `formulas` in Phase 5, with `referenced_by` listing `design/gdd/input-system.md` and `design/gdd/lane-map-system.md` (the latter consumes `world_pos`). Placement & Grid (#25) and Wall/Fortification (#27) GDDs will be appended when authored.

---

### D.2 — `menu_key_repeat_timing` (held-down menu navigation)

The `menu_key_repeat_timing` formula governs synthetic `action_just_pressed` emissions while a `action_ui_navigate_*` key is held down. Two thresholds gate the emission:

```
fire_initial_repeat    ⟺   (now - last_fire_at) > initial_delay_ms     AND    is_first_repeat_pending
fire_subsequent_repeat ⟺   (now - last_fire_at) > repeat_interval_ms   AND   !is_first_repeat_pending
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `first_press_at` | `int` | ms (`Time.get_ticks_msec()`) | `[0, +∞)` | Wall-clock ms when the key first went down |
| `last_fire_at` | `int` | ms | `[first_press_at, now]` | Wall-clock ms of the most recent fire event (initial press or any repeat) |
| `now` | `int` | ms | `[0, +∞)` | Current `Time.get_ticks_msec()` at this `_process` frame |
| `initial_delay_ms` | `int` | ms | safe range `[200, 500]`, default **300** | Delay before first repeat fires after the initial press. Below 200: accidental repeats on quick tap. Above 500: feels sluggish. Tunable per Section G. |
| `repeat_interval_ms` | `int` | ms | safe range `[80, 200]`, default **100** | Interval between subsequent repeats. Below 80: list empties faster than the player can read. Above 200: fast-scroll feels slow. Tunable per Section G. |
| `is_first_repeat_pending` | `bool` | — | — | True until the first repeat fires; false afterwards for the duration of the hold. Reset on `action_just_released`. |

**Output Range:** at default 300/100, holding a key produces 1 initial press + first repeat after 300 ms + subsequent repeats every 100 ms = **~10 events/sec** while held (after the first 400 ms). The player feels: a deliberate single press, then a brief pause, then a steady scroll.

**Example:** Player holds `action_ui_navigate_down` to scroll a 20-item list. T = 0 ms: first press fires, item 1 → 2 (`first_press_at = last_fire_at = 0`, `is_first_repeat_pending = true`). T = 300 ms: first repeat fires, → 3 (`last_fire_at = 300`, `is_first_repeat_pending = false`). T = 400 ms: → 4. T = 500 ms: → 5. … T = 1000 ms: 9 items navigated. ✓

**Wall-clock vs scene-tree time**: this formula uses `Time.get_ticks_msec()` (wall-clock) rather than scene-tree `delta` accumulation. Reason: menus are navigable during `RUN_PAUSED` where scene-tree time freezes; the menu must keep responding while the run is paused. Wall-clock is also immune to global `Engine.time_scale` changes from hit-stop (Juice Pipeline #9 concern).

**Implementation location**: InputBus, NOT consumers. Reason: this is pure input UX convention with no game-state dependency — every menu shares the same expectation; consumers should not reinvent it. Exception to Section C Rule 12 (forgiveness in consumers), justified because key-repeat is a UX/accessibility convention, not gameplay forgiveness.

---

### D.3 — `stick_deadzone_normalization` (gamepad analog stick)

The `stick_deadzone_normalization` formula converts a raw analog-stick reading into a movement vector with a usable `[0.0, 1.0]` magnitude range. Godot 4.5+ `Input.get_vector()` applies this internally when given a deadzone parameter:

```
raw_vector       = Input.get_vector(&"action_move_left", &"action_move_right",
                                    &"action_move_up",   &"action_move_down",
                                    deadzone_inner)
movement_vector  = raw_vector
```

Internal math performed by Godot's `Input.get_vector()`:

```
normalized_magnitude = clamp((raw_magnitude − deadzone_inner) / (1.0 − deadzone_inner), 0.0, 1.0)
movement_vector      = raw_direction × normalized_magnitude
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `raw_magnitude` | `float` | unitless | `[0.0, 1.0]` | Raw stick distance from center, pre-normalization |
| `raw_direction` | `Vector2` | unit vector or `(0,0)` | unit-length or zero | Raw stick direction |
| `deadzone_inner` | `float` | unitless | safe range `[0.05, 0.20]`, default **0.15** | Radius below which stick input is treated as zero. Matches SDL3 default in Godot 4.5+. Tunable per Section G. |
| `normalized_magnitude` | `float` | unitless | `[0.0, 1.0]` | Remapped magnitude after inner-deadzone removal |
| `movement_vector` | `Vector2` | unitless | `[(−1,−1), (1,1)]` componentwise | Final movement vector returned by `InputBus.get_movement_vector()` |

**Output Range:** magnitude `[0.0, 1.0]` (clamped, cannot exceed 1.0); componentwise `[(−1,−1), (1,1)]`. Direction is the unit vector of the raw stick or the zero vector inside the deadzone.

**Example:** Raw stick at magnitude 0.10 with `deadzone_inner = 0.15` → `normalized_magnitude = clamp((0.10 − 0.15) / 0.85, 0, 1) = 0.0` → player feels no movement (stick is in deadzone). Raw stick at magnitude 0.50 → `normalized_magnitude = (0.50 − 0.15) / 0.85 = 0.412` → Champion moves at 41 % of max speed. Raw stick at magnitude 1.00 → `normalized_magnitude = 1.0` → max speed. The first perceptible movement starts smoothly above the deadzone, NOT with a jump from 0 to ~0.15.

**Why this matters for Pillar 4**: without deadzone normalization, the lowest non-zero stick reading would be `deadzone_inner = 0.15`, which would produce an instant 15 % movement burst the moment the player nudges the stick. That violates the "low skill floor" promise — fine-speed movement would be impossible on a gamepad. With normalization, the player gets a smooth `0 → 1` magnitude curve.

**Implementation note**: `Input.get_vector()` accepts a deadzone parameter natively since Godot 4.x; the formula above is fully encoded in one engine call (`InputBus.get_movement_vector()` is a thin wrapper). The variable table documents what Godot is doing internally so the `deadzone_inner` tuning knob's effect is unambiguous to designers.

## Edge Cases

28 documented edge cases organised into 9 categories. Each case follows the format `**If [condition]**: [exact outcome]. [rationale if non-obvious]`.

### Focus & window state

- **E1 — If the application loses focus while any action is held** (Alt-tab, Steam overlay opens, window minimise, OS focus-loss): InputBus receives `NOTIFICATION_APPLICATION_FOCUS_OUT`, then `GameStateMachine.pause()` fires (Run State Rule 12). InputBus then calls `flush_held_states()` which **snapshots** the held-action table and emits `action_just_released(action)` for each entry from the snapshot (not the live table — protects against mid-dispatch mutation). On focus-return, consumers start from a clean "no keys held" baseline. *Rationale*: Godot does not synthesize key-release events when the OS steals focus; without a flush, `Input.is_action_pressed()` stays true for the held key. This single case covers Alt-tab, Steam overlay, OBS overlay, window minimise, and any other OS focus theft.

### Rebinding

- **E2 — If the player rebinds an action's key while currently holding it** (e.g., rebinds Move Forward to ArrowUp while holding W): the rebind is queued and applied on the next `_process` frame (Settings calls `InputBus.apply_pending_rebind()`, NOT direct `InputMap.action_erase_events` inside the Settings confirm handler). After application, Settings calls `flush_held_states()` before dismissing the rebind overlay. The pause overlay's `RUN_PAUSED` state was already suppressing the held movement during the rebind UI's lifetime, so the player feels nothing change visually.
- **E3 — If the player attempts to save a binding where `action_pause`, `action_ui_confirm`, or `action_ui_cancel` has zero events**: Settings refuses to save and shows an error message naming the specific action (e.g., *"Pause must have at least one binding"*). The binding field reverts to its previous valid state — **NOT silently re-inserted with the default** (player may have deliberately displaced it). Per Rule 9.
- **E4 — If the player rebinds to a key code Godot cannot match** (`KEY_UNKNOWN` or an exotic international key): Settings stores the binding successfully (Godot's `InputMap` does not validate at storage time). The key will silently never fire because hardware events arrive with the same `KEY_UNKNOWN`. Settings displays a warning: *"This key may not work on all keyboards."* The player may save it anyway. Reserved-action rule (Rule 9) still applies — if this would leave a reserved action with no working bindings, save is rejected.
- **E5 — If the player binds `action_pause` AND `action_ui_cancel` to the same key**: both signals fire on that key press. The pause overlay opens (from `action_pause`) and immediately closes (from `action_ui_cancel` closing the top modal). Net effect: nothing visible to the player. Settings displays a warning: *"This binding causes Pause to cancel itself. Are you sure?"* — the player may confirm. Not blocked, because intentional unusual configurations are allowed.

### Multi-device

- **E6 — If both KB and gamepad axes are held simultaneously for movement**: `Input.get_vector()` reads all bound actions across all devices and returns a single normalized `Vector2` with magnitude ≤ 1.0 (engine handles internally). Device flag follows most-recent-device-wins (Rule 11) and may flip mid-frame; movement output remains valid.
- **E7 — If a gamepad disconnects while a button is held**: Godot emits `Input.joy_connection_changed(device_id, connected=false)`. InputBus connects to this signal and calls `flush_held_states()` on disconnect, then emits `input_device_changed(KBM)` to revert the device flag. Without the flush, `Input.is_action_pressed()` may continue returning true for the held button until Godot's internal state catches up.
- **E8 — If a second gamepad is plugged in mid-run**: `Input.joy_connection_changed(device_id, connected=true)` fires. InputBus logs the new device. No state change. The new gamepad's buttons fire actions via the existing InputMap bindings (Godot 4.x uses device-agnostic action matching by default). Device flag changes only on the next actual input event from the new device, per Rule 11.

### Same-frame race conditions

- **E9 — If `action_pause` fires in the same frame `WAVE_ACTIVE → WAVE_RESULTS` would transition**: `_input` runs before `_process`, so `action_pause` is processed first — `current_state` becomes `RUN_PAUSED`, `previous_state = WAVE_ACTIVE`. Wave System's deferred `transition_to(WAVE_RESULTS)` then attempts from `RUN_PAUSED`, which `VALID_TRANSITIONS[RUN_PAUSED]` rejects with a warning log. Run State T5's `_pending_wave_complete` flag picks it up — `resume()` re-fires the deferred transition. Pause wins; wave-complete is replayed on resume.
- **E10 — If `action_card_pick_1` fires in the same frame as `state_exited(CARD_ROLL)`**: `_input` runs before any `_process` state transition. InputBus's suppression gate (snapshot of `current_state` at top of `_input`, per E11) sees `CARD_ROLL` and emits the signal. Card-Roll consumer receives the pick. Any second emission after the state has advanced is dropped by Run State E22's double-fire guard.
- **E11 — If `GameStateMachine.current_state` changes between suppression check and signal emission within the same `_input(event)` call** (a consumer triggers `transition_to(new_state)` in an early signal handler): InputBus **snapshots `current_state` once at the top of each `_input(event)` call** into a local `_state_snapshot` variable, and uses that snapshot for all suppression checks within that call. Re-reading `current_state` mid-dispatch is forbidden. *Rationale*: subtle race that would manifest as "sometimes pause-immune actions get consumed" bugs that are hard to reproduce.
- **E12 — If two bindings for the same action both fire in the same frame** (e.g., A face button AND a second button bound to `action_wave_start`): InputBus tracks a per-frame "already-emitted" set for `just_pressed` events and suppresses duplicates within the same `_input` frame. *Rationale*: Godot's event system can deliver multiple `InputEventJoypadButton` events within one frame; without this dedup, Run State sees `transition_to(WAVE_ACTIVE)` called twice (the second is harmlessly rejected, but Test Harness assertions and consumer logs see noise).

### UI focus & text fields

- **E13 — If a `LineEdit` or `TextEdit` gains focus while movement keys are held**: InputBus's per-event suppression check (Rule 7) suppresses signals for the next `_input` event. Critically, `get_movement_vector()` is a poll and inherits Rule 6's amended poll-suppression — returns `Vector2.ZERO` while a text field has focus.
- **E14 — If a modal closes mid-action-release** (player held an action through a modal lifetime): `action_just_released` fires during `_input` as the modal closes. The release may fire into the now-unsuppressed state without a preceding `action_just_pressed` in the consumer's history. Consumers must guard their intent flags: `if _wants_to_fire: apply(); _wants_to_fire = false` — the intent flag handles the asymmetry, not InputBus. Documented in the signal contract: `action_just_released` may fire without a preceding `action_just_pressed` from the same consumer's perspective.

### Cursor & camera

- **E15 — If the mouse pointer is outside the game window when `cursor_world_pos` is polled**: `get_viewport().get_mouse_position()` returns the last-known in-window position (Godot 4.x default). `cursor_world_pos` is a valid world-space coordinate possibly outside the visible play area. This matches D.1's documented output range `(−∞, +∞)`. Consumers (Placement #25, Wall #27) are responsible for ignoring or clamping to their valid region.
- **E16 — If Camera2D is mid-zoom-transition when `cursor_world_pos` reads canvas transform**: `get_viewport().get_canvas_transform()` reflects the zoom at the moment of the `_process` call. Result may be one-frame-stale relative to the final rendered camera position. Error magnitude bound: `|cursor_world_pos_error| ≤ |cursor_world_pos| × |Δzoom_per_frame|` — at typical tween rates and at a 500-unit world coordinate, ≤ half a cell. Acceptable; tile-snapping in Placement #25 absorbs it.
- **E17 — If the player resizes the window during a press** (developer-mode concern; not a shipping concern): `canvas_transform` may be inconsistent for one frame; maximum one-frame cursor jump, imperceptible to the player. No corrective action in InputBus.

### Action publishing hygiene

- **E18 — If Esc is pressed while placement mode is active** (Rule 14 design gap): Esc has bindings for both `action_place_cancel` (placement mode) and `action_pause` (always). InputBus publishes both — Rule 14 says consumers resolve. **Resolution**: Placement & Grid (#25) MUST set a `_just_cancelled_placement_this_frame` flag when it consumes `action_place_cancel`; the pause consumer in Run State checks this flag before opening the pause overlay and skips the open if true. The flag is cleared at `_process` end. *This is a callable contract Placement & Grid #25 GDD must inherit — listed in Section F.*
- **E19 — If a game-world action (`action_fire_primary`, `action_ability_primary`, etc.) is pressed during `MAIN_MENU`, `CHAMPION_SELECT`, or `RUN_LOADING`**: InputBus's suppression gate explicitly suppresses all game-world actions in these pre-run states. Only UI navigation/confirm/cancel fire. Rule 8's suppression policy is amended to list `MAIN_MENU`, `CHAMPION_SELECT`, `RUN_LOADING` as suppressing-states for every game-world action. *Rationale*: relying on rejected `VALID_TRANSITIONS` returns to swallow the input produces Test Harness noise and consumer log spam.

### Repeat-timing edge cases (Formula D.2)

- **E20 — If the player taps a UI nav key 5 times within 200 ms** (faster than `initial_delay_ms`): each tap fires one immediate `action_just_pressed` per Rule 3. `is_first_repeat_pending` resets to `true` and `last_fire_at = now` on each press. No repeat fires because each release-and-re-press happens within the 300 ms window. Player navigates 5 items. Fast tapping works faster than holding — correct behavior.
- **E21 — If the player releases a held UI nav key at exactly the moment a synthetic repeat would fire**: D.2's repeat emission in `_process` checks `is_action_held(action)` as a precondition before firing. A repeat that would coincide with a release frame is silently dropped. *Implementation requirement: the gate must read `is_action_held()` AFTER `_input` (which processes the release) but BEFORE the repeat condition check in the same `_process` frame.*
- **E22 — If the player presses Down (starting the D.2 timer), then presses Up before `initial_delay_ms` elapses**: D.2 state (`last_fire_at`, `is_first_repeat_pending`) is tracked **per-action**, not as a shared timer — `Dictionary[StringName, RepeatState]`. The Up press starts its own independent timer; the Down state continues if still held, or is cleared on Down's release.
- **E23 — If `action_just_released` fires in the same frame as the initial press (sub-frame tap, OS/hardware-specific)**: D.2's timer state is set on the press and immediately cleared on the release within the same frame; only the initial `action_just_pressed` event fires; no repeat is produced. Benign behavior — documented for completeness.

### Deadzone & stick (Formula D.3)

- **E24 — If the analog stick produces persistent low-magnitude input** (hardware drift): `Input.get_vector()` applies the `deadzone_inner` clamp internally; `normalized_magnitude = 0.0` while drift stays below threshold; player sees no unintended movement. If drift exceeds the threshold, the player can increase `deadzone_inner` via Settings up to the safe-range maximum (0.20). *`deadzone_inner` is exposed as a player-configurable tuning knob per Section G.*

### Internal state hygiene

- **E25 — If `flush_held_states()` is called while a signal handler is mid-dispatch on the call stack**: `flush_held_states()` snapshots the held-state table into a local array, then iterates the snapshot to emit releases. The live table is cleared after the iteration. Re-entrant `flush_held_states()` calls are no-ops. *Rationale*: focus-loss flush could coincide with a deferred signal handler that ran mid-flush; iterating the live table during mutation would corrupt the dispatch.
- **E26 — If a rebind operation is applied while an `action_just_pressed` signal is mid-dispatch**: the rebind is queued via `InputBus.apply_pending_rebind()` and executes on the next `_process` frame, not immediately inside the Settings confirm handler. *Rationale*: `InputMap.action_erase_events(action)` mid-dispatch leaves `is_action_held()` in an inconsistent state for the duration of the handler.
- **E27 — If `OS.is_debug_build()` returns `true` in a release build due to misconfigured export template**: the `action_debug_console` binding itself is stripped at `_ready()` — `if not OS.is_debug_build(): InputMap.action_erase_events(&"action_debug_console")`. Removing the binding means no `InputEventKey` can ever match it, regardless of runtime guards. Belt-and-suspenders.
- **E28 — If `get_movement_vector()` or `is_action_held()` is called by a `PROCESS_MODE_ALWAYS` consumer during `RUN_PAUSED`**: both methods apply the same suppression as signals — return `Vector2.ZERO` and `false` respectively when `GameStateMachine.current_state` is in a movement-suppressing state. *Per amended Rule 6.*

## Dependencies

Input is a **Foundation/Layer-0** system: zero upstream GDD-level dependencies; many downstream consumers. The tables below capture every direction in the dependency graph that this GDD assumes.

### Upstream (this system depends on)

| Dependency | Direction | Nature | Hard / Soft |
|---|---|---|---|
| **Godot 4.6.2 Input subsystem** | depends on | `Input` singleton (`get_vector`, `is_action_just_pressed`, `is_action_pressed`), `InputMap` (`action_add_event`, `action_erase_events`), `InputEvent` subclasses, `_input(event)` callback, `_input` ordering before `_process` (engine guarantee), `Time.get_ticks_msec()` for wall-clock timestamps, SDL3 gamepad backend (4.5+) | **Hard** — engine baseline |
| **ADR-0003 (Language Routing Policy)** | depends on | Locks Input as GDScript (per §2, no hot-path criterion met). Signal contract conventions (no string-based connections; typed Callable form) inherit from this ADR. | **Hard** — policy gate |
| **Camera #6** | reads from | Reads `get_viewport().get_canvas_transform()` each `_process` to compute D.1 `cursor_world_pos_transform`. NOTE — InputBus reads from the Viewport directly (Rule 5), so this is technically an implicit dependency on a Camera2D being in the active scene; without one, the canvas transform is the identity and `cursor_world_pos = mouse_screen_pos`. | **Soft** — Input degrades to identity-transform if no camera present, doesn't crash |
| **Run State #8** | reads from | Reads `GameStateMachine.current_state` snapshot at the top of each `_input(event)` for state-gated suppression (Rule 8 + E11). Connects to `run_paused`/`run_resumed` to call `flush_held_states()` (E1). | **Hard** — without Run State, InputBus cannot gate by phase |

### Downstream (these systems depend on Input)

| Dependent | Direction | Nature of dependency | Hard / Soft | Status |
|---|---|---|---|---|
| **Player Controller #14** | depends on Input | Polls `get_movement_vector()` each `_physics_process`. | Hard | Not Started |
| **Weapon #15** | depends on Input | Connects `action_just_pressed(&"action_fire_primary")`; polls `is_action_held(&"action_fire_primary")` for auto-fire. | Hard | Not Started |
| **Ability #16** | depends on Input | Connects `action_just_pressed(&"action_ability_primary")`. | Hard | Not Started |
| **Placement & Grid #25** | depends on Input | Connects `action_just_pressed` for placement actions (`action_place_confirm`, `action_place_cancel`, `action_place_rotate`, `action_place_next`, `action_place_prev`, `action_unit_select_1..4`); polls `cursor_world_pos`. Owns `_just_cancelled_placement_this_frame` flag for Esc-in-placement (E18). | Hard | Not Started |
| **Wall / Fortification #27** | depends on Input | Same input contract as Placement & Grid. | Hard | Not Started |
| **Card-Roll #22** | depends on Input | Connects `action_just_pressed` for `action_card_pick_1..3`. | Hard | Not Started |
| **Run State #8** | depends on Input | Connects `action_just_pressed(&"action_wave_start")` → triggers `transition_to(WAVE_ACTIVE)` from `RUN_PREP`. Connects `action_just_pressed(&"action_pause")` → calls `pause()`/`resume()`. Calls `InputBus.flush_held_states()` on focus-loss/focus-return. | Hard (mutual) | **Approved** (Run State GDD already cites `action_wave_start`) |
| **HUD #29** | depends on Input | Connects `action_just_pressed(&"action_run_summary")` for Tab-toggle overlay (per Run State Rule 11). | Hard | Not Started |
| **Settings #42** | depends on Input | Reads action vocabulary as canonical list. Calls `InputMap.action_erase_events` + `action_add_event` to apply rebinds. Enforces Rule 9 (reserved actions) at save-time. Calls `InputBus.apply_pending_rebind()` + `flush_held_states()` after a rebind confirms (E2, E26). | Hard | Not Started (VS tier) |
| **Accessibility #43** | depends on Input | Reads vocabulary as remap target list. Will add post-MVP assist features (hold-to-toggle conversions, per-action assist settings). Requires the multi-binding + per-action-rebindable data structure to already exist. | Hard | Not Started (Alpha tier) |
| **Test Harness #45** | depends on Input | Emits `InputBus.action_just_pressed` signals directly via `emit_signal` for headless tests. Calls `InputMap.action_add_event` with synthetic `InputEventKey` instances for deterministic replay. | Hard | Not Started |
| **Lane / Map #7** | indirectly depends on Input | Consumes `world_pos: Vector2` (line 229 of `design/gdd/lane-map-system.md`) via Placement & Grid's pass-through of `cursor_world_pos`. Lane/Map doesn't read InputBus directly. | Soft (transitive) | **Approved** (already cites `world_pos`) |
| **Debug Console (non-shipping)** | depends on Input | Connects `action_just_pressed(&"action_debug_console")` — DEBUG builds only; binding stripped at `_ready()` in release per E27. | Hard | Not in MVP scope |

### Interfaces this GDD owns (consumed by everything in the downstream table)

- **Signals**: `action_just_pressed(action: StringName)`, `action_just_released(action: StringName)`, `action_consumed(action: StringName)`, `input_device_changed(device: InputDevice)`
- **Properties**: `cursor_world_pos: Vector2` (poll), `current_input_device: InputDevice` (poll)
- **Methods**: `get_movement_vector() -> Vector2`, `is_action_held(action: StringName) -> bool`, `flush_held_states() -> void`, `apply_pending_rebind() -> void`
- **Public vocabulary**: 28 named actions (see Section C Action Vocabulary)
- **Formulas owned**: D.1 `cursor_world_pos_transform` (registry-registered in Phase 5), D.2 `menu_key_repeat_timing` (internal), D.3 `stick_deadzone_normalization` (internal, encoded in `Input.get_vector()`)

### Bidirectional consistency check

- ✅ **Run State #8 (Approved)** — its GDD already references `action_wave_start` (Rule 9 + E2). This GDD lists Run State as a downstream consumer. **Match.**
- ✅ **Lane/Map #7 (Approved)** — its GDD references `world_pos: Vector2` (line 229) as "Input world position." This GDD lists Lane/Map as an indirect consumer through Placement & Grid pass-through. **Match.**
- ⚠️ **Run State #8 will need a small amendment** — its consumer table (Section C of `design/gdd/run-state-game-flow.md`) does NOT currently list Input as a dependency. When Run State is next revised, add Input #1 as an upstream dependency. Tracked here as a non-blocking follow-up; surfaced for `/propagate-design-change` after this GDD is Approved.
- ➖ All other downstream GDDs (Player Controller #14, Weapon #15, etc.) are Not Started — their dependency declarations will inherit from this GDD when authored. No bidirectional check possible yet.

### Cross-language note (per ADR-0003)

No C# boundary on Input at MVP or V1. Wave #18 (C# batching) does not read input directly — it receives its trigger via `GameStateMachine.state_changed(WAVE_ACTIVE)` after Run State consumes `action_wave_start`. Damage & Health #13 (C# hot-path) is event-driven from gameplay code, not input. Input lives entirely in GDScript.

## Tuning Knobs

Five tuning knobs total — three numeric (from Formulas D.2 + D.3), two structural (the default-binding set and the suppression policy).

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease | Owner |
|---|---|---|---|---|---|
| `initial_delay_ms` (D.2) | **300 ms** | `[200, 500]` ms | Holding a menu nav key feels more deliberate; accidental tap-and-pause is less likely | First repeat fires sooner; risk of accidental repeats on short taps below 200 ms | Designer (locked in `project.godot` defaults; not player-facing at MVP) |
| `repeat_interval_ms` (D.2) | **100 ms** | `[80, 200]` ms | Slower menu scrolling; long lists feel sluggish above 150 ms | Faster menu scrolling; below 80 ms players cannot read items as they pass | Designer (not player-facing at MVP) |
| `deadzone_inner` (D.3) | **0.15** | `[0.05, 0.20]` | Larger dead zone; absorbs more hardware drift; sluggish fine-control above 0.20 | Smaller dead zone; finer low-speed control; below 0.05 hardware drift starts to bleed in | **Player** (exposed in Settings #42 — accessibility/drift mitigation) |
| **Default key/button bindings** (Section C Vocabulary) | WASD movement, LMB fire, Space wave-start, Esc pause, Q ability, Tab HUD overlay, 1–4 unit/card select, gamepad bindings per partial-support strategy | every action rebindable (Rule 2) | n/a — categorical, not numeric | n/a — categorical, not numeric | Designer (defaults in `project.godot`); **Player** (rebinds via Settings #42) |
| **Suppression-state matrix** (Rule 8) | See Rule 8 Suppression Behavior column of Section C Interactions table — defines which actions fire/get-consumed per `GameStateMachine.current_state` | Categorical | n/a — design-locked categorical | n/a | Designer; downstream Accessibility #43 may add per-action assist overrides at Alpha |

### Interactions between knobs

- **`initial_delay_ms` and `repeat_interval_ms`** are independent in effect but interact in feel. If `initial_delay_ms < repeat_interval_ms`, the first repeat lands BEFORE the steady-rate window — feels like a stutter. Constraint: `initial_delay_ms ≥ repeat_interval_ms` at all values (the default 300 / 100 satisfies this comfortably).
- **`deadzone_inner` and movement feel** — Player Controller #14 will own a separate `movement_acceleration_curve` tuning knob; the two together determine fine-control feel. If a player reports "stick feels jumpy at low speeds," check `deadzone_inner` first (Input layer) and movement acceleration second (Player Controller layer).

### Knobs the GDD intentionally does NOT introduce

- **Input buffer window (ms)** — per D2 decision and Rule 12, forgiveness lives in consumers. Each consumer GDD (Weapon, Ability) will introduce its own buffer-window knob if needed. Input does NOT own a global input-buffer knob.
- **Aim assist strength** — anti-pillar; no aim assist exists in this game. No knob.
- **Sticky aim radius** — same as above. No knob.
- **Mouse sensitivity** — at MVP, this game uses raw mouse position for cursor placement (`get_viewport().get_mouse_position()`). No mouse sensitivity multiplier is applied at the Input layer; OS-level mouse settings carry. If Camera #6 adds zoom-controls or aim-via-mouse-delta features later, that GDD owns mouse-sensitivity. Tracked in Open Questions.
- **Default device** — `current_input_device` starts as `KBM` and flips on first gamepad event (Rule 11). No "preferred device" knob — the player's hands decide.

### Cross-system tuning interactions

- **`initial_delay_ms` / `repeat_interval_ms`** — Settings #42 and Accessibility #43 may want to expose these as player sliders for motor-impairment accommodations. The safe ranges defined above bound those sliders. Locked here; Settings/Accessibility GDDs will inherit when authored.
- **`deadzone_inner`** — Settings #42 surfaces this directly as a "Gamepad stick deadzone" slider with the 0.05–0.20 range. Accessibility #43 may add an upper safe-range bump to 0.30 for severe drift cases at Alpha; until that GDD is written, 0.20 is the ceiling.

## Visual/Audio Requirements

**Input itself has no visual or audio requirements.** Input is the conduit; visual and audio feedback for input events belong to consumers and to other Foundation systems:

| Player event | Visual feedback owner | Audio feedback owner |
|---|---|---|
| Pressing `action_fire_primary` (muzzle flash, projectile, sound punch) | Weapon (#15) + VFX (#4) + Juice Pipeline (#9) | Audio Bus (#3) → routed by Weapon (#15) |
| Pressing `action_ability_primary` (ability cast VFX, telegraph) | Ability (#16) + VFX (#4) | Audio Bus (#3) → routed by Ability (#16) |
| Placement ghost preview, snap confirmation | Placement & Grid (#25) + Wall/Fortification (#27) | Audio Bus (#3) → routed by Placement & Grid (#25) |
| Menu navigation (focus change, confirm, cancel) | Main Menu (#33), Settings (#42), Card-Roll UI (#30), etc. | Audio Bus (#3) → routed by the menu UI |
| Device-switch icon glyph swap (KB↔gamepad) | HUD (#29) — reads `InputBus.current_input_device` and `input_device_changed` signal | n/a — no audio cue planned |
| Rebind in progress (Settings rebind UI overlay) | Settings (#42) | Audio Bus (#3) → routed by Settings (#42) |

**The one visual/audio note Input itself owns** is that the input-device flag (`current_input_device`) is the source of truth for **glyph swapping** across the whole game — when the flag flips, every UI that displays a button hint must re-render with the appropriate glyph set (KB key icons vs. gamepad button icons). Input does not own the glyph assets or the swap-rendering code; it owns the event (`input_device_changed`) that drives both.

## UI Requirements

**Input itself has no in-game UI.** The single piece of UI that consumes Input's vocabulary as a first-class concern is **Settings (#42, VS-tier)** — its rebind screen displays the full 28-action list as the canonical source of truth and provides a per-action rebind affordance. Settings GDD (when authored) inherits these UI requirements from this section:

| Requirement | Owner | When authored |
|---|---|---|
| Rebind screen displays all 28 actions from this GDD's vocabulary table (grouped by category: Movement, Combat, Placement, Card-Pick, Run Flow, UI Navigation, Debug-build-only) | Settings (#42) | VS phase |
| Per-action "Rebind" button captures the next `InputEventKey` / `InputEventMouseButton` / `InputEventJoypadButton` and calls `InputBus.queue_pending_rebind(action, new_event)` | Settings (#42) | VS phase |
| Multi-binding display: each action row shows all currently-bound events as separate removable chips (matching `InputMap.action_get_events(action)`) | Settings (#42) | VS phase |
| Reserved-action lock UI: `action_pause`, `action_ui_confirm`, `action_ui_cancel` rows show a small "Required" badge and refuse zero-binding state per Rule 9 | Settings (#42) | VS phase |
| "Reset to Defaults" affordance restores the `project.godot` shipped bindings for all actions in one click | Settings (#42) | VS phase |
| Gamepad-glyph swap when `current_input_device == GAMEPAD`: rebind labels show gamepad button glyphs instead of key labels (matches glyph-swap rule in Visual/Audio Requirements above) | Settings (#42) + HUD (#29) glyph atlas | VS phase |
| `deadzone_inner` slider (D.3): "Gamepad stick deadzone" with range 0.05–0.20 (lifted to 0.30 at Alpha by Accessibility #43) | Settings (#42) | VS phase |

**Important non-requirement**: Input does NOT render or own any of this UI itself. Settings is responsible for the full UI; Input only provides the data structures and methods Settings calls.

> **📌 UX Flag — Input System**: This system has UI requirements (via Settings #42). In Phase 4 (Pre-Production), when Settings #42 is authored, run `/ux-design` to create a UX spec for the rebind screen before writing Settings epics. The rebind screen should cite both `design/ux/settings-rebind.md` and this GDD's Section C Vocabulary as the canonical action list.

## Acceptance Criteria

24 ACs total. Each follows GIVEN-WHEN-THEN format and carries a **Story Type** label per `.claude/docs/coding-standards.md`: **Logic** (formulas, AI, state machines — automated unit test, blocking gate), **Integration** (multi-system end-to-end — automated integration test, blocking), **Config/Data** (static analysis, vocabulary enumeration, linter rules — smoke-check pass, advisory gate), **Visual/UI** (manual walkthrough). Reviewed against Sections C, D, E by qa-lead 2026-05-16.

### Core Rules

**AC-IN-01 (Rule 1, Config/Data)** — GIVEN the codebase, WHEN a grep is performed for the regex `Input\.is_action[_a-z]*\("` (catches `is_action_pressed`, `is_action_just_pressed`, `is_action_released`, `is_action_just_released` with string-literal first arg) anywhere outside `src/input/` (the InputBus implementation directory), THEN zero matches return. *Test: static linter rule registered in `docs/registry/architecture.yaml` forbidden patterns.*

**AC-IN-02 (Rule 2, Logic)** — GIVEN any of the 28 named actions, WHEN Test Harness calls `InputMap.action_erase_events(action)` followed by `InputMap.action_add_event(action, new_event)`, THEN injecting a synthetic `InputEvent` matching `new_event` fires `InputBus.action_just_pressed(action)` exactly once. AND GIVEN `action_move_up` has both W and Up-arrow bound by default (multi-binding demonstration), WHEN a synthetic W press AND a separately-injected Up-arrow press fire (in successive frames), THEN `InputBus.action_just_pressed(&"action_move_up")` fires once per injection. *Test: parameterized unit test over all 28 actions for rebind path + multi-binding sub-case.*

**AC-IN-03 (Rule 3, Integration)** — GIVEN the InputBus autoload is loaded and the scene tree is running at 60 fps, WHEN Test Harness injects a synthetic `InputEventKey` for any registered action via `Input.parse_input_event(event)` and brackets the call with `Time.get_ticks_usec()` measurements, THEN the elapsed time from `Input.parse_input_event` return to the consumer's `action_just_pressed` callback execution is ≤ 16,600 µs (16.6 ms) p95 over 100 injections. *Test: input-pipeline timing benchmark on Tier-2 reference hardware per `.claude/docs/technical-preferences.md` benchmark methodology.*

**AC-IN-04 (Rule 4, Logic)** — GIVEN `action_fire_primary` (edge event) is pressed AND released, WHEN signals and polls are observed, THEN `action_just_pressed(&"action_fire_primary")` and `action_just_released(&"action_fire_primary")` fire once each, AND `InputBus.is_action_held(&"action_fire_primary")` is true between the events; AND `get_movement_vector()` does not change in response to fire input. AND GIVEN `action_move_left` (held-state) is pressed, WHEN polls are observed, THEN `get_movement_vector().x < 0` while held AND `is_action_held(&"action_move_left") == true`. NOTE — `action_just_pressed(&"action_move_left")` and `action_just_released(...)` MAY also fire (signals fire for all actions); Rule 4 only mandates that Player Controller's primary consumption path is `get_movement_vector()`, not that movement actions produce zero signals. *Test: unit test asserting signal/poll separation and Rule 4 consumer-pattern correctness.*

**AC-IN-05 (Rule 6 — pause-immune actions + poll suppression, Integration)** — GIVEN `GameStateMachine.current_state == RUN_PAUSED`, WHEN `action_pause`, `action_ui_confirm`, `action_ui_cancel`, `action_ui_navigate_up/down/left/right` are pressed, THEN `action_just_pressed(action)` fires for each one. AND GIVEN the same state, WHEN `action_fire_primary`, `action_move_up`, `action_ability_primary`, `action_place_confirm` are pressed, THEN `action_consumed(action)` fires instead of `action_just_pressed(action)`. AND `InputBus.get_movement_vector() == Vector2.ZERO` AND `InputBus.is_action_held(&"action_fire_primary") == false` during the same state. *Test: integration test driving GameStateMachine transitions and verifying signal emissions plus poll-method returns.*

**AC-IN-06 (Rule 7 — text-field suppression, Integration)** — GIVEN a `LineEdit` has keyboard focus via `grab_focus()`, WHEN any game-world action key (e.g., W, LMB) is pressed, THEN `action_consumed(action)` fires (not `action_just_pressed`), AND `InputBus.get_movement_vector() == Vector2.ZERO`, AND `InputBus.is_action_held(&"action_fire_primary") == false`. AND in the same focus state, WHEN `action_ui_confirm`, `action_ui_cancel`, `action_ui_navigate_*` are pressed, THEN `action_just_pressed(action)` fires normally for each (UI actions remain active). *Test: integration test instantiating a LineEdit and asserting signal/poll behavior for both suppressed and allowed action categories.*

**AC-IN-07 (Rule 8 + E19 — suppression-state matrix, Integration)** — GIVEN `GameStateMachine.current_state` cycles through all 9 states (`MAIN_MENU` → `CHAMPION_SELECT` → `RUN_LOADING` → `RUN_PREP` → `WAVE_ACTIVE` → `WAVE_RESULTS` → `CARD_ROLL` → `RUN_PAUSED` → `RUN_RESULTS`), WHEN each of the 28 actions is pressed in each state, THEN the signal emission (`action_just_pressed` vs. `action_consumed`) matches the **suppression truth table** stored at `tests/fixtures/input/suppression_matrix.yaml`. *Test: matrix test, 9 × 28 = 252 assertions; truth table must be authored alongside this AC as a versioned fixture, derived from Section C Rule 8 + Section F Interactions table.*

**AC-IN-08 (Rule 9 — reserved-action zero-binding guard, Integration) [DEFERRED]** — **Prerequisite: Settings #42 GDD authored and Settings rebind UI implemented.** GIVEN the Settings UI rebind flow, WHEN the player attempts to save a binding state where `action_pause`, `action_ui_confirm`, or `action_ui_cancel` has zero events, THEN Settings displays an error naming the specific action AND the binding field reverts to its previous valid state (NOT silently re-inserting the default). *Test: Settings UI integration test; this AC is BLOCKED until Settings #42 lands and inherits this requirement.*

**AC-IN-09 (Rule 10 — no quit-app action, Config/Data)** — GIVEN the InputMap is fully initialized at runtime (after `InputBus._ready()` completes), WHEN the action vocabulary is enumerated via `InputMap.get_actions()`, THEN no entry matches the name `action_quit_app` or any variant. *Test: smoke-check assertion at game-start integration test setup phase.*

**AC-IN-10 (Rule 11 — most-recent-device-wins, Logic)** — GIVEN `InputBus.current_input_device == KBM`, WHEN Test Harness injects a synthetic `InputEventJoypadButton`, THEN `current_input_device == GAMEPAD` AND `input_device_changed(GAMEPAD)` signal fires exactly once. AND separately, GIVEN `current_input_device == GAMEPAD`, WHEN Test Harness injects a synthetic `InputEventKey`, THEN `current_input_device == KBM` AND `input_device_changed(KBM)` fires exactly once. *Test: unit test injecting synthetic events; both directions verified independently.*

**AC-IN-11 (Rule 12 — no forgiveness in InputBus, Config/Data)** — GIVEN the InputBus source code (`src/input/input_bus.gd`), WHEN a grep is performed for the patterns `_buffer`, `_queue`, `Array\[.*Input`, `press_window`, `_accumulator`, `_pending_input`, THEN zero matches return. *Test: static linter rule. NOTE — this AC enforces "no forgiveness logic in InputBus" by code pattern. If implementation requires any of these names for unrelated reasons, the linter rule needs a specific allowlist commit-by-commit. Pair with code review checklist item: "InputBus changes that add state tracking beyond `current_input_device` and per-action D.2 timing tables must be justified in PR description against Rule 12."*

**AC-IN-12 (Rule 13 — intent-flag + `_physics_process`, Integration)** — GIVEN a mock Weapon consumer at `tests/integration/input/mock_weapon.gd` that connects to `action_just_pressed(&"action_fire_primary")` with a handler that sets `_wants_to_fire = true` and an `_physics_process()` that calls `apply_fire()` if `_wants_to_fire` is true, WHEN `get_tree().paused = true` is set AND `action_fire_primary` is then injected via Test Harness, THEN `mock_weapon._wants_to_fire == true` (the handler fired) AND `mock_weapon.apply_fire()` was called **zero** times (`_physics_process` did not run during pause). *Test: integration test with mock consumer following Rule 13 pattern.*

**AC-IN-13 (Rule 14 + E18 — Esc/LMB consumer-flag protocol, Integration)** — GIVEN mock Placement consumer is in placement mode AND has its handler for `action_place_cancel` setting `_just_cancelled_placement_this_frame = true`, AND mock Run State pause consumer reads this flag before opening the pause overlay, WHEN synthetic Esc press is injected, THEN `mock_placement._just_cancelled_placement_this_frame == true` AND the pause overlay was NOT opened in the same frame. AND the **inverse**: GIVEN Placement is NOT in placement mode (`_just_cancelled_placement_this_frame == false`), WHEN synthetic Esc press is injected, THEN the pause overlay IS opened. *Test: integration test exercising both Esc-in-placement and Esc-not-in-placement paths.*

### Formulas

**AC-IN-14 (D.1 — cursor world-position, Logic)** — GIVEN viewport 1920×1080, mouse at (960, 540), Camera2D centered at world (640, 960) with zoom=1.0, WHEN `InputBus.cursor_world_pos` is polled, THEN `cursor_world_pos == Vector2(640, 960)` (D.1 worked example). AND GIVEN the same setup with zoom=2.0 AND mouse at (1440, 540) (a quarter-screen right of center), WHEN `cursor_world_pos` is polled, THEN `cursor_world_pos == Vector2(880, 960)` (at zoom=2 the camera maps 1 viewport-pixel to 0.5 world-pixels; 480 viewport-px right of center = 240 world-px right of camera center). *Test: parameterized unit test with mocked viewport canvas transform.*

**AC-IN-15 (D.2 — menu key-repeat timing, Logic) [PREREQ: D.2 clock-injection hook]** — **Implementation requirement (Open Question — see Section M)**: InputBus exposes a virtual `_get_ticks_ms() -> int` method that returns `Time.get_ticks_msec()` by default and can be overridden by Test Harness for deterministic time-driven tests, analogous to Run State T19's `_get_unix_time()`. GIVEN that hook exists AND `action_ui_navigate_down` is set to held via Test Harness time-injection, WHEN simulated 1 second elapses at default 300/100 timing, THEN `action_just_pressed(&"action_ui_navigate_down")` is emitted exactly 9 times (T=0 initial; T=300 first repeat; T=400/500/600/700/800/900/1000 subsequent repeats), with ±1 emission tolerance for frame-boundary timing. *Test: time-mocked unit test using the injected clock.*

**AC-IN-16 (D.3 — stick deadzone normalization, Logic)** — GIVEN `deadzone_inner = 0.15` (default), WHEN the analog stick produces raw magnitudes 0.10, 0.15, 0.50, 1.00 sequentially via synthetic `InputEventJoypadMotion`, THEN `InputBus.get_movement_vector().length()` returns 0.0, 0.0, 0.412 (±0.001), 1.0 respectively. AND GIVEN `deadzone_inner` is changed to 0.10 via tuning, WHEN raw magnitude 0.12 is injected, THEN result is `(0.12 − 0.10) / (1.0 − 0.10) = 0.022` (±0.001) — non-zero. AND WHEN raw magnitude 0.09 is injected with `deadzone_inner = 0.10`, THEN result is 0.0. *Test: parameterized unit test with synthetic joypad motion events; default + tuning sub-cases.*

### High-Value Edge Cases

**AC-IN-17 (E1 — focus-loss flush, Integration)** — GIVEN `action_move_up` is held (verified via `is_action_held` poll returning true), WHEN Test Harness delivers `NOTIFICATION_APPLICATION_FOCUS_OUT` to InputBus, THEN `action_just_released(&"action_move_up")` is emitted exactly once AND `InputBus.is_action_held(&"action_move_up") == false` afterwards AND `get_movement_vector() == Vector2.ZERO`. *Test: integration test with synthetic focus-out notification.*

**AC-IN-18 (E7 — gamepad disconnect mid-hold, Integration)** — GIVEN a gamepad button bound to `action_fire_primary` is held (verified via synthetic `InputEventJoypadButton`), WHEN `Input.joy_connection_changed(device_id, connected=false)` fires (synthetically), THEN `action_just_released(&"action_fire_primary")` fires exactly once AND `input_device_changed(KBM)` fires AND `is_action_held(&"action_fire_primary") == false`. *Test: integration test simulating gamepad-cable-pull mid-hold; covers E7's zombie-input-state risk on real PC hardware.*

**AC-IN-19 (E11 — state snapshot in `_input`, Integration)** — GIVEN InputBus has a consumer registered with a "malicious" handler that calls `GameStateMachine.transition_to(MAIN_MENU)` inside its `action_just_pressed` callback, AND `current_state` was `RUN_PAUSED` before the input frame, WHEN synthetic `action_pause` and `action_ability_primary` are injected in the same frame (pause first, ability second), THEN BOTH actions are evaluated against the `RUN_PAUSED` snapshot — `action_pause` fires normally (pause-immune in RUN_PAUSED), AND `action_ability_primary` is suppressed via `action_consumed` (per Rule 8 RUN_PAUSED suppression). The post-handler `current_state == MAIN_MENU` is NOT used for the second action's suppression check. *Test: integration test with a malicious-pattern consumer that calls transition_to inside a handler; asserts the snapshot is honoured both before AND after the state-changing handler.*

**AC-IN-20 (E12 — same-frame dedup, Logic)** — GIVEN `action_wave_start` has two bindings (Space + A face button) AND `current_state == RUN_PREP`, WHEN both bindings fire synthetic events in the same `_input` frame, THEN `action_just_pressed(&"action_wave_start")` is emitted **exactly once**. AND symmetrically, WHEN both bindings fire synthetic release events in the same frame, THEN `action_just_released(&"action_wave_start")` is emitted exactly once. *Test: synthetic dual-event injection; verify press and release dedup independently.*

**AC-IN-21 (E26 — rebind queued during dispatch, Integration)** — GIVEN a consumer's `action_just_pressed` handler triggers a Settings rebind operation (calls `InputBus.queue_pending_rebind(action, new_event)`), WHEN the handler returns, THEN `InputMap` for `action` has NOT changed yet AND `is_action_held(action)` returns consistent values for the rest of the current `_input` frame. AND on the next `_process` frame, `InputBus.apply_pending_rebind()` runs AND the `InputMap` is mutated to the new event. *Test: integration test with consumer that initiates rebind from within its signal handler; asserts deferral timing.*

### Forbidden Patterns & Performance

**AC-IN-22 (Performance budget, Logic)** — GIVEN 28 actions registered AND 4 named consumers connected to `action_just_pressed` (`Run State`, `Weapon`, `Ability`, `Placement & Grid` — mocked), WHEN synthetic inputs are injected at 5 Hz (one press + release pair per 200 ms) over a 300-frame window with profiler OFF, THEN InputBus's `_input` + `_process` time per frame is ≤ 0.5 ms p95 on **Tier-2 reference hardware (Steam Deck OLED — primary)** per `.claude/docs/technical-preferences.md` benchmark methodology. Results logged to `production/qa/evidence/input-perf-[YYYY-MM-DD].md` with hardware tier tag, run timestamp, OS/driver version. *Test: performance benchmark following locked methodology (300-frame minimum, profiler OFF, `Time.get_ticks_usec()` instrumentation, p95 reported).*

**AC-IN-23 (ADR-0003 forbidden patterns — string-based signal connections, Config/Data)** — GIVEN the codebase, WHEN a grep is performed for `\.connect\("`, `\.connect\('`, `\.disconnect\("`, `\.disconnect\('` (string-based signal connect/disconnect, deprecated since Godot 4.0 — see ADR-0003 forbidden-pattern table), THEN zero matches return outside auto-generated code. *Test: static linter rule (enforced by `docs/registry/architecture.yaml` forbidden_patterns).*

**AC-IN-24 (E27 — debug action stripped in release, Config/Data)** — GIVEN a release export build OR `OS.is_debug_build()` mocked to return false, WHEN `InputBus._ready()` completes AND `InputMap.get_actions()` is enumerated, THEN no entry named `action_debug_console` exists. *Test: smoke-check assertion run during release-build CI; covers E27 shipping regression risk (debug overlay accidentally exposed in release).*

### Cross-References (do NOT duplicate the test, but verify the cross-reference is in the test suite)

- **`action_pause` vs WAVE_ACTIVE→WAVE_RESULTS race (E9)**: covered by Run State GDD AC-RS-E2. Verify `tests/integration/run-state/test_pause_vs_wave_complete_race.gd` exists and references InputBus's state snapshot. No duplicate Input AC.
- **AFK ceiling vs `action_wave_start` race (Run State E2)**: covered by Run State GDD's existing test. Already documented as a Run State responsibility.

## Open Questions

Seven decisions deferred from the GDD draft for future resolution. Each has an owner and target resolution phase.

| # | Question | Owner | Target Resolution | Notes |
|---|---|---|---|---|
| 1 | **D.2 clock-injection hook implementation pattern** — InputBus needs a virtual `_get_ticks_ms() -> int` method (analogous to Run State T19's `_get_unix_time()`) so AC-IN-15 can run with mocked time. Should it be a virtual on InputBus itself, or a separate `ClockProvider` autoload injected via dependency? | godot-specialist | First sprint of Input System story authoring | Without this hook, AC-IN-15 is not deterministically testable; D.2 menu key-repeat regressions would only surface in real-time playtest. **Blocking for AC-IN-15 to flip from PREREQ to PASS.** |
| 2 | **Mid-run gamepad plug/unplug UX** — should InputBus emit a player-visible notification (toast?) on plug/unplug, or is the silent glyph swap (Section "Visual/Audio Requirements") sufficient? | ux-designer + community-manager | Pre-Alpha playtest | Concept says gamepad is partial-support. Silent swap is cleaner but may confuse players who plugged in mid-combat expecting "controller mode" to be obvious. Resolve via playtest evidence. |
| 3 | **Device-switch debounce policy for V1** — Rule 11 ships at MVP with no debounce (most-recent-input-wins). At V1, should we add a 2-event debounce to prevent flicker when a player's hand brushes an idle gamepad? | game-designer + ux-designer | V1 polish phase | Rule 11 already flags this. Debounce trade-off: 2-event debounce eliminates flicker but adds ~30 ms latency to device-switch. Decision needs playtest data on how often the flicker actually occurs on real hardware. |
| 4 | **Mouse sensitivity ownership** — at MVP this game uses raw mouse position with no sensitivity multiplier; OS settings carry. If Camera #6 later adds zoom controls or aim-via-mouse-delta features, does mouse sensitivity belong to Input, Camera, or Settings? | technical-director + game-designer | When Camera #6 GDD is authored | Currently no knob exists. The first place that would WANT a sensitivity knob is the Camera GDD if it adds free-look. Defer the decision until Camera authoring begins. |
| 5 | **Accessibility deadzone upper-bound at Alpha** — should the `deadzone_inner` ceiling rise from 0.20 to 0.30 to accommodate severe hardware drift cases? | accessibility-specialist + game-designer | When Accessibility #43 GDD is authored | Section G flags this as a planned Alpha bump. Decision can wait until Accessibility GDD authoring. Lifting the ceiling has no MVP cost. |
| 6 | **Forbidden-pattern linter implementation strategy** — AC-IN-01, AC-IN-11, AC-IN-23, AC-IN-24 all enforce grep-based static checks. Should these be (a) shell grep run in CI, (b) a Godot-specific linter (e.g., custom GDLint rules), or (c) entries in `docs/registry/architecture.yaml` forbidden_patterns enforced by `/code-review` skill? | devops-engineer + technical-director | First sprint of Input implementation | Run State's forbidden patterns already use `docs/registry/architecture.yaml`. Lean toward (c) for consistency. Decision affects how Story implementation gates check these ACs. |
| 7 | **UI key-repeat tuning knobs at MVP — designer-only or expose to player?** — `initial_delay_ms` (300) and `repeat_interval_ms` (100) are Designer-owned per Section G. Should Accessibility #43 lift either or both into Settings as player sliders, with the safe ranges as bounds? | accessibility-specialist + ux-designer | Alpha | The Designer-only stance at MVP is conservative; motor-impairment accommodations would benefit from per-player tuning. The cost of exposing them as sliders is small. Defer to Accessibility GDD. |

**Resolution discipline**: Each Open Question above has a stable identifier (Q1–Q7 within this GDD). When resolved, edit the Resolution column with the date and outcome; do NOT delete the row. If a resolution invalidates an Acceptance Criterion, file the AC update via `/propagate-design-change`.
