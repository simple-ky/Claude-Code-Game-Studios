---
name: preview-scene
description: Generate a Godot scene wireframe from design docs so the developer can see what the planned game will look like before any gameplay code is written. Use when the user asks to "preview the scene", "see what the gameplay grid looks like", "wireframe the lanes", "visualize the design", or runs /preview-scene. Reads design/registry/entities.yaml + design/gdd/lane-map-system.md and produces a real .tscn file in prototypes/previews/.
model: sonnet
---

# /preview-scene — Design-to-Wireframe Generator

## What this skill does

Builds a real Godot `.tscn` wireframe from the project's design docs so the
developer can **see the planned scene at real scale before writing any
gameplay code**. The wireframe uses `ColorRect` nodes (no sprites) at the
locked `cell_size_px` and lane geometry. The developer opens the file in
the Godot editor manually and can screenshot it to share with Claude when
refining the design.

The output is a throwaway artifact, not a production scene. It lives in
`prototypes/previews/` (gitignored per `directory-structure.md`) and is
regenerated from scratch on every run.

## When to invoke

User runs `/preview-scene <scene>` where `<scene>` is currently one of:

| Scene slug | What gets rendered |
|---|---|
| `gameplay-grid` | Lane grid + spawn zones + goal zones + buildable strip + bend |

(Future expansion: `gameplay-grid-with-camera`, `hud`, `menu`. v1 ships
`gameplay-grid` only.)

If no scene slug is given, list the available scenes and ask which one.

## What the developer sees when they run it

1. Skill reads docs and prints which constants it parsed.
2. If any required value is missing or ambiguous, skill asks the developer
   for it (one question at a time) and suggests where to add it to
   `design/registry/entities.yaml` so the next run is clean.
3. Skill writes `prototypes/previews/gameplay-grid-wireframe.tscn`.
4. Skill prints the absolute file path and a summary of values used.
5. Developer opens the file in the Godot editor manually.

The skill does NOT auto-launch the Godot editor (per the design decision
made when this skill was authored — the developer stays in chat flow and
opens the file when they want to look).

## Process

### Step 1 — Validate MCP availability

The skill requires the godot MCP server. If `mcp__godot__create_scene`
is not available, stop immediately and print:

```
✗ Godot MCP server not connected.

This skill requires the godot MCP server to generate .tscn files. Check
your MCP server status, then re-run /preview-scene gameplay-grid.
```

### Step 2 — Read the registry

Read `design/registry/entities.yaml`. Extract the `constants` section. The
following keys are required for `gameplay-grid`:

| Registry key | Used for |
|---|---|
| `cell_size_px` | Cell width/height in pixels |
| `lane_count_mvp` | Number of lanes |
| `lane_width_cells_mvp` | Each lane's width in cells |
| `lane_depth_cells_mvp` | Each lane's depth in cells |
| `bend_depth_fraction` | Where along the lane the bend sits (fraction of depth) |
| `bend_angle_deg_min` / `bend_angle_deg_max` | Bend angle range (informational only — see Step 3 for actual value) |
| `total_buildable_cells_mvp` | Total buildable cells |

If a key is missing, ask the developer:

> "I couldn't find `<key>` in `design/registry/entities.yaml`. What value
> should I use for this wireframe? (After you tell me, I'll suggest where
> to add it to the registry so this is automatic next time.)"

Cap at 5 missing-key questions. If 6+ are missing, stop and tell the
developer the registry needs a manual pass first — the skill is not the
right tool for a from-scratch population.

### Step 3 — Read the GDD for layout intent

Read `design/gdd/lane-map-system.md`. Three layout facts are NOT in the
registry — they live in the GDD:

- **Lane orientation**: GDD Section C Rule 4 says "Each lane has its own
  `SpawnZone` at the top and its own `GoalZone` at the bottom" → **vertical,
  top-down zombie travel**. Hardcode this for v1. (When a non-vertical
  layout is designed, add an `orientation` constant to the registry and
  read it here instead.)
- **Buildable strip position**: GDD Section C Rule 6 (R2 revision) says
  the strip sits at **40–65% lane depth, surrounding the bend** — NOT the
  legacy R1 position (back 20%). Use the R2 position.
- **Bend angle**: GDD Section C Rule 5 (R2 revision) says **35–45°**. The
  registry still has the stale R1 value (20–30°). Use the GDD's 35–45°
  midpoint (40°). Flag the registry as stale (see Step 6).

If the GDD's R2 values conflict with the registry, **trust the GDD** (it
is the source) and emit a one-line warning suggesting a registry update.

### Step 4 — Compute layout in pixels

```
lane_gap_cells = 1                        # 1-cell visual gap between lanes
grid_width_px  = (lane_count * lane_width_cells + (lane_count - 1) * lane_gap_cells) * cell_size_px
grid_height_px = lane_depth_cells * cell_size_px

For each lane (lane_id ∈ [0, lane_count - 1]):
  lane_x_offset_px = lane_id * (lane_width_cells + lane_gap_cells) * cell_size_px
  spawn_zone_row   = 0                              # top row
  goal_zone_row    = lane_depth_cells - 1           # bottom row
  bend_row         = floor(bend_depth_fraction * lane_depth_cells)
  strip_row_top    = floor(0.40 * lane_depth_cells)
  strip_row_bottom = floor(0.65 * lane_depth_cells)
```

Distribute `total_buildable_cells_mvp` evenly across the lanes within
rows `[strip_row_top, strip_row_bottom]`. If the distribution does not
divide cleanly, allocate the remainder to the lower-numbered lanes.

### Step 5 — Generate the scene via godot MCP

Call tools in this order. **Stop on any failure** and report the error
verbatim to the developer.

1. **`mcp__godot__create_scene`**
   - `path`: `prototypes/previews/gameplay-grid-wireframe.tscn`
   - `root_type`: `Node2D`
   - `root_name`: `GameplayGridWireframe`

2. **`mcp__godot__add_node`** — for each child below. Use the
   `position`/`size`/`color` fields appropriate to each node type.

| Node name pattern | Type | Position / Size | Color |
|---|---|---|---|
| `Lane_<id>_Cell_<row>_<col>` (one per cell) | `ColorRect` | `position = (lane_x + col*96, row*96)`, `size = (96, 96)` | `#444444` if (row+col) even, else `#3a3a3a` |
| `Lane_<id>_SpawnZone` (one per lane) | `ColorRect` | `position = (lane_x, 0)`, `size = (lane_width_cells*96, 96)` | `#cc220033` (translucent red) |
| `Lane_<id>_GoalZone` (one per lane) | `ColorRect` | `position = (lane_x, (lane_depth_cells-1)*96)`, `size = (lane_width_cells*96, 96)` | `#22cc0033` (translucent green) |
| `Lane_<id>_BuildableStrip` (one per lane) | `ColorRect` | `position = (lane_x, strip_row_top*96)`, `size = (lane_width_cells*96, (strip_row_bottom-strip_row_top+1)*96)` | `#2244cc33` (translucent blue) |
| `Lane_<id>_BendMarker` (one per lane) | `Line2D` | points: `[(lane_x, bend_row*96), (lane_x + lane_width_cells*96, bend_row*96)]`, `width: 2` | `#ffcc00` (yellow) |
| `DebugLabel` (one total) | `Label` | `position = (8, 8)` | text color white, font_size 14 |

DebugLabel text (substitute `<>` with parsed values):

```
═══════════════════════════════════════════════
  WIREFRAME — NOT A PRODUCTION SCENE
═══════════════════════════════════════════════
Generated by /preview-scene gameplay-grid
Source:
  • design/registry/entities.yaml
  • design/gdd/lane-map-system.md

cell_size_px:           <value>
lane_count:             <value>
lane_width_cells:       <value>
lane_depth_cells:       <value>
total_buildable_cells:  <value>
bend at:                <bend_depth_fraction> × depth, ~40°
buildable strip:        rows <strip_row_top>-<strip_row_bottom> (40-65% depth, surrounds bend, per R2)

DO NOT extend this scene. Regenerate after any
GDD or registry change by re-running the skill.
This file is gitignored. Safe to delete any time.
```

3. **`mcp__godot__save_scene`** — save the .tscn file.

### Step 6 — Print the result

Print this format exactly (substitute `<>` placeholders):

```
✓ Wireframe written: prototypes/previews/gameplay-grid-wireframe.tscn

Values used:
  cell_size_px:          <value>
  lane_count:            <value>
  lane_width_cells:      <value>
  lane_depth_cells:      <value>
  total_buildable_cells: <value>
  bend:                  <bend_depth_fraction> × depth, ~40°
  buildable strip:       rows <strip_row_top>-<strip_row_bottom> (R2 position)

Total grid: <grid_width_px> × <grid_height_px> px

To view: open the .tscn in the Godot editor.
```

If the registry's `bend_angle_deg_min/max` was stale (20–30° vs GDD's
35–45°), append:

```
⚠ Stale registry values detected:
  • bend_angle_deg_min / bend_angle_deg_max — registry says 20–30°,
    GDD Section C Rule 5 (R2) says 35–45°. Suggest updating
    design/registry/entities.yaml to match the GDD.
```

If any required key was filled in via developer prompt (Step 2 fallback),
append:

```
ℹ Values you provided this run (not in registry):
  • <key> = <value>
  Suggest adding to design/registry/entities.yaml under the
  `constants:` section so next run is automatic.
```

## Failure modes

| Failure | Behavior |
|---|---|
| `design/registry/entities.yaml` missing | Stop. Print: "Registry not found at expected path. This skill requires it." |
| `design/gdd/lane-map-system.md` missing | Stop. Same message with GDD path. |
| Required constant missing in registry | Ask the developer (cap at 5 questions). If 6+ missing, stop. |
| godot MCP server unavailable | Stop with Step 1 error message. |
| `prototypes/previews/` directory does not exist | `mcp__godot__create_scene` will create it. If it fails for other reasons, report verbatim. |
| Output file already exists | Overwrite. Wireframes are throwaway. |
| `lane_count × lane_width_cells > 20` (sanity check) | Warn but proceed. The wireframe will be very wide. |
| `total_buildable_cells / lane_count > (strip_row_bottom - strip_row_top + 1) × lane_width_cells` | The buildable cell budget exceeds the strip area. Stop and print: "Design inconsistency: `total_buildable_cells_mvp` (`<value>`) does not fit in the buildable strip area at the current lane config. This is a design bug — check `lane-map-system.md` Section D.5 and `buildable_strip_distribution` formula." |

## What this skill does NOT do (v1 scope lock)

These were explicitly excluded when this skill was scoped. Adding any of
them is a v2 conversation, not a v1 extension:

- No camera frustum overlay
- No HUD wireframe
- No main menu / title screen
- No file watching / auto-regenerate (manual invocation only)
- No interactive value sliders
- No sprite placeholders (ColorRect only)
- Does NOT open the Godot editor automatically
- Does NOT update the registry — only suggests updates

## Future expansion (notes for v2+)

When extending:

- `gameplay-grid-with-camera` — overlay `Camera2D` frustum + safety margin
  from `design/gdd/camera-system.md` once that GDD reaches Section E+.
- `hud` — once a UX spec exists at `design/ux/hud.md`.
- `--watch` flag — re-emit on file change. Large effort; only build after
  v1 manual usage proves the workflow.
- HTML/SVG output variant for non-Godot quick previews.
- Add an `orientation` constant to the registry (`horizontal` / `vertical`)
  if a non-vertical map is ever designed; replace the hardcode in Step 3.

## Maintenance

If `design/gdd/lane-map-system.md` is revised significantly (e.g., R3+,
or any structural change to lane orientation, bend placement, or
buildable strip rules), re-read Step 3 to confirm the hardcoded
assumptions still hold. The skill's job is to track the docs — when the
docs change shape, the skill needs updating, not the docs.
