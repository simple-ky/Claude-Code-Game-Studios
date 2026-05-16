# Change Impact: Lane / Map System (R2 + R2.1)

> **Triggered by**: `/propagate-design-change design/gdd/lane-map-system.md`
> **Date**: 2026-05-02
> **Source**: `design/gdd/lane-map-system.md` R2 application + R2.1 inline-fix pass; locked decision log `design/gdd/reviews/lane-map-system-decisions-2026-05-02.md` Section G.
> **Companion**: `change-impact-2026-05-01-run-state.md` (Run State R2+R3 propagation — same pattern, prior session).

---

## Change Summary

The Lane / Map System GDD reached **Approved** status after R2 (decision-log application) + R2.1 (inline-fix pass) on 2026-05-02. The 6 user-locked design decisions (DD#1 cooldown-throttled mid-wave; DD#2 sync bake; DD#3 idempotent overwrite; DD#4 cell_size_px 64→96; DD#5 fix-the-map Pillar 4; DD#6 retract Pillar 3) plus the R2.1 user-locked DD#7 (forward-leaning kill-box Player Fantasy) introduced two architectural concerns that fall outside Lane/Map's GDD-level scope:

1. **The state graph cannot abort `RUN_LOADING` to `MAIN_MENU`** without a transition-table addition — but the Lane/Map sync-bake mode (DD#2) introduces two failure paths (pre-bake outline-vertex pre-validation failure; engine-level bake failure) that require this transition. The transition graph is owned by Run State, not Lane/Map.
2. **CrowdManager's behavior when a wall mutation legitimately leaves zero path** (the wall-block case under Lane/Map Rule 9) is undefined — Lane/Map disclaims this behavior to ADR-0002 but ADR-0002 only addressed the race-condition no-path case (Risk 11), not the wall-block case.

Both were named in the decision log Section G as required ADR amendments. This document records their resolution.

### Lane/Map GDD changes affecting architecture (summary; full list in `design/gdd/lane-map-system.md` Section J)

| Change | Architectural touch |
|---|---|
| DD#2 = Sync bake; live-abort timer removed; replaced with pre-bake validation + post-bake assertion | ADR-0001 transition-table addition (`RUN_LOADING → MAIN_MENU`) + new "Bake-failure abort path" subsection |
| Rule 9 (walls may freely block paths) + wall-destruction recovery flow | ADR-0002 new "Wall-Block No-Path Fallback" subsection |
| Aggregated `LaneSystem.geometry_baked()` contract (B5a) | `architecture.yaml` `lane_system_geometry_baked` interface contract entry (already applied in R2) |
| `system: lane-map, budget_ms: 3.0` performance budget with `cost_model: episodic` (B1 + R2.1 Concern E) | `architecture.yaml` performance budget entry (already applied in R2 + R2.1) |
| 3 cross-system invariants (wall destructibility, mid-wave cost lever, mid-wave cooldown lever) | `architecture.yaml` `cross_system_invariants` section (already applied in R2) |
| `forbidden_pattern: mutation_api_called_outside_wall_fortification` (B4 — replaces AC-LM-27) | `architecture.yaml` forbidden_patterns (already applied in R2) |
| ADR-0003 reclassified hard implementation-binding for Lane/Map (R6) | Documented in Lane/Map's Section F; ADR-0003 itself is unchanged |

---

## ADR Impact Analysis

### Not Affected (3)

- **ADR-0003 (Language Routing Policy)**: R2 reclassified ADR-0003 as "hard implementation-binding" for Lane/Map, but the reclassification is recorded in the GDD's Section F (not in ADR-0003 itself). ADR-0003's content is unchanged. Dependency-strength elevation lives in Lane/Map's metadata.
- **ADR-0004 (Juice Pipeline)**: No Lane/Map references; orthogonal.
- **ADR-0006 (Save Schema)**: Lane/Map has zero persistent state at MVP per Section F dependency table.

### Updated In Place (2)

#### ADR-0001 (Run State / Game Flow)

**Amendment applied**: `RUN_LOADING → MAIN_MENU` added to `VALID_TRANSITIONS`. New "Bake-failure abort path" subsection appended after Tightenings.

**What was assumed (line 80 + line 220)**:
> "RUN_LOADING — map + Champion + initial card pool loaded; transient (~0.5s)"
> Transition table allowed only: `GameState.RUN_LOADING: [GameState.RUN_PREP]`

**What the GDD now requires (R2.1 AC-LM-21 + Section E + Open Question #2)**:
- Pre-bake outline-vertex pre-validation may emit `bake_pre_validation_failed(lane_id, reason)` BEFORE any bake is called — this MUST transition `RUN_LOADING → MAIN_MENU`.
- Engine-level bake failure may emit `bake_failed(lane_id, reason)` — same transition.
- No live-abort timer (DD#2 = Sync bake; a `Timer` cannot interrupt a synchronous main-thread `bake_navigation_polygon()` call).
- The 500 ms `RUN_LOADING` ceiling is enforced via pre-bake validation (runs before the bake) + post-bake assertion (a story-Done benchmark gate, NOT a runtime abort).

**Resolution**: Updated in place. ADR-0001's transition table extended; new subsection documents the abort path's two failure triggers and the locked sync-bake rationale. Status remains `Proposed` (Run State #8 GDD is Approved but ADR-0001 is still pre-implementation; the original review-mode ladder applies).

**Outstanding**: ADR-0001 references a placeholder `_pending_load_error: String` field on `GameStateMachine` for surfacing the error string to HUD. The actual error channel design is owned by HUD GDD (#29) when authored.

---

#### ADR-0002 (Crowd Pathfinding)

**Amendment applied**: New "Wall-Block No-Path Fallback" subsection inserted before Key Interfaces.

**What was assumed (Risk 11, line 412)**:
> "Risk: First path query after `geometry_baked` fires before navmesh is rebuilt — returns empty path. Mitigation: Requeries gated on `NavigationServer2D.map_changed`."

This handles the **race condition** between bake completion and first query. Does NOT address the case where a wall mutation **legitimately leaves zero path** under Lane/Map Rule 9.

**What the GDD now requires (R2.1 Section C Rule 9 + Section E + Open Question #9)**:
- CrowdManager must use the truncated path returned by `query_path()` when the goal is fully obstructed (zombie reaches the closest reachable cell adjacent to the wall and stops).
- Do NOT fire `agent_reached_target` until the agent reaches its registered goal (a truncated-terminus stop is NOT a goal-reach).
- Retry policy: event-driven only (`placement_changed`, `wall_destroyed`, `geometry_baked` → gated on `NavigationServer2D.map_changed`). NEVER per-frame retry.
- Zombie behavior at truncated terminus is owned by Zombie AI (#17) + Combat (#13/#27), NOT CrowdManager.
- "No zombie permanently stuck" guarantee: when `wall_destroyed` fires, the path re-opens via the existing event-driven requery path; agent resumes on next velocity-update cycle.

**Resolution**: Updated in place. ADR-0002 new subsection codifies the contract; references Lane/Map's Section E edge-case prose as the source. The implementation note (`bool _isAtTruncatedTerminus` flag on `CrowdAgent`, C#-internal) gives the consumer story a concrete pattern.

**Outstanding**: AC-LM-23 (originally in Lane/Map, deleted in R2 per B4) is now tracked in Lane/Map Section F's cross-system AC re-authoring tracker, pointing at Wall/Fortification (#27). When that GDD lands, the AC verifying "blocked lane resolves when wall is destroyed" lives in Wall/Fortification's AC list.

---

### Likely Superseded (0)

None — neither ADR's core decision is contradicted, only extended.

---

## Resolution Decisions

| ADR | User decision (2026-05-02 widget) | Action taken |
|---|---|---|
| ADR-0001 | "Update in place (Recommended)" | Transition table edit + Bake-failure abort path subsection appended; revision history entry added; status updated. |
| ADR-0002 | "Update in place (Recommended)" | Wall-Block No-Path Fallback subsection inserted; revision history entry added; status updated. |

---

## Files Modified

| File | Change |
|---|---|
| `docs/architecture/adr-0001-run-state-game-flow.md` | Status updated; revision history entry added; `VALID_TRANSITIONS` for `RUN_LOADING` extended with `MAIN_MENU`; new "Bake-failure abort path" subsection appended. |
| `docs/architecture/adr-0002-crowd-pathfinding-architecture.md` | Status + Date + Revision History added; new "Wall-Block No-Path Fallback" subsection inserted before Key Interfaces. |
| `docs/architecture/change-impact-2026-05-02-lane-map.md` | This file (created). |

**Files NOT modified** (already updated during R2 + R2.1 inline-fix pass — see `design/gdd/lane-map-system.md` Section J):
- `design/gdd/lane-map-system.md` (R2 + R2.1 applied)
- `docs/registry/architecture.yaml` (lane-map perf budget; aggregated `LaneSystem.geometry_baked` contract; `cross_system_invariants` section; `forbidden_pattern: mutation_api_called_outside_wall_fortification`; cost_model + steady_state_ceiling fields)
- `.claude/docs/technical-preferences.md` (benchmark hardware spec)
- `design/gdd/systems-index.md` (Lane/Map #7 status: Approved)
- `design/gdd/reviews/lane-map-system-review-log.md` (R2 + R2.1 entry appended)

---

## Follow-Up Actions

- **`/architecture-review`** can now run to verify the full traceability matrix is coherent across the 5 amended ADRs (0001 + 0002 amendments + 0003/0004/0006 unchanged) — recommended before next GDD authoring (Input System #1, the next system in design order).
- **Lane/Map paper prototype** (Open Question #4) — must run before any Lane/Map implementation story.
- **Steam Deck p95 bake benchmark + adjacency-cost test** (Lane/Map Open Question #7) — pre-Lane/Map-story gate; no story authored against Lane/Map until the benchmark is on file.
- **Art Bible amendment** (Lane/Map Open Question #8) — `cell_size_px = 96` propagation into `design/art/art-bible.md` by art-director + producer.
- **Camera GDD Open Question #1** — Lane/Map exposes `camera_bounds: Rect2` vs. Camera derives bounds from lane geometry. Resolved when Camera GDD #6 is authored.
- **Wall/Fortification GDD authoring** can begin (#27); AC-LM-23 + AC-LM-30 await re-authoring per Lane/Map Section F tracker.
- **Crowd Pathfinding GDD authoring** can begin (#11); Wall-Block No-Path Fallback contract is now firm.
- **Placement & Grid GDD authoring** can begin (#25); AC-LM-26 awaits re-authoring per Lane/Map Section F tracker.
- **No new ADR required** for the steady-state trigger rule (Lane/Map D.7 R2.1 + `architecture.yaml` `steady_state_ceiling_for_episodic_validity: 14.0`) — per creative-director synthesis, this is a registry + GDD edit, not a separate architectural decision.
