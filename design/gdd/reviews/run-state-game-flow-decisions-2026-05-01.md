# Run State / Game Flow — Design Decisions Log

> **Review Date**: 2026-05-01
> **Reviewer**: `/design-review` (full mode — 5 specialists + creative-director)
> **GDD Reviewed**: `design/gdd/run-state-game-flow.md`
> **Original Verdict**: **MAJOR REVISION NEEDED**
> **Status**: APPLIED 2026-05-01 — all D1–D12 + E1–E22 + ED1–ED5 reflected in `design/gdd/run-state-game-flow.md` (R2). Pending `/design-review` re-verification + `/propagate-design-change` to ADR-0001 + ADR-0006. **This file is a historical record, not a pending worklist.**
> **Branch**: tower-defense-game

---

## Purpose of This Document

This file is the **complete, self-contained record** of the design decisions made during the 2026-05-01 design-review session. It is intended to be loaded by a fresh Claude Code session that will apply these decisions to the GDD and downstream files.

**A fresh session has zero memory of the review conversation.** Everything needed to apply the revisions is in this file.

---

## How to Resume This Work in a Fresh Session

After running `/clear` to start fresh, paste this exact prompt:

```
Read these files in order to recover context:
1. design/gdd/reviews/run-state-game-flow-decisions-2026-05-01.md (this file — decision log)
2. design/gdd/run-state-game-flow.md (the GDD to revise)
3. docs/architecture/adr-0001-run-state-game-flow.md (governing ADR — propagation target)
4. docs/architecture/adr-0006-save-schema-versioning.md (save-schema ADR — propagation target)

Then apply the design decisions from the decision log to the GDD section by section.
Use Edit tool for surgical changes; ask before each section's edits.
After GDD revisions complete, run `/design-review design/gdd/run-state-game-flow.md` for re-verification.
Then run `/propagate-design-change` to update ADR-0001 and ADR-0006 with the new tightenings.
```

This will load the right context and start the revision workflow.

---

## Specialists Consulted

- **game-designer**: Pillar 4 anchor review; surfaced 7 findings including the floor/auto-advance contradictions
- **systems-designer**: Formula boundary tests; surfaced 10 findings including F4/F5 leaderboard inflation, defeat-path `current_wave` undercount, F2 canonical form contradiction
- **qa-lead**: AC testability review; surfaced 10 findings including "deferred-blocking" undefined, Time mockability, T7 coverage gap
- **ux-designer**: Pause Overlay UX; surfaced 10 findings including ownership split, missing gamepad mapping, misleading confirmation text
- **godot-specialist**: Engine-pattern validation; surfaced 6 critical issues including Steam overlay technically wrong, AC51 unimplementable, window-minimization caveat
- **creative-director**: Senior synthesis; verdict MAJOR REVISION NEEDED; adjudicated specialist disagreements

---

## Section A — Locked Player-Facing Design Decisions (12)

These are the user's explicit choices during the 2026-05-01 review session.

### D1 — Prep Phase Floor: REMOVED

**Original GDD design**: Player presses Ready → wait minimum 45 seconds (`tk_prep_floor`) before wave starts.

**Locked decision**: REMOVED entirely. Ready advances the wave immediately.

**Rationale (user)**: Early-level gameplay is designed easy enough to win without towers. Onboarding tutorial covers new-player risk. The 45-second floor was paternalism that contradicted Pillar 4 ("the run waits for you").

**GDD changes required**:
- **Section C, Core Rule 9**: Rewrite. Was "RUN_PREP is player-advance-when-ready with an AFK timeout." Now: "RUN_PREP advances immediately on `action_wave_start` input; an AFK timeout fires at the ceiling for unattended runs."
- **Section D, F1**: Simplify formula to `effective_prep_duration = min(player_advance_time_seconds, prep_ceiling_seconds)`. Delete `prep_floor_seconds` variable, the clamp wrapping, and the floor rationale paragraph.
- **Section E, E1**: DELETE this edge case (degenerate prep config) — no longer applicable.
- **Section G, tuning knob table**: DELETE `tk_prep_floor` row entirely.
- **Section G, knob interactions**: DELETE the `tk_prep_floor ↔ tk_prep_ceiling` invariant; update the composition formula.
- **Section H, AC24**: Rewrite. Was about floor enforcement. Now: "GIVEN `current_state == RUN_PREP`, WHEN player presses `action_wave_start` at any time, THEN transition to `WAVE_ACTIVE` fires immediately within one frame."
- **Section H, AC29**: DELETE (was the misconfiguration assertion test).

**Files affected**: `design/gdd/run-state-game-flow.md` only.

---

### D2 — Wave Summary Screen: DELETED

**Original GDD design**: WAVE_RESULTS state shows a 5-second auto-advancing screen with kills, time, drops.

**Locked decision**: Wave Summary screen is DELETED. WAVE_RESULTS state still exists briefly (~1-2 second beat) for currency drops to settle and a small "Wave N complete" toast notification at the top of the screen. No screen takeover.

**Rationale (user)**: Three-tier display model — corner HUD (always visible), Tab-key full run summary, no per-wave summary screen. Per-wave screens × 10 waves = ~50 seconds of non-gameplay the player didn't ask for.

**GDD changes required**:
- **Section C, States and Transitions table**: Update WAVE_RESULTS row. Target duration: "1-2s beat (no screen takeover)". Pause allowed: still Yes.
- **Section C, Interactions table**: Wave Summary UI (#32) row — change to "DELETED — no longer in scope. Replaced by toast notification (HUD #29 owns) + Tab-toggle run summary (HUD #29 owns)."
- **Section D, F2**: Remove `tk_wave_results_advance_seconds` from auto-advance examples (no auto-advance from a screen the player can't be on).
- **Section G, tuning knob table**: DELETE `tk_wave_results_advance_seconds` row.
- **Section G, knob interactions**: Update composition formula (no wave-results-advance term).
- **Section F, Dependencies**: Remove Wave Summary UI #32 from downstream consumer table OR mark as "DELETED from MVP scope."
- **Section H, AC27**: Rewrite. Was "5-second auto-advance fires." Now: "GIVEN WAVE_RESULTS entered, WHEN ~1-2 seconds elapse, THEN auto-advance to CARD_ROLL fires (or directly to RUN_RESULTS if defeat path)."

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- `design/gdd/systems-index.md` — Wave Summary UI #32 row should be marked "DELETED" or "Deferred indefinitely (replaced by toast + Tab summary)"

---

### D3 — Tab-Key Full Run Summary: ADDED

**Original GDD design**: No Tab-key run summary; full run stats only at run end.

**Locked decision**: Player presses Tab to overlay a full run summary on any in-run state. Releasing Tab dismisses it. Shows kills, time elapsed, drops, current build, wave count.

**Rationale (user)**: Standard genre convention (Risk of Rain 2, Slay the Spire). Solves the mid-run "how am I doing?" need without screen takeover.

**GDD changes required**:
- **Section C, Interactions table**: Add a new row for "HUD #29 (Tab-toggle run summary surface)" — content requirement that HUD #29 must implement.
- **Section C, Core Rules**: Add new Core Rule 15: "Run summary is overlaid on demand via Tab-toggle input. The overlay reads from `GameStateMachine` snapshot; it does not change run state."

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- HUD GDD #29 (when authored): inherits Tab-toggle run summary as a content requirement.

---

### D4 — Pause Time Excluded from Leaderboard: CONFIRMED

**Original GDD design**: F4 already excluded pause time, but F5 had a bug (open intervals discarded even on intentional save).

**Locked decision**: Active-play time only. Pause time NEVER counts toward leaderboard times. The save-during-pause inflation bug must be fixed.

**Rationale (user)**: Leaderboard measures skill, not wall-clock. A player who paused for a phone call shouldn't be penalised.

**GDD changes required**:
- **Section D, F5**: Add explicit text: "On intentional save during pause, the in-progress pause interval is included in `total_paused_seconds` via `phase_pause_started_at` (which IS in the snapshot). On crash, the open interval is discarded (data loss is unavoidable)."
- **Section E, E10**: Update — distinguish crash (discard) from intentional save (preserve).
- **Section H, AC31**: Update to reference the corrected F5 behavior.
- See Engineering Fix E4 below for snapshot expansion.

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- `docs/architecture/adr-0001-run-state-game-flow.md` (snapshot Dictionary expansion)
- `docs/architecture/adr-0006-save-schema-versioning.md` (schema_version bump 1→2)

---

### D5 — Auto-Pause on Focus Loss: PROPER IMPLEMENTATION

**Original GDD design**: Core Rule 12 + T14 — `_process()` polls `get_tree().paused` to detect external pause sources (Steam overlay, OS focus loss, debug console).

**Locked decision**: Replace the polling approach with `NOTIFICATION_APPLICATION_FOCUS_OUT` / `NOTIFICATION_APPLICATION_FOCUS_IN` handlers. Steam overlay, Alt-Tab, window minimize all trigger auto-pause via the focus signal.

**Rationale (godot-specialist)**: `get_tree().paused` polling does NOT detect Steam overlay (it captures input at OS level, doesn't toggle SceneTree.paused) and doesn't reliably detect window minimization. The focus signal is the correct primitive.

**GDD changes required**:
- **Section C, Core Rule 12**: Rewrite. Was "GameStateMachine reconciles `get_tree().paused` in `_process()`." Now: "GameStateMachine subscribes to `NOTIFICATION_APPLICATION_FOCUS_OUT/IN` via `_notification()`. On focus-out, synthetic `pause()` fires; on focus-in, `resume()` fires. This handles Steam overlay, Alt-Tab, window minimize, OS focus loss uniformly."
- **Section E, E37**: Rewrite. Reference focus notifications instead of `get_tree().paused` polling.
- **Section H, AC49**: Rewrite. Was about `get_tree().paused` polling reconciliation. Now: "GIVEN `current_state == WAVE_ACTIVE`, WHEN `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` fires, THEN `current_state == RUN_PAUSED` and `run_paused.emit()` has fired within one frame."
- **Pre-implementation verification (Section Open Questions)**: Add: "Verify that `NOTIFICATION_APPLICATION_FOCUS_OUT/IN` fires for Steam overlay activation in dev builds."
- **T14 in tightenings table**: Update to reference focus notifications, not `get_tree().paused`.

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- `docs/architecture/adr-0001-run-state-game-flow.md` (T14 propagation)

---

### D6 — Save Model: Suspend Save (single save consumed on resume)

**Original GDD design**: Save model implicit — assumed via ADR-0006, but never explicitly nailed in the GDD.

**Locked decision**: SUSPEND SAVE model. Single save file written when player picks "Save & Resume Later." Loading the save consumes it (cannot reload twice). Cannot save-scum bad decisions by reloading.

**Rationale (user)**: Standard roguelite genre convention (Hades, Slay the Spire, Dead Cells). 30-60 minute runs need a "come back tomorrow" mechanism without enabling save-scumming.

**GDD changes required**:
- **Section A, Overview**: Add a sentence: "The system uses a suspend-save model — single save consumed on resume — to support cross-session run continuation without enabling save-scumming."
- **Section C, Core Rules**: Add new Core Rule 16: "Save & Resume Later writes a single suspend-save anchored to the start of the most recently entered WAVE_ACTIVE state. Loading the save consumes it (file deleted on successful load). Cards picked between waves but before the next wave's WAVE_ACTIVE entry are NOT in the save (player re-picks on reload). Meta-progress events (achievements, discovered enemies, lifetime currency awards) survive the save rollback — they fire immediately and are not part of the run snapshot."
- **Section F, Dependencies**: Save / Load (#2) row — strengthen to "Hard. Suspend-save is a content requirement on Save/Load #2's GDD."

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- `design/gdd/systems-index.md` — Save / Load #2 row may need to mention suspend-save model
- Save / Load GDD #2 (when authored): inherits the suspend-save model + wave-start anchor as upstream constraint.
- ADR-0006 (Save Schema): inherits the meta-progress separation rule.

---

### D7 — Save Trigger: Any Time, Anchored to Wave Start

**Locked decision**: Player can trigger Save & Resume Later from ANY in-run state (RUN_PREP, WAVE_ACTIVE, WAVE_RESULTS, CARD_ROLL, RUN_PAUSED). The save anchor is ALWAYS the start of the most recently entered WAVE_ACTIVE state.

**Examples**:
- Player saves mid-WAVE_ACTIVE for wave 5 → save = start of wave 5 WAVE_ACTIVE; cards 1-4 preserved
- Player saves during CARD_ROLL after wave 5 → save = start of wave 5 WAVE_ACTIVE; card 5 not yet in save (re-pick on reload)
- Player saves during RUN_PREP for wave 6 (after card 5 picked) → save = start of wave 6 WAVE_ACTIVE *if* wave 6 has been entered, else start of wave 5 WAVE_ACTIVE
- Wave 1: save anchor = the moment WAVE_ACTIVE was entered for wave 1 (no cards picked yet)

**Rationale (user)**: Eliminates mid-wave-state-capture complexity. Limits save-scumming to "replay the current wave" (cards already picked between completed waves stay locked in).

**GDD changes required**:
- **Section C, Core Rule 16**: Include the save-anchor rule (see D6 above).
- **Section D**: Add new formula F7 — "Save Anchor State Selection." Define which state to capture for the save based on current state:
  - If `current_state == WAVE_ACTIVE`: save state = `WAVE_ACTIVE`, `phase_entered_at = original wave-start time`, full state preserved as captured at wave-start
  - If `current_state in [WAVE_RESULTS, CARD_ROLL]`: save state = `WAVE_ACTIVE` of the just-completed wave (replay the wave; re-pick the card)
  - If `current_state == RUN_PREP`: save state = `WAVE_ACTIVE` of the upcoming wave's prep — wait, this needs clarification (see ambiguity note below)
  - If `current_state == RUN_PAUSED`: save state = `WAVE_ACTIVE` of `previous_state`'s anchor (apply rule recursively)
- **Section H**: Add new Group 15 with ACs covering save-trigger from each in-run state and the resulting save anchor.

**Ambiguity to resolve in revision pass**: "Save during RUN_PREP for wave 6" — does the save anchor go back to wave 5 start (one full wave loss) or anchor at wave 6 prep (no loss)? My recommendation in the revision: save during RUN_PREP for wave N anchors at the START of wave N's RUN_PREP (i.e., player on reload is back in prep for wave N with cards 1 through N-1 already picked). This preserves card decisions made for entry into wave N. Confirm during revision pass.

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- ADR-0001 (state-snapshot contract expansion)
- ADR-0006 (save schema)

---

### D8 — Save Scope: Cards-before-anchor preserved; meta-progress preserved

**Locked decision**:
- Cards picked BEFORE the save anchor's wave start are preserved in the save.
- Cards in pending state at save time (between WAVE_RESULTS and next WAVE_ACTIVE) are NOT preserved — player re-picks on reload.
- Meta-progress events (achievements, discovered enemies, lifetime currency awards) fire IMMEDIATELY when earned and are NOT rolled back. The save snapshot tracks `meta_progress_events_fired: Array[StringName]` to prevent re-fire on reload.

**GDD changes required**:
- See D6/D7 GDD changes above.
- **Section D, F8 (new)**: Define the meta-progress separation rule formally. Variables: `meta_progress_events_fired: Array[StringName]` — list of event identifiers that have already fired this run; on reload, events whose IDs are in this list are NOT re-fired.
- **Section E**: Add new edge cases: (a) reload after achievement-on-discovery — achievement does not re-fire; (b) reload after kill-milestone meta-currency award — currency is not re-awarded; (c) reload before achievement fired but in a wave where it would have fired — achievement fires normally on the replay (not in the list).

**Files affected**: same as D6/D7.

---

### D9 — Pause Menu Structure: Two Buttons

**Locked decision**: Pause menu has TWO distinct buttons:
1. "Save & Resume Later" — writes suspend save, returns to MAIN_MENU. Available from any in-run state.
2. "Quit Run" — forfeits the run with `RunOutcome.QUIT`. Awards partial meta-currency. Returns to MAIN_MENU via RUN_RESULTS.

**Rationale (user)**: Matches suspend-save model. Players have a clear distinction between "I'll come back to this run" and "I'm done with this run."

**GDD changes required**:
- **Section "UI Requirements"**: Update Pause Overlay Contents (item 2 currently lists only Quit-to-Menu). Add Save & Resume Later as a new required content item. Update behavior:
  1. Resume button — primary action; triggers `resume()`; rebindable to pause input (Esc / Start)
  2. **Save & Resume Later** — triggers save flow per D6/D7, returns to MAIN_MENU on success
  3. Quit Run — triggers `quit_run(QUIT)`. Confirmation dialog from CARD_ROLL only (per Core Rule 14)
  4. Current wave indicator (per F3 helper)
  5. Current build summary (per D11 below)
  6. Settings access — OMIT until Settings #42 ships

**Files affected**: `design/gdd/run-state-game-flow.md`

---

### D10 — Quit Confirmation Text

**Locked text**: **"Quit run? You'll lose this run's build, but unlocks and lifetime currency are saved."**

**GDD changes required**:
- **Section C, Core Rule 14**: Update text from "Quit run? Your progress will be lost." to the locked text.
- **Section H, AC48**: Update dialog text reference.

**Files affected**: `design/gdd/run-state-game-flow.md`

---

### D11 — Build Summary Display: Compact List with Expand-on-Tap

**Locked decision**: Pause overlay's build summary shows cards as a compact list (card name + small icon). Player hovers/taps a card to expand to full description. Standard genre pattern.

**Rationale (user)**: Fits up to 9 cards on any screen size. Matches Hades' boon menu pattern.

**GDD changes required**:
- **Section "UI Requirements"**: Update Pause Overlay Contents item 4 ("Current build summary"). Specify: "Compact list — card name + icon per row. Hover/tap reveals full description. List is fixed-height; cards beyond visible range are scrollable within the build-summary region."
- Add cross-reference to Card-Roll GDD #22 + Build/Modifier GDD #23 for card-data interface contract (this is the integration gap flagged by ux-designer + game-designer).

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- HUD GDD #29 (when authored): inherits compact-list-with-expand as visual implementation requirement.

---

### D12 — Gamepad Pause Button: Start / Options

**Locked decision**: Gamepad Start / Options button opens the pause menu. Pressing it again triggers the Resume action (toggling).

**Rationale (user)**: Universal genre convention. Maps to Xbox Menu/Start, PlayStation Options, Switch +.

**GDD changes required**:
- **Section "UI Requirements"**: Update Pause Overlay Contents item 1 (Resume button). Specify: "Resume input mapping — KB/M: Esc; Gamepad: Start/Options. Both inputs trigger pause OR resume (toggle behavior)."
- Add a sentence about gamepad-coherence: "All overlay buttons (Resume, Save & Resume Later, Quit Run) MUST be navigable via gamepad D-pad or analog stick; activation via face-South (A/Cross) button."
- **Pre-implementation verification**: Add gamepad input verification step.

**Files affected**:
- `design/gdd/run-state-game-flow.md`
- Input System GDD #1 (when authored): inherits Start/Options mapping as upstream constraint.

---

## Section B — Engineering Fixes (22)

These fixes follow from the design decisions OR are pure engineering corrections. They do not require user input, but they DO require GDD updates.

### E1 — Clock Abstraction (B1)

**Issue**: `Time.get_unix_time_from_system()` cannot be mocked. AC51, AC30-33, AC42, AC49 unimplementable.

**Fix**: Add `_get_unix_time() -> float` virtual hook on `GameStateMachine`. All formulas (F2, F4, F5, F6) call this hook. Tests inject a controlled clock by overriding the method or by setting a `_test_clock_provider: Callable` field.

**GDD changes**:
- **Section D preamble**: "All formulas use `_get_unix_time()` (a virtual method on GameStateMachine that defaults to `Time.get_unix_time_from_system()`) as the canonical wall-clock source. Test fixtures override this for deterministic time control."
- **Section H, AC51**: Update fixture description to reference `_test_clock_provider` injection.
- **Add new T19 to tightenings table**: "Add `_get_unix_time() -> float` virtual hook to `GameStateMachine`; ADR-0001 must specify the hook in Key Interfaces section."

---

### E2 — F2 Canonical Form (B5)

**Fix**: Lock F2 to safe form: `should_auto_advance = max(0.0, _get_unix_time() - phase_entered_at) >= ceiling_seconds`. Delete the unsafe form from formula box. Update Notes to confirm safe form is canonical.

---

### E3 — Defeat-Path `current_wave` Undercount (B6)

**Issue**: VALID_TRANSITIONS allows WAVE_ACTIVE → RUN_RESULTS direct (defeat path). Core Rule 7 increments `current_wave` on entry to WAVE_RESULTS. Defeat path skips WAVE_RESULTS → off-by-one.

**Fix**: On defeat path, increment `current_wave` BEFORE `run_ended(DEFEAT)` fires. Document in Core Rule 7.

**GDD changes**:
- **Section C, Core Rule 7**: Add: "On defeat path (WAVE_ACTIVE → RUN_RESULTS), `current_wave` is incremented immediately before `run_ended(DEFEAT)` to ensure the run summary reports the correct wave-of-death."
- **Section E, E21**: Update with the increment rule.
- **Section H**: Add new AC: "GIVEN `current_state == WAVE_ACTIVE` for wave 5 AND player HP=0, WHEN defeat path triggers, THEN `current_wave == 5` at the moment `run_ended(DEFEAT)` fires (not 4)."

---

### E4 — Snapshot Dictionary Expansion (B2 + B7 + D8)

**Fix**: Add the following keys to the snapshot Dictionary (and bump `run_snapshot.save` schema_version 1 → 2):
- `phase_pause_started_at: float` — timestamp of most recent pause; 0.0 if not paused
- `total_paused_seconds: float` — cumulative paused time (already in T2)
- `phase_entered_at: float` — timestamp of current phase entry (required for save-resume to preserve phase timer)
- `meta_progress_events_fired: Array[StringName]` — event IDs already fired this run (per D8 meta-progress separation)

**GDD changes**:
- **Section A, Overview**: No change (high-level)
- **Section D, snapshot section** (which references ADR-0001 §286-303): Update to list new keys.
- **Tightenings T2 + new T20**: Update T2 to expand the schema fields list. Add T20: "snapshot includes `phase_entered_at` and `phase_pause_started_at` for active-phase timer preservation."

---

### E5 — T7 quit_run AC Coverage (B9)

**Fix**: Add 3 new ACs covering `quit_run(QUIT)` from RUN_PREP, WAVE_RESULTS, CARD_ROLL.

**GDD changes**:
- **Section H, Group 3**: Insert AC11.5/11.6/11.7 (or renumber to AC15/16/17 in a new sub-group): cover quit_run from each of the three uncovered states.

---

### E6 — AC40 Reclassification (B10)

**Fix**: Remove AC40 from BLOCKING table. Reclassify as DEFERRED with explicit prerequisite: "Test Harness #45 linter must ship first." Document operational meaning of "deferred-blocking" or remove the term.

---

### E7 — Lints as Documentation (T11/T14)

**Fix**: Reclassify `direct_property_write_to_game_state_machine`, `direct_tree_pause_write` as code-review-checklist items, NOT automated lints. Note: GDExtension linter is V1+ consideration.

**GDD changes**: Update tightenings T11 + T14 entries. Add note in Open Questions: "Automated lint enforcement deferred to V1+ pending GDExtension linter."

---

### E8 — Steam Overlay Implementation (B3)

See D5. Replace `_process()` polling with `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT/IN)` handler.

---

### E9 — Window Minimization Caveat (B4)

**Fix**: Pin `application/run/low_processor_mode = false` in project settings (default — this is just a constraint reminder).

**GDD changes**: Add to pre-implementation verifications.

---

### E10 — T13 Implementation Note (R6)

**Fix**: `phase_pause_started_at` MUST be set inside `pause()` itself, regardless of trigger source (player input, focus signal, manual API call). Document explicitly.

---

### E11 — T16 Enum Verification (R7)

**Fix**: Add 5-min verification step to pre-implementation checklist: "Test on Godot 4.6.2 dev build whether `var x: GameState = -1` silently coerces to `0`. If yes, `STATE_NONE` rule applies as written. If no, simplify the rule."

---

### E12 — F1 Assertion Removal (R1)

**Note**: D1 removes the floor entirely. The `prep_floor < prep_ceiling` assertion is no longer needed. Delete the assertion entirely.

---

### E13 — F3 Wave-Display Helper (R18)

**Fix**: Extend F3 with `state_override` parameter: `get_displayed_wave_number(state_override: GameState = current_state) -> int`. Pause overlay calls with `state_override = previous_state` to get correct displayed wave.

**GDD changes**: Update F3 signature in Section D and consumer references.

---

### E14 — AC34 100-Rep Cleanup (R9)

**Fix**: Replace 100-repetition determinism check with two single-assertion sub-cases:
- AC34a: GIVEN `_pending_outcome = DEFEAT` set, then `_pending_outcome = VICTORY` set, in same deferred frame → resolves to VICTORY.
- AC34b: GIVEN `_pending_outcome = VICTORY` set, then `_pending_outcome = DEFEAT` set, in same deferred frame → resolves to VICTORY.

---

### E15 — AC23 Specificity (R10)

**Fix**: Specify error type. Replace "without error" with "without `assert()` failures or Godot error log entries."

---

### E16 — AC50 Reverse-Test Isolation (R11)

**Fix**: Move AC50's reverse-test to `tests/unit/run_state/typing_contract_negative_test.gd`. Exclude from passing CI suite. Mark file as "developer reference — DO NOT add to default CI."

---

### E17 — Modal Stack Contract (R17)

**Fix**: Add a Core Rule (or sub-rule under UI Requirements): "Modal stack contract — each modal layer consumes its own dismiss input before propagating; outermost layer is last to receive input. Confirmation dialog over Pause Overlay over CARD_ROLL panel: Esc/B button dismisses topmost; pause input is suppressed while a modal is active."

---

### E18 — Input Suppression Rule (R16)

**Fix**: Update line 521 (UI Requirements behavioral requirements) to suppress gameplay inputs (shoot, ability activation, placement confirm) in addition to UI inputs.

---

### E19 — STATE_NONE Location (R19)

**Fix**: Lock `STATE_NONE = -1` to `GameStateMachine.STATE_NONE` class constant. Document in Section C.

---

### E20 — Tuning Composition Constraint (R3)

**Fix**: Add hard bound to tuning table: `(0 + tk_prep_ceiling) × tk_waves_per_run < 3600s` (or whatever the locked composition is, post-D1/D2). Note that `tk_wave_results_advance_seconds` is gone.

---

### E21 — T17 Reclassification (R4)

**Fix**: Document T17 separately as subscriber-contract change (signal API addition), NOT save-schema change. Update tightenings table to clarify scope.

---

### E22 — F5 Crash-vs-Save Distinction (R20)

**Fix**: Explicit text in F5: "On normal save during pause, the in-progress pause interval is included via `phase_pause_started_at` snapshot field. On crash, the open interval is unrecoverable and is discarded on reload (data loss is unavoidable)."

---

## Section C — Editorial Fixes (Low Priority)

| # | Item | Fix |
|---|---|---|
| ED1 | Open Questions title says "12 ADR tightenings" | Update to "22 ADR tightenings" (T1-T22 including new) |
| ED2 | Group intro says "13 categories" | Update to "15 categories" (Group 14 added during review; new Group 15 added for save-trigger ACs in this revision) |
| ED3 | Total AC count | Recount after revisions; expected: ~58-60 ACs |
| ED4 | Settings placeholder button | Remove from Pause Overlay Contents — omit button entirely until #42 ships |
| ED5 | Active session state | Update `production/session-state/active.md` with revision status |

---

## Section D — Files That Need Updating

### Primary

1. **`design/gdd/run-state-game-flow.md`** — the GDD itself. Substantial revisions across all sections per D1-D12 + E1-E22.

### Secondary

2. **`design/gdd/systems-index.md`** — Wave Summary UI #32 row may be marked DELETED. Run State #8 row update to "In Review — Revisions Applied (pending re-review)" once GDD revisions complete.

3. **`docs/architecture/adr-0001-run-state-game-flow.md`** — propagate tightenings T1-T22. Update Decision section (signal contract, snapshot expansion, focus-notification handler), Migration Plan (new pre-impl verifications), Validation Criteria, Risks (Steam overlay risk closed; new risk for clock abstraction).

4. **`docs/architecture/adr-0006-save-schema-versioning.md`** — schema_version 1→2 migration for `run_snapshot`. Add suspend-save model documentation.

5. **`docs/registry/architecture.yaml`** — add new state ownerships for `phase_entered_at`, `phase_pause_started_at`, `meta_progress_events_fired`. Add `_get_unix_time()` virtual hook to interface contracts.

6. **`production/session-state/active.md`** — update with 2026-05-01 review completion + decisions-applied status.

### Tertiary (when downstream GDDs are authored)

7. **HUD GDD #29** (future) — inherits Tab-toggle run summary, compact build-summary list, gamepad pause mapping, modal stack contract.
8. **Save / Load GDD #2** (future) — inherits suspend-save model, wave-start anchor, meta-progress separation.
9. **Card-Roll GDD #22** (future) — re-pick on reload behavior + interface contract for build summary data.
10. **Wave & Spawn GDD #18** (future) — `wave_ended` before `run_ended(DEFEAT)` rule (T8 already documented).
11. **Test Harness GDD #45** (future) — Clock injection contract; AC40 linter prerequisite.
12. **Input System GDD #1** (future) — Start/Options gamepad mapping for pause.

---

## Section E — How to Apply These Decisions in a Fresh Session

### Step 1 — Recover Context

In a fresh session, paste the exact prompt at the top of this file (under "How to Resume This Work in a Fresh Session"). This loads the right files in the right order.

### Step 2 — Apply GDD Revisions Section-by-Section

Per the project's incremental file-writing rule, revise the GDD one section at a time. Suggested order (matches GDD top-to-bottom):

1. **Section A (Overview)** — add suspend-save sentence (D6)
2. **Section C (Detailed Design)** — Core Rules 9, 12, 14 updates (D1, D5, D10); add new Core Rules 15 (Tab summary) + 16 (suspend-save anchor); States table (D2 WAVE_RESULTS update); Interactions table (D2 Wave Summary UI deletion + D3 HUD Tab row); Anti-patterns unchanged
3. **Section D (Formulas)** — F1 simplify (D1); F2 canonical form (E2); F3 helper (E13); F5 crash-vs-save (E22); F6 unchanged; add new F7 (Save Anchor), F8 (Meta-Progress Separation)
4. **Section E (Edge Cases)** — DELETE E1 (D1); update E10 (D4); update E37 (D5); add new edge cases for save reload (D7/D8)
5. **Section F (Dependencies)** — Wave Summary UI #32 marked DELETED; Save/Load #2 strengthened (D6); add HUD #29 Tab-summary requirement
6. **Section G (Tuning Knobs)** — DELETE `tk_prep_floor` row (D1); DELETE `tk_wave_results_advance_seconds` row (D2); update knob interactions; update composition constraint (E20)
7. **Visual/Audio Requirements** — unchanged
8. **UI Requirements** — Pause Overlay Contents major update (D9, D10, D11, D12, E18); modal stack contract (E17)
9. **Section H (Acceptance Criteria)** — substantial revisions: AC24/27/29 rewrites or deletes (D1/D2); AC34a/b split (E14); AC23/AC50/AC51 fixes (E15/E16/E1); add AC11.5/11.6/11.7 for T7 coverage (E5); add AC for E3 defeat increment; new Group 15 for save-trigger ACs (D7)
10. **Open Questions** — update tightenings table to T1-T22; update worklist; remove resolved items; update title (ED1)

### Step 3 — Update Downstream Files

After GDD revisions complete:
- Update `design/gdd/systems-index.md` (Wave Summary UI #32 status, Run State #8 status)
- Update `production/session-state/active.md` (revision complete, ready for re-review)

### Step 4 — Re-Review

Run: `/design-review design/gdd/run-state-game-flow.md`

This validates the revisions and may surface additional findings.

### Step 5 — Propagate to ADRs

Run: `/propagate-design-change`

This iterates the T1-T22 tightenings table and applies to ADR-0001 + ADR-0006.

### Step 6 — Mark Complete

Once re-review passes:
- Update `design/gdd/systems-index.md` Run State #8 status to "Approved"
- Append a "Revision 2 — APPROVED" entry to `design/gdd/reviews/run-state-game-flow-review-log.md`
- Update `production/session-state/active.md` to reflect approval

---

## Section F — Specialist Disagreements (Adjudicated)

### Disagreement 1 — RUN_RESULTS content obligation

**[game-designer]** argued RUN_RESULTS lacks a required content obligation for meta-currency display + run-to-run progress (Pillar 4 emotional landing).

**[GDD design]** assigns this to Run Results UI #34 (downstream consumer).

**[creative-director]** did not directly engage.

**Adjudication (in revision)**: Defer to GDD's design (Run Results UI #34 owns it). BUT add a flag in the Dependencies section: "Run Results UI #34's content brief MUST include the Pillar 4 emotional landing requirement (meta-currency earned this run, lifetime progress delta, restart hook)." This is a content requirement Run State imposes on the consumer.

### Disagreement 2 — 45s prep floor

**[game-designer]**: Remove the floor.
**[GDD authors]**: Keep the floor as Pillar 4 protection.
**[creative-director]**: Compromise — keep but add cancel-Ready.
**[user, this session]**: REMOVE entirely (D1). Resolves the disagreement decisively.

---

## Section G — Audit Trail

| Date | Event | Outcome |
|---|---|---|
| 2026-04-25 | ADR-0001 authored | Proposed (godot-specialist validated) |
| 2026-04-28 | ADR-0001 reviewed in /architecture-review (full) | PASS |
| 2026-04-28 → 2026-04-30 | GDD authored via /design-system | DRAFT (T1-T12 flagged) |
| 2026-05-01 | /design-review (full) | MAJOR REVISION NEEDED — 13 blockers, 21 recommended |
| 2026-05-01 | User session — design decisions locked | All 12 player-facing decisions resolved |
| 2026-05-01 | Decision log written (this file) | Ready for fresh-session revision pass |

---

## Section H — Re-Review Acceptance Criteria

The revision is complete and ready for re-review when:
- [ ] GDD reflects all 12 locked design decisions (D1-D12)
- [ ] GDD reflects all 22 engineering fixes (E1-E22)
- [ ] All 5 editorial fixes applied (ED1-ED5)
- [ ] Tightenings table updated to T1-T22
- [ ] Open Questions worklist updated (resolved items removed; T18 marked deferred; new items if any)
- [ ] Total AC count recomputed and stated
- [ ] Cross-references to D1-D12 in Section A's Overview match the body
- [ ] No remaining references to: 45s `tk_prep_floor`, 5s WAVE_RESULTS auto-advance, `get_tree().paused` polling for external sources, `Time.get_unix_time_from_system()` directly (must use `_get_unix_time()`)
- [ ] Pre-implementation verifications updated with focus-signal + clock-abstraction + enum-coercion checks

When all items are checked, run `/design-review` for re-verification.

---

**End of decision log.**
