# Lane / Map System — Locked Decisions from `/design-review` 2026-05-02

> **Status**: LOCKED — apply in fresh session (R2 revision pass)
> **Source review**: `/design-review design/gdd/lane-map-system.md` (full mode)
> **Verdict**: MAJOR REVISION NEEDED — 8 blocking, 12 recommended, 6 nice-to-have
> **Scope signal**: XL (matches Run State #8 R1 scope class)
> **Specialists consulted**: game-designer, systems-designer, ai-programmer, level-designer, performance-analyst, godot-specialist, qa-lead, creative-director (senior synthesizer)
> **Prior verdict resolved**: First review (no prior log)
> **Created**: 2026-05-02

---

## How to use this document

This is the **contract** the fresh-session R2 revision pass applies against `design/gdd/lane-map-system.md`. The pattern mirrors `run-state-game-flow-decisions-2026-05-01.md`:

1. Fresh session opens, reads this file + `lane-map-system.md`.
2. Applies all B1–B8 blockers and R1–R12 recommendations as inline GDD edits.
3. Where a blocker requires a design decision the user must make, those decisions are flagged below as **DESIGN DECISION REQUIRED** — the fresh session presents them via `AskUserQuestion` before editing.
4. After all edits applied, fresh session runs `/design-review` again for re-verification.
5. After re-review passes (or REVISION with inline fixes only), runs `/propagate-design-change` to update `architecture.yaml`, the entity registry, and any ADR amendments.

Per project rule: **locked decisions logs are the approval; apply edits without per-section gates.**

---

## Senior synthesis (creative-director verdict)

> "MAJOR REVISION NEEDED. This GDD has the same structural disease as Run State #8 R1: a Foundation document writing checks against systems that don't exist (Wall #27, Crowd #11) while simultaneously misstating the engine reality it sits on (sync bake, unverified 4.6.2 APIs, double-counted frame budget). The four downstream consumers cannot author against this document without inheriting its corruption. Fixing acceptance criteria scope (qa-lead) without fixing the frame budget (4 specialists) and the engine API surface (godot-specialist) would just paper over a deeper problem. The Pillar 4 gap is the diagnostic that confirms it: when prose and contracts disagree, the contracts win — and these contracts don't deliver the promised player experience."

---

## Section B — BLOCKING items (must be addressed before R2 closes)

---

### B1 — Frame budget rebuild (D.7 + new architecture.yaml entry)

**Sources**: systems-designer findings 1+2; performance-analyst findings 1+2; godot-specialist findings 1+8; ai-programmer finding 3
**GDD target**: Section D, formula D.7; new entry in `docs/registry/architecture.yaml` performance_budgets section

**Findings (clustered)**:
- D.7's frame table double-counts CrowdManager sub-components (MoveAndSlide, spatial hash, velocity loop) — these are already inside ADR-0002's registered 2.0 ms budget. Real crowd cost is 2.0 ms, not 3.1 ms.
- The "5 ms slack" derives from the lower bound of a 6–8 ms engine overhead range. At 8 ms overhead, slack collapses.
- Juice (0.5 ms registered), VFX, HUD, Damage Numbers, Wave/Spawn batching are all unregistered in D.7 but compete for the same frame.
- Most damning: `bake_navigation_polygon()` is **synchronous** in Godot 4.x. The D.7 model assumes deferred-frame execution; this is wrong for sync bakes.

**Prescribed fix**:
1. Remove the MoveAndSlide and spatial hash rows from D.7's frame table; replace with a single 2.0 ms "CrowdManager (per ADR-0002)" line.
2. Use the 8 ms upper bound for engine overhead (not 6 ms) in the slack derivation.
3. Add line items to D.7 for: juice (0.5 ms), VFX particles (estimate or TBD), HUD updates (estimate or TBD), Wave/Spawn (estimate or TBD), Damage Numbers (estimate or TBD).
4. Decide whether the bake is sync or async — see B3.
5. Re-state the resulting slack honestly. If real slack is < 3 ms, the mid-wave placement mechanic (Section C Rule 8) needs throttle/thread escalation by default, not as a fallback.
6. Register a Lane/Map performance budget entry in `docs/registry/architecture.yaml`: `system: lane-map`, `budget_ms: 3` (the D.7 hard constraint limit on `t_navpoly_rebake`), with a note that the cost is **episodic** (fires only on wall mutation events).

**DESIGN DECISION REQUIRED #1**:
> "If the rebuilt frame budget shows true slack < 3 ms, do you want to (a) throttle mid-wave placement to ≤ 1 placement per N seconds (Rule 8 becomes a real cooldown lever), (b) move the bake to a Godot thread (requires confirmation that NavigationServer2D is thread-safe in 4.6.2 — see B2), or (c) disable mid-wave placement entirely at MVP (Rule 8 reverts to WAVE_PREP-only)?"
> Player experience: (a) the player can mid-wave-place but feels a cooldown; (b) the player gets seamless mid-wave placement with no perceptible cost; (c) the player can only place between waves, must commit to plans during prep.

---

### B2 — Godot 4.6.2 API verification (engine-reference cross-check)

**Sources**: godot-specialist findings 1+2+3+4+5; ai-programmer finding 1; qa-lead finding 5
**GDD target**: Section C Rule 2, Section D, AC-LM-09, AC-LM-15, AC-LM-21; possibly `docs/engine-reference/godot/modules/navigation.md`

**Findings**:
The GDD wrote APIs from LLM training data (cutoff May 2025); project is on Godot 4.6.2 (Jan 2026). Project's own `engine-reference/godot/VERSION.md` flags 4.5/4.6 as HIGH RISK.
- `bake_navigation_polygon()` sync vs async behavior in 4.6.2 — affects timeout viability + queue thread-safety.
- `get_world_2d().navigation_map` property name — wrong name = silent null RID = invisible failure.
- `NavigationServer2D.map_changed` signal name + signature — unverified.
- `NavigationServer2D.map_get_path()` (used in AC-LM-09, AC-LM-15) may be deprecated in favor of `query_path()` Parameters pattern (ADR-0002 already uses Parameters).
- `NavigationPolygon.add_outline()` method name (used implicitly in mutation API) — unverified for 4.6.2.

**Prescribed fix**:
1. Run a WebSearch / engine-reference verification pass against Godot 4.6.2 official docs for each API call above.
2. Update `docs/engine-reference/godot/modules/navigation.md` if it lacks any verified entries.
3. Update GDD Section C Rule 2 (mutation API), Section D D.6/D.7, and ACs LM-09, LM-15, LM-21 with verified API names.
4. If `map_get_path()` is deprecated, switch all AC fixtures to the `NavigationPathQueryParameters2D` + `query_path()` pattern.

---

### B3 — Bake sync/async decision + 500 ms timeout viability

**Sources**: godot-specialist finding 1; performance-analyst finding 3; folds in B1 finding 4
**GDD target**: Section C state machine, AC-LM-21, Edge Case "If a lane's bake fails", Section D D.6, Open Question #2, Open Question #7

**Finding**:
A `Timer` cannot fire during a synchronous `bake_navigation_polygon()` call — the main thread is blocked. AC-LM-21's "abort to MAIN_MENU at 500 ms" is **unimplementable as written** if the bake is sync. The 500 ms number is also unbenchmarked on real Steam Deck hardware (Open Question #7).

**Prescribed fix** (one of two paths):

**Path A — Sync bake (matches default Godot 4.x behavior)**:
- Remove the live-abort timeout mechanism from AC-LM-21.
- Replace with pre-load geometry validation: before calling `bake_navigation_polygon()`, run a synchronous outline-vertex-count check; if vertices exceed a benchmarked safe threshold, abort BEFORE the bake call.
- 500 ms ceiling becomes a **post-bake assertion only** (story is Done if measured bake time was < 500 ms on Steam Deck p95, not a runtime abort).
- Open Question #7 promoted to a **pre-Lane/Map-story gate** (no story authored against this GDD until Steam Deck p95 bake benchmark is on file).

**Path B — Async bake (`on_thread: true`)**:
- Verify `bake_navigation_polygon(on_thread: true)` is supported in 4.6.2 (B2 task).
- Make the mutation queue (Rule 11) **thread-safe** — currently no thread-safety is specified.
- AC-LM-21's 500 ms timer remains viable (timer runs on main thread; bake runs on worker thread).
- Document required thread-safety guarantees explicitly in Section C Rule 11.

**DESIGN DECISION REQUIRED #2**:
> "Path A (sync bake, replace live-abort with pre-bake validation + post-bake assertion) or Path B (async bake on a worker thread, queue becomes thread-safe)?"
> Player experience: Path A — startup time is whatever the bake takes (no abort), but bake exceeding 500ms on slow hardware ships as a recurring stutter rather than an error screen; Path B — startup is responsive (timeout fires), but mid-wave wall placement involves cross-thread coordination that may have its own 4.6.2-specific risks.

---

### B4 — Strip cross-system ACs out of this GDD

**Sources**: qa-lead findings 1+2+3+5+6; game-designer findings B2+B4; ai-programmer finding 1
**GDD target**: Section H Acceptance Criteria

**Findings**: Roughly a third of the ACs belong to other systems' GDDs.
- AC-LM-21 — tests UI rendering Lane/Map disclaims owning. **Rewrite** THEN clause to test signal+state only.
- AC-LM-23 — tests CrowdManager + Wall/Fortification behavior using stubs of GDDs that don't exist. **Delete** from this GDD; re-author in Wall/Fortification's AC list when that GDD lands.
- AC-LM-26 — tests Wall/Fortification's calling sequence (it's checking another system's contract). **Delete** from this GDD; re-author in Wall/Fortification's AC list. Add equivalent Placement & Grid AC ("Placement & Grid is the sole authority on cell-occupancy rejection") to Placement & Grid's GDD when authored.
- AC-LM-27 — one-time manual grep, not a test. **Convert** to a `forbidden_patterns` lint rule registered in `docs/registry/architecture.yaml`: "No script outside `Wall/Fortification` may call `add_wall_outline` or `remove_wall_outline`."
- AC-LM-11 — fixture impossible (NavigationServer2D singleton can't be mocked). **Replace** test fixture with a `_test_bake_suspend: bool` injectable export flag on the lane scene (test-mode only; excluded from shipping builds via `OS.has_feature("editor")` check). Defer the bake until the flag is cleared.

**Prescribed fix**: Apply each rewrite/delete/convert above. Update Story-Type Classification table to reflect new AC count (estimated 27 → 24 after deletions). Add a tracking note in this GDD's Section F (Dependencies) flagging that AC-LM-23 and AC-LM-26 must be re-authored in their owning systems' AC lists.

---

### B5 — Lock cross-system contracts explicitly

**Sources**: systems-designer findings 4+5; ai-programmer findings 5+6; game-designer finding B3; godot-specialist finding 4; level-designer finding 7
**GDD target**: Section C Rules 2, 7, 11; Section F Dependencies; Visual/Audio Section; `docs/registry/architecture.yaml` (multiple entries)

**Findings (clustered)**:

a. **`geometry_baked` ownership**: GDD says per-lane signal; `architecture.yaml` ADR-0002 entry assumes aggregated `LaneSystem.geometry_baked`. Resolution per creative-director: **aggregated form wins** (only contract that survives async bake mode and matches ADR-0002).

b. **`spawn_zone_center` is single Vector2** — 50+ simultaneous spawns stack at a single point. Resolution: add `spawn_zone_radius: float` (or `spawn_zone_polygon: PackedVector2Array`) to lane data model.

c. **Mutation queue (Rule 11) underspecified**: no FIFO, no dedup, no admission policy, no max queue depth. Add: FIFO, dedup-by-`(lane_id, cell_ref)` (overwrite or reject — see DESIGN DECISION #3), max queue depth (e.g., 8), and admission policy that returns `false` when queue full. Reconcile with Rule 7's "false ONLY on input-validation failure" — extend Rule 7 to allow `false` on queue-full as a documented secondary case.

d. **Wall destructibility is prose-only** — register as cross-system invariant in `architecture.yaml`. New entry under a new `cross_system_invariants` section (or extend `forbidden_patterns`): "LaneMap.Rule9 requires WallFortification.destructibility = true at all times."

e. **CrowdManager no-path fallback gap**: Lane/Map disclaims the no-path behavior to ADR-0002, but ADR-0002 doesn't actually own it. Either (i) add the no-path behavior spec to ADR-0002 amendment, or (ii) write it into Lane/Map's Edge Cases as a tested behavior. Recommendation: amend ADR-0002 (it's the consumer's contract).

f. **Champion sprite vs cell-size conflict**: Art Bible's 1.5× Champion-width gap rule (≥72 px) contradicts `cell_size_px = 64` (single-cell gap = 64 px). Reconcile by either (i) raising `cell_size_px` to 96 (breaks pipeline lock — high cost), (ii) lowering Art Bible Champion width to ≤43 px so 1.5× = 64.5 px (small Art Bible amendment), or (iii) explicitly stating "single-cell gaps are visually impassable; minimum legal traversal gap is 2 cells = 128 px" (adds spatial constraint). 

**DESIGN DECISION REQUIRED #3** (queue dedup policy):
> "When `add_wall_outline(lane_id=0, cell_ref=A)` is called twice during the same in-flight bake, should the queue (a) overwrite the first entry with the second (idempotent), (b) reject the second call returning `false` (caller must retry), or (c) allow both and apply both (last write wins, no semantic change)?"
> Player experience: (a) and (c) produce the same visible result (one wall at cell A); (b) means a player who clicks twice during a bake gets one placement and one no-op feedback.

**DESIGN DECISION REQUIRED #4** (Champion sprite vs cell-size):
> "Champion's heroic-scale sprite (Art Bible ≥72 px) doesn't fit a single-cell 64 px gap. Pick: (a) raise cell_size_px to 96 (breaks art pipeline lock — high cost; whole project re-tunes), (b) shrink Champion to ≤43 px (small Art Bible amendment, but visual impact), or (c) state 'single-cell gaps are visually impassable; minimum legal traversal gap is 2 cells = 128 px' (no asset changes; constrains level design)?"
> Player experience: (a) larger cells, larger lanes — entire game scales up; (b) Champion looks smaller / less heroic; (c) walls always come in pairs visually, narrow-gap clutch maneuvers don't exist.

---

### B6 — Reconcile geometry with Pillar 4 (or retract the claim)

**Sources**: level-designer findings 1+2+3+R4+7; game-designer findings B1+R1+R2; creative-director Pillar 4 verdict
**GDD target**: Section B Player Fantasy + Pillar Alignment; Section C Rules 5, 6; Section H ACs (new playtest AC needed)

**Findings (creative-director verdict)**: "The GDD claims Pillar 4 (Low Skill Floor / High Expression Ceiling) but the contracts undermine it — same diagnostic as Run State #8 R1." Contradictions:

- The 20-30° bend at 320 px lane width is too gentle to read as a chokepoint; reference TDs use 60-90°.
- Collapse Markers (visual cue "place a wall here") sit at the bend (cell row 18); legal placement zone is rows 24-30 (6 cells away). The affordance lies to the player.
- Champion sprite vs cell-size contradiction (B5f) is itself a Pillar 4 violation — heroic-scale Champion can't fit single-cell gaps.
- "HUD-free chokepoint readability" is asserted in prose but **not in any AC**.
- "The run waits for you" (Pillar 4 from Run State #8) is silently violated by mid-wave wall placement (Rule 8) — the very feature this GDD adds.

**Prescribed fix** (one of two paths):

**Path A — Make the geometry deliver Pillar 4**:
1. Raise `bend_angle_deg` lower bound to 35° (or 45°+); update Tuning Knobs safe range and AC-LM-05 vertex angle band.
2. Move the buildable strip to surround the bend (40-65% lane depth) — OR — move the Collapse Markers to the strip's front edge so they point at legal placement zones.
3. Resolve the Champion sprite vs cell-size conflict (DESIGN DECISION #4 in B5f).
4. Add a new AC: "Given a first-time player (never seen the game) with no verbal instruction, observe whether they place their first wall within 2 cells of the bend chokepoint. Pass criterion: ≥70% of N=10 cold playtesters place correctly." Tag as Playtest, ADVISORY.
5. Section C Rule 8 explicitly acknowledges the Pillar 4 trade-off: "Mid-wave placement is intentionally a time-pressured action — it does not honor the 'run waits for you' promise. That promise is scoped to WAVE_PREP and PAUSE." This frames the trade-off rather than hiding it.

**Path B — Retract Pillar 4 as primary**:
- Section B header: change "Implements Pillar 4 primary, Pillar 2 supporting" to "Implements Pillar 2 primary; pillar-neutral on Pillar 4 (HUD-free readability is a goal, not a guarantee)."
- Less honest path; doesn't fix the actual readability problem, just stops claiming it.

**DESIGN DECISION REQUIRED #5**:
> "Path A — fix the geometry so it delivers Pillar 4 (sharper bend, strip at the bend, champion sprite reconciled, playtest AC added)? Or Path B — retract Pillar 4 as primary and accept that the 'Last Wall' fantasy is Pillar 2-driven only?"
> Player experience: Path A — a brand-new player can read the field and place walls correctly without instruction (the game's onboarding promise lands); Path B — Lane/Map stops claiming HUD-free readability; the tutorial system has to carry the readability load instead.

---

### B7 — Retract or rewrite the Pillar 3 alignment claim

**Sources**: game-designer finding B1; level-designer finding F2 (cluster)
**GDD target**: Section B header metadata; Section B "Pillar alignment" paragraph; Tuning Knobs `total_buildable_cells_mvp` "If too low" entry

**Finding**: The header and Section B claim "Indirect support for Pillar 3 (build variety via spatial constraint on placement)." A small constrained strip *reduces* placement variety, it does not generate it. Pillar 3 ("Build Variety Beats Build Depth") is about discovering different *combinations* each run — that comes from cards (the actual driver), not from the strip's geometry.

**Prescribed fix** (one of two — pick A unless argument is found):

**Path A — Retract** (recommended):
- Header: remove "Indirect support for Pillar 3" line.
- Section B "Pillar alignment": remove the Pillar 3 paragraph or replace with "Pillar 3 is owned by Card #21 and Build/Modifier #23. Lane/Map is pillar-neutral on build variety — its small-strip design constrains placement choices but does not generate variety."
- Tuning Knobs `total_buildable_cells_mvp`: rewrite "If too low: no placement experimentation; build-variety Pillar 3 fails" to "If too low: placement choice collapses to single optimum; players have no spatial decision to make."

**Path B — Articulate** (only if a real mechanism exists):
- Add a paragraph explaining the specific mechanism that turns "fewer cells" into "more variety" (e.g., "constraint forces harder choices between placement types, which produces more distinctive builds"). Currently no such argument is in the GDD.

**DESIGN DECISION REQUIRED #6**:
> "Path A — retract the Pillar 3 alignment claim entirely (Lane/Map becomes pillar-neutral on build variety)? Or Path B — articulate the specific mechanism turning constraint into variety (requires real argument)?"
> Player experience: Path A — no change to player experience; just truth in documentation; Path B — same player experience, but the GDD now claims something it must defend in playtest.

---

### B8 — Lock the "mid-wave clutch tool" intent in a real lever

**Sources**: game-designer finding B2
**GDD target**: Section C Rule 8; Section H Acceptance Criteria; cross-reference into Wall/Fortification GDD when authored

**Finding**: Rule 8 names `wall_mid_wave_cost_multiplier` and `wall_mid_wave_cooldown_seconds` as the levers that enforce "clutch tool, not optimal strategy." Both are owned by Wall/Fortification GDD which doesn't exist. No AC tests "mid-wave is more expensive than prep-phase."

**Prescribed fix**:
1. Promote both knobs from "Referenced knobs owned by other systems" footnote to a **bidirectional invariant** in Section F Dependencies (analogous to wall-destructibility load-bearing assumption).
2. Register the invariant in `architecture.yaml`: "Wall/Fortification GDD MUST include `wall_mid_wave_cost_multiplier` (default ≥ 1.5×) and `wall_mid_wave_cooldown_seconds` (default ≥ 5s) with non-trivial values."
3. Add a new AC (after AC-LM-22): "Given Wall/Fortification's GDD has been authored, verify that calling `add_wall_outline` during `WAVE_ACTIVE` incurs a resource cost ≥ 1.5× the equivalent call during `WAVE_PREP`." Tag as Integration, ADVISORY (depends on Wall/Fortification existing).

---

## Section C — RECOMMENDED items

R1 — D.5 safe range upper bound (24) hits the 3-row hard cap exactly with zero margin. **Fix**: lower upper bound to 22. Add explicit guard for non-integer `cells_per_lane` (V1 inputs like `total=20, lane_count=3`): assert `total_buildable_cells % lane_count == 0` at scene authoring. *[systems-designer 3]*

R2 — D.4 path-length formula vs `NavigationServer2D` actual path may diverge by 10-15% (agents hug outer wall of bend). **Fix**: tighten AC-LM-15 ±2% tolerance after empirical measurement, OR mark D.4 as planning-time approximation only and require Wave/Spawn to measure actual path length at runtime. *[game-designer R3, upgraded to BLOCKING-adjacent by creative-director]*

R3 — AC-LM-23 deletion (covered in B4); Wall/Fortification AC list takes ownership when that GDD lands. *[ai-programmer 2, qa-lead 1, game-designer B4]*

R4 — AC-LM-17/AC-LM-18 reclassified Integration+Performance ADVISORY in CI. **Fix**: pinned hardware spec in `technical-preferences.md` (e.g., "Steam Deck OLED + 2019-class laptop named explicitly"); manual benchmark gate, not CI BLOCKING. Add measurement methodology section to AC: 300-frame minimum, profiler OFF during measurement, `Time.get_ticks_usec()` instrumentation around bake call. *[qa-lead 4]*

R5 — Rule 11 mutation queue specification (folded into B5c).

R6 — Section F dependency hierarchy: ADR-0003 (language routing) reclassified from "soft" to "hard implementation-binding". **Fix**: Section F dependency table row for ADR-0003: change "soft" to "hard"; add rationale: "Lane/Map's GDScript→C# `geometry_baked` direction is already an undocumented contract." *[systems-designer 7]*

R7 — Bend-vs-strip 6-cell affordance gap (folded into B6 Path A).

R8 — Add `inter_lane_gap_cells` and `max_total_map_width_cells` to lane/map data model. **Fix**: Section C Rule 1 (map data table) adds `inter_lane_gap_cells: int` (scene-authoring constant); Tuning Knobs adds `max_total_map_width_cells` with safe range tied to 1280 px Steam Deck viewport (max = 20 cells = 1280 px). *[level-designer 7+8]*

R9 — Mood-state tile-variant trigger needs a named owner. **Fix**: Visual/Audio section mood-state table — append a "Trigger owner" column. Either Lane/Map subscribes to `state_changed` and swaps tiles internally (preferred — keeps presentation atomic), or designate a Presentation system to own this. Recommend: Lane/Map subscribes to `state_changed` for internal tile-variant swaps; document in Section C Interactions table. *[game-designer R4]*

R10 — AC-LM-21 THEN clause rewrite (folded into B4).

R11 — Cross-rule failure interaction: queue disposal during bake-in-flight run abort. **Fix**: add AC-LM-28: "GIVEN a mutation is queued while bake is in flight AND the run is aborted before the bake completes, WHEN the lane scene is freed, THEN no crash occurs, no deferred queue consumer fires on the freed node, and no error is logged." *[qa-lead 8]*

R12 — AC-LM-05 kink-detection method (engine-stable). **Fix**: rewrite test fixture from `NavigationPolygon` vertex extraction to `NavigationServer2D.map_get_path()` direction-change measurement at 55-65% path length. *[qa-lead 9]*

---

## Section D — Specialist disagreements (creative-director arbitrated)

1. **AC-LM-23 severity**: qa-lead said wrong owner; ai-programmer said wrong tolerance; game-designer said no stub exists. **Resolution**: all three correct + compound. Single fix: delete from this GDD and re-author in Wall/Fortification's AC list when that GDD lands. (Applied in B4.)

2. **`geometry_baked` shape**: GDD says per-lane; `architecture.yaml` ADR-0002 entry assumes aggregated `LaneSystem.geometry_baked`. **Resolution**: aggregated form wins (only contract that survives async bake mode and matches the existing ADR). Fix the GDD, not the ADR. (Applied in B5a.)

3. **Bake sync vs async**: godot-specialist says sync in 4.x, timeout impossible; performance-analyst budgets as if abortable. **Resolution**: godot-specialist wins on facts. Either drop abort-and-retry OR specify `on_thread:true` AND make the queue thread-safe. (DESIGN DECISION #2 in B3.)

---

## Section E — Severity adjustments (creative-director vs raw specialist findings)

**Upgraded to BLOCKING (folded into B-series above)**:
- D.4 path-length divergence (R2 above is the documentation; the substance is in B5/B6 cross-references)
- Bend-vs-strip 6-cell affordance gap (folded into B6 Path A)

**Downgraded from BLOCKING (now RECOMMENDED or absorbed)**:
- AC-LM-23 stub dependency — sequencing issue, not design defect. Reframed to "delete and re-author in Wall/Fortification" (B4).
- AC-LM-17/18 CI non-determinism — story-execution concern, advisory tier (R4).
- Mutation queue zombie-in-future-obstacle — folds into FIFO/admission policy fix (B5c).

**Kept as BLOCKING but reframed**:
- 500 ms RUN_LOADING ceiling — promoted Open Question #7 to a hard pre-consumer-authoring gate (B3).

---

## Section F — Pillar 4 verdict (creative-director)

> "The GDD claims Pillar 4 (Low Skill Floor / High Expression Ceiling) but the contracts undermine it — same diagnostic as Run State #8 R1."

What the prose promises: lanes are legible, chokepoints are obvious, the player can see at a glance where to defend. HUD-free chokepoint readability is named as a design intent.

What the contracts deliver:
- The bend is too gentle to read as a chokepoint (level-designer F1).
- Collapse Markers point at a chokepoint 6 cells away from where walls are legal (level-designer R4).
- Champion sprite (Art Bible ≥72 px) doesn't fit 64 px cell with 1.5× gap rule (level-designer F7).
- HUD-free chokepoint readability is asserted but **not in any AC** (game-designer R1).
- "The run waits for you" is violated by mid-wave wall placement (game-designer R2).

**Resolution**: B6 Path A — make the geometry deliver Pillar 4. (DESIGN DECISION #5.)

---

## Section G — Open follow-ups (post-R2, not blocking R2 close)

- **ADR-0001 amendment** (Open Question #2): the 500 ms `RUN_LOADING` timeout-and-abort behavior. Apply during `/propagate-design-change` after R2 closes. Note: B3's resolution may change the shape of this amendment (sync path = post-bake assertion, not abort; async path = abort survives).
- **ADR-0002 amendment** (B5e): CrowdManager no-path fallback specification. Apply during `/propagate-design-change` after R2 closes.
- **ADR-0002 amendment** (potentially): `_pathCache` key scheme for V1 convergent/branching lane layouts (nice-to-have N5).
- **`architecture.yaml` updates**: register `system: lane-map` performance budget (B1 step 6); register cross-system invariants for wall destructibility (B5d) and mid-wave cost (B8); register `forbidden_patterns` lint for `add_wall_outline`/`remove_wall_outline` (B4); update `geometry_baked` interface contract entry to aggregated `LaneSystem.geometry_baked` (B5a).
- **Steam Deck p95 bake benchmark** (Open Question #7): pre-Lane/Map-story gate. No story authored against this GDD until benchmark on file.
- **Paper prototype** (Open Question #4): unchanged from prior session — must run before any Lane/Map story.

---

## Section H — Instructions for the fresh session

1. Read this file in full.
2. Read `design/gdd/lane-map-system.md` in full.
3. Read `docs/registry/architecture.yaml` (especially the entries that B1, B5, B8 need to update).
4. Resolve the **6 DESIGN DECISIONS REQUIRED** by presenting them in a single multi-tab `AskUserQuestion` widget. Do not interrupt mid-revision for each individually (per project rule: "locked decisions logs are the approval; apply edits without per-section gates"). The 6 decisions are:
   - DD#1 (B1): If real slack < 3 ms, mid-wave throttle/thread/disable?
   - DD#2 (B3): Sync bake (Path A) or async bake on worker thread (Path B)?
   - DD#3 (B5c): Queue dedup policy — overwrite, reject, or last-write-wins?
   - DD#4 (B5f): Champion sprite vs cell-size — raise cell to 96, shrink champion, or 2-cell minimum gap rule?
   - DD#5 (B6): Path A (fix geometry to deliver Pillar 4) or Path B (retract Pillar 4 claim)?
   - DD#6 (B7): Retract Pillar 3 claim (Path A) or articulate mechanism (Path B)?
5. After decisions are locked, apply all B1–B8 fixes inline to `lane-map-system.md`.
6. Apply all R1–R12 fixes inline.
7. Update `docs/registry/architecture.yaml` per Section G.
8. Run `/design-review design/gdd/lane-map-system.md` again for re-verification. (Re-review will be the second entry in `design/gdd/reviews/lane-map-system-review-log.md`.)
9. After re-review passes (or REVISION with inline fixes only), run `/propagate-design-change` to update ADRs 0001 and 0002 per Section G.

**Estimated R2 effort**: 1 long fresh session (the Run State R2 was a single fresh session; Lane/Map's scope is comparable).

---

> **Authored**: 2026-05-02 by `/design-review` (full mode, 7 specialists + creative-director).
> **Apply in fresh session**. Do not edit this file during R2 application — append a "Section I — R2 application notes" section at the bottom if needed.
