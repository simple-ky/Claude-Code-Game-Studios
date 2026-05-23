# Architecture Review — Full (5 ADRs + 2 Approved GDDs)

> **Date:** 2026-05-16
> **Mode:** `/architecture-review` (full — no argument)
> **Verdict:** **PASS** — with 1 MINOR documentation precision recommendation (applied inline; see Edits Applied below)
> **Engine:** Godot 4.6.2
> **Predecessor reviews:**
> - `architecture-review-2026-04-28-adr-0001.md` (focused single-ADR scope, PASS)
> - `architecture-review-2026-04-28-full.md` (5 ADRs, PASS, 2 minor tightenings resolved inline)

---

## Scope

This review validates the cross-ADR coherence of the architecture after two propagation cycles since the last full review:

- **2026-05-01 R2+R3 amendments** propagated from Run State GDD #8 → ADR-0001 (T1–T19 tightenings; T20–T22 deleted with suspend-save) + ADR-0006 (R3 cleanup; `run_snapshot.save` domain removed)
- **2026-05-02 R2.1 amendments** propagated from Lane/Map GDD #7 → ADR-0001 (`RUN_LOADING → MAIN_MENU` transition + Bake-failure abort path subsection) + ADR-0002 (Wall-Block No-Path Fallback subsection)

Plus first full validation of two **Approved** GDDs against the architecture:

| Input | Count |
|---|---|
| GDDs reviewed | 2 — Run State #8 (56 ACs Approved 2026-05-01); Lane/Map #7 (24 active ACs Approved 2026-05-02 R2.1) |
| ADRs reviewed | 5 — ADR-0001 (Proposed, twice-amended), ADR-0002 (Proposed, once-amended), ADR-0003 (Proposed), ADR-0004 (Proposed), ADR-0006 (Proposed, R3-revised) |
| Engine reference | 12 files — Godot 4.6.2 (VERSION + breaking-changes + deprecated-apis + current-best-practices + modules/×8) |
| Registry stances | architecture.yaml — 6 state owners, 11 interface contracts, 3 perf budgets, ~18 api decisions, 14 forbidden patterns, `cross_system_invariants` section (new since 2026-04-28) |
| TR registry entries before review | 0 (intentionally empty per prior-review deferral policy) |
| Consistency-failures log | absent — no prior CONFLICT entries across project history |

ADR-0005 (`ModifierTarget`) and ADR-0007 (Effect Composition Taxonomy) remain out-of-scope — both are scheduled to live inside their parent GDDs (Champion #12, Build/Modifier #23), neither yet authored.

---

## Phase 2 — Technical Requirements Extracted (and Persisted)

This review **persists** TRs for the 2 Approved GDDs (Run State, Lane/Map). The 50 suggested TRs from the 2026-04-28 review for the other 5 systems (Crowd Pathfinding, Juice, Save Schema, Language Routing, Test Harness) remain *suggested* and continue to defer to their GDD-authoring time, per that prior review's policy.

| System | New TR IDs | Source |
|---|---|---|
| Run State (#8) | TR-runstate-001..022 (22 IDs) | `design/gdd/run-state-game-flow.md` Core Rules 1–15 + AC1–AC56 |
| Lane/Map (#7) | TR-lanemap-001..021 (21 IDs) | `design/gdd/lane-map-system.md` Core Rules 1–11 + AC-LM-01..AC-LM-30 (24 active) |
| **Total new TRs persisted** | **43** | First-time `tr-registry.yaml` population |

Full TR text in `docs/architecture/tr-registry.yaml` (v2; populated 2026-05-16).

---

## Phase 3 — Traceability Matrix (TR → ADR)

### Run State (22 TRs)

| TR-ID | Requirement (concise) | ADR Coverage | Status |
|---|---|---|---|
| TR-runstate-001 | 9-state enum, append-only evolution | ADR-0001 §State Enum + §Save Snapshot Contract + Risk 8 | ✅ |
| TR-runstate-002 | One phase at a time; forward-only sequence; transition validation | ADR-0001 §VALID_TRANSITIONS + §Transition Validation | ✅ |
| TR-runstate-003 | Pause/resume orthogonal; previous_state restoration | ADR-0001 §Pause + Risk 6 + T12 | ✅ |
| TR-runstate-004 | Cross-language wave_complete fires once per wave; pause-aware deferral | ADR-0001 §Cross-Language Signal + T5 + Risk 3; ADR-0003 §Cross-Language Boundary | ✅ |
| TR-runstate-005 | quit_run() bypasses VALID_TRANSITIONS from any in-run state | ADR-0001 §Key Interfaces + T1 + T7 | ✅ |
| TR-runstate-006 | Three RunOutcome values; priority VICTORY>DEFEAT>QUIT | ADR-0001 §Key Interfaces + T6 | ✅ |
| TR-runstate-007 | get_displayed_wave_number() state-conditional helper | ADR-0001 §Key Interfaces + T3 | ✅ |
| TR-runstate-008 | current_wave increment timing; defeat-path pre-increment | ADR-0001 §Key Interfaces + T8 | ✅ |
| TR-runstate-009 | CARD_ROLL skippable; card_picked gated on CARD_ROLL state | ADR-0001 §State Enum + §Signal Contract + T9 | ✅ |
| TR-runstate-010 | RUN_PREP floor removed; ceiling AFK auto-advance | ADR-0001 design intent only; tuning is GDD-owned | ⚠️ Partial (tuning is GDD-owned, correctly) |
| TR-runstate-011 | WAVE_RESULTS auto-advance timing (1.5s / 3.0s boss) | GDD-owned tuning; ADR coverage via state graph only | ⚠️ Partial (tuning is GDD-owned, correctly) |
| TR-runstate-012 | RunStateConfig.tres data-driven phase pacing | ADR-0001 §Migration Plan; GDD owns Resource shape | ⚠️ Partial (Resource shape in GDD, correctly) |
| TR-runstate-013 | Pause-aware phase timer; F4/F5/F6; active-elapsed | ADR-0001 §Key Interfaces + T13 + T19 + T2 | ✅ |
| TR-runstate-014 | state_snapshot_ready snapshot Dictionary contract | ADR-0001 §Save Snapshot Contract + T10 + T11; ADR-0006 envelope rules | ✅ |
| TR-runstate-015 | Headless drivable via transition_to() + load_snapshot() | ADR-0001 §Key Interfaces + T11 | ✅ |
| TR-runstate-016 | state_loaded signal distinct from state_changed | ADR-0001 §Key Interfaces + T17 | ✅ |
| TR-runstate-017 | External pause via focus notification; documented poll fallback | ADR-0001 §Risk 5 + T14 (R3 fallback added inline this review per MINOR-1) | ✅ |
| TR-runstate-018 | Quit-from-CARD_ROLL confirmation dialog (locked text) | ADR-0001 §Key Interfaces + T15 | ✅ |
| TR-runstate-019 | previous_state typed int with STATE_NONE=-1 sentinel | ADR-0001 §Key Interfaces + T16 | ✅ |
| TR-runstate-020 | Consumer connection contract (typed Callable; load order) | ADR-0001 §Signal Contract + Risk 1; registry forbidden_patterns | ✅ |
| TR-runstate-021 | Pillar 4 pause-holds-state ≥60s (ADVISORY felt experience) | ADR-0001 §Constraints (Pillar 4) | ✅ |
| TR-runstate-022 | Bake-failure abort path (RUN_LOADING → MAIN_MENU) | ADR-0001 §Bake-failure abort path (2026-05-02 amendment) | ✅ |

**Run State coverage**: 22 TRs → 19 ✅ Covered, 3 ⚠️ Partial, 0 ❌ Gaps. All 3 partials are tuning-knob shapes that legitimately live in the GDD's Tuning Knobs section, not the ADR.

### Lane/Map (21 TRs)

| TR-ID | Requirement (concise) | ADR Coverage | Status |
|---|---|---|---|
| TR-lanemap-001 | Map = container of lane instances; lane = fundamental unit | Lane/Map GDD §Core Rules 1–2; ADR-0002 references | ✅ |
| TR-lanemap-002 | Lane is Node2D-rooted with NavigationRegion2D + zones + 3 TileMapLayers | Lane/Map GDD §Core Rule 2; ADR-0002 §Map Rid Acquisition | ✅ |
| TR-lanemap-003 | Lanes are independent; no cross-lane geometry coupling | Lane/Map GDD §Core Rule 3 | ✅ |
| TR-lanemap-004 | MVP has exactly 2 parallel lanes | Lane/Map GDD §Core Rule 4 | ✅ |
| TR-lanemap-005 | Bend at ~60% lane depth, 35–45°; engine-stable detection | Lane/Map GDD §Core Rule 5 + AC-LM-05 | ✅ |
| TR-lanemap-006 | Buildable strip surrounds bend (40–65% lane depth) | Lane/Map GDD §Core Rule 6 + AC-LM-06 (R2.1) | ✅ |
| TR-lanemap-007 | Mutation API + forbidden_pattern lint for caller authorization | Lane/Map GDD §Core Rule 7 + R2.1 cell_ref→outline_index mapping; registry forbidden_patterns | ✅ |
| TR-lanemap-008 | Mid-wave placement co-occurs with WAVE_ACTIVE; cooldown invariant | Lane/Map GDD §Core Rule 8; registry cross_system_invariants | ✅ |
| TR-lanemap-009 | Walls may freely block all paths; no path-validity check | Lane/Map GDD §Core Rule 9; ADR-0002 §Wall-Block No-Path Fallback (2026-05-02) | ✅ |
| TR-lanemap-010 | Wall removal unconditional + idempotent | Lane/Map GDD §Core Rule 10 | ✅ |
| TR-lanemap-011 | Mutation queue FIFO + dedup overwrite + max_queue_depth=8 | Lane/Map GDD §Core Rule 11 (R2 spec) | ✅ |
| TR-lanemap-012 | D.1–D.3 geometric formulas at cell_size_px=96 | Lane/Map GDD §D.1–D.3 | ✅ |
| TR-lanemap-013 | D.4 spawn-to-goal runtime path ±10% tolerance | Lane/Map GDD §D.4 + AC-LM-15 | ✅ |
| TR-lanemap-014 | D.5 strip depth ≤ 3 rows hard cap | Lane/Map GDD §D.5 | ✅ |
| TR-lanemap-015 | D.6 initial bake ≤ 15ms/lane, ≤ 500ms total (ADVISORY) | Lane/Map GDD §D.6 + AC-LM-17; technical-preferences.md hardware spec | ✅ |
| TR-lanemap-016 | D.7 mid-wave re-bake ≤ 3ms; episodic cost model | Lane/Map GDD §D.7 + AC-LM-18; registry `cost_model: episodic` | ✅ |
| TR-lanemap-017 | Aggregate LaneSystem.geometry_baked signal contract | ADR-0001 + ADR-0002; registry `lane_system_geometry_baked` | ✅ |
| TR-lanemap-018 | Aggregate geometry_baked gates RUN_LOADING→WAVE_PREP | ADR-0001 §Bake gate + amendment 2026-05-02 | ✅ |
| TR-lanemap-019 | Pre-bake validation + bake-failure abort path | Lane/Map GDD §AC-LM-21; ADR-0001 §Bake-failure abort path (2026-05-02) | ✅ |
| TR-lanemap-020 | Bidirectional ordering: CrowdManager + Wave/Spawn defer until geometry_baked | ADR-0002 §Path Query Trigger Set; Lane/Map GDD §Interactions | ✅ |
| TR-lanemap-021 | Pillar 4 cold-player wall-placement readability (ADVISORY) | Lane/Map GDD §AC-LM-29 | ✅ |

**Lane/Map coverage**: 21 TRs → 21 ✅ Covered (the cross-system mid-wave-cost invariant — formerly AC-LM-30 — is tracked in `architecture.yaml cross_system_invariants` with the concrete AC re-authored in Wall/Fortification GDD when that lands; this is expected and correct, not a gap).

### Aggregated coverage across both Approved GDDs

| Status | Count | Notes |
|---|---|---|
| ✅ Covered | 40 |  |
| ⚠️ Partial | 3 | All 3 are GDD-owned tuning shapes (RUN_PREP ceiling, WAVE_RESULTS auto-advance timing, RunStateConfig.tres resource shape) — correctly NOT in the ADR |
| ❌ Gaps | **0** | No requirement uncovered |

**Plus the 50 suggested TRs from the 2026-04-28 review** (Crowd Pathfinding, Juice, Save Schema, Language Routing, Test Harness) remain deferred to their GDD authoring — same status as prior review.

---

## Phase 4 — Cross-ADR Conflict Detection

### Pairwise audit (10 pairs — exhaustive re-audit after amendments)

| Pair | Result |
|---|---|
| ADR-0001 ↔ ADR-0002 | ✅ **Re-verified after 2026-05-02 amendments**: the new `RUN_LOADING → MAIN_MENU` transition (ADR-0001) plus the Wall-Block No-Path Fallback (ADR-0002) interlock cleanly. Lane/Map's `bake_pre_validation_failed` signal triggers the state transition; CrowdManager's truncated-path behavior under wall-block is independent of the state graph. Run State subscribes for the abort; CrowdManager subscribes for the requery. No double-ownership; no contradictory assumptions. |
| ADR-0001 ↔ ADR-0003 | ✅ Unchanged — Run State follows GDScript orchestration rule; cross-language `wave_complete` correct (snake_case auto-translation). |
| ADR-0001 ↔ ADR-0004 | ✅ Unchanged — ADR-0004 subscribes to `state_changed` for hit-stop abort on `RUN_PAUSED`. The new T14 focus-notification handler (ADR-0001 R2) does NOT change the signal contract Juice consumes — Juice still sees `state_changed` regardless of pause trigger source. |
| ADR-0001 ↔ ADR-0006 | ✅ **Re-verified after R3 cleanup**: the `run_snapshot.save` domain removal (ADR-0006 R3 + ADR-0001 T20–T22 deletion) is symmetric. Both sides agree: Run State's snapshot Dictionary is now runtime-only (used by Test Harness `load_snapshot()` + `state_snapshot_ready` consumers); no on-disk persistence. The enum-stability rule generalizes to `inserting_persisted_enum_values` for the 5 remaining persistent domains. No phantom-coupling. |
| ADR-0002 ↔ ADR-0003 | ✅ Unchanged — Crowd Pathfinding routed to C# per criterion 1 (>50 entities/frame); boundary naming rules jointly codified (`csharp_method_snakecase_in_gdscript_call` + `csharp_signal_pascalcase_in_gdscript_connect`). |
| ADR-0002 ↔ ADR-0004 | ✅ Unchanged — ADR-0004 sets the 100+ zombie target per ADR-0002. No shared per-frame budget contention. |
| ADR-0002 ↔ ADR-0006 | ✅ Unchanged — Crowd Pathfinding has no persistent state; agents are transient. |
| ADR-0003 ↔ ADR-0004 | ✅ Unchanged — `damage_dealt(HitEvent)` follows ADR-0003 boundary contract; runtime guard for cold-start downgrade. |
| ADR-0003 ↔ ADR-0006 | ✅ Unchanged — SaveManager is GDScript; persistent state snapshotted on GDScript side. |
| ADR-0004 ↔ ADR-0006 | ✅ Unchanged — JSON-vs-Resource carve-out preserved (Risk 7 in ADR-0006). |

### One MINOR finding — documentation precision only

**MINOR-1**: ADR-0001 Risk 5 (focus-notification verification) did NOT cite the Run State GDD's documented poll fallback path.

| Aspect | Finding |
|---|---|
| **Concern** | Run State GDD *Pre-implementation verification* #6 documents an explicit fallback: if Steam overlay does NOT trigger the focus-out notification on Windows D3D12 borderless mode, `GameStateMachine` adds a ~10 Hz poll of `DisplayServer.window_is_focused()` from `_process()`. This is part of the GDD's response to a godot-specialist BLOCKING concern. ADR-0001 Risk 5 mentioned only "escalate before implementation" without referencing the fallback. |
| **Severity** | LOW — documentation precision; both documents correct in isolation, but the GDD has more implementation guidance than the ADR. |
| **Resolution applied during this review** | ADR-0001 Risk 5 amended inline (this review) to cite the GDD fallback at file path. Implementer choice path is now explicit at the ADR level: verify first; if verification fails, implement the GDD-documented poll fallback. |
| **Blocking?** | No — fix is documentation only; implementation path is unchanged. |

**No CONFLICT-class findings.** No `docs/consistency-failures.md` append needed.

### ADR Dependency Order (re-verified, unchanged since 2026-04-28)

```
Foundation (no deps):
  1. ADR-0003: Language Routing Policy             — Proposed

Depends on Foundation:
  2. ADR-0001: Run State / Game Flow               — Proposed; twice-amended (2026-05-01 R2+R3; 2026-05-02 bake-failure); MINOR-1 fix applied 2026-05-16

Depends on Foundation + ADR-0001:
  3. ADR-0002: Crowd Pathfinding Architecture      — Proposed; once-amended (2026-05-02 Wall-Block)
  4. ADR-0004: Juice Pipeline Integration Model    — Proposed

Depends on ADR-0001:
  5. ADR-0006: Save Schema & Versioning            — Proposed; R3-revised (2026-05-01)
```

- **No cycles.**
- **No structural unresolved deps.**
- All 5 remain `Proposed` per the project's intentional batching policy.

### Recommended promotion order (unchanged from 2026-04-28)

1. **ADR-0003 → Accepted** (foundational; unblocks others).
2. **ADR-0001 → Accepted** (already godot-specialist-validated; both 2026-05-* amendments propagated and Approved-GDD-coherent; MINOR-1 fix now applied).
3. **ADR-0002 → Accepted** *after* Crowd Pathfinding prototype validates the architecture; Wall-Block amendment propagated and Lane/Map-coherent.
4. **ADR-0004 → Accepted** (unblocks GDD #9 Juice).
5. **ADR-0006 → Accepted** *after* ADR-0001 (unblocks GDD #2 Save/Load).

---

## Phase 5 — Engine Compatibility

| Check | Result |
|---|---|
| Engine version match (4.6.2) across all 5 ADRs | ✅ all 5 |
| Engine Compatibility section present | ✅ all 5 |
| Post-Cutoff APIs declared | ✅ all 5 (unchanged from 2026-04-28) |
| Deprecated API references | ✅ none |
| Stale version references | ✅ none |
| Knowledge Risk levels | ADR-0001 LOW, ADR-0002 MEDIUM-HIGH, ADR-0003 LOW-MEDIUM, ADR-0004 LOW, ADR-0006 MEDIUM |

### Amendment-specific engine claims (verified)

- **ADR-0001 R2+R3 T14** (`_notification(NOTIFICATION_APPLICATION_FOCUS_OUT/IN)`): listed as a pre-implementation verification step; Godot documentation supports this notification for window focus events. Steam overlay behavior on Windows D3D12 is the specific uncertainty — the GDD documents the fallback poll (now also cited in ADR-0001 Risk 5 per MINOR-1 fix). ✅ Consistent.
- **ADR-0001 2026-05-02 bake-failure path**: synchronous `bake_navigation_polygon()` on the main thread is Godot 4.x default behavior per `modules/navigation.md`. ✅ Consistent.
- **ADR-0002 Wall-Block No-Path Fallback**: relies on `NavigationServer2D` returning a path that ends at the closest reachable point when the goal is fully obstructed — documented Godot 4.x `NavigationPathQueryParameters2D` behavior. ✅ Consistent.
- **Lane/Map GDD Rule 7 R2 / R2.1**: flags `NavigationPolygon.add_outline()` / `remove_outline(idx)` API name as **UNVERIFIED for 4.6.2** in `docs/engine-reference/godot/modules/navigation.md`. The GDD explicitly gates story authoring on a WebSearch verification pass. ✅ Correctly flagged by the GDD itself — not an architecture-review-level finding.

### Engine Specialist Consultation

ADR-0001 already godot-specialist-validated (per 2026-04-28 review). ADR-0002 / 0003 / 0004 / 0006 still unvalidated by godot-specialist, but no new specialist findings required for this review — the 2026-05-* amendments to ADR-0001 + ADR-0002 are propagations of already godot-specialist-reviewed GDD decisions (Run State R2+R3 used godot-specialist; Lane/Map R2 + R2.1 used godot-specialist). Specialist validation remains a per-ADR promotion gate, not a review blocker.

---

## Phase 5b — GDD Revision Flags

**None.** Both Approved GDDs are consistent with verified engine behavior. The Lane/Map GDD's unverified `NavigationPolygon.add_outline()` API name is a known knowledge gap flagged by the GDD itself (Open Question B2) — not an engine-vs-design conflict; it's an engine-reference-doc completeness gap that is the responsibility of the WebSearch pass before Lane/Map story authoring.

---

## Phase 6 — Architecture Document Coverage

`docs/architecture/architecture.md` does NOT exist. **Expected** — 5 of 7 planned ADRs authored; ADR-0005 (`ModifierTarget`) and ADR-0007 (Effect Composition Taxonomy) still live inside future Champion + Build/Modifier GDDs. Run `/create-architecture` after those parent GDDs are authored.

**Observation worth noting**: the Lane/Map GDD has matured into a system-internal architectural spec (mutation API, queue policy, state lifecycle, bend geometry, episodic performance budget, cross-system invariants registered in `architecture.yaml`). This is the **same pattern** as ADR-0005/0007 (architecture-decisions-inside-a-GDD). Not a finding — confirms the architecture is materially complete for Lane/Map even without a dedicated `adr-0008-lane-map-geometry.md` file.

---

## Verdict — **PASS** with MINOR-1 fix applied inline

All 5 ADRs are internally consistent, registry-aligned, engine-compliant after the 2026-05-01 + 2026-05-02 amendment cycles, and integrate correctly across all 10 pairwise combinations. The 2 Approved GDDs (Run State #8 + Lane/Map #7) have **zero coverage gaps** in the architecture — 40 of 43 TRs ✅ fully covered, 3 ⚠️ Partial (all GDD-owned tuning shapes, correctly).

### Edits Applied During Review

1. **`docs/architecture/adr-0001-run-state-game-flow.md` Risk 5** — appended a 4th bullet citing the Run State GDD's documented `DisplayServer.window_is_focused()` poll fallback at file-path location. Resolves MINOR-1.

2. **`docs/architecture/tr-registry.yaml` populated** for the first time — 43 new TR-IDs covering Run State (22) + Lane/Map (21). Version bumped to v2; `last_updated: 2026-05-16`. The 50 suggested TRs from the 2026-04-28 review for Crowd Pathfinding / Juice / Save Schema / Language Routing / Test Harness remain deferred per prior policy (will graduate to active entries when each GDD is authored).

### User decision audit trail

> Plain-English approval (2026-05-16): *"Save all three + fix the wording (Recommended)"*

Translation to technical actions: write this report, populate the TR registry with 43 entries, edit ADR-0001 Risk 5 to cite the GDD fallback, append session-state extract block.

### Deferred (Out of Scope of This Review)

- **Specialist validation of 4 unvalidated ADRs** (ADR-0002/0003/0004/0006). Spawn `godot-specialist` per-ADR before each promotion to Accepted.
- **Architecture.md authoring**. Run `/create-architecture` after ADR-0005 + ADR-0007 are authored at GDD time (Champion + Build/Modifier).
- **TR persistence for 5 systems without GDDs yet** (Crowd Pathfinding, Juice, Save Schema, Language Routing, Test Harness). Continue to defer per 2026-04-28 policy.
- **`docs/consistency-failures.md` reflexion log**. File does not exist; no append needed (no CONFLICT findings).

---

## Required ADRs (still missing, in priority order — unchanged from 2026-04-28)

1. **ADR-0005 `ModifierTarget` Contract** — authored *inside* Champion GDD; gates GDD #13 Champion + GDD #16 Ability + GDD #15 Weapon + GDD #22 Build/Modifier + GDD #21 Card.
2. **ADR-0007 Effect Composition Taxonomy** — authored *inside* Build/Modifier GDD; gates GDD #21 Card.

Both are scoped sections of their parent GDDs, not standalone ADRs.

---

## Recommended Next Actions (in order)

1. **Steam Deck p95 bake benchmark + adjacency-cost test** (Lane/Map Open Question #7) — pre-Lane/Map-story gate.
2. **Lane/Map paper prototype** (Lane/Map Open Question #4) — validates `lane_width_cells = 5`, `total_buildable_cells_mvp = 18`, 35–45° bend, and bend-colocated strip readability with cold playtesters before any Lane/Map story is authored.
3. **Art Bible amendment** for `cell_size_px = 96` (Lane/Map Open Question #8) — owned by art-director + producer.
4. **`/design-system input-system`** — begin authoring Input System #1 (next system in design order: Foundation/Core, MVP, Effort: S).
5. **WebSearch verification** for `NavigationPolygon.add_outline()` / `remove_outline(idx)` API name in 4.6.2 (Lane/Map B2 flag) — pre-Lane/Map-story gate.
6. **Run `/architecture-review`** (full mode again) after the next 2 GDDs are authored — to validate TR coverage as the matrix grows.
7. **Spawn `godot-specialist` validation passes** for ADR-0002, ADR-0003, ADR-0004, ADR-0006 before each promotion to Accepted (can be batched).
