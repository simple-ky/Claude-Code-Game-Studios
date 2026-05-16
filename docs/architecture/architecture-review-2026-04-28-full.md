# Architecture Review — Full (5 ADRs)

> **Date:** 2026-04-28
> **Mode:** `/architecture-review` (full — no argument)
> **Verdict:** **PASS** (with 2 minor tightenings applied during the review)
> **Engine:** Godot 4.6.2
> **Predecessor review:** `architecture-review-2026-04-28-adr-0001.md` (focused single-ADR scope)

---

## Scope

Full cross-ADR review covering all 5 authored ADRs:

| ADR | Title | Status | Specialist Validated? |
|---|---|---|---|
| ADR-0001 | Run State / Game Flow | Proposed | ✅ (prior review) |
| ADR-0002 | Crowd Pathfinding Architecture | Proposed | ⚠️ pending |
| ADR-0003 | Language Routing Policy | Proposed | ⚠️ pending |
| ADR-0004 | Juice Pipeline Integration Model | Proposed | ⚠️ pending |
| ADR-0006 | Save Schema & Versioning | Proposed | ⚠️ pending |

The 5 ADRs are reviewed against:
- Internal completeness
- Cross-ADR consistency (all 10 pairwise combinations)
- Engine compatibility against pinned Godot 4.6.2 reference
- Registry alignment (`docs/registry/architecture.yaml`)
- Coverage of technical requirements derivable from `design/gdd/systems-index.md` + `design/gdd/game-concept.md`

No per-system GDDs exist yet, so per-GDD coverage will re-validate after each GDD authoring cycle.

ADR-0005 (`ModifierTarget` Contract) and ADR-0007 (Effect Composition Taxonomy) are scheduled to live INSIDE their respective system GDDs (Champion and Build/Modifier) per the systems-index plan — they are intentionally not yet authored as standalone ADRs and are out of scope of this review.

---

## Inputs Loaded

| Input | Count |
|---|---|
| ADRs (all `Proposed`) | 5 — ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0006 |
| Per-system GDDs | 0 (only systems-index + game-concept) |
| Engine reference docs | 12 (VERSION, breaking-changes, deprecated-apis, current-best-practices, modules/×7) |
| Registry stances | 30 (6 state-ownerships, 9 interface contracts, 1→2 perf budgets after this review, 14 API decisions, 14 forbidden patterns) |
| TR registry entries | 0 (intentional — anchored to GDDs which are not yet authored) |
| Consistency-failures log | absent (no prior conflicts logged across project lifetime) |

---

## Phase 2 — Technical Requirements Extracted

50 TR-IDs derived from `design/gdd/systems-index.md` + `design/gdd/game-concept.md`. These remain *suggested* (NOT yet persisted to `tr-registry.yaml`) because no GDD anchors them. They graduate to registry entries when their respective GDDs are authored. The previous review (2026-04-28 ADR-0001 focused) extracted the first 10 (Run State); this review extends the set.

| System | TR Count | Source |
|---|---|---|
| Run State (#8) | 10 (TR-runstate-001..010) | systems-index Pattern 1 + High-Risk; concept Core Loop |
| Crowd Pathfinding (#11) | 7 (TR-crowdpath-001..007) | systems-index High-Risk Technical |
| Language Routing (cross-cutting) | 9 (TR-langrouting-001..009) | systems-index Language Routing Policy + Performance Watchlist |
| Juice Pipeline (#9) | 9 (TR-juice-001..009) | concept Tech Risks (per-weapon warning); Pillar 2 |
| Save Schema (Save/Load #2) | 11 (TR-savescheme-001..011) | concept Tech Risks line 325; ADR-0001 handoff |
| Test Harness (#45) | 4 (TR-testharness-001..004) | TD-added in systems-index |

**TR registry persistence deferred** — committing TR-IDs now would risk renumbering churn when GDDs refine wording. Defer until each GDD is authored against its TR set.

---

## Phase 3 — Traceability Matrix

| TR Suggested ID Range | Requirement Theme | ADR Coverage | Status |
|---|---|---|---|
| TR-runstate-001..010 | 9-state enum, signals, pause/resume, snapshot, headless drivable, append-only enum, batched cross-language signal, CARD_ROLL distinct, typed Callable | ADR-0001 | ✅ all 10 |
| TR-crowdpath-001..007 | 100+ agents @ 60fps, event-driven path queries, cheap register/deregister, separation steering, pause-aware, headless drivable | ADR-0002 | ✅ all 7 |
| TR-langrouting-001..009 | GDScript default, hot-path criteria, signals over methods, GDExtension excluded, marshalling cap, RefCounted-vs-Node guidance | ADR-0003 | ✅ all 9 |
| TR-juice-001..009 | Single dispatch path, data-driven recipes, ≤50/frame batched signal, pause-clean abort, pooled artifacts, hybrid hit-stop, UI/audio decoupling, ≤0.5ms budget, per-Champion shake | ADR-0004 | ✅ all 9 |
| TR-savescheme-001..011 | user:// JSON + ConfigFile carve-out, schema_version envelope, split-by-domain, N-2 migration window, .bak fallback, atomic writes (Windows-safe), append-only enums, ADR-0001 snapshot integration, Tech Risk recovery UX | ADR-0006 | ✅ all 11 |
| TR-testharness-001..004 | --headless runner, deterministic RNG, fixture loader, card-combo sims | ADR-0001 (`transition_to` drivable), ADR-0002 (`UpdateVelocitiesForTest`), ADR-0004 (VC-1..VC-9 tests), ADR-0006 (fixture path via SaveManager) | ⚠️ partial — no dedicated ADR; covered piecewise by consumer ADRs |

**Coverage: 50 TRs total — 49 ✅ Covered, 1 ⚠️ Partial, 0 ❌ Gaps**

The Test Harness "partial" status is by design — it's a system for GDD authoring (not architecture). Each ADR provides its own headless-test entry point. No follow-up ADR is needed; Test Harness GDD will integrate the entry points.

---

## Phase 4 — Cross-ADR Conflict Detection

### Pairwise audit (10 pairs — exhaustive)

| Pair | Result |
|---|---|
| ADR-0001 ↔ ADR-0002 | ✅ Already validated in prior review. CrowdManager subscribes to `state_changed`; pause integration (`_waveActive` flag) correct; autoload load-order rule documented. |
| ADR-0001 ↔ ADR-0003 | ✅ Already validated. ADR-0001 follows GDScript orchestration rule; cross-language `wave_complete` signal correct (snake_case auto-translation). |
| ADR-0001 ↔ ADR-0004 | ✅ ADR-0004 subscribes to `state_changed` for hit-stop abort on `RUN_PAUSED` (lines 282-298); explicitly references `state_machine_pattern` precedent when rejecting EventBus alternative (line 319-320). |
| ADR-0001 ↔ ADR-0006 | ✅ ADR-0006 explicitly says `run_snapshot.save`'s `schema_version` IS the snapshot Dictionary's `schema_version` from ADR-0001 (one field, two consumers — not double-versioning). Generalizes ADR-0001's `inserting_game_state_enum_values` to `inserting_persisted_enum_values`. |
| ADR-0002 ↔ ADR-0003 | ✅ Already validated. CrowdPathfinding routed to C# per criterion 1 (>50 entities/frame). Complementary forbidden patterns (`csharp_method_snakecase_in_gdscript_call` + `csharp_signal_pascalcase_in_gdscript_connect`) codify both halves of boundary naming rule. |
| ADR-0002 ↔ ADR-0004 | ✅ ADR-0004 sets the 100+ zombie target per ADR-0002. No state ownership conflict; no shared per-frame budget contention. |
| ADR-0002 ↔ ADR-0006 | ✅ ADR-0006 Related Decisions: "No interaction; pathfinding state is regenerated each wave, not persisted." |
| ADR-0003 ↔ ADR-0004 | ✅ ADR-0004's `damage_dealt(HitEvent)` C#→GDScript signal contract follows ADR-0003 boundary rule; PascalCase property access guarded with runtime `assert(hit_event is HitEvent, ...)` for the cold-start C#-assembly-not-loaded silent-downgrade case. |
| ADR-0003 ↔ ADR-0006 | ✅ ADR-0006 Related Decisions: SaveManager is GDScript; persistent state crosses language boundary by being snapshotted on the GDScript side via `state_changed` handlers. C# hot-path systems do not write directly to disk. |
| ADR-0004 ↔ ADR-0006 | ✅ ADR-0006 Risk 7 explicitly carves out the JSON-vs-Resource distinction: ADR-0004 bans JSON for *designer-tuned config* (use `.tres` Resources for `JuiceProfile`); ADR-0006 uses JSON for *user-mutable save data*. The two stances are non-contradictory once carved out — recorded in registry as `purpose: save_file_format` rationale. |

### Two minor findings — both resolved during this review

**MINOR-1: Stale cross-reference in ADR-0002 line 474 — RESOLVED 2026-04-28**

| Aspect | Finding |
|---|---|
| **Original concern** | ADR-0002 line 474 read: *"ADR-0003 should be retrofit-edited to remove the incorrect snake-case method example (a known follow-up per `production/session-state/active.md`)."* |
| **Reality** | That retrofit was completed in the prior review (2026-04-28). ADR-0003 line 95 was edited from `compute_stats` → `ComputeStats`. The "should be retrofit-edited" wording was now wrong-tense — referring to completed work as pending. |
| **Fix applied** | Edited ADR-0002 line 474 to acknowledge the completed retrofit and clarify that the two complementary forbidden_patterns (`csharp_method_snakecase_in_gdscript_call` in ADR-0002 + `csharp_signal_pascalcase_in_gdscript_connect` in ADR-0001) jointly codify the full boundary naming rule. |
| **Severity before fix** | Cosmetic — documentation precision only; no Decision content was affected. |

**MINOR-2: Crowd Pathfinding performance budget unregistered — RESOLVED 2026-04-28**

| Aspect | Finding |
|---|---|
| **Original concern** | ADR-0002 line 44 + line 430 declare an informal target of **≤2.0 ms/frame at 100 agents** but did not register it in `docs/registry/architecture.yaml` `performance_budgets:` section. Only ADR-0004's `juice: 0.5 ms` was registered. |
| **Headroom check** | Juice (0.5 ms) + Crowd (2.0 ms) = 2.5 ms registered; total frame budget 16.6 ms. Leaves 14.1 ms for the remaining 41 systems — well within ceiling. No performance-budget conflict. |
| **Fix applied** | Added `crowd-pathfinding: 2.0 ms` entry to `performance_budgets:` with breakdown (spatial hash 0.3 ms + velocity loop 0.6 ms + MoveAndSlide×100 0.8 ms) and exclusions (path queries are event-driven and deferred). |
| **Severity before fix** | Low — informal claim was correct and consistent; only registry visibility was missing. |

### ADR Dependency Order (topologically sorted)

```
Foundation (no deps):
  1. ADR-0003: Language Routing Policy             — Proposed

Depends on Foundation:
  2. ADR-0001: Run State / Game Flow               — Proposed; depends on ADR-0003

Depends on Foundation + ADR-0001:
  3. ADR-0002: Crowd Pathfinding Architecture      — Proposed; depends on ADR-0003 + ADR-0001
  4. ADR-0004: Juice Pipeline Integration Model    — Proposed; depends on ADR-0001 + ADR-0003

Depends on ADR-0001:
  5. ADR-0006: Save Schema & Versioning            — Proposed; declares "ADR-0001 must be Accepted"
```

- **No cycles.**
- **No structural unresolved deps.** All 5 are `Proposed` because the project is intentionally batching promotion until cross-ADR review passes (now). ADR-0006's "ADR-0001 must be Accepted" is a promotion-order requirement, not a structural blocker against authoring.
- ADR-0005 (`ModifierTarget` Contract) and ADR-0007 (Effect Composition Taxonomy) live inside Champion and Build/Modifier GDDs respectively — authored at GDD time per the systems-index plan, not as standalone ADRs.

### Recommended promotion order

1. **ADR-0003 → Accepted** (foundational; no deps; unblocks all others).
2. **ADR-0001 → Accepted** (unblocks GDD #1 Run State + 13 consumers + ADR-0006 promotion).
3. **ADR-0002 → Accepted** *after* the Crowd Pathfinding prototype validates the architecture per its own Validation Criteria. Until prototype passes, remain Proposed.
4. **ADR-0004 → Accepted** (unblocks GDD #9 Juice + GDD #13 Damage signal contract section + GDD #35).
5. **ADR-0006 → Accepted** *after* ADR-0001 (unblocks GDD #2 Save/Load + 8 persistent systems).

Each promotion warrants a focused `godot-specialist` validation pass for the unvalidated 4 ADRs (see Phase 5).

---

## Phase 5 — Engine Compatibility

| Check | Result |
|---|---|
| Engine version match (4.6.2) across all 5 ADRs | ✅ all 5 |
| Engine Compatibility section present | ✅ all 5 |
| Post-Cutoff APIs declared | ✅ all 5 (see breakdown) |
| Deprecated API references | ✅ none — all use typed Callable / `await signal` / `instantiate()` etc. |
| Stale version references | ✅ none |
| Knowledge Risk levels | ADR-0001 LOW, ADR-0002 MEDIUM-HIGH, ADR-0003 LOW-MEDIUM, ADR-0004 LOW, ADR-0006 MEDIUM |

### Post-Cutoff API Summary

| ADR | Post-cutoff APIs | Load-bearing? | Verified against engine reference |
|---|---|---|---|
| ADR-0001 | `@abstract` (4.5+), `await signal` (4.0+) | No — opportunistic | ✅ current-best-practices.md |
| ADR-0002 | `NavigationServer2D` dedicated 2D (4.5), C# `[Signal]` PascalCase→snake_case auto-translation | YES — auto-translation rule is the core boundary contract | ✅ modules/navigation.md, breaking-changes.md |
| ADR-0003 | GDScript variadics (4.5), `@abstract` (4.5), C# string extraction (4.6) | No — additive | ✅ current-best-practices.md, breaking-changes.md |
| ADR-0004 | `GPUParticles2D.restart(keep_seed)` (4.4) | YES — pool reuse correctness depends on `keep_seed=false` | ✅ breaking-changes.md |
| ADR-0006 | `FileAccess.store_*` returning `bool` (4.4) | YES — return-check is mandatory; ignored returns silently truncate saves | ✅ breaking-changes.md, deprecated-apis.md |

### Deprecated API audit

Grep across all 5 ADRs against `deprecated-apis.md`:

- ✅ No use of `connect("name", obj, "method")` — all use typed `signal.connect(callable)`.
- ✅ No use of `yield()` — `await signal` used where async needed.
- ✅ No use of `instance()` — `instantiate()` referenced where applicable.
- ✅ No use of `Navigation2D` / `Navigation3D` — `NavigationServer2D` used.
- ✅ No use of `TileMap` — `TileMapLayer` referenced (ADR-0002 mentions "lane TileMapLayer geometry").
- ✅ No use of `duplicate()` for nested resources — ADR-0004 line 207 explicitly uses `duplicate_deep()` (4.5 advisory).

### Engine Specialist Consultation — recommendation, not blocker

Per `.claude/docs/technical-preferences.md`, the primary specialist is `godot-specialist`. Status:

- **ADR-0001**: ✅ Already specialist-validated (per `production/session-state/active.md`, prior review).
- **ADR-0002, ADR-0003, ADR-0004, ADR-0006**: ⚠️ Not yet specialist-validated.

Each unvalidated ADR has well-reasoned engine-claim sections (ADR-0002 has 11 risks; ADR-0006 has 9 risks; both cite `breaking-changes.md` and `deprecated-apis.md` correctly). This review's audit found no engine-claim defects.

**Recommendation**: spawn a focused `godot-specialist` review for each of the 4 unvalidated ADRs **before each one promotes from `Proposed` → `Accepted`**, not before they remain Proposed. Specialist validation is a promotion gate, not a review blocker.

---

## Phase 5b — GDD Revision Flags

**None.** No per-system GDDs exist yet to flag. All 5 ADRs declare engine claims that align with the verified engine reference. When per-system GDDs begin authoring (starting with GDD #1 Run State), each `/design-system` run will pull engine-fact constraints from the ADR Decision sections directly — no GDD-side adjustments needed at this stage.

---

## Phase 6 — Architecture Document Coverage

`docs/architecture/architecture.md` does not exist. **Expected** — only 5 of 7 planned ADRs authored.

ADR-0005 (`ModifierTarget` Contract) lives inside Champion GDD; ADR-0007 (Effect Composition Taxonomy) lives inside Build/Modifier GDD. Both author at GDD time per the systems-index plan, not as standalone ADRs. Run `/create-architecture` after the Champion + Build/Modifier GDDs are written and ADRs 0005/0007 are extracted from them — that is the appropriate trigger for the master architecture document.

---

## Verdict — **PASS**

All 5 ADRs are internally consistent, registry-aligned, engine-compliant, and integrate correctly across all 10 pairwise combinations. The 2 minor findings (MINOR-1 stale wording, MINOR-2 unregistered budget) were resolved during the review — neither is a blocking conflict.

### Edits Applied During Review

1. **ADR-0002 line 474** — Stale "ADR-0003 should be retrofit-edited" recommendation rewritten to acknowledge completed retrofit and clarify the joint role of `csharp_method_snakecase_in_gdscript_call` + `csharp_signal_pascalcase_in_gdscript_connect` forbidden patterns in codifying the full boundary naming rule.

2. **`docs/registry/architecture.yaml` `performance_budgets:`** — Added `crowd-pathfinding: 2.0 ms` entry with detailed breakdown (spatial hash + velocity loop + MoveAndSlide×100) and exclusions (path queries are event-driven and deferred). Registry total now: juice 0.5 + crowd 2.0 = 2.5 ms vs 16.6 ms ceiling — 14.1 ms headroom.

### Deferred (Out of Scope of This Review)

- **TR registry update**. The 50 suggested TR-IDs above should be persisted to `docs/architecture/tr-registry.yaml` only when each per-system GDD is authored against them. Committing them now would risk renumbering churn.
- **Architecture.md authoring**. Run `/create-architecture` after ADR-0005 + ADR-0007 are authored at GDD time.
- **Specialist validation of 4 unvalidated ADRs**. Spawn `godot-specialist` per-ADR before each promotion to `Accepted`.
- **`docs/consistency-failures.md` reflexion log**. File does not exist; no append needed (no CONFLICT findings to record — only GAP- and MINOR-class findings, which the skill explicitly excludes from reflexion logging).

---

## Required ADRs (still missing, in priority order)

1. **ADR-0005 `ModifierTarget` Contract** — authored *inside* Champion GDD; gates GDD #13 Champion + GDD #16 Ability + GDD #15 Weapon + GDD #22 Build/Modifier + GDD #21 Card.
2. **ADR-0007 Effect Composition Taxonomy** — authored *inside* Build/Modifier GDD; gates GDD #21 Card.

Both are authored at GDD time per the systems-index plan. They are not standalone ADRs; they are scoped sections of their parent GDDs.

---

## Recommended Next Actions (in order)

1. **Promote ADR-0003 from Proposed → Accepted.** Foundational; no remaining open issues; unblocks ADR-0001 / ADR-0002 / ADR-0004 / ADR-0006 promotions. Spawn `godot-specialist` validation pass first.
2. **Promote ADR-0001 from Proposed → Accepted.** Already specialist-validated. Unblocks GDD #1 (Run State) authoring and 13 consumer system GDDs.
3. **Begin GDD #1 authoring**: `/design-system run-state-game-flow` — ADR-0001 has unblocked it. The 10 suggested TR-runstate IDs above will become real entries in `tr-registry.yaml` at that point.
4. **Spawn `godot-specialist` validation passes for ADR-0002, ADR-0003, ADR-0004, ADR-0006.** Before each promotion. Can be batched into a single pass or run per-ADR.
5. **After Crowd Pathfinding prototype validates ADR-0002 architecture**: promote ADR-0002 → Accepted. Run `/prototype crowd-pathfinding` (per systems-index Phase B).
6. **Run `/architecture-review`** (full mode again) once GDD #1 is authored — to validate that the 10 TR-runstate IDs migrate cleanly into `tr-registry.yaml` and that GDD coverage of Run State requirements remains complete.
7. **When ADR-0005 + ADR-0007 are authored** (inside their respective GDDs): run `/create-architecture` to author `docs/architecture/architecture.md`.
