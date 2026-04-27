# Architecture Review — ADR-0001 (Focused Single-ADR Audit)

> **Date:** 2026-04-28
> **Mode:** `/architecture-review ADR-0001` (non-standard argument; interpreted as focused single-ADR review)
> **Verdict:** **PASS** (with 3 tightenings applied during the review)
> **Engine:** Godot 4.6.2

---

## Scope

This review focused on **ADR-0001 Run State / Game Flow** specifically:
- Internal completeness against the 10 technical requirements derived from the systems-index + game-concept
- Engine compatibility against the pinned Godot 4.6.2 reference
- Cross-ADR consistency vs ADR-0003 (its declared dependency) and ADR-0002 (downstream consumer)
- Registry alignment

The downstream coverage of the 13 consumer systems (HUD, Save/Load, Adaptive Music, etc.) was **not** audited as no per-system GDDs exist yet. That coverage check is appropriate after `/design-system run-state-game-flow` produces GDD #1.

---

## Inputs Loaded

| Input | Count |
|---|---|
| ADRs (all Proposed) | 3 — ADR-0001, ADR-0002 (untracked), ADR-0003 |
| Per-system GDDs | 0 |
| Engine reference docs | 4 (VERSION, deprecated-apis, breaking-changes, current-best-practices) |
| Registry stances | 26 (6 state-ownerships, 6 interfaces, 7 API decisions, 7 forbidden patterns) |
| TR registry entries | 0 (registry empty — appropriate; no GDDs yet) |

---

## Phase 2 — Technical Requirements Extracted

Sourced from `design/gdd/systems-index.md` (System 8 row + Pattern 1 + High-Risk Systems entry) and `design/gdd/game-concept.md` (Core Loop + retention hooks). These are *suggested* TR-IDs; they should be persisted to `docs/architecture/tr-registry.yaml` only when GDD #1 is authored against them.

| Suggested TR-ID | Requirement | Source |
|---|---|---|
| TR-runstate-001 | 9-phase run-flow enum: `MAIN_MENU → CHAMPION_SELECT → RUN_LOADING → RUN_PREP → WAVE_ACTIVE → WAVE_RESULTS → CARD_ROLL → RUN_PAUSED → RUN_RESULTS` | concept Core Loop; systems-index System 8 |
| TR-runstate-002 | Transition events fire as typed signals | technical-preferences + ADR-0003 boundary rule |
| TR-runstate-003 | Pause from any in-run state preserves prior state and resumes correctly | concept Pillar 4 (mid-wave card reading) |
| TR-runstate-004 | Snapshot publishable on every transition (JSON-serializable Dictionary) | downstream of ADR-006 (Save Schema, pending) |
| TR-runstate-005 | Wave System (C#) emits one `WaveComplete` per wave end → transitions WAVE_ACTIVE→WAVE_RESULTS | systems-index Pattern 1 (Run State ↔ Wave) |
| TR-runstate-006 | Test Harness drives `transition_to()` programmatically in `--headless` | System 45 |
| TR-runstate-007 | `GameState` enum value stability across builds (append-only enum) | save-format integrity |
| TR-runstate-008 | Cross-language signal batched (≤1/wave from C# Wave) | ADR-0003 forbidden_pattern `unbatched_csharp_to_gdscript_signal_emission` |
| TR-runstate-009 | `CARD_ROLL` distinct from `WAVE_RESULTS` (two sub-beats) | concept "30s loot/card-roll"; Adaptive Music + Tutorial differentiation |
| TR-runstate-010 | Typed Callable connection form only | forbidden_pattern `string_based_signal_connection` |

---

## Phase 3 — Traceability Matrix

| TR-ID | Requirement | ADR-0001 Coverage | Status |
|---|---|---|---|
| TR-runstate-001 | 9-state enum | Decision § State Enum (lines 67–82) | ✅ |
| TR-runstate-002 | Typed-signal transitions | Decision § Signal Contract (lines 132–162) | ✅ |
| TR-runstate-003 | Pause preserves & resumes | Decision § pause()/resume() + `previous_state` field (lines 244–279) | ✅ |
| TR-runstate-004 | Snapshot every transition | Decision § Save Snapshot Contract (lines 282–313) | ✅ |
| TR-runstate-005 | Wave→RunState handoff | Decision § Cross-Language Signal (lines 164–204) | ✅ |
| TR-runstate-006 | Headless drivability | Decision § transition_to() + Validation Criteria | ✅ |
| TR-runstate-007 | Enum stability | Decision § enum stability rule + Risk #8 + regression test in Validation Criteria | ✅ |
| TR-runstate-008 | Batched cross-language signal | Decision §164–204 + Risk #6 | ✅ |
| TR-runstate-009 | CARD_ROLL distinct | Decision § "Why CARD_ROLL is its own state" (line 84) | ✅ |
| TR-runstate-010 | Typed Callable form | Decision § Signal Contract example + forbidden_pattern hook | ✅ |

**Coverage: 10/10 ✅**

---

## Phase 4 — Cross-ADR Conflict Detection

### ADR-0001 vs ADR-0003 — RESOLVED 2026-04-28

| Aspect | Finding |
|---|---|
| **Original concern** | `active.md` flagged ADR-0003 line 95 as having a PascalCase signal-connection example (`HealthChanged.connect`) that should be snake_case |
| **Reality on review** | Signal-side example (line 97) was already correct (`health_changed.connect`). The actual stale issue was a method example on line 95: `BuildModifier.compute_stats(input)` — methods preserve PascalCase per ADR-0002's `csharp_method_snakecase_in_gdscript_call` forbidden pattern (added 2026-04-27, two days after ADR-0003 was written) |
| **Fix applied** | Edited ADR-0003 line 95 from `BuildModifier.compute_stats(input)` to `BuildModifier.ComputeStats(input)` with an inline note about method/signal naming asymmetry |
| **Cascading fix** | Edited ADR-0001 line 202 to remove the stale "ADR-0003 should be retrofit-edited" recommendation; replaced with positive cross-reference acknowledging ADR-0003 + ADR-0002 jointly codify the full boundary naming rule |

### ADR-0001 vs ADR-0002 — Consistent (no fix needed)

| Aspect | Finding |
|---|---|
| State ownership | ADR-0002's `CrowdManager` reads `GameStateMachine.current_state` and subscribes to `state_changed`; respects `write_access: game-state-machine-only` ✅ |
| Pause coordination | `_waveActive = (new_state == WAVE_ACTIVE)` correctly derives from ADR-0001's transition contract, including resume semantics (RUN_PAUSED → WAVE_ACTIVE re-enables loop) ✅ |
| Autoload ordering | ADR-0002 explicitly requires `CrowdManager` loaded after `GameStateMachine`; matches ADR-0001 Risk #1 mitigation ✅ |
| Forbidden patterns | ADR-0002's `csharp_method_snakecase_in_gdscript_call` is the inverse of ADR-0001's `csharp_signal_pascalcase_in_gdscript_connect` — together they codify both halves of the boundary naming rule ✅ |
| Save schema | ADR-0002 has no persistent state; doesn't intersect ADR-0001's snapshot Dictionary ✅ |

### ADR Dependency Order

```
Foundation:
  1. ADR-0003 (Language Routing Policy)        — Proposed
Depends on Foundation:
  2. ADR-0001 (Run State / Game Flow)          — Proposed; depends on ADR-0003
  3. ADR-0002 (Crowd Pathfinding Architecture) — Proposed; depends on ADR-0003 + ADR-0001
```

No cycles. No unresolved dependencies. All three remain in `Proposed` because none have been formally promoted yet — not because of a structural blocker.

---

## Phase 5 — Engine Compatibility

| Check | Result |
|---|---|
| Engine version match (4.6.2) | ✅ |
| Engine Compatibility section present | ✅ |
| Post-Cutoff APIs declared | ✅ `@abstract` (4.5+) and `await signal` (4.0) marked as opportunistic, not load-bearing |
| Deprecated API usage | ✅ None — uses `signal.connect(callable)`, NOT `connect("name", obj, "method")` |
| Stale version references | ✅ None |

### Tightening Applied — ADR-0001 line 18

**Before:**
> Confirm autoload's `process_mode = PROCESS_MODE_ALWAYS` (Godot default for autoloads) so its signal handlers continue firing while `get_tree().paused = true`.

**Issue:** `PROCESS_MODE_ALWAYS` is **not** the default for autoloads (or any Node). The default is `PROCESS_MODE_INHERIT`. The implementation at line 171 explicitly sets it. Additionally, signal handlers themselves fire regardless of process mode — they are direct invocations. PROCESS_MODE_ALWAYS is load-bearing only for *deferred follow-up work* created inside handlers (Tween, await, call_deferred).

**After:**
> Confirm autoload's `process_mode = PROCESS_MODE_ALWAYS` (set explicitly in `_ready()`; the default for any Node — autoloads included — is `PROCESS_MODE_INHERIT`) so deferred follow-up work created inside signal handlers (`Tween` instances, `await get_tree().process_frame`, `call_deferred`) continues across `get_tree().paused = true`. Note: signal handlers themselves are direct invocations and fire regardless of process mode; `PROCESS_MODE_ALWAYS` is load-bearing only for these in-handler continuations.

**Severity before fix:** Cosmetic — the *code* was correct; only the parenthetical reasoning was imprecise. Tightening makes the verification step's intent unambiguous to a future reader.

---

## Phase 5b — Design Revision Flags

**None.** Knowledge Risk on ADR-0001 is LOW; no GDDs exist yet to revise; no HIGH RISK engine findings; no deprecated API usage; no post-cutoff API surprises.

---

## Phase 6 — Architecture Document Coverage

`docs/architecture/architecture.md` does not exist. Expected — only 3 ADRs exist (target: 7 before architecture doc is authored). Run `/create-architecture` after ADR-0006 lands.

---

## Verdict

**PASS** for ADR-0001.

ADR-0001 is internally complete, registry-aligned, engine-consistent, and integrates correctly with both ADR-0003 (its declared dependency) and ADR-0002 (downstream consumer). The three review-driven edits (one in each of ADR-0001 [×2] and ADR-0003 [×1]) tighten precision and reconcile a stale cross-reference; none change the Decision section's substance.

### Edits Applied During Review

1. **ADR-0001 line 18** — `process_mode = PROCESS_MODE_ALWAYS` verification note tightened to acknowledge it is explicitly set (not a default), and that its load-bearing aspect is in-handler continuations (not signal-handler invocation itself).
2. **ADR-0001 line 202** — Stale "ADR-0003 should be retrofit-edited" recommendation replaced with a positive cross-reference acknowledging ADR-0003 + ADR-0002 together codify the full boundary naming rule (signals → snake_case in GDScript; methods → PascalCase in GDScript).
3. **ADR-0003 line 95** — Method example corrected from `BuildModifier.compute_stats(input)` (snake_case, wrong — methods preserve PascalCase) to `BuildModifier.ComputeStats(input)`, with inline note pointing to ADR-0002's `csharp_method_snakecase_in_gdscript_call` forbidden pattern.

### Deferred (Out of Scope of This Review)

- **TR registry update.** The 10 TR-IDs above should be persisted to `docs/architecture/tr-registry.yaml` only when GDD #1 (Run State) is authored against them. The IDs were derived from the systems-index + game-concept; the GDD will likely refine wording and split/merge some, so committing them now would risk renumbering churn. Defer until `/design-system run-state-game-flow` produces GDD #1.
- **Full architecture coverage audit** of all 7 planned ADRs. Re-run `/architecture-review` (without an ADR argument) after ADR-0004 (Juice Pipeline) and ADR-0006 (Save Schema) are authored, to validate cross-ADR coverage at the project scale.

---

## Recommended Next Actions (in order)

1. **Promote ADR-0003 from Proposed → Accepted.** It is foundational, has no remaining open issues, and unblocks ADR-0001 / ADR-0002 promotions.
2. **Promote ADR-0001 from Proposed → Accepted.** This unblocks GDD #1 (Run State) authoring and 13 consumer system GDDs.
3. **Promote ADR-0002 from Proposed → Accepted** *after* its prototype validates the chosen architecture (per its own Validation Criteria). Until then it remains Proposed.
4. **Author next ADR**: ADR-0004 (Juice Pipeline Integration Model) is the next gate, blocking GDD #9 (Juice).
5. **Begin GDD #1 authoring**: `/design-system run-state-game-flow` — ADR-0001 has unblocked it. The 10 suggested TR-IDs above will become real entries in `tr-registry.yaml` at that point.
6. **Re-run `/architecture-review`** (without argument, full mode) after ADR-0004 + ADR-0006 are written, before the pre-production gate.
