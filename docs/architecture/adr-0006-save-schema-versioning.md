# ADR-0006: Save Schema & Versioning

## Status
Proposed (revised 2026-05-01 — `run_snapshot.save` domain removed per `design/gdd/run-state-game-flow.md` R3)

## Date
2026-04-28 (original) / 2026-05-01 (R3 cleanup applied — suspend-save mechanism removed)

## Revision History

- **Original (2026-04-28)**: Authored via `/architecture-decision`. Validated by `/architecture-review` 2026-04-28 (PASS).
- **2026-05-01 (R3 cleanup)**: GDD revision R3 removed the suspend-save mechanism entirely (reversed R2's D6/D7/D8 decisions). The `run_snapshot.save` persistent domain is therefore DELETED from this ADR — it had no implementation yet, and per R3 the run is a single session with no mid-run resume. Removed: `run_snapshot.save` row from File Layout; `"run_snapshot": 1` from `CURRENT_SCHEMA_VERSIONS`; the planned v1→v2 migration (which was driven by R2 T20-T22 — also deleted in R3); ADR-0001 dependency phrasing about "persisting the snapshot Dictionary shape." The 8 persistent domains drop to 7 (settings, meta_progression, meta_currency, leaderboard, achievements + the soft Save/Load #2 consumer; Test Harness fixture loading still uses SaveManager). All other ADR-0006 contracts (envelope format, atomicity rules, `.bak` chain, `FileAccess.store_*` return-checking, Windows remove-before-rename) are unaffected and remain authoritative.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Persistence |
| **Knowledge Risk** | MEDIUM — `FileAccess.store_*` return type changed in 4.4 (was void, now bool); `duplicate_deep()` added in 4.5. No persistence module reference doc exists; verified from `breaking-changes.md` and `deprecated-apis.md` only. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_string` returning bool (4.4) — load-bearing; the bool MUST be checked or saves silently truncate. `JSON.stringify` / `JSON.parse_string` are pre-cutoff and unchanged. |
| **Verification Required** | (1) Unit test: write a save file, simulate disk-full / readonly target, confirm `FileAccess.store_string` returns false and SaveManager propagates the failure rather than reporting success. (2) Integration test: corrupt a save file by hand, confirm load falls back to `.bak`, then to defaults, with the warning surfaced in-game. (3) Windows-specific test: mock `DirAccess.rename_absolute` returning `ERR_ALREADY_EXISTS`, assert SaveManager removes-then-renames and the main file ends up updated (Risk 8). (4) Robustness test: load a save file containing valid JSON of a non-Dictionary root (bare array, `null`), confirm fallback chain triggers without crash (Risk 9). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Run State / Game Flow) — must be Accepted. *(R3 update 2026-05-01)* The dependency is now LIGHT — ADR-0006 no longer persists Run State's snapshot Dictionary; per GDD R3 the run is a single session with no mid-run save. ADR-0001 still defines the canonical save-relevant rules (enum stability, JSON-serializable shape) that this ADR generalises across all persistent domains. |
| **Enables** | GDD #2 (Save/Load — soft consumer post-R3, persists meta-currency/achievements/unlocks/settings only), GDD #37 (Meta-Currency), GDD #38 (Meta-Progression), GDD #39 (Per-Champion Mastery), GDD #41 (Leaderboard), GDD #42 (Settings), GDD #44 (Achievement), GDD #45 (Test Harness fixture loading). |
| **Blocks** | GDD #2 (Save/Load) cannot be authored until this is Accepted. GDDs that produce persistent data shapes (#37–#42, #44) should not data-lock until this Accepts. |
| **Ordering Note** | Author and Accept BEFORE GDD #2. Can be authored in parallel with ADR-0005 / ADR-0007 (which live inside Champion / Build-Modifier GDDs respectively). ADR-0001 → ADR-0006 chain is now soft after R3 (no run-snapshot persistence) but retained for the enum-stability + JSON-serializable rules ADR-0001 codifies. |

## Context

### Problem Statement

Seven systems will write user data to disk over the project's life *(R3 reduction — was 8; the Run State snapshot domain was removed when GDD R3 deleted the suspend-save mechanism)*: Save/Load (#2 VS — now a soft consumer of Run State), Settings (#42 VS), Meta-Currency (#37 Alpha), Meta-Progression (#38 Alpha), Per-Champion Mastery (#39 Alpha), Leaderboard (#41 Alpha), Achievement (#44 Full Vision), and Test Harness fixture loading (#45 MVP). Without a shared format, versioning rule, migration policy, and corruption-recovery rule, each system would re-decide these — yielding seven incompatible serializers, seven migration backlogs, and seven independent ways to corrupt a save.

ADR-0001 originally handed off the **on-disk policy** for its run-snapshot Dictionary to this ADR. *(R3 update 2026-05-01)* GDD R3 removed the suspend-save mechanism entirely — the run is now a single session with no mid-run resume — so the run-snapshot Dictionary is **runtime-only**, never persisted to disk. ADR-0001 still locks the in-memory shape (used by Test Harness for assertions and by `state_snapshot_ready` consumers), but no on-disk policy is required for it. The concept's Technical Risks section still flags save corruption as a retention-killer ("Corrupted saves kill retention. Invest in save versioning and recovery early." — `design/gdd/game-concept.md` line 325) — making this ADR an MVP-locked forward contract even though Save/Load (#2) implements at VS for lifetime-persistence (meta-currency, achievements, unlocks, settings) only.

### Constraints

- **Inherited from ADR-0001 (general format rules)**: any persistent domain's Dictionary MUST be all primitive-typed and JSON-serializable. The first key is `schema_version`. *(R3 2026-05-01: Run State's snapshot Dictionary itself is no longer one of the persistent domains — it is runtime-only. The format rules still apply to the 7 remaining persistent domains.)*
- **Inherited from ADR-0001 forbidden_pattern `inserting_game_state_enum_values` (generalised post-R3)**: ADR-0001's GameState enum is no longer one of the persisted-enum cases (its int value was previously persisted via `run_snapshot.save`, but R3 removed that domain). The append-only-evolution principle nevertheless **generalises here** as a project-wide rule: ANY enum whose int value is persisted (e.g. `RunOutcome` in leaderboard records, future achievement-category enums) must follow append-only evolution; insertion is a schema-breaking change requiring a `schema_version` bump.
- **Engine fact (Godot 4.4 breaking change)**: `FileAccess.store_string` (and all `store_*`) methods now return `bool`. The save-write contract MUST check return values; ignored returns are how saves silently truncate.
- **Engine fact (Windows behavior)**: `DirAccess.rename_absolute` fails when the destination file already exists on Windows. The save flow must remove the main file (gated on `file_exists`) before renaming the `.tmp` over it. The project's primary platform is Windows; ignoring this rule means every save after the first silently fails on the target platform.
- **Concept Tech Risks line 325**: corrupted saves kill retention; mitigation requires backup files and recovery, not just defensive coding.
- **MVP boundary**: MVP has zero runtime saves (no meta-progression, no settings save). This ADR is a forward contract, not an MVP feature — MVP only enforces the format rules at the Test Harness level (deterministic fixture loading per System 45).
- **Solo first-time dev**: migration code must be bounded to keep the project finishable. Migration window of N-2 (current + 2 prior versions) is the upper limit.
- **Local-only**: No cloud save sync, no encryption, no anti-cheat (single-player + one-time-purchase monetization).

### Requirements

- All persistent user data MUST live under `user://` (Godot's per-user persistent path).
- All save files (except `settings.cfg`) MUST be JSON text encoded as UTF-8.
- Each save file MUST carry a top-level `schema_version: int` field. Loader reads this field BEFORE attempting to populate domain data.
- Each persistent domain MUST have its own file with its own `schema_version` (split-file layout).
- Loader MUST handle `schema_version`, `schema_version - 1`, and `schema_version - 2`. Older versions MUST surface a friendly error and offer a fresh-start dialog.
- Every successful save MUST first copy the prior file to a `.bak` sibling. Load failure on the main file MUST attempt the `.bak` before falling back to defaults.
- Saves MUST be atomic: write to `<file>.tmp`, then rename to `<file>` (and ALL `FileAccess.store_*` return values MUST be checked, AND main file MUST be removed before rename on Windows).
- Any enum whose int value is persisted MUST evolve append-only.

## Decision

**Save data is partitioned by domain into separate JSON files under `user://`. Each file is independently versioned via a top-level `schema_version: int`. The loader supports the current version and the two prior versions (N-2). On load failure, the loader falls back to a `.bak` sibling, then to fresh defaults, surfacing a non-blocking warning in-game. Every save is written atomically (write-temp-then-rename, with main-file removal before rename to satisfy Windows semantics) and ALL `FileAccess.store_*` return values are checked.**

### File Layout (under `user://`)

| Path | Purpose | Owning System | First Author Milestone |
|------|---------|---------------|------------------------|
| `user://settings.cfg` | Keybinds, audio levels, video, accessibility flags | #42 Settings | VS |
| `user://meta_progression.save` | Unlocked Champions, unlocked card pool, Champion mastery progress | #38 Meta-Progression, #39 Mastery | Alpha |
| `user://meta_currency.save` | Persistent currency totals | #37 Meta-Currency | Alpha |
| `user://leaderboard.save` | Local high-score entries | #41 Leaderboard | Alpha |
| `user://achievements.save` | Unlocked achievement IDs | #44 Achievement | Full Vision |
| ~~`user://run_snapshot.save`~~ | **DELETED 2026-05-01 (GDD R3).** Was: active run state (mid-run resume). The suspend-save mechanism was removed in GDD R3 — the run is a single session. Run State's `_build_snapshot()` Dictionary remains runtime-only (used by Test Harness assertion + `state_snapshot_ready` signal); it is never written to disk. | — | — |
| `<file>.bak` (per file above) | Backup created before each save | (auto-managed by SaveManager) | — |
| `<file>.tmp` (per file above) | Transient pre-rename target | (auto-managed by SaveManager; cleaned on success) | — |
| `user://corrupted_<domain>_<unix>.save` | Forensic preservation of corrupted file | (auto-managed) | — |

`settings.cfg` uses Godot's `ConfigFile` (INI-like) per platform convention. All other domains use JSON via `FileAccess`.

### File Format Specification (JSON files)

Each JSON file follows this canonical envelope:

```json
{
  "schema_version": 1,
  "saved_at_unix": 1730000000,
  "engine_version": "4.6.2",
  "data": { /* domain-specific shape, owned by the system GDD */ }
}
```

- `schema_version` (int, REQUIRED): The on-disk version of THIS file's `data` shape. Independent of other files. The loader reads `schema_version` by key name, not position. Godot 4.6.2's `JSON.stringify` does not guarantee key order; the "envelope" structure shown above is a documentation convention for human readers, not a wire-format contract.
- `saved_at_unix` (int, REQUIRED): Unix timestamp at write. Diagnostic only; not load-bearing.
- `engine_version` (string, REQUIRED): The Godot version that wrote this file. Diagnostic.
- `data` (object, REQUIRED): The domain-specific payload. Shape owned by the corresponding system GDD.

*(R3 2026-05-01: This paragraph used to describe the `run_snapshot.save` file's `data` field as the Dictionary defined by ADR-0001. That file is DELETED — the suspend-save mechanism was removed in GDD R3, so Run State's snapshot Dictionary is now runtime-only. The general envelope rule still applies to the 7 remaining persistent domains.)*

### Versioning Rules

- `schema_version = 1` at first ship of each file.
- A schema change is **any of**:
  1. A key added to `data` (or any nested object).
  2. A key removed from `data` (or any nested object).
  3. A key's value type changed.
  4. An enum value inserted (vs. appended) — breaks all persisted int-encoded enum references.
  5. The semantic meaning of a value changed (e.g., currency was per-account, now per-Champion).
- Any schema change requires:
  - Bumping the domain's entry in `SaveManager.CURRENT_SCHEMA_VERSIONS` by +1.
  - Adding a migration function `migrate_v<from>_to_v<from+1>(old: Dictionary) -> Dictionary` to `src/persistence/migrations/<domain>.gd`.
  - Adding a fixture file `tests/fixtures/save/<domain>_v<from>.json`.
  - Adding a unit test asserting load round-trip from v(from) → v(from+1).

### Migration Window

- Loader handles `schema_version`, `schema_version - 1`, `schema_version - 2`. (Current + two prior — three total.)
- File with `schema_version > current` → friendly error: "This save is from a newer version of the game. Update to load it." Do NOT attempt to load.
- File with `schema_version < current - 2` → friendly error: "This save is from a much older version. Start fresh, or visit [user save folder] to recover by hand." Offer fresh-start dialog.
- Migration runs eagerly at load, chained: v(N-2) → v(N-1) → v(N). Migrated data is NOT written back to disk on load — it is written back on the next save (preserving the original until then for forensic recovery).

### Corruption Recovery (Fallback Chain)

**On load:**
1. Attempt main file. If JSON parses to a Dictionary AND `schema_version` is in window AND migration succeeds → return migrated data. Done.
2. On any failure (parse error, non-Dictionary root, version-out-of-window, migration throws): copy main file to `user://corrupted_<domain>_<unix>.save` for forensic preservation, then try `<file>.bak`.
3. If `.bak` succeeds: return migrated data. Surface in-game: `load_recovered_from_backup` signal. UI shows "Save data recovered from backup. Some recent progress may be missing."
4. If `.bak` also fails: copy `.bak` to `user://corrupted_<domain>_<unix>.bak.save`, fall back to defaults. Surface: `load_fell_back_to_defaults` signal. UI shows "Save data could not be loaded. Started fresh. Previous file preserved at [path]."

**On save:**
1. If main file exists, copy it to `<file>.bak` (overwriting any prior `.bak`).
2. Write new content to `<file>.tmp`.
3. Check ALL `FileAccess.store_*` return values. ANY false → abort, surface `save_failed` signal, leave `<file>.bak` and `<file>` untouched. Do not rename `.tmp` (orphaned `.tmp` is truncated by the next save's `FileAccess.open(..., WRITE)`).
4. **Before** renaming `.tmp` to `<file>`: if `<file>` exists, call `DirAccess.remove_absolute(<file>)`. This is required for Windows compatibility (`DirAccess.rename_absolute` fails on Windows when destination exists). The `.bak` already holds the prior content, so removing `<file>` before rename is safe.
5. Rename `<file>.tmp` to `<file>` via `DirAccess.rename_absolute` (atomic replace once the destination is absent).

### Key Interfaces

```gdscript
# src/persistence/save_manager.gd  (autoload)
# Single entry point for ALL persistent domains.

class_name SaveManager extends Node

const CURRENT_SCHEMA_VERSIONS: Dictionary = {
    "settings":         1,
    "meta_progression": 1,
    "meta_currency":    1,
    "leaderboard":      1,
    "achievements":     1,
    # "run_snapshot": REMOVED 2026-05-01 (GDD R3) — suspend-save mechanism deleted;
    # the run is a single session with no mid-run resume. Run State's snapshot
    # Dictionary is runtime-only; it does not need a persistence schema.
}

const SUPPORTED_VERSION_DEPTH: int = 2  # N-2 window

# === API ===

# Returns true on full success; false on any FileAccess failure.
# Callers do NOT manage atomicity, .bak rotation, store_* return checks,
# or the Windows remove-before-rename step.
func save_domain(domain: StringName, data: Dictionary) -> bool

# Returns LoadResult (never throws). Domains check `status` and react.
func load_domain(domain: StringName) -> LoadResult

# === Signals ===
signal save_failed(domain: StringName, reason: String)
signal load_recovered_from_backup(domain: StringName)
signal load_fell_back_to_defaults(domain: StringName, preserved_path: String)
signal load_too_old(domain: StringName, file_version: int, supported_min: int)
signal load_too_new(domain: StringName, file_version: int)
```

```gdscript
# src/persistence/load_result.gd
class_name LoadResult extends RefCounted

enum Status {
    OK,
    RECOVERED_FROM_BACKUP,
    FELL_BACK_TO_DEFAULTS,
    REFUSED_TOO_OLD,
    REFUSED_TOO_NEW,
    REFUSED_OTHER,
}

var status: Status
var data: Dictionary
var migrated_from_version: int   # 0 if no migration ran
var preserved_corrupt_path: String  # "" if no preservation
```

```gdscript
# src/persistence/migrations/<domain>.gd
# Pure functions. No side effects. Deterministic.

static func migrate_v1_to_v2(old: Dictionary) -> Dictionary:
    var new := old.duplicate(true)
    # ... transform ...
    return new
```

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      System / GDD Layer                         │
│  Settings  Meta-Currency  Meta-Progression  Mastery  Leaderboard│
│  Achievement   Save/Load (run snapshot consumer)   Test Harness │
└──────────────────────┬──────────────────────────────────────────┘
                       │ save_domain(name, data) / load_domain(name)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│              SaveManager (autoload, GDScript)                   │
│  - Atomicity: temp→remove-main→rename                           │
│  - .bak rotation                                                │
│  - FileAccess.store_* return-value checks (4.4+ engine fact)    │
│  - Migration runner (chains v(N-2) → v(N-1) → v(N))             │
│  - Fallback chain (main → .bak → defaults)                      │
│  - schema_version envelope wrap/unwrap                          │
│  - Non-Dictionary parse-result guard                            │
└──────┬─────────────────────────────────────┬────────────────────┘
       │                                     │
       ▼                                     ▼
┌──────────────┐                ┌────────────────────────────────┐
│  ConfigFile  │                │  FileAccess + JSON.stringify   │
│  (settings)  │                │  (all other domains)           │
└──────┬───────┘                └────────────┬───────────────────┘
       │                                     │
       ▼                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    user:// (per-user dir)                       │
│ settings.cfg  meta_progression.save  meta_currency.save         │
│ leaderboard.save  achievements.save  run_snapshot.save          │
│ <each>.bak  <corrupted_*>.save  <*.tmp> (transient)             │
└─────────────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: Single profile file (one save.json)
- **Description**: All domains nested under one root JSON; single `schema_version`; single atomic write per save.
- **Pros**: Simpler code; one file to back up; trivial atomicity; easy to reason about.
- **Cons**: Any corruption wipes the entire profile. Settings migration coupled to meta migration. Every save rewrites everything. Schema-version churn is high (any domain change bumps the global version, forcing all migrations to be authored together).
- **Rejection Reason**: Concept Tech Risks line 325: "corrupted saves kill retention." A single corrupt byte shouldn't cost 100h of meta-progression. Domain-split corruption is recoverable per-domain; combined corruption is not. Cost of complexity (separate files + `.bak` each) is bounded; cost of total-profile-wipe is unbounded.

### Alternative 2: Variant binary via `FileAccess.store_var` / `get_var`
- **Description**: Use Godot's native Variant binary serializer. Smaller files; faster reads/writes; no JSON parsing.
- **Pros**: Fast, compact, supports Vector2/Color/Resource refs without manual conversion. No quoting/escaping bugs.
- **Cons**: Opaque — corrupt bytes are unrecoverable; dev cannot inspect a save by opening it; cannot fix "off-by-one in a single field" by hand. Variant binary format itself can change between Godot versions (another schema dimension). Concept's "invest in versioning and recovery early" is much harder when the file format isn't human-readable.
- **Rejection Reason**: ADR-0001 already declared the snapshot "JSON-serializable" — choosing Variant binary contradicts that. Performance cost of JSON is irrelevant (saves run on PREP boundaries, ~1 per ~3 minutes; not hot-path). Dev-time inspectability and corruption-recovery transparency are worth more than the few KB and few microseconds saved.

### Alternative 3: Godot Resource (.tres / .res) via `ResourceSaver` / `ResourceLoader`
- **Description**: Define each persistent domain as a `Resource` subclass with `@export` properties; save/load via `ResourceSaver.save()` / `ResourceLoader.load()`.
- **Pros**: Type-safe via `@export`; editor inspector "for free"; schema couples to GDScript class definitions (renaming a property surfaces immediately). `duplicate_deep()` (Godot 4.5+) handles nested resource trees.
- **Cons**: Resources are designed for editor-authored assets, not user save data. Loading a user-modified `.tres` invokes Godot's resource loader, which expects type-correct `script:` references and `class_name`-resolved fields — a mismatched class_name (different platform build, post-rename) refuses to load. The format is not stable across class refactors. Migration becomes fighting the resource loader rather than transforming a Dictionary.
- **Rejection Reason**: Resources are the wrong abstraction for user-mutable persistent state. They're great for read-only assets the editor authors (Champion definitions, card data, level configs) — but those ship inside the project under `res://`, not under `user://`, and are NOT in this ADR's scope.

## Consequences

### Positive
- Single contract for all 8 persistent systems. No system re-invents serialization, atomicity, or migration logic.
- Domain-isolated corruption blast radius. A corrupted leaderboard does not lose meta-progression.
- Concept Tech Risk directly mitigated: "Corrupted saves kill retention" → backup-file fallback chain + warning UX.
- Bounded migration burden. N-2 window means at any time, only 3 versions of any domain need to load.
- Dev-friendly debug. JSON files are human-readable; corrupted-file forensics is opening the file in a text editor.
- Engine-fact compliance enforced in one place. `FileAccess.store_*` return-value checks AND the Windows remove-before-rename step live in `SaveManager`, not duplicated across 8 systems.
- ADR-0001 compatibility preserved. The run snapshot's `schema_version` IS the run_snapshot.save file's version — no double-versioning, no contract drift.

### Negative
- More files on disk (8+, plus `.bak` each). Trivial cost on PC; non-issue on Steam/itch target.
- Per-domain migration discipline required. Each schema change = +1 migration function + +1 unit test. Forgetting one is a corruption vector.
- JSON cost of stringifying Vector2 / Color. Domains using Godot-native types must serialize them as primitive arrays (e.g., `[x, y]`) and document the convention in their GDD.
- Migration testing scales with versions. At schema_version = 5, the test harness must load v3, v4, and v5 fixtures.

### Risks

1. **Risk: Loader silently downgrades a load failure to "fresh defaults" without surfacing the warning, and players think they lost progress to a bug.**
   - **Mitigation**: `load_fell_back_to_defaults` is a HARD UI contract — meta-progression UI MUST subscribe and render a non-blocking warning. Acceptance test: simulate corrupt save, assert signal fires, assert warning UI renders. Warning includes `preserved_corrupt_path` for power-user recovery.

2. **Risk: A domain forgets to bump `schema_version` after changing its `data` shape.**
   - **Mitigation**: `SaveManager.CURRENT_SCHEMA_VERSIONS` is a single source of truth domains read. Code review enforcement; lint-style check in `/story-done` scans for changes to a domain's data shape WITHOUT a corresponding bump. Migration unit-test failure is the runtime backstop.

3. **Risk: An enum's int value is inserted (not appended), corrupting all persisted save files using that enum.**
   - **Mitigation**: ADR-0001's `inserting_game_state_enum_values` forbidden_pattern generalizes here. A new generalized forbidden_pattern, `inserting_persisted_enum_values`, is registered alongside this ADR covering ALL enums declared in code paths that read or write save data. Per-system unit tests assert enum value stability for any enum used in `data`.

4. **Risk: `FileAccess.store_*` returns false silently in a build that doesn't run unit tests.**
   - **Mitigation**: Verification test in Migration Plan §1: simulate readonly target, assert SaveManager returns false AND `save_failed` signal fires AND main file untouched (since we wrote `.tmp` first). Required to pass before MVP.

5. **Risk: Migration v3→v4 throws an unhandled exception, leaving the user with a save that won't load AND no UI explanation.**
   - **Mitigation**: SaveManager wraps each migration call in error capture. On migration throw, load result is `REFUSED_OTHER` with a captured error message — falls through to `.bak` path. Migration tests are mandatory: every released migration ships with a fixture file at the from-version + an asserted output at the to-version.

6. **Risk: Save schema rules locked at MVP turn out to be wrong by VS, forcing every Alpha system to retrofit.**
   - **Mitigation**: This ADR's rules are the **format envelope** (`schema_version`, `data`, atomicity, `.bak` chain) — not the per-domain `data` shapes. Per-domain shapes are owned by per-domain GDDs. The envelope is stable across reasonable evolutions of the data inside it.

7. **Risk: JSON files appear forbidden by ADR-0004 (which lists "JSON config files (loses Godot's type-safe `@export` validation)" as a not-recommended pattern in the Juice context).**
   - **Mitigation**: ADR-0004 bans JSON for *designer-tuned config / balance data* (where `@export`-driven Resources give type-safe inspector authoring). Save data is dynamic per-run user state, NOT designer-authored config. The two stances are non-contradictory: project-shipped config = `.tres`/Resource; user-mutable runtime state = JSON. This ADR explicitly carves out the distinction so future review doesn't flag a phantom conflict. (The same carve-out is recorded in the registry as the rationale for choosing JSON-via-FileAccess for user save data while Resource-based authoring remains the rule for `res://` config.)

8. **Risk: `DirAccess.rename_absolute` on Windows fails if the destination file already exists. The `.tmp` → main rename will fail on every save after the first.**
   - **Mitigation**: After the `.bak` copy and BEFORE the rename, the save flow MUST call `DirAccess.remove_absolute(path)` (gated on `FileAccess.file_exists(path)`) to delete the main file. This is safe because `.bak` already holds the prior content. Required as a load-bearing implementation rule for `SaveManager`. Verification test in Migration Plan §1: simulate Windows rename-over-existing failure (mock `DirAccess.rename_absolute` to return `ERR_ALREADY_EXISTS`), assert SaveManager removes-then-renames and the main file ends up holding the new content. Without this rule, **every save after the first silently fails on Windows** — the project's primary target platform.

9. **Risk: `JSON.parse_string` returns `Variant`. A corrupted save that is valid JSON of a non-Dictionary root (`[1,2,3]`, `null`, `42`, `"string"`) crashes on `parsed["schema_version"]` access rather than triggering the `.bak` fallback.**
   - **Mitigation**: `_try_load_file` MUST guard with `if parsed == null or not parsed is Dictionary` before any key access. Non-Dictionary roots fall through to the `.bak`-then-defaults chain identically to JSON parse failures. Unit test: feed `_try_load_file` a file containing `[1, 2, 3]` and a file containing the literal string `null`, assert both produce `LoadResult.Status.RECOVERED_FROM_BACKUP` or `FELL_BACK_TO_DEFAULTS` (not a crash).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `design/gdd/systems-index.md` (#2 Save/Load) | "Schema rules (versioning, migration, recovery) lock at MVP even though Save/Load GDD ships at VS" (line 291) | Locks the schema envelope, versioning rules (per-file, append-only enums, N-2 window), recovery (`.bak` chain), and atomicity contract (incl. Windows remove-before-rename) before any persistent system writes its first byte. |
| `design/gdd/systems-index.md` (High-Risk #2) | "Concept warns: corrupted saves kill retention. Versioning + migration + recovery design." (line 327) | `.bak` fallback chain + `load_recovered_from_backup` / `load_fell_back_to_defaults` signals + corrupted-file forensic preservation directly mitigate. |
| `design/gdd/game-concept.md` (Tech Risks) | "Save system robustness: ... Corrupted saves kill retention. Invest in save versioning and recovery early." (line 325) | Versioning per-file with N-2 window; recovery is `.bak` + defaults + warning UX; FileAccess return-value checking enforced in `SaveManager`. |
| `design/gdd/systems-index.md` (#45 Test Harness) | "Headless run runner + deterministic RNG + fixture loader" | Test harness loads fixture saves via `SaveManager.load_domain` — same code path as production. |
| `docs/architecture/adr-0001-run-state-game-flow.md` | "ADR-006 (Save Schema) will own: persistence policy, versioning + migration rules for `schema_version`, recovery rules for corrupted snapshots." (lines 307–310) | *(R3 2026-05-01)* The `run_snapshot.save` domain has been DELETED — GDD R3 removed the suspend-save mechanism, so Run State's snapshot Dictionary is runtime-only. ADR-0001's enum-stability + JSON-serializable rules still generalise to all 7 remaining persistent domains; the per-domain `.bak` chain + envelope + atomicity rules apply uniformly. |

## Performance Implications

- **CPU**: Negligible. JSON parse/stringify of a save file (peak ~50KB at Alpha) takes <1ms. Saves happen on phase boundaries, never per-frame. Migration runs at load, once per session.
- **Memory**: Negligible. Save Dictionaries are transient; freed after `data` handed to domain. Steady-state SaveManager footprint ~1KB.
- **Load Time**: ~5–20ms total at startup if all 6+ files are read. Below 60fps frame budget for a single startup frame; not user-perceptible.
- **Network**: N/A — local-only.
- **Disk**: Steady-state ~12 files, ~200KB total at Alpha. Trivial.

## Migration Plan

This ADR is forward-looking — there is no existing save format to migrate FROM. The "migration plan" is the **adoption sequence**.

### §1. SaveManager autoload + verification (MVP, blocks GDD #45)
- Implement `SaveManager` autoload (`src/persistence/save_manager.gd`) with the API above.
- Implement `LoadResult`, fallback chain, atomicity (incl. Windows remove-before-rename), `.bak` rotation, FileAccess return-value checks, non-Dictionary parse guard.
- Unit tests in `tests/unit/persistence/save_manager_test.gd`:
  - Save → load round-trip preserves data.
  - Save with readonly target (mocked FileAccess) returns false; main file untouched.
  - Corrupt main → load uses `.bak`; `load_recovered_from_backup` fires.
  - Corrupt main + `.bak` → load returns defaults; corrupt files preserved at `corrupted_<unix>` paths; `load_fell_back_to_defaults` fires.
  - Future-version file → `REFUSED_TOO_NEW`; signal fires.
  - Old-version file → `REFUSED_TOO_OLD`; signal fires.
  - Migration v(N-2) → v(N-1) → v(N) chain runs at load (synthetic test domain).
  - **Windows rename test**: mock `DirAccess.rename_absolute` to return `ERR_ALREADY_EXISTS` on first call; assert SaveManager removes main file and retries / proceeds correctly.
  - **Non-Dictionary parse guard test**: load a file containing `[1,2,3]` and a file containing the JSON literal `null`; assert both fall through to `.bak`-or-defaults without crashing.
- Verification of FileAccess return-bool engine fact: write to readonly path, assert all three (return false / save_failed signal / main untouched).

### §2. Test Harness fixture loading (MVP, blocks GDD #45)
- GDD #45 writes fixture saves at known schema versions to `tests/fixtures/save/`.
- `SaveManager.load_domain` is used by both production and test code paths.

### §3. Per-domain adoption (per system GDD authoring)
- Each persistent system GDD includes a "Persistence" section: file(s), `data` shape for v1, declared persisted enums, save-trigger events (granularity is GDD-owned), fresh-defaults values.

### §4. Schema bump procedure (per change)
1. Bump `CURRENT_SCHEMA_VERSIONS[<domain>]` by +1.
2. Add `migrate_v<old>_to_v<new>(old: Dictionary) -> Dictionary` to `src/persistence/migrations/<domain>.gd`.
3. Add fixture file `tests/fixtures/save/<domain>_v<old>.json`.
4. Add unit test asserting `load_domain` returns `Status.OK` with `migrated_from_version = old` and produces expected v(new) shape.
5. If old becomes < current - 2, the corresponding migrate_v function and fixture can be retired (with a code-review note); loader stops supporting that version.

## Validation Criteria

This ADR is correct if, at GDD #2 (Save/Load) authoring:
- Every persistent system GDD references `SaveManager.save_domain` / `load_domain` — no system has its own serializer.
- No domain has been retrofitted to add its own version field, migration, or `.bak` handling.
- At least one schema bump (v1 → v2) has been performed via the documented procedure on a synthetic test domain, and the migration test passes. *(R3 2026-05-01: the original validation criterion required this on a real domain — `run_snapshot` was the planned candidate. With `run_snapshot` deleted in R3, the bump-procedure exercise can be done on a Test Harness fixture domain instead. The procedure must still be exercised end-to-end before this ADR Accepts.)*
- Test harness loads fixtures using the same SaveManager API as production.
- Corruption-recovery acceptance test (Migration Plan §1) passes on every CI run.
- Windows rename-over-existing test (Migration Plan §1) passes on every CI run.
- No P0/P1 save-corruption bugs in playtest.

This ADR is wrong if:
- The single-file alternative would have been simpler than maintaining 5+ files and migrations through Alpha. *(R3 2026-05-01: was 6+; reduced by one with `run_snapshot` deletion.)*
- 0 schema bumps after 6 months post-MVP development (over-engineered the migration window).
- Players hit corruption-recovery paths frequently enough that `.bak` chain isn't enough (would force escalation to cloud save in V1.x).

## Related Decisions

- **ADR-0001 (Run State / Game Flow)** — Locks in-memory snapshot Dictionary shape (used by Test Harness assertions and `state_snapshot_ready` consumers). *(R3 2026-05-01)* The on-disk persistence path for Run State has been removed — the suspend-save mechanism was cut in GDD R3. ADR-0001's enum-stability rule (append-only enum values) still informs this ADR's general `inserting_persisted_enum_values` forbidden pattern, but no `schema_version` coupling between the two ADRs exists post-R3.
- **ADR-0002 (Crowd Pathfinding)** — No interaction; pathfinding state is regenerated each wave, not persisted.
- **ADR-0003 (Language Routing Policy)** — SaveManager is GDScript (not C#); persistent state crosses the language boundary by being snapshotted on the GDScript side via `state_changed` handlers. C# hot-path systems (Damage, CrowdManager, Wave) do not write directly to disk.
- **ADR-0004 (Juice Pipeline)** — No persisted state; ADR-0004 line 27 explicitly notes "Juice owns no persisted state". JuiceProfile resources ship under `res://`, not `user://`. The JSON-config-vs-save-data carve-out (Risk 7) reconciles ADR-0004's anti-JSON stance with this ADR's pro-JSON-for-saves stance.
- **ADR-0005 (`ModifierTarget` Contract — pending, in Champion GDD)** — Champion definitions are read-only project assets, not save data. Per-Champion mastery progression IS save data and lives in `meta_progression.save`.
- **ADR-0007 (Effect Composition Taxonomy — pending, in Build/Modifier GDD)** — Effects are project assets (read-only). Run-time effect stacks live only in memory and reconstitute from cards held; cards are part of the run snapshot.
