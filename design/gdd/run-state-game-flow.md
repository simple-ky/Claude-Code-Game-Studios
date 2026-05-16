# Run State / Game Flow System

> **Status**: **Approved** 2026-05-01 — R3 applied + ADRs 0001/0006 propagated (`docs/architecture/change-impact-2026-05-01-run-state.md`)
> **Author**: user + game-designer (with creative-director, systems-designer, qa-lead, ux-designer, godot-specialist consults at section boundaries)
> **Last Updated**: 2026-05-01
> **Revision History**:
> - **R1 (2026-04-28 → 2026-04-30)**: Initial draft via `/design-system` — 11 Core Rules, 9-state table, 13-consumer interactions, 5 formulas, 36 edge cases, 47 ACs, 12 ADR tightenings (T1–T12).
> - **R2 (2026-05-01)**: Applied locked decisions from `/design-review` (5-specialist + creative-director) per `design/gdd/reviews/run-state-game-flow-decisions-2026-05-01.md`. Major changes: prep floor REMOVED (D1); Wave Summary screen DELETED (D2); Tab-toggle run summary ADDED (D3); pause time excluded from leaderboard CONFIRMED (D4); focus-notification handler replaces polling (D5); suspend-save model + wave-start anchor + meta-progress separation LOCKED (D6/D7/D8); pause menu structure + quit text + build summary + gamepad LOCKED (D9–D12). 22 engineering fixes (E1–E22). 5 editorial fixes (ED1–ED5). 4 new Core Rules (15, 16). 3 new formulas (F7 save anchor, F8 meta-progress separation; F1 simplified). 5 new edge cases (E27a–e). 4 new tightenings (T19–T22). New ACs (AC53–AC62) across 3 new groups (15, 16, 17). Total ACs: 62 (was 52).
> - **R3 (2026-05-01)**: Applied 4 inline fixes from second `/design-review` re-review (5-specialist + creative-director). Fixes: (a) Tab-toggle run summary changed from hold-to-show to **press-toggle** (Pillar 4 violation in a Pillar 4 feature — fixed); (b) **Suspend-save mechanic REMOVED entirely** — major scope cut, reversing R2's D6/D7/D8 decisions. Each run is a session; quit-mid-game still grants meta-progress via QUIT outcome but the run cannot be resumed. Save/Load demoted from hard to soft consumer (now only persists meta-currency, achievements, and settings — no run-state snapshot). (c) Wave 10 boss kill gets a 3.0s WAVE_RESULTS beat (vs. 1.5s for waves 1-9) so the final boss has emotional space to land. (d) Plus minor cleanup: stale Wave Summary UI #32 reference removed; T11 forbidden-write rule clarified to exempt test-injection fields; pause overlay handles RUN_LOADING wave-0 display. Deletions: Core Rule 16, F7, F8, E27a-e, AC57-62 (Group 17), tightenings T20-T22, "Save & Resume Later" pause overlay button. **Total ACs: 56** (was 62; AC57-62 deleted).
> **Implements Pillar**: Pillar 4 (Low Skill Floor, High Expression Ceiling) primary; Pillar 1 (Every Champion Plays a Different Game) supporting
> **Governing ADR**: [ADR-0001 Run State / Game Flow](../../docs/architecture/adr-0001-run-state-game-flow.md) — *Proposed*
> **Related ADRs**: [ADR-0003 Language Routing](../../docs/architecture/adr-0003-language-routing-policy.md), [ADR-0006 Save Schema](../../docs/architecture/adr-0006-save-schema-versioning.md)

---

## Overview

The Run State / Game Flow System is the project's authoritative source of truth for *"what phase is the game in?"* — a 9-state machine (`MAIN_MENU`, `CHAMPION_SELECT`, `RUN_LOADING`, `RUN_PREP`, `WAVE_ACTIVE`, `WAVE_RESULTS`, `CARD_ROLL`, `RUN_PAUSED`, `RUN_RESULTS`) that sequences a single run from main-menu through champion select, ten waves of prep/combat/loot/card-roll, and into a victory or defeat screen. It is a Foundation-layer infrastructure system: 12 downstream MVP consumer systems (HUD, Wave & Spawn, Card-Roll, Adaptive Music, Save/Load, Tutorial, Test Harness, Run Results UI, Main Menu, Resource/Economy, Meta-Currency, Leaderboard) read its current state and react to its transition signals; nothing else writes the run's phase. (Wave Summary UI was originally the 13th consumer; deleted from MVP scope on 2026-05-01 per D2 — replaced by a wave-complete toast + Tab-toggle run summary owned by HUD #29.) Without it, each consumer would invent its own phase tracking — producing state desync (HUD showing `PREP` while Wave System has already started spawning), transition-blind consumers (music keeping the combat track during card-roll), and untestable headless runs (Test Harness has no contract to drive against). [ADR-0001](../../docs/architecture/adr-0001-run-state-game-flow.md) is the authoritative implementation contract — the state enum, transition table, signal shape, and pause semantics are locked there; this GDD owns the *design intent*: why these specific phases, what each phase is *for* in the player's run experience, and how phase timing serves the game pillars. **A run is a single session — there is no mid-run save** (R3 reversal of R2's D6/D7/D8). Quit-mid-run still grants meta-progress (currency, unlocks, achievements) via the QUIT outcome path, but the run itself cannot be resumed; each new run starts fresh from Champion Select. This matches the standard roguelite genre contract (Slay the Spire, Dead Cells) and aligns with the concept's 30–60 minute target session length.

## Player Fantasy

> *Indirect — players feel what this system enables, not the system itself.*

Players don't think about Run State — they feel its promise: *the run is yours to control*. You can pause to read a card mid-wave and the horde freezes mid-stride. You can sit in `PREP` as long as you need. You can step away, come back, and the run is exactly where you left it. This system exists so that pacing belongs to the player, not the clock — every mistake is a build choice, never a tempo failure.

**Aligned pillar**: Pillar 4 (Low Skill Floor, High Expression Ceiling). The system's player-facing test, restated from [ADR-0001](../../docs/architecture/adr-0001-run-state-game-flow.md) §*Constraints*: *"pause must work cleanly so players can stop mid-wave to read card descriptions without losing position, build state, or wave progress."* When this fantasy fails — when a paused wave keeps spawning, when resume drops the player out of position, when the build menu can't be read while paused — Pillar 4 has been violated.

**Where consumer systems deliver the actual fantasy**: HUD (#29) keeps wave state visible during pause; Card-Roll (#22) cards must be readable while paused; Adaptive Music (#10) ducks audio cleanly during pause. Run State's role is to give those systems a clean signal contract (`run_paused`, `run_resumed`, `state_changed`) so each can do its part of the *"the run waits for you"* promise.

## Detailed Design

### Core Rules

The Run State / Game Flow System is governed by the following design-intent rules. The technical implementation of each rule is in [ADR-0001](../../docs/architecture/adr-0001-run-state-game-flow.md); this section names the *design intent* each rule serves.

1. **A run is a discrete arc with nine player-experience phases.** Each phase exists because it solves a player problem or enables a consumer-system hook that would otherwise become an embedded sub-state. The 9 phases are the player's full structural experience of a run from first menu open to results screen and back.
2. **One phase at a time. No overlap.** Exactly one `GameState` is active at any moment. No two phases co-exist; no phase has hidden sub-states (with one exception — Pause, see Rule 4). This is the design rule that makes consumer reactions clean and testable.
3. **Phases advance in a fixed forward sequence within a run.** Once the player advances `RUN_PREP → WAVE_ACTIVE`, they cannot return to `RUN_PREP` mid-wave. *Design intent*: forward motion is a roguelite tempo property — the run is a one-way river. Going back would let players test placements against live waves and retry, violating the genre's social contract.
4. **Pause is orthogonal to phase, not a transition-table entry.** `RUN_PAUSED` is reachable from any in-run phase via `pause()` (which bypasses `VALID_TRANSITIONS`) and exits via `resume()` to the previous phase. *Design intent*: pause is a cross-cutting Pillar 4 concession — players must be able to stop the run from any in-run moment without transition-rule friction.
5. **Quit-mid-run is a special transition, also bypassing the table.** A new `quit_run(outcome: int)` API method ends the run from `RUN_PAUSED` (where the pause overlay's "Quit to Menu" lives) by transitioning directly to `RUN_RESULTS` with `outcome = QUIT`. *Design intent*: quitting is a deliberate decision the player makes via the pause overlay; it should NOT require resume-then-end (which would emit misleading `run_resumed` before `run_ended`). **This is a tightening of ADR-0001** — see "ADR-0001 tightening flagged" below.
6. **Run end is one of three outcomes.** `RunOutcome.VICTORY` (wave 10 boss defeated), `RunOutcome.DEFEAT` (player HP=0 in any wave), `RunOutcome.QUIT` (player chose to quit-to-menu via pause overlay). All three transition to `RUN_RESULTS`; the `outcome` value flows through `run_ended(outcome)` to consumers. *Design intent*: the concept's "Death always grants partial meta-currency" rule needs a way to distinguish *I died trying* from *I quit early* — Meta-Currency awards may differ.
7. **Wave count increments at end-of-wave, not start.** `current_wave` increments on entry into `WAVE_RESULTS` (when Wave System's `wave_complete` signal fires). HUD reads "Wave N Results" on WAVE_RESULTS, "Preparing Wave N+1" on the next RUN_PREP (computed at display time). *Design intent*: a crash during prep should resume to "wave N completed, prep for N+1" — not "wave N+1 started but didn't actually start." Save recovery boundary-clean.
8. **`CARD_ROLL` is skip-able.** The player may transition `CARD_ROLL → RUN_PREP` without picking a card; `card_picked` is an optional emission, `card_roll_offered` is required. *Design intent*: forcing a pick is anti-Pillar-3 — build expression must include the right to refuse. Reroll concerns belong in [Card-Roll GDD #22], not here.
9. **`RUN_PREP` advances immediately on player input.** Pressing `action_wave_start` transitions to `WAVE_ACTIVE` within one frame regardless of how long the player has been in `RUN_PREP`. An AFK ceiling auto-advances unattended runs. *Design intent*: the prior 45s floor was paternalism — early-level waves are designed easy enough to win without towers, and the onboarding tutorial covers new-player risk. Pillar 4's "the run waits for you" promise extends to "the run starts when you say so."
10. **Phase pacing is data-driven, not hardcoded.** All phase-timing values (prep floor/ceiling, results auto-advance, anti-AFK timeouts) are tuning knobs — see Section G. *Design intent*: project coding standard mandates data-driven gameplay values; pacing must be tunable without code changes for first playtest.
11. **`GameState` enum values are append-only.** New states added at the end of the enum (after `RUN_RESULTS = 8`). Insertion = save corruption. ADR-0001 §305 + ADR-0006 §40 lock this rule jointly. *Design intent*: the player's persistent run history must remain loadable across patches.
12. **`GameStateMachine` is the sole authority on engine pause.** The autoload runs at `process_mode = PROCESS_MODE_ALWAYS` (so signal handlers fire while paused) and subscribes to `NOTIFICATION_APPLICATION_FOCUS_OUT` / `NOTIFICATION_APPLICATION_FOCUS_IN` via `_notification()`. On focus-out (Steam overlay activation, Alt-Tab, window minimize, OS focus loss), a synthetic `pause()` fires; on focus-in, `resume()` fires. This handles all external pause sources uniformly. *Design intent*: Pillar 4 ("the run waits for you") must hold regardless of *who* paused — players don't care if it was their pause input, the Steam overlay, or an Alt-Tab. `get_tree().paused` polling is rejected because it does not detect Steam overlay (which captures input at OS level without toggling SceneTree.paused) and is unreliable for window minimization. **This is a tightening of ADR-0001 — see T14 in the consolidated table.**
13. **Pause freezes phase timers.** When `pause()` fires, `phase_pause_started_at` is recorded. On `resume()`, `phase_entered_at` is offset forward by the pause duration so F2's auto-advance ceiling counts only *active* time in the phase, not wall-clock. *Design intent*: a 30-minute pause during CARD_ROLL must NOT cause the 5-minute AFK timer to fire on resume. Pillar 4 requires pause-time exclusion at the phase-timer level, not just at the run-elapsed level. **This is a tightening of ADR-0001 — see T13 in the consolidated table.**
14. **Quit-from-CARD_ROLL requires confirmation.** When `quit_run(QUIT)` is invoked while `current_state == CARD_ROLL` (or `previous_state == CARD_ROLL` if paused), the pause overlay MUST present a confirmation dialog before transitioning. Other in-run states quit without confirmation. *Design intent*: the pause overlay renders over the card panel; an accidental click on "Quit Run" while card-pick is open ends the run unintentionally. The confirmation is a destructive-action safeguard, not a card-loss warning (cards are per-run; the actual loss is the run itself). **This is a tightening of ADR-0001 — see T15 in the consolidated table.**
15. **Run summary is overlaid on demand via Tab-toggle input** *(R3: changed from hold-to-show to press-to-toggle)*. Pressing `Tab` (or its rebound equivalent) in any in-run state shows a full run summary overlay — kills, time elapsed, drops, current build, wave count. Pressing `Tab` again, pressing `Esc`, or pressing the gamepad-equivalent dismiss button closes it. The overlay reads from `GameStateMachine` snapshot; it does NOT change run state. *Design intent*: standard genre convention (Slay the Spire's run-screen toggle pattern) — solves the mid-run "how am I doing?" need without screen takeover. Toggle (vs. hold) was chosen because AC47 expects the player to be able to read card descriptions for 60+ seconds; holding a key for that duration is ergonomically hostile and contradicts the very Pillar 4 promise this feature delivers. Owning consumer: HUD #29.

> **Core Rule 16** *(R2 — DELETED in R3)*: was the suspend-save anchor rule. R3 removed the save mechanism entirely; quit-mid-run still grants meta-progress via the QUIT outcome path, but the run cannot be resumed. See Overview for rationale.

### States and Transitions

Design-level summary. The exact `VALID_TRANSITIONS` dictionary is in [ADR-0001 §VALID_TRANSITIONS](../../docs/architecture/adr-0001-run-state-game-flow.md) — refer there for the implementation.

| Phase | Design intent (one line) | Target duration | Pause allowed? | Aligned pillar |
|---|---|---|---|---|
| `MAIN_MENU` | Neutral resting state — home of save/load, leaderboards, quit-to-desktop | indefinite | No | Pillar 4 |
| `CHAMPION_SELECT` | The run's inciting act — committing to an identity before the run begins | indefinite | No | Pillar 1 |
| `RUN_LOADING` | Quarantine zone — load map + Champion + initial card pool before any gameplay queries | ~0.5s | No | (correctness, not experience — see coherence flag) |
| `RUN_PREP` | The player's turn — placement, repair, build review (the next wave's hypothesis) | 45–90s, player-advance-when-ready, AFK timeout | Yes | Pillar 3 |
| `WAVE_ACTIVE` | The test — combat phase; Wave System in control | 2–4 min (owned by Wave & Spawn GDD #18) | Yes | Pillar 2 |
| `WAVE_RESULTS` | The exhale — currency drops settle; toast notification fires (no screen takeover) | 1.5s beat (waves 1–9) / 3.0s beat (final wave 10 victory, R3) | Yes | Pillar 3 |
| `CARD_ROLL` | The commitment — pick 1 of 3 cards (or skip) | indefinite, anti-AFK silent timeout (~5min) | Yes | Pillar 3 + Pillar 1 |
| `RUN_PAUSED` | Cross-cutting safety valve — pause-from-any-in-run-phase | indefinite | (n/a — IS pause) | Pillar 4 |
| `RUN_RESULTS` | The landing pad — outcome screen; meta-currency awards; restart hook | indefinite | No | Pillar 4 + Pillar 3 |

**Forward flow within a single 10-wave run:**

```
MAIN_MENU → CHAMPION_SELECT → RUN_LOADING → RUN_PREP → WAVE_ACTIVE → WAVE_RESULTS → CARD_ROLL
                                               ↑                                          │
                                               └──────── (loop 10 times) ────────────────┘
                                                                                           │
                                      ┌────── after wave 10 boss / HP=0 / quit ────────────┘
                                      ▼
                                 RUN_RESULTS → MAIN_MENU
```

**Pause/resume orthogonal flow** (allowed from `RUN_PREP`, `WAVE_ACTIVE`, `WAVE_RESULTS`, `CARD_ROLL`):

```
[any in-run phase] —pause()—→ RUN_PAUSED —resume()—→ [previous phase]
                                         └─quit_run(QUIT)─→ RUN_RESULTS
```

**ADR-0001 tightening flagged by this GDD**: ADR-0001's `VALID_TRANSITIONS` lists `RUN_PAUSED: []` (no allowed exits via `transition_to()`), with exits managed by `resume()`. This GDD adds a second special-case API method `quit_run(outcome: int)` parallel to `pause()`/`resume()`, which bypasses `VALID_TRANSITIONS` to transition `RUN_PAUSED → RUN_RESULTS` directly. **Action: run `/propagate-design-change` after this GDD is approved to update ADR-0001's API + Migration Plan + Validation Criteria.**

**Coherence flags (no MVP changes; flag for future revision)**:
- `RUN_LOADING` is correctness-only (~0.5s). If load time later compresses sub-frame, candidate for collapse into CHAMPION_SELECT's exit transition.
- `CHAMPION_SELECT` MVP impl is a debug dropdown (per systems-index VS-tier promotion). Design intent (Pillar 1 weight) is correct and locked; UI debt to pay before V1 ship.

### Interactions with Other Systems

Run State publishes signals; consumers connect. **Run State NEVER calls into a consumer.** This is the contract that prevents bidirectional coupling.

| Consumer System | Signals consumed (Run State → Consumer) | Triggers a transition? | Recommended `process_mode` |
|---|---|---|---|
| **Wave & Spawn (#18)** [C# batching] | `state_entered(WAVE_ACTIVE)`, `state_exited(WAVE_ACTIVE)`, `run_paused`, `run_resumed` | YES — emits `wave_complete` (C# `[Signal] WaveCompleteEventHandler`) → triggers `WAVE_ACTIVE → WAVE_RESULTS`. **Once per wave, never per zombie or per frame** (per [ADR-0003](../../docs/architecture/adr-0003-language-routing-policy.md) boundary). | `PROCESS_MODE_PAUSABLE` |
| **Card-Roll (#22)** | `state_entered(CARD_ROLL)`, `card_roll_offered(cards)`, `state_exited(CARD_ROLL)`, `run_paused`, `run_resumed` | YES — emits `card_picked(card)` (or skips by triggering transition without picking) → advances `CARD_ROLL → RUN_PREP`. | `PROCESS_MODE_ALWAYS` |
| **HUD (#29)** | `state_changed`, `wave_started`, `wave_ended`, `run_paused`, `run_resumed`. Also reads `GameStateMachine` snapshot on demand for: (a) corner-HUD always-visible state, (b) wave-complete toast (per Core Rule 11), (c) Tab-toggle run summary overlay (per Core Rule 15). | NO | `PROCESS_MODE_ALWAYS` |
| ~~**Wave Summary UI (#32)**~~ | **DELETED from MVP scope.** Replaced by toast notification + Tab-toggle run summary, both owned by HUD #29 per Core Rules 11 + 15. No dedicated wave-summary consumer. | — | — |
| **Run Results UI (#34)** | `state_entered(RUN_RESULTS)`, `run_ended(outcome)` | NO | `PROCESS_MODE_ALWAYS` |
| **Main Menu & Champion Select (#33)** | `state_entered(MAIN_MENU)`, `state_entered(CHAMPION_SELECT)` | YES — Champion select UI triggers `CHAMPION_SELECT → RUN_LOADING` with `champion_id`, `map_id`, `seed` carried via `run_started`. | `PROCESS_MODE_ALWAYS` |
| **Adaptive Music (#10)** | `state_changed` (subscribes to all transitions for music swap) | NO | `PROCESS_MODE_ALWAYS` |
| **Save / Load (#2)** | `state_snapshot_ready(snapshot: Dictionary)` (every transition) | NO — selectively persists per [ADR-0006](../../docs/architecture/adr-0006-save-schema-versioning.md) policy. | `PROCESS_MODE_ALWAYS` |
| **Resource / Economy (#20)** | `wave_started`, `wave_ended`, `run_started`, `run_ended` | NO | `PROCESS_MODE_PAUSABLE` |
| **Tutorial (#36)** | `state_entered` (subscribes to all enters for first-run prompts) | NO | `PROCESS_MODE_ALWAYS` |
| **Meta-Currency (#37)** | `run_ended(outcome)` (awards on every outcome — VICTORY, DEFEAT, QUIT — concept: "Death always grants partial meta-currency") | NO | `PROCESS_MODE_ALWAYS` |
| **Leaderboard (#41)** | `run_ended(outcome=VICTORY)` (and others per V1 design) | NO | `PROCESS_MODE_ALWAYS` |
| **Test Harness (#45)** | All signals (asserts emission); calls `transition_to()` directly to drive deterministic state sequences in `--headless` | YES — full state-driving authority in headless mode | `PROCESS_MODE_ALWAYS` |

#### Consumer connection pattern (canonical)

```gdscript
# In any consumer scene (NOT autoload)
func _ready() -> void:
    GameStateMachine.state_changed.connect(_on_state_changed)
    GameStateMachine.run_paused.connect(_on_run_paused)
    GameStateMachine.run_resumed.connect(_on_run_resumed)

func _exit_tree() -> void:
    # Required for consumers that may be instanced/freed mid-run
    # (e.g., Wave Summary panel, Card-Roll overlay)
    if GameStateMachine.state_changed.is_connected(_on_state_changed):
        GameStateMachine.state_changed.disconnect(_on_state_changed)
    # ... etc. for each connected signal
```

#### Consumer anti-patterns (FORBIDDEN — registered in `docs/registry/architecture.yaml`)

- **Polling `current_state` in `_process()` or `_physics_process()`** — subscribers to `state_changed` are notified synchronously; polling is one frame stale or wasteful.
- **Calling `transition_to()` from inside a `state_changed` handler** — re-entrant signal dispatch silently skips intermediate states. Use `call_deferred("transition_to", next)`.
- **Caching `current_state` across frame boundaries** — read once at startup; subscribe for changes (per [ADR-0001 Risk 2](../../docs/architecture/adr-0001-run-state-game-flow.md)).
- **Holding a `WavePerformance` reference past its handler frame** — Wave System may overwrite the resource on the next wave. Copy primitives or call `.duplicate()`.
- **Connecting via string-based `connect("signal_name", target, "method")`** — typed Callable form only (per `forbidden_patterns: string_based_signal_connection`).
- **Emitting from C# to GDScript more than ~50 times per frame** — marshalling-flood. Wave System's `WaveComplete` fires once per wave; this rule extends to all future C# consumers (per [ADR-0003](../../docs/architecture/adr-0003-language-routing-policy.md) `unbatched_csharp_to_gdscript_signal_emission`).

## Formulas

Run State is a state machine, not a balance system, so this section covers timing and computation rules. All formulas use SI units (seconds). The canonical wall-clock source is `_get_unix_time()` — a virtual method on `GameStateMachine` that defaults to `Time.get_unix_time_from_system()`. Test fixtures override this method (or set a `_test_clock_provider: Callable` field) to inject a controlled clock for deterministic time control. **This is a tightening of ADR-0001 — see T19 in the consolidated table.** All wall-clock-derived computations route through this hook; calling the static `Time` API directly is FORBIDDEN.

### F1 — Effective Prep Duration

The `effective_prep_duration` formula determines how long `RUN_PREP` actually lasts:

`effective_prep_duration = min(player_advance_time_seconds, prep_ceiling_seconds)`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `player_advance_time_seconds` | float | `[0.0, +inf)` | Real seconds elapsed since RUN_PREP entry when the player presses `action_wave_start`. Unbounded above because if the player never presses, the ceiling fires. |
| `prep_ceiling_seconds` | float | `(0.0, +inf)` | Maximum prep duration; AFK auto-advance fires here. Default 90s (tuning knob `tk_prep_ceiling`). |

**Output range:** `[0.0, 90s]` at default tuning. Capped at the ceiling; no floor.

**Example:** Player presses Ready 2s into RUN_PREP → `min(2.0, 90.0) = 2.0` (player advance honored immediately, per Core Rule 9). Player presses Ready 60s in → `min(60.0, 90.0) = 60.0`. Player AFK 90s → ceiling fires → `min(90.0, 90.0) = 90.0`.

**Design rationale for removing the floor (locked 2026-05-01)**: the prior 45s floor was paternalism that contradicted Pillar 4 ("the run waits for you"). Early-level waves are designed easy enough to win without towers; the onboarding tutorial covers new-player risk. Removing the floor restores player agency and aligns the formula with Core Rule 9.

### F2 — Auto-Advance Trigger (generalized predicate)

A single predicate handles all phase auto-advance triggers (`RUN_PREP → WAVE_ACTIVE` at 90s, `WAVE_RESULTS → CARD_ROLL` at ~1.5s, `CARD_ROLL → RUN_PREP` at 300s):

`should_auto_advance(phase_entered_at, ceiling_seconds) = max(0.0, _get_unix_time() - phase_entered_at) >= ceiling_seconds`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `phase_entered_at` | float | `[0.0, _get_unix_time()]` | Unix time recorded when the current phase was entered (autoload field, set on every transition; offset on resume per F6). |
| `ceiling_seconds` | float | `(0.0, +inf)` | Per-phase ceiling: 90s (RUN_PREP — `tk_prep_ceiling`), 1.5s (WAVE_RESULTS waves 1–9, hardcoded), 3.0s (WAVE_RESULTS final-wave-10 victory only, hardcoded — R3), 300s (CARD_ROLL anti-AFK silent failsafe — `tk_card_roll_afk_seconds`). |

**Output range:** Boolean.

**Example:** WAVE_RESULTS entered at unix 1000.0, `_get_unix_time()` returns 1001.6, ceiling is 1.5s (waves 1–9) → `max(0.0, 1001.6 - 1000.0) >= 1.5` → `1.6 >= 1.5` → `true`. Auto-advance fires. For wave 10 victory, ceiling is 3.0s — same predicate, longer beat (so the boss-kill moment has emotional space).

**Notes:**
- The CARD_ROLL 300s ceiling is a **silent failsafe** — NOT surfaced to the player as a countdown. HUD authors MUST NOT display it. **However**, when the failsafe fires (auto-skip), Card-Roll GDD #22 owns surfacing the *outcome* (e.g., a post-wave summary line "Card skipped due to inactivity") — silent timer is acceptable; silent state mutation is not.
- WAVE_RESULTS auto-advance for waves 1–9 is a hardcoded 1.5s beat (per D2 — no tuning knob). For the **final wave 10 victory path only** (R3), the beat extends to 3.0s — the boss-kill moment is the run's emotional peak and warrants additional landing time before transitioning to RUN_RESULTS. The implementation selects the ceiling at WAVE_RESULTS entry: `ceiling = (current_wave == waves_per_run and outcome_pending == VICTORY) ? 3.0 : 1.5`. The 1.5s and 3.0s values are not surfaced as tuning knobs (per D2).
- **Canonical safe form** (locked 2026-05-01 per E2): the formula uses `max(0.0, _get_unix_time() - phase_entered_at)` to remain correct under system-clock regression. The unsafe direct-subtraction form `(now - phase_entered_at)` is REJECTED — implementations MUST use the safe form.
- **Runtime assertion**: `GameStateMachine._ready()` MUST assert `ceiling_seconds > 0.0` for every per-phase ceiling read from `RunStateConfig.tres`. A zero or negative ceiling produces `should_auto_advance == true` on the same frame the phase is entered, causing a tight transition loop. The "safe range" entries in Section G are documentation only; the assertion is the enforcement.

### F3 — Displayed Wave Number (state-conditional)

The wave number shown to the player depends on the current state. To avoid HUD authors reimplementing this conditional, **a public read-only method `get_displayed_wave_number(state_override: int = current_state) -> int` MUST be provided on `GameStateMachine`** — see "ADR-0001 tightening flagged" in Section C. The optional `state_override` parameter lets callers (notably the pause overlay) pass `previous_state` to retrieve the correct displayed wave during pause, since `RUN_PAUSED` itself returns 0.

`displayed_wave = get_displayed_wave_number()` returns (using `state_override` if provided, else `current_state`):

| Current State | Returns |
|---|---|
| `RUN_PREP` | `current_wave + 1` |
| `WAVE_ACTIVE` | `current_wave` |
| `WAVE_RESULTS` | `current_wave` |
| `CARD_ROLL` | `current_wave` |
| `MAIN_MENU`, `CHAMPION_SELECT`, `RUN_LOADING`, `RUN_PAUSED`, `RUN_RESULTS` | `0` (sentinel — caller should hide label) |

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `current_wave` | int | `[0, waves_per_run]` | Number of waves completed this run. 0 before any wave completes; increments on `WAVE_ACTIVE → WAVE_RESULTS` (per Core Rule 7). |
| `displayed_wave` | int | `[0, waves_per_run]` | Wave number for HUD display. 0 means "no wave context — hide label". |

**Output range:** `[0, waves_per_run]` where `waves_per_run = 10` for MVP. The `+1` in RUN_PREP should never produce 11 because the final WAVE_RESULTS triggers run-end before the next RUN_PREP can be entered. **Local defensive guard**: `get_displayed_wave_number()` MUST clamp the return to `waves_per_run` and emit a warning if `current_wave + 1 > waves_per_run` is observed in RUN_PREP — this catches a Wave System upstream bug (failure to fire run-end after wave 10) without silently displaying "Preparing Wave 11" to the player. The clamp is a belt-and-braces check, not a silent fix.

**Example:** Run starts, `current_wave = 0`. Enter RUN_PREP first time → `get_displayed_wave_number() → 1`. HUD shows "Preparing Wave 1". WAVE_ACTIVE → wave completes → `current_wave = 1`. HUD shows "Wave 1 Results". RUN_PREP again → `1 + 1 = 2` → HUD shows "Preparing Wave 2".

### F4 — Active-Play Elapsed Run Seconds

The value reported in the snapshot Dictionary, surfaced to leaderboards, and used by Wave Summary's `time_seconds`:

`active_elapsed = max(0.0, (_get_unix_time() - run_started_at) - total_paused_seconds)`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `run_started_at` | int | `[0, now_unix]` | Unix timestamp when the run began. 0 if no run is active. (Locked in [ADR-0001 §296](../../docs/architecture/adr-0001-run-state-game-flow.md).) |
| `total_paused_seconds` | float | `[0.0, +inf)` | Cumulative seconds spent in `RUN_PAUSED` this run; sum of completed pause/resume intervals. 0.0 if never paused. **NEW field — flags an ADR-0001 + ADR-0006 tightening (see F5).** |
| `active_elapsed` | float | `[0.0, +inf)` | Seconds of active play this run, excluding pause time. |

**Output range:** `[0.0, +inf)`. Practical ceiling for a 10-wave MVP run: ~50 min of active play (3000s). Returns 0.0 if `run_started_at == 0`. The outer `max(0.0, ...)` matches F5's per-interval guard pattern — both layers must be non-negative under clock regression.

**Example:** Player starts a run at unix 1000, plays 15 min total, pauses twice for 90s combined. Now = 1900 → wall-clock elapsed = 900s → `active_elapsed = max(0.0, 900 - 90) = 810s = 13.5 min`.

**Design rationale**: leaderboards and wave-clear times are skill indicators. Counting pause time inflates them and turns a skill stat into a "did you take a break?" stat. Excluding pause is one accumulator's cost for a permanent multi-system data-quality win.

### F5 — Cumulative Paused Seconds (snapshot field)

`total_paused_seconds` is computed live by `GameStateMachine` from a list of completed pause/resume pairs and persisted in the snapshot Dictionary:

`total_paused_seconds = sum(max(0.0, resume_at[i] - pause_at[i])) for i in [0, pause_count)`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `pause_at[i]` | float | `[run_started_at, now_unix]` | Unix timestamp when the i-th pause began. |
| `resume_at[i]` | float | `[pause_at[i], now_unix]` | Unix timestamp when the i-th pause ended. |
| `pause_count` | int | `[0, +inf)` | Number of completed pause/resume cycles this run. **Open intervals (un-resumed pauses) are excluded** — see Section E. |
| `total_paused_seconds` | float | `[0.0, +inf)` | Sum of completed pause durations this run. |

**Output range:** `[0.0, wall-clock-elapsed]`. When all pauses are closed, `active_elapsed + total_paused_seconds = wall-clock-elapsed` exactly.

**Example:** Two pauses this run, durations 120s and 45s. `total_paused_seconds = max(0, 120) + max(0, 45) = 165.0s`.

**ADR-0001 + ADR-0006 tightening flagged by this GDD**: Adding `total_paused_seconds` to the snapshot Dictionary is a schema change (new key under `data`). Per [ADR-0006 §99–114](../../docs/architecture/adr-0006-save-schema-versioning.md) versioning rules, this triggers:
1. **ADR-0001** — `_build_snapshot()` Dictionary (§286–303) gains a `total_paused_seconds: float` key.
2. **ADR-0006** — `CURRENT_SCHEMA_VERSIONS["run_snapshot"] = 2` and a `migrate_v1_to_v2(old) -> { …old, "total_paused_seconds": 0.0 }` migration function (missing-key default = 0.0 for pre-v2 saves).

**Migration safety note**: the `0.0` default for v1 saves is acceptable ONLY because no v1 save was ever distributed to players (this is a pre-launch project). If real player data ever needs backfill, this migration would silently inflate `active_elapsed` by the player's actual paused time. The migration function MUST carry an inline comment recording this constraint.

**Open-interval handling on crash (R3 simplified — suspend-save removed)**: F5's "open intervals discarded" rule applies on game crash during `RUN_PAUSED`. Without a save mechanism (R3) there is no resume-from-save path; the run is lost on crash and the next run starts fresh from MAIN_MENU. The `total_paused_seconds` accumulator is runtime-only — it lives on the autoload for the duration of one run and is reset on every new run. Pause time NEVER counts toward leaderboard times (per D4) — this rule is unchanged from R2.

**This is the second tightening flag in this GDD** (the first being `quit_run()` from Section C). Both will be propagated together via `/propagate-design-change` after GDD approval.

### F6 — Pause-Aware Phase Timer Offset

When the player pauses mid-phase and resumes minutes (or hours) later, F2's auto-advance ceiling MUST count only *active* phase time, not wall-clock since `phase_entered_at`. The simplest correct implementation: offset `phase_entered_at` forward by the pause duration on resume, so F2's existing formula remains unchanged.

`phase_entered_at_after_resume = phase_entered_at_before_pause + (resume_at - phase_pause_started_at)`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `phase_pause_started_at` | float | `[0.0, now_unix]` | Unix timestamp when the most recent `pause()` fired. New autoload field; reset to 0.0 on transition out of `RUN_PAUSED`. |
| `phase_entered_at_before_pause` | float | `[0.0, now_unix]` | Value of `phase_entered_at` at the moment of `pause()`. |
| `resume_at` | float | `[phase_pause_started_at, now_unix]` | Unix timestamp when `resume()` fires. |
| `phase_entered_at_after_resume` | float | `[phase_entered_at_before_pause, now_unix]` | Updated `phase_entered_at`; F2 uses this value post-resume. |

**Output range:** monotonically non-decreasing across pause cycles; never goes backwards.

**Example**: Player enters CARD_ROLL at unix 1000 (`phase_entered_at = 1000`, ceiling = 300s). Pauses at unix 1060 (60s into card-roll, `phase_pause_started_at = 1060`). Resumes at unix 4660 (60-minute pause). `phase_entered_at` is offset to `1000 + (4660 - 1060) = 4600`. F2 now checks `(4660 - 4600) >= 300` = `60 >= 300` = `false`. The card-roll continues with the same 240 seconds remaining the player had before pausing. **Without this rule, F2 would check `(4660 - 1000) >= 300` = `true` and silently auto-skip the card on resume — Pillar 4 violation.**

**Design rationale**: this rule is the mechanical implementation of Pillar 4's "the run waits for you" promise at the phase level. F4/F5 already exclude pause time from run-elapsed; F6 extends the same exclusion to per-phase ceilings. Both layers are required because they serve different consumers: F4/F5 → leaderboard, F6 → auto-advance.

**Interaction with F5**: F5 still records each completed pause/resume pair into the cumulative `total_paused_seconds`; F6 only adjusts `phase_entered_at` for the in-progress phase. The two are complementary, not redundant — F5 is the run-level accumulator, F6 is the phase-level offset.

**ADR-0001 tightening flagged**: `phase_pause_started_at` is a new autoload field (init to 0.0). `pause()` MUST set it; `resume()` MUST apply the offset to `phase_entered_at` before re-evaluating F2 in `_process()`. `phase_pause_started_at` is also persisted in the snapshot (per T20 — required for intentional-save-during-pause to preserve open intervals per F5). **This is T13 in the consolidated table.**

### F7 — *(R2 — DELETED in R3)*

> **DELETED 2026-05-01 (R3)**: was the Save Anchor State Selection formula for the suspend-save mechanic. R3 removed the save mechanism entirely — see Overview. Meta-progress (currency, achievements, unlocks) is granted on `run_ended(outcome)` for any of the three outcomes; meta-currency rules belong in Meta-Currency GDD #37, not here.

### F8 — *(R2 — DELETED in R3)*

> **DELETED 2026-05-01 (R3)**: was the Meta-Progress Event Separation formula tracking fired event IDs to prevent re-fire on save reload. With save removed, there is no replay path within a single run — each meta-progress event has at most one firing opportunity per run, and consumer systems (Achievement #44, Meta-Currency #37, Meta-Progression #38) handle their own deduplication of lifetime events on the persistence side. This GDD owns no contract for meta-progress event tracking.

## Edge Cases

Edge cases are grouped by source/category. Several cases (E14, E17, E19, E20, E25–E27, E29, E30, E31) expose tightenings to ADR-0001's locked contract — flagged inline and consolidated in the table at the end.

### Configuration / clamp edge cases

- **E1 — *DELETED 2026-05-01*** (per D1: prep floor removed; degenerate-clamp case no longer applicable).
- **E2 — Player-input vs AFK-timer race**: If the player presses `action_wave_start` within the same 16ms frame the AFK ceiling fires, player input takes precedence. The `_input` handler runs before `_process` in Godot's frame order; `transition_to(WAVE_ACTIVE)` from the input fires first and the second call from `_process` finds `current_state == WAVE_ACTIVE` and is rejected by VALID_TRANSITIONS.
- **E3 — `phase_entered_at = 0.0`**: If `phase_entered_at` is uninitialized (cold-start bug or save-load corruption), `now - 0.0` is huge → auto-advance fires immediately. Mitigation: every `_state_entered` handler MUST set `phase_entered_at = _get_unix_time()` (the virtual hook per T19, NOT the static `Time` API directly); a unit test asserts `phase_entered_at > 0.0` after every transition.
- **E4 — System clock regression**: If wall-clock goes backwards (DST, NTP sync, manual change) mid-phase, `now - phase_entered_at` may be negative. Use `max(0.0, now - phase_entered_at)` everywhere — the predicate `<= ceiling` is correct under negative values (negative < ceiling → false → stays in phase).
- **E5 — CARD_ROLL silent timeout**: The 300s anti-AFK ceiling MUST NOT be surfaced to the player as a visible countdown. HUD authors MUST NOT subscribe to the timer for display purposes.

### Wave-counter edge cases

- **E6 — First-wave display**: When `current_wave = 0` and state is RUN_PREP (very first prep), `get_displayed_wave_number() = 0 + 1 = 1`. HUD shows "Preparing Wave 1". Correct — no off-by-one.
- **E7 — No-wave-context states**: `RUN_LOADING`, `RUN_RESULTS`, `RUN_PAUSED`, `MAIN_MENU`, `CHAMPION_SELECT` all return `0` from `get_displayed_wave_number()`. HUD MUST treat 0 as "hide label", not display "Wave 0".
- **E8 — Run-end wave display**: `RUN_RESULTS` shows the final wave count via the `run_summary` payload from `run_ended`, NOT `get_displayed_wave_number()`. Run Results UI authors MUST NOT call this method from RUN_RESULTS.

### Pause-tracking edge cases

- **E9 — Negative pause interval**: If wall-clock regresses during pause, `resume_at - pause_at` may be negative. Per F5, each interval is wrapped with `max(0.0, ...)` so `total_paused_seconds` remains monotonically non-decreasing.
- **E10 — Open pause interval on crash** *(R3 simplified — no intentional-save case after suspend-save removal)*: If the game crashes during `RUN_PAUSED` (no `resume_at` recorded), the run is lost — there is no save mechanism to recover from. Subsequent runs start fresh from MAIN_MENU. The cumulative `total_paused_seconds` accumulator is runtime-only (not persisted) and resets on the next run start.
- **E11 — Rapid pause/resume mash**: Each pause/resume cycle adds a small float to `total_paused_seconds`. At float64 precision, no realistic mash session causes overflow.

### Transition-table edge cases

- **E12 — Self-transition is a silent no-op**: If `transition_to(X)` is called when `current_state == X`, the early-return guard fires; no signals emit, return `false`. Test Harness fixture-reset patterns must transition AWAY first then back.
- **E13 — `transition_to()` from `RUN_PAUSED` is rejected**: Because `VALID_TRANSITIONS[RUN_PAUSED] == []`, any caller (including Test Harness) trying `transition_to(WAVE_ACTIVE)` from RUN_PAUSED is rejected with a warning. The only valid exits are `resume()` and `quit_run()`. Documented behavior.
- **E14 — CHAMPION_SELECT → MAIN_MENU with stale fields** ⚠ **ADR-0001 tightening (T4)**: If the player backs out of CHAMPION_SELECT to MAIN_MENU after partial run setup (`current_champion_id` written), and re-enters CHAMPION_SELECT → RUN_LOADING, the autoload may retain stale champion/seed data. **`MAIN_MENU` entry MUST reset `current_champion_id`, `current_map_id`, `run_seed`, `run_started_at`, `total_paused_seconds`, and the pause/resume interval list to defaults.**
- **E15 — RUN_RESULTS → MAIN_MENU before consumer autoloads connected**: If Save/Load or Meta-Currency haven't connected to `run_ended` when the transition fires (possible on first boot in a very fast simulated run), they miss the signal. Mitigation: all consumer autoloads MUST connect in their own `_ready()` BEFORE any scene-level `_ready()` triggers a transition. Documented in Dependencies (Section F).

### Concurrent-trigger edge cases

- **E16 — `pause()` called from inside a `state_changed` handler**: If a Tutorial consumer's `_on_state_changed` calls `GameStateMachine.pause()`, re-entrant signal dispatch corrupts emission ordering for later subscribers. **Mitigation: extend the `call_deferred` rule (already covering `transition_to`) to `pause()` and `quit_run()` calls inside signal handlers.**
- **E17 — `wave_complete` fires same frame as `pause()`** ⚠ **ADR-0001 BUG FIX (T5)**: If Wave System emits `wave_complete` on the same frame the player pauses, current ADR-0001 `_on_wave_complete` guards on `current_state != WAVE_ACTIVE` and silently drops the signal. **Outcome under current contract**: run is stuck in WAVE_ACTIVE permanently after resume — Wave System has already finished the wave on the C# side and won't re-emit. **Required fix: `_on_wave_complete` MUST set a `_pending_wave_complete: bool` flag when state is RUN_PAUSED; `resume()` MUST replay via `call_deferred("transition_to", WAVE_RESULTS)` if the flag is set and `previous_state == WAVE_ACTIVE`.**
- **E18 — `quit_run()` racing deferred `transition_to(WAVE_RESULTS)`**: If both are queued in the same deferred frame, whichever fires first wins. The other becomes an invalid-transition rejection (warning logged, no state change). Both orderings are safe — no corruption — but the warning is expected/benign in dev logs and should be documented as such.

### Run-end edge cases

- **E19 — VICTORY + DEFEAT same frame** ⚠ **ADR-0001 tightening (T6)**: If wave 10 boss dies AND player HP=0 in the same frame, both call `transition_to(RUN_RESULTS)`. Current ADR-0001 has no priority rule. **Required design rule: VICTORY > DEFEAT > QUIT.** Whichever outcome arrives at `transition_to()` first wins; if VICTORY's transition fires first the second (DEFEAT) is correctly rejected, but designs must serialize via `_pending_outcome: int` and resolve to highest-priority outcome at end-of-frame. The boss died — the run is a victory.
- **E20 — `quit_run()` called from non-RUN_PAUSED state** ⚠ **ADR-0001 tightening (T7)**: OS-level quit (Alt-F4, window close) during RUN_LOADING has no pause overlay. **Required behavior: `quit_run(QUIT)` MUST be callable from any in-run state (RUN_LOADING, RUN_PREP, WAVE_ACTIVE, WAVE_RESULTS, CARD_ROLL, RUN_PAUSED) and MUST always emit `run_ended(QUIT)` regardless of the prior state.** Meta-Currency depends on this.
- **E21 — Defeat path skips WAVE_RESULTS** ⚠ **ADR-0001 tightening (T8)**: VALID_TRANSITIONS allows `WAVE_ACTIVE → RUN_RESULTS` (defeat skips results). **Design rule: `wave_ended(wave_number, partial_performance)` MUST fire before `run_ended(DEFEAT)`** — Wave Summary UI and Leaderboard depend on always seeing `wave_ended` before `run_ended`. Wave System is responsible for producing a partial-wave `WavePerformance` on player death. **Additional defeat-path rule (locked 2026-05-01 per E3)**: on the defeat path, `current_wave` MUST be incremented immediately BEFORE `run_ended(DEFEAT)` fires, so the run summary reports the correct wave-of-death (not `wave_of_death - 1`). Without this, leaderboard "died on wave N" is off-by-one because Core Rule 7 normally increments on entry to `WAVE_RESULTS`, which the defeat path skips.

### Card-roll edge cases

- **E22 — Double-fire `card_picked` on UI double-click** ⚠ **ADR-0001 tightening (T9)**: If the Card-Roll UI lacks debounce and emits `card_picked` twice, downstream consumers may apply the card twice. **Required guard in Run State**: `card_picked.emit(card)` MUST be gated by `if current_state == GameState.CARD_ROLL` — second emission after CARD_ROLL → RUN_PREP is silently dropped.
- **E23 — CARD_ROLL exit-path semantics**: Three valid paths exit CARD_ROLL → RUN_PREP: (a) `card_picked(card)` then transition (player picked), (b) transition only (player skipped via UI button), (c) auto-advance after 300s (AFK). All three land in RUN_PREP. **Consumers detect the path by**: `card_picked` fired this CARD_ROLL session = pick; `card_roll_offered` fired but no `card_picked` = skip or AFK (Card-Roll GDD #22 owns the distinction).
- **E24 — `card_roll_offered` fired then immediately `quit_run(QUIT)`**: If the player opens pause overlay and quits during the same frame as CARD_ROLL entry, Card-Roll UI receives `card_roll_offered` and starts rendering, then receives `state_exited(CARD_ROLL)` and `run_ended(QUIT)`. **Card-Roll UI MUST tear down on `state_exited(CARD_ROLL)`, not on `card_picked`** — the card panel may need to disappear without a pick ever firing.

### Save / load edge cases

- **E25 — Save loaded with `state = RUN_PAUSED`** ⚠ **ADR-0001 tightening (T10)**: A snapshot persisted during pause has `state: RUN_PAUSED`, `previous_state: WAVE_ACTIVE` (etc.). **Required load behavior: when restoring a snapshot with `state == RUN_PAUSED`, `GameStateMachine` MUST auto-resume to `previous_state` immediately on load, not sit in RUN_PAUSED with no overlay.** Otherwise the player faces an invisible soft-lock.
- **E26 — Snapshot with `state == RUN_PAUSED` AND `previous_state == -1`** ⚠ **ADR-0006 tightening (T10) + sentinel-type tightening (T16)**: Corrupted/manual save where `previous_state` is the not-paused sentinel but `state` says paused. `resume()` would set `current_state = -1` (out of enum range) → permanent stuck. **Required load validation: `if snapshot.state == RUN_PAUSED and snapshot.previous_state == STATE_NONE`, treat as corrupted; fall back to MAIN_MENU with logged warning** (per ADR-0006's `.bak` chain). **Sentinel typing**: `previous_state` MUST be declared as `int` (NOT typed `GameState`) with a named module-level constant `STATE_NONE = -1`. If `previous_state` is typed as the `GameState` enum, assigning `-1` silently coerces to `0` (= `MAIN_MENU`) on strict-typed builds, and this E26 check never fires — load passes silently with `previous_state = MAIN_MENU` and the same soft-lock occurs without a warning. The named constant + int typing are jointly required.
- **E27 — Snapshot with `current_wave > waves_per_run`** ⚠ **ADR-0006 tightening (T10)**: Manually-edited save has `current_wave: 11`. `get_displayed_wave_number() = 12` (out of F3 range); run-end-on-wave-10 logic may fire incorrectly. **Required load validation: `if snapshot.current_wave > waves_per_run`, treat as corrupted; fall back to MAIN_MENU.**
> **E27a–E27e *(R2 — DELETED in R3)***: were save-reload semantics covering achievement re-fire prevention, card re-roll on reload, and prep-anchor preservation. All five cases are obsolete with the suspend-save mechanism removed in R3. There is no replay path within a single run; there is no save reload to defend against.

### Test Harness edge cases

- **E28 — Test Harness drives `transition_to()` before `_connect_wave_system()` completes**: Test that drives state manually does not need the C# connection — benign. Test that exercises the C# integration MUST wait one frame for `call_deferred("_connect_wave_system")` to complete. Documented in Test Harness GDD #45 acceptance criteria.
- **E29 — Test Harness direct-property-write to `current_state`** ⚠ **ADR-0001 tightening + new forbidden_pattern (T11) + signal-misleading fix (T17)**: Bypassing `transition_to()` skips all signals. **Required: `GameStateMachine` MUST expose a `load_snapshot(snapshot: Dictionary)` public method that restores fields AND fires the appropriate signals.** Direct property writes to `current_state`, `current_wave`, `previous_state` are FORBIDDEN — register `direct_property_write_to_game_state_machine` as a new forbidden_pattern.

  **Signal contract (T17)**: `load_snapshot()` MUST NOT emit `state_changed(previous_state, current_state)` because the synthesized "previous" is the pre-load state (typically MAIN_MENU) and the "current" is the snapshot's restored state — Adaptive Music subscribed to `state_changed` would interpret this as a fresh wave-start crossfade. **Required impl (pick one and lock in ADR-0001)**:
  - **Option A (recommended)**: `load_snapshot()` emits a dedicated `state_loaded(snapshot: Dictionary)` signal. Consumers that need to react to load events subscribe to `state_loaded` (Adaptive Music, HUD, Save/Load roundtrip). `state_changed` is reserved for actual transitions only. Cleanest separation; Adaptive Music does not crossfade on load.
  - **Option B**: `load_snapshot()` sets `_is_loading_snapshot: bool = true` before signal emission and clears it after. Consumers read this flag inside their `state_changed` handlers and branch (e.g., Adaptive Music sets the music track directly without crossfade if the flag is set). Simpler signal surface; more consumer-side logic.

  **Default for ADR-0001 propagation**: Option A. Add `state_loaded` to the signal list in ADR-0001 §Signal Contract. Update the consumer table in this GDD's Section C to add `state_loaded` to Adaptive Music, HUD, and Save/Load rows (consumers that need post-load reaction).
- **E30 — `pause()` / `resume()` return values** ⚠ **ADR-0001 tightening (T12)**: Currently `pause()` and `resume()` are `void` and silently return early on invalid states. **Required: return `bool` (success/no-op)** so Test Harness can assert the early-return case explicitly.

### Cross-language edge cases

- **E31 — `wave_complete` during RUN_PAUSED**: See E17 above — same fix (T5).
- **E32 — `wave_complete` emitted twice for one wave**: First emission transitions WAVE_ACTIVE → WAVE_RESULTS, increments `current_wave`. Second emission's guard (`current_state != WAVE_ACTIVE`) drops it with a warning. No double-increment. Wave System GDD #18 acceptance criteria documents this as a known impl-bug error case (not "impossible").

### Consumer-system edge cases

- **E33 — Consumer connects to `state_changed` mid-emission**: If a consumer's `_ready()` runs during a signal dispatch (e.g., spawned by another consumer's handler), the new connection is added but NOT iterated for the current emission. **Mitigation: consumers spawned mid-run MUST read `GameStateMachine.current_state` in `_ready()` to sync initial state — they cannot rely on catching the signal that caused their instantiation.**
- **E34 — Consumer disconnects mid-emit**: If consumer A's handler frees consumer B (also subscribed), Godot's signal system gracefully skips B's handler for the current emission. The canonical teardown pattern in Section C (`is_connected()` guard before `disconnect()`) handles this safely. No design change needed.
- **E35 — Consumer handler throws / asserts**: A handler hitting `assert(false)` or a runtime error does NOT halt signal dispatch. State has already been committed (`current_state = next` precedes all `emit()` calls). The crashing consumer is in undefined state; other consumers still receive the signal. **Documented design rule: transition is non-atomic with respect to consumer success — a crashed consumer does not roll back the state change.**
- **E36 — `card_roll_offered` never fires this run**: A run that ends on wave 10 victory via WAVE_RESULTS → RUN_RESULTS (skipping CARD_ROLL on the final wave per VALID_TRANSITIONS) means consumers connected to `card_roll_offered` simply never receive the signal. **Card-Roll UI MUST handle "0 card rolls this run" as a valid scenario** (per Core Rule 8 skip-ability + final-wave-victory pattern).

### Pause-source edge cases

- **E37 — External pause sources (Steam overlay, Alt-Tab, window minimize, OS focus loss)** ⚠ **ADR-0001 tightening (T14)** *(rewritten 2026-05-01 per D5)*: The original `get_tree().paused` polling approach is REJECTED. Reason: Steam overlay captures input at the OS level WITHOUT toggling `SceneTree.paused`, so polling never detects it. Window-minimization detection via the polling approach is also unreliable. **Required: `GameStateMachine` MUST subscribe to `NOTIFICATION_APPLICATION_FOCUS_OUT` / `NOTIFICATION_APPLICATION_FOCUS_IN` via `_notification(what: int)` and treat focus events as the authoritative external-pause signal**: on `NOTIFICATION_APPLICATION_FOCUS_OUT`, fire a synthetic `pause()`; on `NOTIFICATION_APPLICATION_FOCUS_IN`, fire a synthetic `resume()` (only if state is `RUN_PAUSED` AND the previous pause was synthetic — to avoid resuming an intentional player-paused session). This handles Steam overlay, Alt-Tab, window minimize, and OS focus loss uniformly. Per Core Rule 12, `GameStateMachine` is sole authority on the state↔tree-pause relationship. **Pre-implementation verification required**: confirm `NOTIFICATION_APPLICATION_FOCUS_OUT/IN` fires for Steam overlay activation in dev builds (recorded in Open Questions).
- **E38 — Pause-aware phase timer (T13 link to F6)**: When `pause()` fires during CARD_ROLL with 240s remaining on the 300s ceiling, then 60 minutes elapse with the game paused, then `resume()` fires — F2 MUST NOT auto-skip the card-roll. F6's offset rule (Section D) is the mechanism: `phase_entered_at` is pushed forward by the pause duration on resume so the 240s remaining is preserved. Without this rule, every long pause during CARD_ROLL silently skips the card. **This is the most damaging Pillar 4 violation surfaced by /design-review and is now closed by F6 + T13.**
- **E39 — Quit-from-CARD_ROLL accidental click** ⚠ **ADR-0001 tightening (T15)**: Player has card-pick screen open, opens pause overlay (which renders over the card panel), clicks "Quit to Menu" thinking they're dismissing the menu. Run ends. Card lost (per-run only — see GDD Section C Rule 14 design intent), partial meta-currency awarded with QUIT outcome. **Required: pause overlay MUST present a confirmation dialog ("Quit run? Your progress will be lost.") when `quit_run(QUIT)` is invoked from `RUN_PAUSED` with `previous_state == CARD_ROLL`** OR when `current_state == CARD_ROLL` directly (OS-level quit during card-pick). Confirmation requirement does NOT extend to other in-run states — only CARD_ROLL gets the safeguard, because CARD_ROLL is the only in-run state where the pause overlay obscures another modal. Implementation owner: pause overlay (Section "UI Requirements"). Behavioral test: AC48 (new).

### Concurrent-trigger edge cases (continued)

- **E40 — Heterogeneous deferred `transition_to` targets in same idle frame**: If consumer A calls `call_deferred("transition_to", WAVE_RESULTS)` and consumer B calls `call_deferred("transition_to", CARD_ROLL)` from their `state_changed` handlers in the same frame, the deferred queue processes A first (`WAVE_ACTIVE → WAVE_RESULTS` succeeds), then B (`WAVE_RESULTS → CARD_ROLL` is a VALID_TRANSITIONS hit, succeeds in the SAME idle frame's deferred flush). Two transitions in one frame, no rendering between them. Consumers see two `state_changed` emissions back-to-back. This is technically not corruption — VALID_TRANSITIONS gates each call — but it can produce surprising consumer behavior (e.g., HUD flashing through WAVE_RESULTS for 0 frames). **Mitigation: add a `_deferred_transition_pending: bool` field; `transition_to()` early-returns if one is pending in the current frame; first deferred call wins, subsequent calls in the same frame are dropped with a warning.** This is a minor tightening; consider documenting as an MVP-deferred polish item rather than blocking.

---

### ADR-0001 + ADR-0006 tightenings flagged by this GDD (consolidated)

This table consolidates all implementation-contract changes surfaced across Sections C, D, and E. Both ADR-0001 and ADR-0006 are still in `Proposed` status, so these tightenings do not require superseding ADRs.

| # | Source | Tightening |
|---|---|---|
| T1 | Section C, Rule 5 | Add `quit_run(outcome: int)` API method (parallel to `pause()`/`resume()`); bypasses VALID_TRANSITIONS; allowed from any in-run state per E20. |
| T2 | Section D, F4–F5 *(R3 simplified — no save-snapshot path)* | The leaderboard fields (`total_paused_seconds`, `phase_pause_started_at`, `phase_entered_at`) are runtime-only autoload fields. They do NOT need to be persisted to the run snapshot — there is no save reload. ADR-0006 `run_snapshot` schema is unchanged from v1; the schema bump previously planned for these fields is dropped. Test Harness reads them via the existing snapshot Dictionary (`_build_snapshot()`) for assertion purposes only. |
| T3 | Section D, F3 | Add `get_displayed_wave_number() -> int` public read-only method (centralizes F3 conditional). |
| T4 | E14 | `MAIN_MENU` entry MUST reset run-context fields (`current_champion_id`, `current_map_id`, `run_seed`, `run_started_at`, `total_paused_seconds`, pause/resume list). |
| T5 | E17 + E31 | `_on_wave_complete` MUST queue `_pending_wave_complete = true` when state is RUN_PAUSED; `resume()` MUST replay via `call_deferred("transition_to", WAVE_RESULTS)` if flag set + `previous_state == WAVE_ACTIVE`. |
| T6 | E19 | Run-end outcome priority rule: VICTORY > DEFEAT > QUIT. Implement via `_pending_outcome: int` deferred resolution at end-of-frame. |
| T7 | E20 | `quit_run(QUIT)` MUST be callable from any in-run state, not just RUN_PAUSED. Always emits `run_ended(QUIT)`. |
| T8 | E21 | Defeat path: Wave System MUST fire `wave_ended(wave_number, partial_performance)` before `run_ended(DEFEAT)`. |
| T9 | E22 | `card_picked.emit()` gated by `if current_state == CARD_ROLL`. |
| T10 | E25, E26, E27 | Save-load validation: auto-resume from RUN_PAUSED on load (E25); reject corrupted snapshots with `state==RUN_PAUSED && previous_state==-1` (E26) and `current_wave > waves_per_run` (E27). Falls through ADR-0006 .bak chain. |
| T11 | E29 | Add `load_snapshot(snapshot: Dictionary)` public method for Test Harness. Document `direct_property_write_to_game_state_machine` as a code-review-checklist rule (NOT an automated lint at MVP — GDExtension linter is V1+ consideration per E7). **Scope (R3 clarification)**: the rule covers gameplay-state fields ONLY — `current_state`, `current_wave`, `previous_state`. Test-injection fields (`_pending_outcome`, `_test_clock_provider`) are EXEMPT and may be written directly from test fixtures. The exemption is documented in this row and in the Test Harness GDD #45 contract. |
| T12 | E30 | `pause()` and `resume()` return `bool`. |
| T13 | F6 + E38 | `phase_pause_started_at` field + `phase_entered_at` offset on resume — F2 must count active phase time only, not wall-clock. **Closes Pillar 4 silent CARD_ROLL skip bug.** |
| T14 | Core Rule 12 + E37 | Replace `_process()` polling with `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT/IN)` handler in `GameStateMachine` (locked 2026-05-01 per D5 — polling did not detect Steam overlay because it captures input at OS level without toggling SceneTree.paused). Focus-out → synthetic `pause()`; focus-in → synthetic `resume()` (only if state is RUN_PAUSED AND prior pause was synthetic). Document `direct_tree_pause_write` as a code-review-checklist rule (NOT an automated lint at MVP per E7). |
| T15 | Core Rule 14 + E39 | Pause overlay MUST present a confirmation dialog when `quit_run(QUIT)` is invoked while `previous_state == CARD_ROLL` (or `current_state == CARD_ROLL` for OS-quit). Dialog text (locked 2026-05-01 per D10): "Quit run? You'll lose this run's build, but unlocks and lifetime currency are saved." Other in-run states quit without confirmation. |
| T16 | E26 | `previous_state` MUST be declared as `int` (not the `GameState` enum) with a named constant `STATE_NONE = -1`. Prevents silent coercion to `0` (= `MAIN_MENU`) on strict-typed builds, which would mask E26's load-validation check. |
| T17 | E29 update | `load_snapshot()` MUST suppress `state_changed` emission, OR emit a distinct `state_loaded(snapshot)` signal that consumers subscribe to instead. Current T11 contract emits `state_changed(MAIN_MENU, restored_state)` after load — Adaptive Music sees this as a fresh wave-start crossfade and fires music wrongly. Recommended impl: `_is_loading_snapshot: bool` guard checked inside `state_changed` handlers (consumers branch on it), OR a dedicated `state_loaded` signal so the snapshot-restoration case has its own signal contract. ADR-0001 Risk 2 + Validation Criteria must be updated. |
| T18 | E40 | Optional MVP-deferred: `_deferred_transition_pending: bool` to drop heterogeneous deferred targets in same idle frame. Polish item; not blocking. |
| T19 | Section D preamble (E1) | Add `_get_unix_time() -> float` virtual hook to `GameStateMachine`. All formulas (F2, F4, F5, F6) call this hook. **Single canonical injection mechanism (R3)**: tests override `_get_unix_time()` in a test subclass OR set `_test_clock_provider: Callable` field directly (exempt from T11 per the R3 clarification). Pick one mechanism per test fixture; do not mix. Direct calls to `Time.get_unix_time_from_system()` from Run State formulas are FORBIDDEN. Required for AC51, AC30–AC33, AC42, AC49 to be implementable. |
| ~~T20~~ | ~~F6 + E10 + Save scope (E4)~~ | ***(R3 — DELETED)*** was snapshot persistence of `phase_entered_at`, `phase_pause_started_at`, `meta_progress_events_fired` for save-during-pause + meta-progress separation. Suspend-save removed in R3; runtime-only fields remain on the autoload but are not persisted. |
| ~~T21~~ | ~~Section D, F7 (D7)~~ | ***(R3 — DELETED)*** was `save_for_resume()` API method for the suspend-save mechanic. Suspend-save removed in R3. |
| ~~T22~~ | ~~Section D, F8 (D8)~~ | ***(R3 — DELETED)*** was `fire_meta_progress_event()` API for re-fire suppression on save reload. Suspend-save removed in R3 — meta-progress event deduplication (across runs / lifetime persistence) belongs in Achievement #44 / Meta-Currency #37 / Meta-Progression #38, not here. |

**Action**: After GDD approval, run `/propagate-design-change` to update ADR-0001's Decision section, Migration Plan, Validation Criteria, and Risks. **Active tightenings after R3: T1–T19 (T20–T22 deleted per R3 save-mechanism removal).** ADR-0006 propagation is no longer required — the v1→v2 schema bump is dropped, and the run-snapshot persistence path is unchanged from v1. Tightenings T13–T18 were surfaced by `/design-review` (2026-05-01); T19 was added during R2; T20–T22 were added during R2 and deleted in R3 along with the suspend-save mechanic.

## Dependencies

### Upstream Dependencies (this system depends on)

**None.** Run State / Game Flow is Layer 0 Foundation — it has zero upstream dependencies. This is by design: Run State is the bottleneck contract that 12 downstream MVP systems consume *(R2: Wave Summary UI #32 deleted; was 13)*. If Run State had upstream dependencies, those upstream systems could not be tested headlessly, and the bottleneck risk identified in [systems-index High-Risk Systems](systems-index.md) would propagate further.

The autoload-load-order constraint (per [ADR-0001 Risk 1](../../docs/architecture/adr-0001-run-state-game-flow.md)) is NOT a dependency — `GameStateMachine._ready()` does no work that requires another autoload to exist; cross-language wiring to Wave System (C#) is deferred via `call_deferred("_connect_wave_system")`.

### Downstream Dependencies (systems that depend on this one)

12 MVP consumer systems (was 13 — Wave Summary UI #32 deleted from MVP scope per D2). Full signal-and-data interfaces are documented in [Section C — Interactions with Other Systems](#interactions-with-other-systems). This table summarizes dependency type and criticality.

| # | Consumer | Hard / Soft | Criticality if Run State breaks |
|---|---|---|---|
| #2 | Save / Load | Soft *(R3 demoted from Hard)* | Save/Load persists meta-currency, achievements, unlocks, and settings — NOT run-state. There is no mid-run resume after R3 (suspend-save model removed). If Save/Load breaks, lifetime progression is lost but the active run is unaffected. |
| #10 | Adaptive Music | Hard | Music plays wrong track for current phase |
| #18 | Wave & Spawn (C#) | **Hard** | No wave-end signal handoff; run cannot advance past wave 1. **`wave_ended` MUST fire before `run_ended(DEFEAT)` (per T8); defeat-path `current_wave` increment is also Wave System's responsibility (per E21 / E3).** |
| #20 | Resource / Economy | Hard | Resources don't reset between runs; phase-gated awards break |
| #22 | Card-Roll | **Hard** | No card-roll phase trigger; build expression broken. **Card-data interface for the pause overlay's build summary display is a content requirement imposed by this GDD (per D11).** |
| #29 | HUD | **Hard** | Player has no visible game state; UI broken. **Wave-complete toast (Core Rule 11), Tab-press-toggle run summary (Core Rule 15 — R3 changed from hold to toggle), compact build summary list with expand-on-tap (per UI Requirements / D11), and gamepad pause mapping (per D12) are content requirements imposed by this GDD on HUD #29 GDD.** |
| ~~#32~~ | ~~Wave Summary UI~~ | ~~Soft~~ | **DELETED from MVP scope (per D2).** Replaced by HUD #29 wave-complete toast + Tab-toggle run summary. No dedicated consumer. |
| #33 | Main Menu & Champion Select | **Hard** | No path into a run |
| #34 | Run Results / Death UI | **Hard** | No run-end screen; player stuck after death |
| #36 | Tutorial | Soft | New-player onboarding broken (degraded for new players) |
| #37 | Meta-Currency | **Hard** | No currency awards on run end. Meta-currency is granted on `run_ended(outcome)` for any of the three outcomes (VICTORY, DEFEAT, QUIT). Per-run event deduplication is owned by Meta-Currency #37 itself (lifetime persistence layer); this GDD imposes no event-tracking contract after R3. |
| #41 | Leaderboard | Soft | No leaderboard updates (Alpha-tier; not MVP-blocking). **Pause time is excluded from leaderboard times (per D4 / F4-F5).** |
| #45 | Test Harness | **Hard** | Cannot drive deterministic state sequences in headless tests. **Clock injection via `_get_unix_time()` virtual hook (per T19) is a content requirement imposed on Test Harness #45 GDD.** |

**Hard** = consumer cannot function without Run State signals/state queries.
**Soft** = consumer is degraded but the game is still playable (typically Alpha-tier or polish layer).

Result *(R3)*: 8 hard MVP consumers, 4 soft consumers (Save/Load #2 demoted to Soft after R3 save-mechanism removal; Wave Summary UI #32 deleted in R2). Run State broken = 8 MVP systems broken simultaneously — still confirms the High-Risk Systems "bottleneck" classification, but the bottleneck risk is now slightly reduced (Save/Load no longer depends on Run State for run-state persistence).

### Bidirectional consistency requirements

Each consumer GDD MUST list this system in its "depends on" section. When authoring each consumer GDD, the `/design-system` skill's bidirectional consistency check (per [.claude/rules/design-docs.md](../../.claude/rules/design-docs.md)) MUST verify the back-reference exists. The systems-index already encodes this: every consumer in the table above has Run State (#8) in its Depends On column.

Run a `/consistency-check` after the third consumer GDD is authored to confirm bidirectional references are intact.

### Autoload load-order constraint

Although Run State has no upstream dependencies, the Godot autoload-load-order matters for *consumer* connection timing:

1. **GameStateMachine** (this autoload) MUST be registered first or early in `Project Settings → Autoload`.
2. **Consumer autoloads** (Save/Load, Adaptive Music, Meta-Currency, Test Harness, Wave System if implemented as autoload) connect to GameStateMachine signals in their own `_ready()` — Godot guarantees autoload `_ready()` runs in declaration order, and all autoloads' `_ready()` complete before any scene-level `_ready()` (per [ADR-0001 Risk 1](../../docs/architecture/adr-0001-run-state-game-flow.md)).
3. **Cross-language Wave System connection** uses `call_deferred("_connect_wave_system")` to allow WaveSystem autoload to register regardless of declaration order; the assertion in `_connect_wave_system()` catches the failure case at runtime in dev (per E15).

**Documented load-order rule**: GameStateMachine registers first. Consumer autoloads register after. WaveSystem registers anywhere (lazy-connected via `call_deferred`).

## Tuning Knobs

All values are exposed via a `RunStateConfig.tres` Resource (per project coding standard: gameplay values must be data-driven, never hardcoded). The Resource is loaded by `GameStateMachine._ready()` and re-read on each transition for live-tuning during dev.

### Phase duration knobs

> *`tk_prep_floor` deleted 2026-05-01 per D1 — Ready advances the wave immediately. `tk_wave_results_advance_seconds` deleted 2026-05-01 per D2 — WAVE_RESULTS is a hardcoded 1.5s beat for waves 1–9 and 3.0s for the final wave 10 victory path (R3) — no screen takeover, no player-tunable countdown.*

| Knob | Default | Safe Range | Affects | If too low | If too high |
|---|---|---|---|---|---|
| `tk_prep_ceiling` | 90.0 s | [30, 180] s | Maximum RUN_PREP before AFK auto-advance (per F1). The only RUN_PREP knob — the prior floor is gone. | < 30s: insufficient time for placement on dense mid-run waves (Pillar 4) | > 180s: AFK player blocks the run for 3+ minutes per wave; total run wall-clock balloons |
| `tk_card_roll_afk_seconds` | 300.0 s | [120, 600] s | Silent anti-AFK auto-skip from CARD_ROLL → RUN_PREP (per F2; HUD must NOT display) | < 120s: punishes players who legitimately read all 3 card descriptions carefully | > 600s: AFK player blocks the run for 10+ minutes; meta-currency stats for the run never written |

### Run-structure knobs

| Knob | Default | Safe Range | Affects | If too low | If too high |
|---|---|---|---|---|---|
| `tk_waves_per_run` | 10 | [3, 30] | Total waves per run before final boss / RUN_RESULTS | < 3: insufficient build expression (Pillar 3); cards barely get to interact | > 30: session length blows past concept's 30-60 min target; player fatigue |

> **Note on `tk_waves_per_run`**: concept-locked at 10 for V1 ([game-concept.md line 148](game-concept.md)). MVP uses 5 waves (concept's MVP definition line 364). Tunable for prototype experiments only — V1 ships 10. Listed as a knob because the value is referenced in F3 (`displayed_wave` upper bound) and Section E E27 (corruption check).

### Knob interactions

- **`tk_prep_ceiling` × `tk_waves_per_run` composition** (locked 2026-05-01 per E20): total per-run non-combat time ≈ `tk_prep_ceiling × tk_waves_per_run` (the ~1.5s WAVE_RESULTS beat is negligible at this granularity). At defaults: `90 × 10 = 900s ≈ 15 min` of non-combat. Combined with 2-4 min wave duration × 10 waves = 20-40 min combat → total run = 35-55 min, within concept's 30-60 min target. **Hard bound**: `tk_prep_ceiling × tk_waves_per_run < 3600s` (one hour of pure non-combat is the absolute ceiling — beyond it, runs blow past the session target regardless of player engagement). Violating this composition (e.g., `tk_prep_ceiling = 180`, `tk_waves_per_run = 30`) pushes total non-combat to 90 min — well past the session target.
- **`tk_card_roll_afk_seconds` is NOT a UI element**: setting it lower does NOT make the card-roll phase shorter for engaged players — it only lowers the AFK safety net. Engaged players see no effect; only AFK players are affected.

### Knobs NOT exposed (deliberately)

- **State enum members** are NOT tuning knobs — they are append-only per Core Rule 11; changing them requires a save schema bump (T2 / T10).
- **`VALID_TRANSITIONS` table** is NOT a tuning knob — it is the contract surface. Adding/removing transitions requires an ADR superseding ADR-0001.
- **Signal contract** is NOT a tuning knob — adding/removing signals breaks consumer subscriptions. Requires ADR tightening (already 12 flagged in this GDD; future additions require new propagation).
- **`RunOutcome` enum** is NOT a tuning knob — same reasoning as state enum.
- **`waves_per_run` runtime mutation** — the value is set once at run start (read from `tk_waves_per_run`) and frozen for the duration of the run. Changing it mid-run would corrupt save snapshots and HUD wave-display.

## Visual/Audio Requirements

**Not applicable directly.** Run State / Game Flow is a Foundation/Infrastructure system with no visual or audio output of its own. State-transition feedback is delivered by consumer systems:

- **Visual**: HUD (#29) — wave-complete toast + Tab-toggle run summary (per Core Rules 11, 15) + Pause Overlay; Card-Roll UI (#22), Run Results UI (#34), Main Menu (#33). *(Wave Summary UI #32 was deleted in R2 per D2.)*
- **Audio**: Adaptive Music (#10) reacts to `state_changed` for music swaps; transition SFX is owned by Audio Bus (#3) consumers.

The signal contract in [Section C — Interactions with Other Systems](#interactions-with-other-systems) is the canonical hand-off — consumer systems author the visual/audio response.

## UI Requirements

**Not applicable directly.** Run State has no UI of its own. UI ownership is distributed across these consumer GDDs (each runs `/ux-design` separately at UI authoring time):

- HUD (#29) — wave label, pause overlay, state-conditional displays
- Card-Roll UI (#22) — card panel, "Skip" action input
- Wave Summary UI (#32) — performance summary, "Continue" advance input
- Run Results UI (#34) — outcome screen, restart hook
- Main Menu & Champion Select (#33) — menu navigation, debug Champion-picker dropdown at MVP
- Pause Overlay — `pause()` / `resume()` UI surface; spec'd in this GDD (see "Pause Overlay Contents" below) because it is the primary delivery mechanism for the Pillar 4 player fantasy. **Owning GDD for the visual implementation: HUD GDD #29.**

The "Ready" input (`action_wave_start`) and the "Skip" action are inputs Run State responds to but does not own — input action mapping is owned by Input System (#1), UI surface ownership is per-consumer.

### Pause Overlay Contents (Pillar 4 delivery surface)

The Pause Overlay is the player-facing surface that delivers the Player Fantasy stated in Section B ("the run waits for you"). HUD GDD #29 owns the visual implementation, but **the content requirements below are owned by this GDD** because they are the mechanical delivery of Pillar 4 — without them the fantasy fails regardless of visual treatment.

**Required content (MVP, R3 simplified — two action buttons after suspend-save removal):**

1. **Resume button** — primary action; triggers `resume()`. Input mapping (per D12):
   - Keyboard/Mouse: `Esc`
   - Gamepad: Start / Options (Xbox `Menu/Start`, PlayStation `Options`, Switch `+`)
   - Both inputs trigger pause OR resume — toggle behavior.
2. **Quit Run button** — triggers `quit_run(RunOutcome.QUIT)`. Forfeits the run; awards partial meta-currency (per Meta-Currency #37); returns to MAIN_MENU via RUN_RESULTS. **MUST present a confirmation dialog when `previous_state == CARD_ROLL` (or `current_state == CARD_ROLL` for OS-level quit)** with text (locked per D10): **"Quit run? You'll lose this run's build, but unlocks and lifetime currency are saved."** Other in-run states quit without confirmation (per T15). Confirmation-dialog button labels (R3 lock — addressing prior `[ux-designer]` ambiguity): **"Quit Run" / "Keep Playing"** (asymmetric labels — never "Yes / No" — to prevent reflex misclicks on the destructive option).
3. **Current wave indicator** — calls `get_displayed_wave_number(previous_state)` (per F3 / T3 / E13 — passes `previous_state` because RUN_PAUSED itself returns 0). Displays e.g., "Paused — Wave 3 of 10". **R3 fix for RUN_LOADING edge case**: when `get_displayed_wave_number(previous_state)` returns 0 (i.e., paused via focus-out from RUN_LOADING, RUN_RESULTS, MAIN_MENU, or CHAMPION_SELECT), the overlay MUST hide the wave-indicator label entirely — do NOT display "Paused — Wave 0 of 10". The label is suppressed, not zeroed.
4. **Current build summary** — compact list of cards picked this run (locked per D11):
   - Compact list — card name + small icon per row.
   - Hover/tap reveals full card description on demand.
   - List is fixed-height; cards beyond visible range scroll within the build-summary region (fits up to 9 cards comfortably; expandable beyond if the run ever exceeds 10 picks).
   - Card data ownership: Card-Roll GDD #22 + Build/Modifier GDD #23. This overlay is a *consumer* of their data interface.
   - Pillar 4 explicitly cites "stop mid-wave to read card descriptions" as the felt experience. The compact-with-expand pattern matches Hades' boon menu and Slay the Spire's run-screen — proven genre convention.

**Settings access removed (ED4)**: The Settings / Options button is OMITTED from MVP entirely (was previously listed as item 5 with a "placeholder" caveat). No placeholder button — when Settings #42 ships at VS-tier, the button is added then.

**Gamepad navigation requirement (per D12; R3 updated for two-button overlay + asymmetric dialog labels)**: Both overlay buttons (Resume, Quit Run) MUST be navigable via gamepad D-pad or analog stick; activation via the face-South button (Xbox `A`, PlayStation `Cross`, Switch `B`). Confirmation-dialog buttons (`Quit Run` / `Keep Playing` per R3) follow the same rule. Pre-implementation verification: confirm gamepad nav lands focus on the overlay's first button on overlay-show, not on a stale background-scene focus target.

**Modal stack contract (per E17)**: Each modal layer consumes its own dismiss input before propagating to layers beneath it. Stack ordering, innermost-first: Confirmation Dialog > Pause Overlay > CARD_ROLL panel. `Esc` / `B`-button dismisses the topmost layer only. **Pause input is suppressed while a confirmation dialog is active** — the player cannot pause-toggle out of a confirmation prompt without answering it first. This rule prevents accidental quit-without-confirmation when the player tries to dismiss the dialog with the same key they used to open the overlay.

**Forbidden content (MVP):**
- Active gameplay surfaces (no shooting, no placement, no ability use during pause). The overlay is read-only on the run state.
- Any element that would mutate the run (re-pick cards, modify placements, change build). Pause is for review and exit, not for gameplay.

**Behavioral requirements:**
- Overlay MUST be visible within one rendered frame of `pause()` returning `true` (per AC47 felt-experience criterion).
- Overlay MUST tear down within one rendered frame of `resume()` or `quit_run()` returning successfully. *(R3: `save_for_resume()` removed.)*
- The overlay's input handling runs at `PROCESS_MODE_ALWAYS` (so input continues to work while `get_tree().paused = true`).
- **Input suppression (locked per E18)**: While the overlay is visible, it MUST suppress ALL underlying inputs — both UI inputs (Card-Roll panel selection, Placement UI confirm, etc.) AND gameplay inputs (shoot, ability activation, placement confirm, movement). The previous "underlying-scene input" wording was ambiguous about whether gameplay inputs were covered; this clarification closes that gap.

**Coherence flag**: this is the only player-visible Pillar 4 surface authored *in this GDD* (other phases are state-machine-only). If HUD GDD #29 deviates from these content requirements during its authoring, escalate to creative-director — Pillar 4 mechanical correctness is non-negotiable; visual treatment is.

## Acceptance Criteria

Acceptance criteria are grouped into 17 categories (was 13 originally; Group 14 added during the initial T13–T18 work; Groups 15, 16, and 17 added during the 2026-05-01 revision). Each criterion follows GIVEN-WHEN-THEN format and is independently testable without reading other sections of this GDD. Test-evidence type for each group is noted at the end (Logic = unit test BLOCKING; Integration = integration test BLOCKING; Visual/Feel = manual sign-off ADVISORY) per [.claude/docs/coding-standards.md](../../.claude/docs/coding-standards.md).

### Group 1 — State machine correctness *(Logic, BLOCKING)*

*Covers Core Rules 1–3, 11.*

- **AC1**: GIVEN a fresh `GameStateMachine` autoload has completed `_ready()`, WHEN `current_state` is read, THEN it equals `GameState.MAIN_MENU` and no other `GameState` value is simultaneously set anywhere in the autoload's exported fields.
- **AC2**: GIVEN `current_state == CHAMPION_SELECT`, WHEN a valid `champion_id`, `map_id`, and `seed` are supplied and `transition_to(RUN_LOADING)` is called, THEN `current_state` becomes `RUN_LOADING`, `state_changed` emits exactly once with `(CHAMPION_SELECT, RUN_LOADING)`, and `current_state` is never read as `CHAMPION_SELECT` again by any listener receiving that emission.
- **AC3**: GIVEN `current_state == WAVE_ACTIVE`, WHEN `transition_to(RUN_PREP)` is called directly (not via `quit_run()`), THEN `transition_to()` returns `false`, `current_state` remains `WAVE_ACTIVE`, `state_changed` does not emit, and a warning is logged.
- **AC4**: GIVEN a complete 3-wave headless run driven by Test Harness (using `load_snapshot()` + `transition_to()`), WHEN each transition in the sequence `RUN_PREP → WAVE_ACTIVE → WAVE_RESULTS → CARD_ROLL → RUN_PREP` is executed twice, THEN `current_state` equals the expected state at each step in strict sequential order with no phase overlap observed at any point in the transition log.
- **AC5**: GIVEN an existing save file with `GameState` enum values 0 through 8, WHEN a new state value `NEW_STATE = 9` is appended to the enum (as the only acceptable change) and the save is loaded, THEN the save loads without error and `current_state` resolves to the correct pre-save state; no existing enum integer shifts.

### Group 2 — Pause / resume correctness *(Logic, BLOCKING)*

*Covers Core Rule 4, T5, T12, Pillar 4.*

- **AC6**: GIVEN `current_state == WAVE_ACTIVE`, WHEN `pause()` is called, THEN `pause()` returns `true`, `current_state` becomes `RUN_PAUSED`, `run_paused` signal emits, and `previous_state` field equals `WAVE_ACTIVE`.
- **AC7**: GIVEN `current_state == RUN_PAUSED` with `previous_state == WAVE_ACTIVE`, WHEN `resume()` is called, THEN `resume()` returns `true`, `current_state` returns to `WAVE_ACTIVE`, `run_resumed` signal emits, and `previous_state` is cleared to the not-paused sentinel.
- **AC8**: GIVEN `current_state == MAIN_MENU`, WHEN `pause()` is called, THEN `pause()` returns `false`, `current_state` remains `MAIN_MENU`, and `run_paused` does not emit.
- **AC9**: GIVEN `current_state == WAVE_ACTIVE` and `pause()` has been called (state is now `RUN_PAUSED`), WHEN the Wave System emits `wave_complete` on the same frame as or after the pause call, THEN `_pending_wave_complete` flag is set to `true`; after `resume()` is subsequently called, `transition_to(WAVE_RESULTS)` is deferred via `call_deferred` and `current_state` advances to `WAVE_RESULTS` exactly once.
- **AC10**: GIVEN `current_state == RUN_PAUSED` with `previous_state == WAVE_ACTIVE`, WHEN `resume()` is called and `_pending_wave_complete` is `true`, THEN `current_wave` increments by exactly 1 and `WAVE_RESULTS` is entered — the wave is not silently dropped.

### Group 3 — Quit-run correctness *(Logic, BLOCKING)*

*Covers Core Rule 5, 6, T1, T7.*

- **AC11**: GIVEN `current_state == RUN_PAUSED`, WHEN `quit_run(RunOutcome.QUIT)` is called, THEN `current_state` becomes `RUN_RESULTS`, `run_ended` emits with `outcome == RunOutcome.QUIT`, and `run_resumed` does NOT emit.
- **AC12**: GIVEN `current_state == WAVE_ACTIVE` (no pause overlay — simulates OS-level quit), WHEN `quit_run(RunOutcome.QUIT)` is called, THEN `current_state` becomes `RUN_RESULTS`, `run_ended` emits with `outcome == RunOutcome.QUIT`, and no "invalid transition" warning is logged.
- **AC13**: GIVEN `current_state == RUN_LOADING`, WHEN `quit_run(RunOutcome.QUIT)` is called, THEN `current_state` becomes `RUN_RESULTS`, `run_ended` emits with `outcome == RunOutcome.QUIT`.
- **AC14**: GIVEN a completed run with all three `RunOutcome` values exercised in separate runs, WHEN each `run_ended(outcome)` signal is inspected, THEN `outcome` equals `RunOutcome.VICTORY` (wave 10 boss defeated), `RunOutcome.DEFEAT` (player HP=0), and `RunOutcome.QUIT` (player quit) respectively — no two outcomes share the same integer value.

### Group 4 — Wave-counter correctness *(Logic, BLOCKING)*

*Covers Core Rule 7, F3, T3.*

- **AC15**: GIVEN `current_wave == 0` and `current_state == RUN_PREP`, WHEN `get_displayed_wave_number()` is called, THEN it returns `1` (not `0`).
- **AC16**: GIVEN `current_wave == 3` and `current_state` is each of `WAVE_ACTIVE`, `WAVE_RESULTS`, `CARD_ROLL` tested separately, WHEN `get_displayed_wave_number()` is called in each state, THEN it returns `3` in all three states.
- **AC17**: GIVEN `current_state` is `MAIN_MENU`, `CHAMPION_SELECT`, `RUN_LOADING`, `RUN_PAUSED`, or `RUN_RESULTS` (each tested separately), WHEN `get_displayed_wave_number()` is called, THEN it returns `0` in every non-in-run state.
- **AC18**: GIVEN `current_state == WAVE_ACTIVE` and `current_wave == 2`, WHEN the Wave System emits `wave_complete` and the transition to `WAVE_RESULTS` completes, THEN `current_wave == 3` — the increment happens on entry into `WAVE_RESULTS`, not on entry into the preceding `WAVE_ACTIVE`.

### Group 5 — Card-roll correctness *(Logic for AC19–AC21, Integration for AC22–AC23, all BLOCKING)*

*Covers Core Rule 8, T9, E22, E23, E24, E36.*

- **AC19**: GIVEN `current_state == CARD_ROLL`, WHEN `card_picked` is emitted once by the Card-Roll UI, THEN the transition to `RUN_PREP` completes and `card_picked` is forwarded to consumers exactly once.
- **AC20**: GIVEN `current_state == CARD_ROLL`, WHEN `card_picked` is emitted a second time (simulated UI double-click, same frame), THEN the second emission is silently dropped — `state_changed` does not emit a second time and `current_state` is already `RUN_PREP` after the first pick.
- **AC21**: GIVEN `current_state == CARD_ROLL`, WHEN the player activates the skip action without emitting `card_picked`, THEN `current_state` transitions to `RUN_PREP`, `card_roll_offered` was emitted at CARD_ROLL entry, and `card_picked` was never emitted this CARD_ROLL session — this is a valid run state.
- **AC22**: GIVEN `current_state == CARD_ROLL` and `card_roll_offered` has emitted, WHEN `quit_run(RunOutcome.QUIT)` is called (player quits mid-card-pick), THEN `state_exited(CARD_ROLL)` emits and `run_ended(QUIT)` emits; `card_picked` does NOT emit; the Card-Roll UI can tear down on `state_exited` without error.
- **AC23**: GIVEN a run that reaches wave 10 victory and WAVE_RESULTS transitions directly to `RUN_RESULTS` (final wave — CARD_ROLL skipped per VALID_TRANSITIONS), WHEN the run ends, THEN `card_roll_offered` emits zero times for that final wave — consumers subscribed to `card_roll_offered` must handle receiving zero emissions for the run-ending wave **without `assert()` failures and without Godot error log entries** (test passes if both error channels are clean for the duration of the test scenario).

### Group 6 — Phase-pacing correctness *(Logic, BLOCKING)*

*Covers Core Rule 9, 10, F1, F2.*

- **AC24** *(rewritten 2026-05-01 per D1)*: GIVEN `current_state == RUN_PREP` (no floor — `tk_prep_floor` deleted per D1), WHEN the player presses `action_wave_start` at any elapsed time (including 1 second after entry), THEN the transition to `WAVE_ACTIVE` fires immediately within one frame; no minimum-duration delay is enforced. Player advance is honored regardless of how recently the phase was entered.
- **AC25**: GIVEN `tk_prep_ceiling = 90.0` and `current_state == RUN_PREP`, WHEN the player presses `action_wave_start` at 60 seconds elapsed, THEN the transition to `WAVE_ACTIVE` fires at 60 seconds (within ceiling — player advance honored, no floor to enforce).
- **AC26**: GIVEN `current_state == RUN_PREP` and no player input, WHEN 90 seconds have elapsed since `phase_entered_at`, THEN `should_auto_advance` returns `true` and the transition to `WAVE_ACTIVE` fires automatically.
- **AC27** *(rewritten 2026-05-01 per D2; extended R3 for boss-kill beat)*: GIVEN `current_state == WAVE_RESULTS` for waves 1–9 (no screen takeover), WHEN 1.5 seconds elapse since `phase_entered_at`, THEN the auto-advance to `CARD_ROLL` fires (or directly to `RUN_RESULTS` if the defeat path is active per E21). **R3 final-wave extension**: GIVEN `current_state == WAVE_RESULTS` for wave 10 victory (the final-wave boss-kill path), WHEN 3.0 seconds elapse since `phase_entered_at`, THEN the auto-advance to `RUN_RESULTS` fires. The exact durations (1.5s and 3.0s) are not player-tunable.
- **AC28**: GIVEN `RunStateConfig.tres` is modified at runtime to change `tk_prep_ceiling` to `60.0`, WHEN the next `RUN_PREP` phase is entered, THEN the auto-advance fires at 60 seconds (not 90 seconds) — config is re-read per transition.
- **AC29** *(DELETED 2026-05-01 per D1)*: was the `tk_prep_floor >= tk_prep_ceiling` misconfiguration assertion test. Removed because the floor itself is gone — there is no longer a floor-vs-ceiling invariant to assert.

### Group 7 — Active-play elapsed time *(Logic, BLOCKING)*

*Covers F4, F5, T2.*

- **AC30**: GIVEN a run with `run_started_at` recorded at unix time X, no pauses, and current unix time `X + 300`, WHEN `active_elapsed` is computed (F4), THEN it equals `300.0` seconds.
- **AC31**: GIVEN a run where the player paused once for 120 seconds and once for 45 seconds (both pauses fully resumed), WHEN `total_paused_seconds` is computed (F5), THEN it equals `165.0` and `active_elapsed = wall_clock_elapsed - 165.0`.
- **AC32**: GIVEN a snapshot Dictionary saved during schema_version 1 (before T2) that lacks the `total_paused_seconds` key, WHEN `migrate_v1_to_v2(old_snapshot)` is applied, THEN the resulting snapshot contains `total_paused_seconds: 0.0` and `schema_version: 2`.
- **AC33**: GIVEN a run where the game crashes during `RUN_PAUSED` (no `resume_at` recorded for the open interval), WHEN the save is loaded and `total_paused_seconds` is computed, THEN the open interval is discarded and `total_paused_seconds` reflects only completed pause/resume pairs — no crash-inflated pause time.

### Group 8 — Run-end outcome resolution *(Logic, BLOCKING)*

*Covers T6, T8, E19, E21.*

- **AC34a** *(replaces former AC34 first half, locked 2026-05-01 per E14)*: GIVEN a Test Harness fixture sets `_pending_outcome = DEFEAT` and then sets `_pending_outcome = VICTORY` within the same deferred frame, WHEN the end-of-frame outcome resolution runs, THEN `_pending_outcome` resolves to `VICTORY` (priority rule per T6) and `run_ended.emit(RunOutcome.VICTORY)` is called exactly once.
- **AC34b** *(replaces former AC34 second half, locked 2026-05-01 per E14)*: GIVEN a Test Harness fixture sets `_pending_outcome = VICTORY` and then sets `_pending_outcome = DEFEAT` within the same deferred frame, WHEN the end-of-frame outcome resolution runs, THEN `_pending_outcome` still resolves to `VICTORY` (priority rule is order-independent per T6) and `run_ended.emit(RunOutcome.VICTORY)` is called exactly once. The "same frame" requirement is enforced by the Test Harness fixture, NOT by racing real wave/HP signals. The original 100-repetition determinism check is replaced by these two single-assertion sub-cases — the priority rule is order-independent, so two cases prove it without flake risk.
- **AC35**: GIVEN player HP reaches 0 during `WAVE_ACTIVE`, WHEN the defeat path is triggered, THEN `wave_ended(wave_number, partial_performance)` emits BEFORE `run_ended(RunOutcome.DEFEAT)` — the Wave Summary UI and Leaderboard receive `wave_ended` first in every observed execution ordering.

### Group 9 — Save / load contract *(Integration, BLOCKING)*

*Covers T10, E25, E26, E27.*

- **AC36**: GIVEN a snapshot saved with `state: RUN_PAUSED` and `previous_state: WAVE_ACTIVE`, WHEN the snapshot is loaded via `load_snapshot()`, THEN `GameStateMachine` auto-resumes to `WAVE_ACTIVE` and `current_state == WAVE_ACTIVE` — no soft-lock in RUN_PAUSED with no visible overlay.
- **AC37**: GIVEN a snapshot with `state: RUN_PAUSED` and `previous_state: -1` (corrupted sentinel), WHEN the snapshot is loaded via `load_snapshot()`, THEN the load is rejected, a warning is logged, `current_state` falls back to `MAIN_MENU`, and the save manager triggers the `.bak` fallback chain per ADR-0006.
- **AC38**: GIVEN a snapshot with `current_wave: 11` (exceeds `tk_waves_per_run = 10`), WHEN the snapshot is loaded via `load_snapshot()`, THEN the load is rejected, a warning is logged, and `current_state` falls back to `MAIN_MENU`.

### Group 10 — Test Harness drivability *(Integration, BLOCKING)*

*Covers T11, E29, E30, system #45.*

- **AC39**: GIVEN the Test Harness calls `GameStateMachine.load_snapshot(snapshot)` with a valid snapshot Dictionary, WHEN the method executes, THEN `current_state`, `current_wave`, `previous_state`, and `run_started_at` are all restored to snapshot values AND `state_entered`, `state_changed`, and `state_snapshot_ready` signals emit — consumers receive the restored state as if a real transition occurred.
- **AC40** *(DEFERRED — depends on linter tooling not yet built)*: GIVEN `direct_property_write_to_game_state_machine` is registered in `docs/registry/architecture.yaml` under `forbidden_patterns` AND a pre-commit or CI hook (Test Harness GDD #45 owns implementation) reads that registry, WHEN GDScript code containing `GameStateMachine.current_state =`, `GameStateMachine.current_wave =`, or `GameStateMachine.previous_state =` (direct property assignment) is committed, THEN the hook exits non-zero and outputs `forbidden_pattern: direct_property_write_to_game_state_machine` — the commit is rejected before merge. **Prerequisite**: T11 propagated to `architecture.yaml` AND the linter hook implemented in Test Harness GDD #45. AC marked DEFERRED until both prerequisites ship; it is NOT blocking for the first Run State implementation story.
- **AC41**: GIVEN a headless Test Harness run with `--headless` flag and no wave-system C# connection, WHEN `transition_to(WAVE_ACTIVE)` is called, THEN the state machine advances without error — the absence of the C# wave system connection does not crash the autoload.

### Group 11 — Cross-language Wave System integration *(Integration, BLOCKING)*

*Covers T5, E17, E31, E32.*

- **AC42**: GIVEN `current_state == WAVE_ACTIVE` and the C# Wave System has completed a wave, WHEN `wave_complete` fires on the same engine frame as `pause()` is called, THEN after `resume()` is subsequently called, `current_state` advances to `WAVE_RESULTS` exactly once — the wave is not dropped and does not double-advance.
- **AC43**: GIVEN `current_state == WAVE_ACTIVE` and the C# Wave System emits `wave_complete` twice for the same wave (known C# edge case per E32), WHEN both emissions are processed, THEN `current_wave` increments exactly once, the second emission is rejected with a warning (guard: `current_state != WAVE_ACTIVE`), and `WAVE_RESULTS` is entered exactly once.

### Group 12 — Consumer connection contract *(Integration, BLOCKING)*

*Covers anti-patterns, E15, E33–E36.*

- **AC44**: GIVEN a consumer scene that connects to `state_changed` in `_ready()` and is freed mid-run, WHEN the consumer's `_exit_tree()` runs, THEN all signal connections made in `_ready()` are disconnected using the `is_connected()` guard pattern — no orphaned connections remain and no "signal connected to freed object" error appears in subsequent signal emissions.
- **AC45**: GIVEN a consumer scene that is instantiated during an active `state_changed` signal dispatch, WHEN the consumer's `_ready()` completes, THEN `current_state` read in `_ready()` reflects the current state correctly — the consumer does not rely on catching the in-flight signal that caused its instantiation; no stale-state scenario results.
- **AC46**: GIVEN all 12 consumer autoloads are registered in Project Settings after `GameStateMachine` *(R2: was 13 — Wave Summary UI #32 deleted)*, WHEN the game starts for the first time (first `_ready()` cycle), THEN all consumer autoloads have connected their signal handlers before any scene-level `_ready()` can call `transition_to()` — verified by log ordering in dev build.

### Group 13 — Pillar 4 felt experience *(Visual/Feel, ADVISORY — manual sign-off)*

- **AC47** *(R3 — clarified for Tab-toggle change)*: GIVEN a player is in `WAVE_ACTIVE` with enemies visibly moving toward towers, WHEN the player presses the pause input, THEN within one rendered frame all enemy movement halts, the pause overlay is visible per "Pause Overlay Contents" (Section "UI Requirements") with the current build summary displayed, and the player can hover/tap any card row to read its full description (per D11 expand-on-tap) for a minimum of 60 seconds without any enemy advancing, wave timer decrementing, or resource value changing — confirmed via manual playtest sign-off recorded in `production/qa/evidence/`. **The "build summary" surface referenced here is owned by HUD GDD #29's pause overlay implementation per the content requirements in this GDD.** AC is ADVISORY; the BLOCKING mechanical correctness is covered by AC9, AC10, AC42, AC51 (pause-aware phase timer). **R3 note**: the 60-second criterion is satisfied by the pause overlay holding state (no time pressure on the player to release); it does NOT require the player to hold a key for 60 seconds. The Tab-summary overlay (Core Rule 15) is now press-toggle (R3) and is a separate surface from the pause overlay.

### Group 14 — New tightenings (T13–T18) *(Logic + Integration, BLOCKING)*

*Covers T13 (F6 pause-aware phase timer), T14 (external pause reconciliation), T15 (quit-from-CARD_ROLL confirmation), T16 (sentinel typing), T17 (load_snapshot signal contract).*

- **AC48** *(T15, locked 2026-05-01 per D10)*: GIVEN `current_state == RUN_PAUSED` AND `previous_state == CARD_ROLL`, WHEN the player triggers the pause overlay's "Quit Run" button (which would call `quit_run(QUIT)`), THEN a confirmation dialog appears with text **"Quit run? You'll lose this run's build, but unlocks and lifetime currency are saved."**, and `quit_run()` is NOT called until the player confirms. If the player cancels, the overlay returns to its non-confirm state and `current_state` remains `RUN_PAUSED`. (For `previous_state != CARD_ROLL`, the confirm dialog MUST NOT appear — quit fires immediately.)
- **AC49** *(T14, rewritten 2026-05-01 per D5)*: GIVEN `current_state == WAVE_ACTIVE`, WHEN `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` fires (simulated by the test fixture — represents Steam overlay activation, Alt-Tab, window minimize, or OS focus loss), THEN within one engine frame `current_state` becomes `RUN_PAUSED` with `previous_state == WAVE_ACTIVE` and `run_paused.emit()` has fired. **Reverse case**: GIVEN `current_state == RUN_PAUSED` (entered via the synthetic focus-out path), WHEN `_notification(NOTIFICATION_APPLICATION_FOCUS_IN)` fires, THEN within one engine frame `current_state` becomes `WAVE_ACTIVE` and `run_resumed.emit()` has fired. The previous `get_tree().paused`-polling formulation is rejected — Steam overlay does not toggle `SceneTree.paused` (it captures input at OS level), so polling never detected it.
- **AC50** *(T16, locked 2026-05-01 per E16)*: GIVEN `previous_state` is declared as `int` with module-level constant `STATE_NONE = -1` AND a snapshot is loaded with `previous_state == STATE_NONE`, WHEN the load-validation check from E26 runs, THEN the snapshot is rejected (matches `STATE_NONE` correctly because `int` typing preserves `-1` without coercion). **Reverse-test (developer-reference only — DO NOT include in default CI)**: GIVEN `previous_state` is INCORRECTLY declared as `GameState` enum AND a snapshot has `previous_state == STATE_NONE`, WHEN load runs, THEN the value coerces to `0` (= `MAIN_MENU`) and the E26 check FAILS to fire. The reverse-test lives in `tests/unit/run_state/typing_contract_negative_test.gd` and is **excluded from the passing CI suite** — the file MUST carry a top-of-file comment "developer reference — DO NOT add to default CI" so future contributors do not accidentally re-include it. It exists to document the typing bug, not to gate releases.
- **AC51** *(T13 + T19, locked 2026-05-01 per E1)*: GIVEN the test fixture injects a controlled clock via `_test_clock_provider: Callable` (or by overriding `_get_unix_time()` directly) AND `current_state == CARD_ROLL` with `phase_entered_at = 1000.0`, WHEN the fixture sets `_test_clock_provider` to return `1060.0` and calls `pause()` (60s into card-roll, 240s remaining on the 300s ceiling), the fixture then sets `_test_clock_provider` to return `4660.0` (advancing simulated time by 3600s = 1 hour), and `resume()` is called, THEN F6 offsets `phase_entered_at` to `1000.0 + (4660.0 - 1060.0) = 4600.0`, F2 evaluates `max(0.0, 4660.0 - 4600.0) >= 300.0` = `60.0 >= 300.0` = `false`, and the card-roll does NOT auto-skip on resume — 240 seconds of active card-roll time remain. The clock-injection hook (T19) is a prerequisite for this AC to be implementable; the previous "advances simulated time" wording was unimplementable because `Time.get_unix_time_from_system()` cannot be mocked.
- **AC52** *(T17, Option A — `state_loaded` signal)*: GIVEN `GameStateMachine.current_state == MAIN_MENU` AND a Test Harness consumer subscribed to both `state_changed` and `state_loaded`, WHEN `load_snapshot(valid_snapshot_with_state_WAVE_ACTIVE)` is called, THEN `state_loaded.emit(snapshot)` fires exactly once, `state_changed` does NOT fire (or fires only with the `_is_loading_snapshot` flag set, per Option B), and `current_state == WAVE_ACTIVE` after the call returns. Adaptive Music's test fixture confirms it does NOT trigger a wave-start crossfade on this load.

### Group 15 — quit_run from each in-run state *(Logic, BLOCKING)*

*Covers T7 / E5 — adds coverage for RUN_PREP, WAVE_RESULTS, CARD_ROLL (existing AC11-AC13 cover RUN_PAUSED, WAVE_ACTIVE, RUN_LOADING).*

- **AC53** *(T7, locked 2026-05-01 per E5)*: GIVEN `current_state == RUN_PREP`, WHEN `quit_run(RunOutcome.QUIT)` is called (e.g., OS-level Alt-F4 or pause-overlay quit), THEN `current_state` becomes `RUN_RESULTS`, `run_ended` emits with `outcome == RunOutcome.QUIT`, and no "invalid transition" warning is logged.
- **AC54** *(T7, locked 2026-05-01 per E5)*: GIVEN `current_state == WAVE_RESULTS`, WHEN `quit_run(RunOutcome.QUIT)` is called (during the ~1.5s WAVE_RESULTS beat — e.g., player Alt-F4s while currency drops are settling), THEN `current_state` becomes `RUN_RESULTS`, `run_ended` emits with `outcome == RunOutcome.QUIT`, and no warning is logged.
- **AC55** *(T7 + T15, locked 2026-05-01 per E5)*: GIVEN `current_state == CARD_ROLL` (no pause overlay active), WHEN `quit_run(RunOutcome.QUIT)` is called via OS-level quit (the pause overlay does not exist in this state), THEN the confirmation dialog from T15 appears (per Core Rule 14 — CARD_ROLL is the only in-run state where confirmation is required), and `quit_run()` actually completes only after player confirmation. If confirmed: `current_state` becomes `RUN_RESULTS`, `run_ended` emits with `outcome == RunOutcome.QUIT`. If cancelled: `current_state` remains `CARD_ROLL`.

### Group 16 — defeat-path wave increment *(Logic, BLOCKING)*

*Covers E3 / E21 update — defeat path must increment `current_wave` before `run_ended(DEFEAT)`.*

- **AC56** *(E3, locked 2026-05-01)*: GIVEN `current_state == WAVE_ACTIVE` for wave 5 (i.e., `current_wave == 4` per Core Rule 7) AND player HP reaches 0, WHEN the defeat path triggers, THEN `current_wave == 5` at the moment `run_ended(DEFEAT)` fires (NOT 4). The increment happens inside the defeat path immediately before the signal emission, compensating for the skipped WAVE_RESULTS state. Without this, leaderboard "died on wave N" reads wave 4 when the player actually died on wave 5.

### Group 17 — *(R2 — DELETED in R3)*

> **DELETED 2026-05-01 (R3)**: was the suspend-save anchor test group (AC57–AC62) covering `save_for_resume()` anchor selection per current state and meta-progress event re-fire suppression. All six ACs are obsolete with the suspend-save mechanism removed in R3. There is no `save_for_resume()` API and no `fire_meta_progress_event()` API to test.

### Test evidence summary (updated for R3)

The 2026-05-01 R2 revision pass added 11 new BLOCKING ACs across three new groups (Group 15: AC53–AC55, Group 16: AC56, Group 17: AC57–AC62) and modified existing ACs (AC23, AC24, AC25, AC27, AC34, AC48, AC49, AC50, AC51) plus deleted AC29. **R3 deleted Group 17 entirely (AC57–AC62) and clarified AC27 + AC47 for the boss-kill beat extension and Tab-toggle change.** Net AC count after R3: **56 BLOCKING + 1 ADVISORY = 57** (was 62 in R2; -6 from Group 17 + 1 net from rewording = -6 net). AC47 remains ADVISORY; AC40 remains DEFERRED.

---

### Test evidence summary

| Group | AC range | Test type | Gate level | Location |
|---|---|---|---|---|
| 1 — State machine | AC1–AC5 | Logic | BLOCKING | `tests/unit/run_state/` |
| 2 — Pause/resume | AC6–AC10 | Logic | BLOCKING | `tests/unit/run_state/` |
| 3 — Quit-run | AC11–AC14 | Logic | BLOCKING | `tests/unit/run_state/` |
| 4 — Wave counter | AC15–AC18 | Logic | BLOCKING | `tests/unit/run_state/` |
| 5 — Card-roll | AC19–AC23 | Logic + Integration | BLOCKING | `tests/unit/run_state/` + `tests/integration/run_state/` |
| 6 — Phase pacing | AC24–AC28 (AC29 DELETED per D1) | Logic | BLOCKING | `tests/unit/run_state/` |
| 7 — Elapsed time | AC30–AC33 | Logic | BLOCKING | `tests/unit/run_state/` |
| 8 — Run-end outcome | AC34a–AC35 (AC34 split into AC34a/b per E14) | Logic | BLOCKING | `tests/unit/run_state/` |
| 9 — Save/load | AC36–AC38 | Integration | BLOCKING | `tests/integration/run_state/` |
| 10 — Test Harness | AC39–AC41 | Integration | BLOCKING (AC40 DEFERRED per E6) | `tests/integration/run_state/` |
| 11 — Cross-language | AC42–AC43 | Integration | BLOCKING | `tests/integration/run_state/` |
| 12 — Consumer contract | AC44–AC46 | Integration | BLOCKING | `tests/integration/run_state/` |
| 13 — Pillar 4 felt | AC47 | Visual/Feel | ADVISORY | `production/qa/evidence/` |
| 14 — T13–T18 | AC48–AC52 | Logic + Integration | BLOCKING | `tests/unit/run_state/` + `tests/integration/run_state/` |
| 15 — quit_run state coverage (T7 / E5) | AC53–AC55 | Logic | BLOCKING | `tests/unit/run_state/` |
| 16 — defeat-path increment (E3) | AC56 | Logic | BLOCKING | `tests/unit/run_state/` |
| ~~17~~ — *(R3 — DELETED)* | ~~AC57–AC62~~ | — | — | suspend-save mechanic removed |

**Totals (post-R3 revision, 2026-05-01)**: **56 criteria — 35 Logic (BLOCKING), 20 Integration (BLOCKING), 1 Visual/Feel (ADVISORY)**. AC40 remains DEFERRED pending Test Harness #45 linter. AC50's reverse-test isolated to `tests/unit/run_state/typing_contract_negative_test.gd` and excluded from default CI per E16.

## Open Questions

This section captures unresolved design threads and the worklist for `/propagate-design-change` (which will run after this GDD is approved).

### Worklist — 19 ADR tightenings to propagate (was 22; T20–T22 deleted in R3)

Implementation-contract changes flagged across Sections C/D/E. ADR-0001 is still in `Proposed` status — these tightenings do not require superseding ADRs. ADR-0006 is no longer affected (R3 removed the suspend-save persistence path). The full canonical descriptions are in the **consolidated tightenings table** at the end of Section E (T1–T19 active; T20–T22 deleted); this worklist mirrors that table with assigned owners + propagation targets so `/propagate-design-change` can iterate row-by-row.

| # | Source | Owner | Target | Status |
|---|---|---|---|---|
| T1 — `quit_run(outcome)` API | Section C, Rule 5 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T2 — Runtime fields only (R3: no schema bump; suspend-save removed) | Section D, F4–F6 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T3 — `get_displayed_wave_number(state_override)` helper | Section D, F3 (signature extended per E13) | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T4 — MAIN_MENU resets run-context fields | Section E, E14 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T5 — `_pending_wave_complete` resume-replay (E17/E31 BUG FIX) | Section E, E17 + E31 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T6 — Outcome priority VICTORY > DEFEAT > QUIT | Section E, E19 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T7 — `quit_run()` callable from any in-run state | Section E, E20 + AC53–AC55 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T8 — `wave_ended` fires before `run_ended(DEFEAT)` + defeat-path `current_wave++` (E3) | Section E, E21 + AC56 | godot-gdscript-specialist + Wave & Spawn GDD #18 author | Before Wave & Spawn GDD authoring begins | Pending |
| T9 — `card_picked.emit()` gated on CARD_ROLL state | Section E, E22 | godot-gdscript-specialist | Before Card-Roll GDD #22 authoring begins | Pending |
| T10 — Save-load validation (auto-resume from RUN_PAUSED; reject corrupted) | Section E, E25–E27 | godot-gdscript-specialist + ADR-0006 author | Before ADR-0006 promotion to Accepted | Pending |
| T11 — `load_snapshot()` Test Harness API + code-review-checklist rule (E7 reclassified) | Section E, E29 | godot-gdscript-specialist + Test Harness GDD #45 author | Before Test Harness GDD authoring begins | Pending |
| T12 — `pause()` / `resume()` return `bool` | Section E, E30 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T13 — Pause-aware phase timer (`phase_pause_started_at` + offset on resume) | Section D, F6 + E38 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T14 — External pause via `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT/IN)` (locked per D5) | Section C Rule 12 + E37 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T15 — Quit-from-CARD_ROLL confirmation dialog (locked text per D10) | Section C Rule 14 + E39 + UI Requirements | godot-gdscript-specialist + HUD GDD #29 author | Before HUD GDD #29 authoring begins | Pending |
| T16 — `previous_state` typed `int` + `STATE_NONE = -1` constant | Section E, E26 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T17 — `load_snapshot()` `state_loaded` signal — subscriber-contract change, NOT save-schema (per E21 reclass.) | Section E, E29 | godot-gdscript-specialist | Before ADR-0001 promotion to Accepted | Pending |
| T18 — Heterogeneous deferred targets guard (optional MVP-deferred polish) | Section E, E40 | godot-gdscript-specialist | Optional — defer until consumer-side spam observed | Open / deferred |
| T19 — `_get_unix_time()` virtual hook for clock injection (locked per E1; R3 single-mechanism clarification) | Section D preamble + AC51 | godot-gdscript-specialist + Test Harness GDD #45 author | Before ADR-0001 promotion to Accepted | Pending |
| ~~T20~~ — *(R3 — DELETED)* | — | — | — | Removed with suspend-save mechanic |
| ~~T21~~ — *(R3 — DELETED)* | — | — | — | Removed with suspend-save mechanic |
| ~~T22~~ — *(R3 — DELETED)* | — | — | — | Removed with suspend-save mechanic |

**Action**: Run `/propagate-design-change` after this GDD is approved. The skill should iterate the active rows (T1–T19), update ADR-0001 sections, and mark each row as `Resolved` or `Deferred` with rationale. ADR-0006 propagation is no longer required (R3 removed the run-snapshot persistence path; v1→v2 schema bump dropped). **Tightenings T13–T18 are from the 2026-05-01 `/design-review`; T19 was added during the 2026-05-01 R2 revision pass; T20–T22 were added in R2 and deleted in R3 along with the suspend-save mechanism.**

### Coherence flags (deferred revision candidates)

- **`RUN_LOADING` is correctness-only** (~0.5s transient): no player-experience design. If load time later compresses sub-frame (e.g., resource preloading moves to a background thread before CHAMPION_SELECT exits), RUN_LOADING is a candidate for collapse into CHAMPION_SELECT's exit transition.
  - **Owner**: tech-lead at architecture revision time
  - **Target**: post-MVP (V1 prep phase)
  - **Status**: Open — not blocking MVP
- **`CHAMPION_SELECT` MVP impl is a debug dropdown** (per systems-index VS-tier promotion): MVP uses a debug Champion-picker dropdown rather than the full UI. Design intent (Pillar 1 weight) is correct and locked; UI debt to pay before V1 ship.
  - **Owner**: ux-designer + ui-programmer at VS-tier UI authoring
  - **Target**: VS milestone
  - **Status**: Open — known UI debt; not blocking MVP

### Pre-implementation verifications (carried from ADR-0001 §494–498 + 2026-05-01 revision additions)

Before the first Run State implementation story, verify on the dev machine:

1. Autoload `_ready()` runs before any scene-level `_ready()` in Godot 4.6.2.
2. `process_mode = PROCESS_MODE_ALWAYS` keeps signal handler continuations firing while `get_tree().paused = true`.
3. Typed Callable connection (`signal.connect(callable)`) compiles and works in Godot 4.6.2.
4. Enum-as-int serialization to JSON via `JSON.stringify()` round-trips correctly.
5. **GDD-added**: `pause()` / `resume()` signal emission ordering relative to `get_tree().paused = true` toggle works as documented in ADR-0001 §455 — write a 30-line test scene that pauses the tree, fires a deferred `Tween` from a `state_changed` handler during pause, and confirms the Tween completes after resume (per AC9).
6. **Added 2026-05-01 (per D5; R3 fallback added)**: Confirm that `NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_APPLICATION_FOCUS_IN` fire correctly for the Steam overlay activation in dev builds (Steam client present, Big Picture mode + windowed-mode test). **Documented fallback (R3, addresses godot-specialist's BLOCKING #1)**: if the Steam overlay does NOT trigger the focus-out notification on Windows D3D12 borderless mode, `GameStateMachine` adds a low-frequency (~10 Hz) poll of `DisplayServer.window_is_focused()` from `_process()` (which already runs at PROCESS_MODE_ALWAYS for F2 timers), comparing against the previous frame's value to detect transitions. The poll is confined to the autoload itself — no per-consumer overhead. The fallback is implemented only if the verification fails; if the notification fires correctly, the poll is not added.
7. **Added 2026-05-01 (per E1 / T19)**: Confirm that overriding `_get_unix_time()` in a test fixture (or assigning `_test_clock_provider` to a `Callable` returning a controlled value) is observed by all formula call sites (F2, F4, F5, F6) — write a 20-line test that injects a clock returning 1000.0, calls each formula, and asserts each returns the controlled-time-derived value. AC51, AC30–AC33 are unimplementable until this verification passes.
8. **Added 2026-05-01 (per E11 — 5-min check)**: Test on Godot 4.6.2 dev build whether `var x: GameState = -1` silently coerces to `0` (= `MAIN_MENU`). If yes, the `STATE_NONE` typing rule (T16) applies as written. If no (the assignment fails or warns), simplify the rule and update T16 + AC50.
9. **Added 2026-05-01 (per E9)**: Confirm `application/run/low_processor_mode = false` in `project.godot` (this is the Godot 4.6.2 default; this verification only catches accidental override). Required because `true` would suppress `_process()` on idle frames during external pause and break T14's focus-notification handling.
10. **Added 2026-05-01 (per D12)**: Confirm gamepad `Start / Options` button is mapped to the pause input action and triggers the pause overlay in a smoke test. Required for AC48 / pause-overlay gamepad coherence.

**Owner**: First Run State implementation story author (godot-gdscript-specialist).
**Target**: Before first implementation PR.
**Status**: Open — pre-implementation gate.

### Open design threads

None at GDD approval. The design questions surfaced during authoring (prep duration, quit-from-pause path, WAVE_RESULTS advance behavior, active-play vs wall-clock elapsed) were all resolved within this session and are reflected in the locked content above. If new threads arise during implementation or `/design-review`, append them here.

### `/design-review` recommendation

*(R3 update — was R1 historical note: "This GDD covers a 13-consumer bottleneck system with 47 acceptance criteria, 36 edge cases, and 12 ADR tightenings.")* Post-R3 totals: **12-consumer bottleneck system with 56 acceptance criteria (35 Logic BLOCKING + 20 Integration BLOCKING + 1 ADVISORY), 35 edge cases (E27a-e deleted in R3; E1 deleted in R2), and 19 active ADR tightenings (T20-T22 deleted in R3).** Two `/design-review` passes (2026-05-01 R2 and R3) have been run; revision history is in the header. Future re-reviews append to `design/gdd/reviews/run-state-game-flow-review-log.md`.
