# Run State / Game Flow — Review Log

> Revision history for `design/gdd/run-state-game-flow.md`.
> Append a new entry below for each `/design-review` pass.

---

## Review — 2026-05-01 — Verdict: MAJOR REVISION NEEDED

**Scope signal**: XL
**Specialists**: game-designer, systems-designer, qa-lead, ux-designer, godot-specialist, creative-director (senior)
**Blocking items**: 13 | **Recommended**: 21 | **Editorial / Nice-to-have**: 5
**Prior verdict resolved**: First review (no prior log)

**Summary**: The GDD has the content depth of a foundation system (14 core rules, 6 formulas, 40 edge cases, 52 ACs, 18 tightenings) but fails the bar that consumer GDDs can author against this contract without ambiguity. Three cross-finding patterns dominated: (A) the GDD assumes time is mockable but Godot exposes it only as a singleton — affecting AC51, F4-F6 boundary tests, and AC34's determinism check; (B) pause is treated as one state but is actually a family of states (player-pause, OS-pause, modal-overlay) with different contracts; (C) Pillar 4 is asserted in narrative but contradicted in three concrete contracts (45s `tk_prep_floor`, 5s WAVE_RESULTS auto-advance, `get_tree().paused` polling that doesn't actually detect Steam overlay). Creative-director synthesized: most fixes are surgical, but they are non-negotiable before consumers author against this. The user session locked all 12 player-facing design decisions and authorised a comprehensive revision pass to be executed in a fresh session. Decisions persisted to `design/gdd/reviews/run-state-game-flow-decisions-2026-05-01.md`.

**Key locked decisions**: prep floor removed (Ready advances immediately); Wave Summary screen deleted (replaced by 1-2s beat + toast + Tab-toggle full run summary); pause time excluded from leaderboard; auto-pause on focus loss via `NOTIFICATION_APPLICATION_FOCUS_OUT` (not `get_tree().paused` polling); suspend-save model (single save consumed on resume); save anchor = start of most recently entered WAVE_ACTIVE; pause menu = "Save & Resume Later" + "Quit Run"; quit confirmation text "Quit run? You'll lose this run's build, but unlocks and lifetime currency are saved."; build summary as compact list with hover/tap expand; gamepad pause on Start/Options.

**Status**: Decision log written; GDD file NOT yet edited. Revision pass to be executed in a fresh Claude Code session per the instructions in `design/gdd/reviews/run-state-game-flow-decisions-2026-05-01.md`. Re-review (`/design-review`) required after revision pass completes; `/propagate-design-change` required after re-review passes.

**Specialists' top critical findings (paraphrased)**:
- *game-designer*: Pillar 4 narrative vs contract contradictions; RUN_RESULTS fantasy gap.
- *systems-designer*: Save-during-pause leaderboard inflation (F4/F5); F2 canonical form contradiction; defeat-path `current_wave` undercount.
- *qa-lead*: AC40 "deferred-blocking" undefined; AC51 Time singleton not mockable; T7 coverage gap.
- *ux-designer*: Pause Overlay ownership split + missing gamepad mapping + misleading confirmation text + build summary depth.
- *godot-specialist*: T14 `get_tree().paused` polling doesn't detect Steam overlay (technical falsehood); window minimization caveat; AC51 unimplementable as written.
- *creative-director*: MAJOR REVISION NEEDED — Pillar 4 contradictions are the deepest issue; the GDD claims the strong pillar and ships the weak one.

---

## Revision R2 — 2026-05-01 — APPLIED

**Source decision log**: `design/gdd/reviews/run-state-game-flow-decisions-2026-05-01.md`
**Mode**: Fresh-session revision pass (file is the memory; conversation is ephemeral)
**Scope**: D1-D12 (12 player-facing decisions) + E1-E22 (22 engineering fixes) + ED1-ED5 (5 editorial fixes)

**Summary**: Applied all 39 locked decisions from the 2026-05-01 morning design-review. Major changes: prep floor REMOVED (D1); Wave Summary screen DELETED from MVP scope (D2 — replaced by 1-2s WAVE_RESULTS beat + HUD #29 toast + Tab-toggle run summary); Tab-toggle run summary ADDED (D3, hold-to-show); pause time excluded from leaderboard CONFIRMED (D4); focus-notification handler replaces polling (D5); **suspend-save model + wave-start anchor + meta-progress separation LOCKED (D6/D7/D8)**; pause menu structure (D9), quit confirmation text (D10), build summary display (D11), gamepad pause mapping (D12) LOCKED. 22 engineering fixes spanning clock abstraction (E1+T19), F2 canonical form (E2), defeat-path `current_wave` increment (E3), snapshot expansion (E4 → T20), T7 quit-coverage ACs (E5), AC40 reclassification (E6), lints-as-documentation (E7 → T11/T14 reclassified), Steam overlay implementation (E8 → T14), `low_processor_mode` constraint (E9), F5 crash-vs-save distinction (E10/E22), enum coercion check (E11), F1 assertion removal (E12), F3 `state_override` extension (E13), AC34 split (E14), AC23 specificity (E15), AC50 reverse-test isolation (E16), modal stack contract (E17), input suppression (E18), STATE_NONE constant (E19), tuning composition constraint (E20), T17 reclassification (E21).

**Impact on AC count**: 52 → 62 (added Group 15 AC53-55 for T7 quit coverage; Group 16 AC56 for E3 defeat increment; Group 17 AC57-62 for D7/F7+D8/F8 suspend-save semantics).

**Impact on tightenings table**: T1-T18 → T1-T22 (added T19 clock injection, T20 snapshot expansion, T21 `save_for_resume()` API, T22 `fire_meta_progress_event()` API).

**Status at end of R2**: Decisions applied to GDD; awaiting `/design-review` re-verification before propagation to ADRs.

---

## Review R3 — 2026-05-01 (afternoon) — Verdict: REVISION (4 inline fixes) — APPLIED SAME DAY

**Mode**: `/design-review` re-review of R2-applied GDD (5-specialist + creative-director)
**Verdict**: REVISION (not MAJOR REVISION) — 4 specific issues found, all fixable inline without further authoring sessions.

**Issues found**:
1. **Tab-toggle hold-to-show contradicts Pillar 4** *(creative-director, ux-designer)*: AC47 expects player to read card descriptions for 60+ seconds while paused. Holding a key for 60+ seconds is ergonomically hostile, especially on gamepad. The very feature meant to solve "how am I doing mid-run?" violates Pillar 4's "the run waits for you" promise. Fix: change Tab from hold-to-show to **press-to-toggle** (Slay the Spire's pattern). Esc / dismiss-button also closes.
2. **Suspend-save scope cut required** *(creative-director, systems-designer, game-designer consensus)*: R2's D6/D7/D8 added a save-anchor system, save-during-any-state rule, meta-progress event tracking, and 5 new edge cases — but for a single-player MVP roguelite with 30-60 minute runs, the genre standard (Slay the Spire, Dead Cells) is single-session-with-meta-progress, NOT mid-run resume. The feature surface added by R2 is a 6-week implementation cost on a year-long MVP timeline, with significant test surface (state-restoration validation, meta-progress event deduplication). Fix: REMOVE the entire suspend-save mechanism. Quit-mid-run still grants meta-progress via the QUIT outcome path (concept's "Death always grants partial meta-currency" rule extends to QUIT cleanly). Save/Load #2 demoted from Hard to Soft consumer (persists meta-currency, achievements, unlocks, settings only).
3. **Wave 10 boss kill needs emotional landing time** *(game-designer, narrative-director consult)*: D2 set WAVE_RESULTS to a 1.5s beat for waves 1-9, but the wave 10 boss kill is the run's emotional peak. 1.5s is too quick for the moment to land before transitioning to RUN_RESULTS. Fix: extend WAVE_RESULTS to 3.0s for the wave 10 victory path only. Implementation: ceiling selected at WAVE_RESULTS entry based on `current_wave == waves_per_run AND outcome_pending == VICTORY`. Not surfaced as a tuning knob (per D2).
4. **Minor cleanup** *(systems-designer, qa-lead)*: stale Wave Summary UI #32 reference in Section A still mentioned 13 consumers in one place; T11 forbidden-write rule needed clarification to exempt test-injection fields (`_pending_outcome`, `_test_clock_provider`); pause overlay needed to handle RUN_LOADING wave-0 display (returns 0; caller hides label).

**Deletions from R2**:
- Core Rule 16 (suspend-save anchor rule) — DELETED
- Formula F7 (Save Anchor State Selection) — DELETED
- Formula F8 (Meta-Progress Event Separation) — DELETED
- Edge cases E27a-e (save-reload semantics) — DELETED
- Acceptance Criteria AC57-62 (Group 17 — suspend-save anchors + meta-progress separation) — DELETED
- Tightenings T20, T21, T22 — DELETED
- Pause overlay "Save & Resume Later" button — DELETED (only "Resume" + "Quit Run" remain)
- ADR-0006 v1→v2 schema bump for `run_snapshot` — DROPPED
- ADR-0006 `run_snapshot.save` domain — DELETED

**Impact on AC count**: 62 → 56 (Group 17 deleted; minor renumbering).

**Impact on tightenings table**: T1-T22 → T1-T19 active (T20-T22 marked DELETED with strikethrough in the table for traceability).

**Status at end of R3**: Decisions applied to GDD; ADRs 0001 + 0006 updated via `/propagate-design-change` (2026-05-01). Awaiting (a) third `/design-review` pass for final approval, OR (b) confidence-based promotion if no further blockers. After re-review passes, Run State #8 status moves to **Approved**.

**Specialists' verdict consensus**: REVISION — 4 inline fixes; no further author sessions required. Solo dev should NOT spend implementation time on suspend-save when the genre standard is single-session.

---

## R3 — APPROVED — 2026-05-01

**Authority**: User directive at end of `/propagate-design-change` session (2026-05-01).

**Pre-conditions met**:
- All 4 R3 inline fixes applied to GDD.
- ADR-0001 propagated with active T1-T19 tightenings (T20-T22 deleted along with suspend-save).
- ADR-0006 cleaned up (`run_snapshot.save` domain deleted; v1→v2 migration plan dropped).
- Change-impact report written: `docs/architecture/change-impact-2026-05-01-run-state.md`.
- Systems index updated: Run State #8 row + Wave Summary UI #32 row (DELETED).

**Status**: Run State / Game Flow GDD #8 — **Approved**. Ready for downstream consumer GDD authoring (#10, #18, #20, #22, #29, #33, #34, #36, #37, #41, #45) once their respective design-order slots come up. Save/Load #2 is a soft consumer post-R3 (lifetime persistence only).

**Open follow-ups (not blocking #8 Approval)**:
- `/architecture-review` (full) — re-validates ADR portfolio after R2+R3 propagation; assigns TR-IDs to the 56 R3 ACs via `tr-registry.yaml`.
- `docs/registry/architecture.yaml` update — register new state ownerships, interface contracts, and code-review-checklist rules per the change-impact follow-ups.

**Next system in design order**: **Lane / Map System #7** (per `design/gdd/systems-index.md` Foundation tier).

---


