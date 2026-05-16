# Lane / Map — Review Log

> Revision history for `design/gdd/lane-map-system.md`.
> Append a new entry below for each `/design-review` pass.

---

## Review — 2026-05-02 — Verdict: MAJOR REVISION NEEDED

**Scope signal**: XL
**Specialists**: game-designer, systems-designer, ai-programmer, level-designer, performance-analyst, godot-specialist, qa-lead, creative-director (senior)
**Blocking items**: 8 | **Recommended**: 12 | **Nice-to-have**: 6
**Prior verdict resolved**: First review (no prior log)

**Summary**: The GDD has the content depth of a Foundation system (11 core rules, 7 formulas, 16 edge cases, 27 ACs across 11 sections) but the same structural disease as Run State #8 R1: a Foundation document writing checks against systems that don't exist (Wall/Fortification #27, Crowd Pathfinding #11) while simultaneously misstating the engine reality it sits on. Five cross-finding patterns dominated. (1) **Frame budget is fiction** — D.7 double-counts crowd sub-components against ADR-0002's registered 2.0ms, uses optimistic engine overhead, omits juice/VFX/HUD/wave costs, and assumes async bake when Godot 4.x's `bake_navigation_polygon()` is synchronous; real slack is 2-3ms not 5ms. (2) **Engine API surface is unverified for 4.6.2** — `bake_navigation_polygon` sync/async, `get_world_2d().navigation_map`, `NavigationServer2D.map_changed`, `map_get_path` all need verification against the project's HIGH-RISK 4.6.2 engine reference. (3) **Cross-system ACs leak into the wrong GDD** — AC-LM-21 tests UI; AC-LM-23 tests CrowdManager; AC-LM-26 tests Wall/Fortification's calling code; AC-LM-27 is a manual grep; AC-LM-11's NavigationServer mock is impossible. (4) **Geometry decoratively claims Pillar 4 but contracts undermine it** — bend too gentle, Collapse Markers point at zone where placement is illegal, Champion sprite contradicts cell-size, "the run waits for you" violated by mid-wave placement. (5) **Cross-system contracts are implicit** — `geometry_baked` ownership ambiguous, `spawn_zone_center` single-point doesn't survive 50+ spawns, mutation queue has no FIFO/dedup/admission policy, wall destructibility is prose-only. Creative-director synthesized: same diagnostic that triggered Run State #8 R1's MAJOR REVISION. The four downstream consumers cannot author against this document without inheriting its corruption.

**Status**: Decision log written to `design/gdd/reviews/lane-map-system-decisions-2026-05-02.md`. GDD file NOT yet edited. Revision pass (R2) to be executed in a fresh Claude Code session per Section H of the decision log. Re-review (`/design-review`) required after R2 completes; `/propagate-design-change` required after re-review passes.

**6 design decisions requiring user input** (locked into decision log Section H, item 4): mid-wave perf escalation policy (DD#1); sync vs async bake (DD#2); queue dedup policy (DD#3); champion-sprite vs cell-size reconciliation (DD#4); Pillar 4 geometry rework vs retract (DD#5); Pillar 3 claim retract vs articulate (DD#6).

**Specialists' top critical findings (paraphrased)**:
- *game-designer*: Pillar 3 alignment claim is backwards (constraint reduces variety, not generate it); mid-wave "clutch tool" intent is promise-ware (its levers are owned by an unauthored GDD); HUD-free chokepoint readability untested.
- *systems-designer*: D.7 frame budget double-counts vs ADR-0002; D.5 zero-margin at upper safe range; non-integer cells_per_lane undefined for V1; `geometry_baked` ownership mismatch with architecture.yaml.
- *ai-programmer*: ADR-0002 doesn't actually own the no-path fallback Lane/Map disclaims to it; AC-LM-23's 2-frame tolerance undefendable from deferred-chain math; mutation queue agent-state-during-queue undefined.
- *level-designer*: 20-30° bend too gentle for 320px lane to function as chokepoint; 5×2 strip SHAPE constrains variety more than COUNT; two parallel non-converging lanes risk reading as two separate games; 6-cell gap between bend (visual cue) and legal placement zone (affordance lie).
- *performance-analyst*: 5ms slack uses lower-bound engine overhead; 5-15ms initial bake unbenchmarked; 500ms ceiling unvalidated and AC BLOCKING is a sequencing trap; NavigationServer2D thread safety in 4.6.2 unverified.
- *godot-specialist*: bake is SYNCHRONOUS in 4.x — 500ms timeout cannot fire mid-bake; four 4.6.2 API names unverified; collision TileMapLayer doesn't auto-feed navigation geometry.
- *qa-lead*: 6 of 27 ACs misplaced or non-implementable; AC-LM-11 NavigationServer mock impossible without `_test_bake_suspend` injectable; AC-LM-17/18 non-deterministic on CI without pinned hardware.
- *creative-director* (senior synthesizer): MAJOR REVISION NEEDED — same structural disease as Run State #8 R1; the four downstream consumers cannot author against this document until the frame-budget rebuild + engine-API verification + AC re-scoping land. Pillar 4 is decorative not delivered.

---

## Review — 2026-05-02 (R2 + R2.1) — Verdict: CONDITIONAL APPROVED → APPROVED after inline fixes

**Scope signal**: XL (matched R1)
**Specialists**: game-designer, systems-designer, qa-lead, godot-specialist, performance-analyst, creative-director (senior synthesizer; ai-programmer + level-designer not re-spawned per decision log Section H — their R1 concerns were fully delegated to ADR amendments and cross-system AC re-authoring).
**Blocking items**: 2 (both inline-fixable in same session) | **Recommended/inline**: 16
**Prior verdict resolved**: Yes — all 8 R1 BLOCKERS (B1–B8) and all 12 R1 RECOMMENDATIONS (R1–R12) are addressed in the GDD R2 application, verified by specialist re-check; the locked-decision-log contract (`design/gdd/reviews/lane-map-system-decisions-2026-05-02.md`) is fully applied.

**Summary**: Round 2 confirmed all R1 blockers and recommendations were correctly applied per the locked decision log: D.7 frame budget rebuilt (single 2.0 ms CrowdManager line, 8 ms engine overhead upper bound, juice/VFX/HUD/Wave-Spawn/Damage Numbers TBD line items, honest ~3 ms slack); aggregated `LaneSystem.geometry_baked` contract; full mutation queue spec (FIFO + idempotent overwrite per DD#3 + max_queue_depth=8); sync bake mode (DD#2) with pre-bake outline-vertex pre-validation + post-bake assertion; bend angle 35–45° (DD#5 B6 Path A); strip relocated to surround the bend at 40–65% lane depth; cell_size_px raised 64→96 (DD#4); Pillar 3 alignment retracted (DD#6); cooldown invariant promoted to bidirectional cross-system invariant (B8); 5 AC rewrites/deletions/conversions per B4 + 3 new ACs (LM-28/29/30) per R11/B6/B8; architecture.yaml updated with lane-map perf budget + aggregated `LaneSystem.geometry_baked` contract + 3 cross-system invariants + `forbidden_pattern: mutation_api_called_outside_wall_fortification`. Two BLOCKERS surfaced in Round 2 specialist review (AC-LM-06 wrong strip position contradicting R2 Rule 6; AC-LM-18 (a) requiring frame ≤ 16.6 ms contradicting D.7's accepted-stutter design intent under DD#1 cooldown framing) plus 16 inline-fixable findings. Creative-director (senior synthesizer) verdict: **CONDITIONAL APPROVED — apply inline fixes in same session, no formal R3 needed**. R2.1 inline-fix pass applied all 18 fixes including the user creative-decision (DD#7 = "Forward-leaning kill-box" Player Fantasy realignment per creative-director recommendation), the steady-state trigger rule for D.7 (concern 19), `cost_model: episodic` structured field on architecture.yaml lane-map entry, Steam Deck OLED + 2019-class laptop benchmark hardware spec in `.claude/docs/technical-preferences.md`, `OS.is_debug_build()` test guard correction, `cell_ref → outline_index` mapping documentation in Rule 7, adjacency-cost test in Open Question #7 benchmark protocol, and "Three Advisory" → "Four Advisory" prose count.

**Status**: GDD APPROVED for `/propagate-design-change`. Section J of the GDD (R2 application notes + R2.1 inline-fix notes) is the canonical narrative of what changed and why. Outstanding follow-ups tracked in Section J: ADR-0001 amendment (sync-mode 500 ms post-bake assertion), ADR-0002 amendment (CrowdManager no-path fallback), Art Bible amendment (cell_size_px 64→96), Steam Deck p95 bake benchmark + adjacency-cost test (Open Question #7), Camera GDD Open Question #1, V1 async bake revisit (Open Question #10).

---
