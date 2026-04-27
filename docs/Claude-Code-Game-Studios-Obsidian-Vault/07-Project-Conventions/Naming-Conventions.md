---
title: Naming Conventions
tags: [conventions, naming]
---

# Naming Conventions

Consistent names across files, code, scenes, assets, and documents. Source: `.claude/docs/technical-preferences.md`.

---

## Code naming (Godot)

Already covered in [[07-Project-Conventions/Coding-Standards-Godot]]. Quick reference:

| Element | GDScript | C# |
|---------|----------|-----|
| Classes | PascalCase | PascalCase, `partial` |
| Public methods | snake_case | PascalCase |
| Private fields | snake_case `_underscore` | `_camelCase` |
| Constants | UPPER_SNAKE_CASE | PascalCase |
| Files | snake_case | PascalCase |
| Signals | snake_case past tense | `EventHandler` suffix |

---

## File naming

### Markdown documents

| Document type | Convention | Example |
|---------------|-----------|---------|
| GDD per system | snake-kebab-case | `damage-system.md` (or `damage_system.md`) |
| ADR | `adr-NNN-slug.md` (zero-padded) | `adr-003-language-routing.md` |
| Epic | `EPIC.md` (always) inside `<epic-slug>/` folder | `epic-slug/EPIC.md` |
| Story | snake-kebab-case | `combat-damage-formula.md` |
| Sprint plan | `sprint-N.md` | `sprint-3.md` |
| Playtest report | `<date>.md` or `<date>-<topic>.md` | `2026-04-25-vertical-slice.md` |
| Bug report | `<id>.md` (auto-numbered) | `BUG-042.md` |

### Code files

Match the language convention — see [[07-Project-Conventions/Coding-Standards-Godot]].

### Test files

`[system]_[feature]_test.[ext]`

- `combat_damage_formula_test.gd`
- `inventory_capacity_test.cs`
- `pathfinding_a_star_test.cs`

### Test functions

`test_[scenario]_[expected]`

- `test_zero_armor_damage_equals_base`
- `test_negative_damage_clamps_to_one`
- `test_crit_with_max_armor_still_doubles`

---

## Scene file naming (Godot)

| Element | Convention | Example |
|---------|-----------|---------|
| Scene file | PascalCase matching root node | `PlayerController.tscn` |
| Resource file | PascalCase | `DamageProfile.tres` |
| Sub-scene | PascalCase nested | `EnemyArcher_Chest.tscn` |

---

## Asset naming

### Sprites

`[category]_[subject]_[variant]_[state].png`

- `actor_player_idle_01.png`
- `tile_floor_stone_cracked.png`
- `vfx_hit_blood_01.png`

### Audio

`[category]_[subject]_[variant].wav` (or `.ogg`)

- `sfx_combat_hit_metal_01.wav`
- `music_loop_dungeon_calm.ogg`
- `voice_npc_merchant_greeting.wav`

### Models

`[category]_[subject]_[variant].glb`

- `prop_chest_wood.glb`
- `actor_enemy_skeleton.glb`

`/asset-audit` enforces this scheme. Names that don't match are flagged.

---

## Folder naming

| Folder type | Convention | Example |
|-------------|-----------|---------|
| Top-level | lowercase | `src`, `assets`, `design` |
| Sub-systems | lowercase, kebab-case | `gameplay/combat`, `ai/pathfinding` |
| Epic folders | kebab-case | `combat-foundation/`, `ui-main-menu/` |
| Date-based | `YYYY-MM-DD` | `production/playtests/2026-04-25/` |

---

## Branch naming

Suggested (not strict):

- `feature/<epic-slug>` for epic-level work
- `feature/<story-slug>` for story-level work
- `bugfix/<bug-id>` for bug fixes
- `hotfix/<id>` for emergencies (managed by `/hotfix`)
- Phase-specific: `tower-defense-game` (this project's branch — phase-named)

---

## Commit message style

Per `coding-standards.md`: **commits must reference the relevant design document or task ID.**

Format suggestion:

```
<type>(<scope>): <subject>

<body explaining why>

Refs: <TR-ID> or <story-id> or <ADR-NNN>
```

Examples:

```
feat(combat): implement damage formula service

Implements TR-CMB-001 per design/gdd/combat.md and ADR-007. Pure C# for
deterministic testing. Exposes signal damage_calculated to GDScript per ADR-003
language routing.

Refs: TR-CMB-001, ADR-007, story combat-damage-formula
```

```
fix(ui): pause menu focus skips first button on gamepad

Tab order was constructed before children were ready. Defer until _ready.

Refs: BUG-042
```

---

## Variable naming hygiene

These show up across both languages:

| Concept | Good name | Avoid |
|---------|-----------|-------|
| Health remaining | `current_health` | `hp`, `h` |
| Max health | `max_health` | `mhp`, `health_max` |
| Damage to apply | `incoming_damage` | `dmg`, `amount`, `n` |
| Player reference | `player` | `p`, `pl` |
| Time delta | `delta` (Godot convention) | `dt`, `time_delta` |
| Loop iterator | `i` (only when truly iterator) | `index_of_thing` |

Cross-system variable consistency matters because **GDDs reference these names**. If `damage` here and `dmg` elsewhere, you've created a search hazard.

---

## Common pitfalls

- **Mixing case in file names.** `playerController.gd` and `player_controller.gd` look the same on Windows but break on Linux/macOS in Git. Always snake_case in Godot.
- **Skipping the zero-pad on ADRs.** `adr-3.md` sorts after `adr-10.md`. Always `adr-003`.
- **Generic names for assets.** `enemy_01.png` is not findable. `actor_enemy_skeleton_idle_01.png` is.
- **Inconsistent variable names across GDDs.** `/consistency-check` flags these.

---

## See also

- [[07-Project-Conventions/Coding-Standards-Godot]]
- [[07-Project-Conventions/Directory-Structure]]
- `.claude/docs/technical-preferences.md` — source
