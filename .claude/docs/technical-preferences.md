# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6.2
- **Language**: GDScript (primary — gameplay, UI), C# (performance-critical systems), C++ via GDExtension (native only)
- **Rendering**: Forward+ (desktop) — default for Godot 4.6 on Windows
- **Physics**: Jolt (default in 4.6)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Steam / itch)
- **Input Methods**: Keyboard/Mouse, Gamepad (optional)
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial (tower placement via cursor; menus gamepad-navigable)
- **Touch Support**: None
- **Platform Notes**: PC-only release. No mobile/console UX constraints. Gamepad is a nice-to-have, not a shipping requirement.

## Naming Conventions

**GDScript (.gd files):**
- **Classes**: PascalCase (`PlayerController`)
- **Variables/Functions**: snake_case (`move_speed`, `take_damage()`)
- **Signals**: snake_case past tense (`health_changed`)
- **Files**: snake_case matching class (`player_controller.gd`)
- **Scenes**: PascalCase matching root node (`PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_HEALTH`)

**C# (.cs files):**
- **Classes**: PascalCase, must be `partial` (`public partial class PlayerController : Node`)
- **Public properties/fields**: PascalCase (`MoveSpeed`)
- **Private fields**: `_camelCase` (`_currentHealth`)
- **Methods**: PascalCase (`TakeDamage()`)
- **Signal delegates**: PascalCase + `EventHandler` suffix (`HealthChangedEventHandler`)
- **Files**: PascalCase matching class (`PlayerController.cs`)
- **Constants**: PascalCase (`MaxHealth`)

**Cross-language rule:** Prefer signals over direct method calls at the GDScript/C# boundary.

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6 ms
- **Draw Calls**: ≤ 1500 per frame
- **Memory Ceiling**: 2 GB RAM total

### Benchmark Hardware (added 2026-05-02 per Lane/Map R2.1)

Performance ACs that require pinned hardware to be deterministic (e.g., AC-LM-17, AC-LM-18, AC-LM-21 post-bake assertion, Open Question #7 in `design/gdd/lane-map-system.md`) reference the following Tier-2 reference hardware. When authoring a new performance AC, name these specs:

- **Tier-2 reference (PRIMARY)**: Steam Deck OLED (AMD APU "Sephiroth" 6 nm; 8-core RDNA 2 iGPU; 16 GB LPDDR5x; 1280×800 native viewport at primary game resolution; default thermal envelope; SteamOS Holo 3.x; baseline 0.5h cold-boot warmup before measurement).
- **Tier-2 reference (SECONDARY)**: 2019-class laptop — Intel Core i7-9750H (or equivalent AMD Ryzen 5 3600 mobile), NVIDIA GTX 1660 Ti / GTX 1650 Mobile, 16 GB DDR4-2666, 1920×1080 viewport, Windows 11, antivirus active during measurement (the realistic-user condition).

**Benchmark methodology** (locked per Lane/Map R2):
- 300-frame minimum measurement window
- Profiler **OFF** during measurement (profiler overhead invalidates timing)
- `Time.get_ticks_usec()` instrumentation around measured code paths (NOT `delta` from `_process` — too coarse)
- Results logged to `production/qa/evidence/` with hardware tier tag, run timestamp, and OS/driver version
- 95th percentile (p95) is the canonical reporting metric, NOT mean or median (tail latency is what ships as "stutter")

## Testing

- **Framework**: GUT (GDScript tests), GodotXUnit or chickensoft-games/GoDotTest (C# tests) — finalize on first sprint
- **Minimum Coverage**: Deferred until architecture phase
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **GDScript Specialist**: godot-gdscript-specialist (.gd files — gameplay/UI scripts)
- **C# Specialist**: godot-csharp-specialist (.cs files — performance-critical systems)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for cross-language architecture decisions and which systems belong in which language. Invoke GDScript specialist for .gd files. Invoke C# specialist for .cs files and .csproj management. Prefer signals over direct cross-language method calls at the boundary.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Game code (.cs files) | godot-csharp-specialist |
| Cross-language boundary decisions | godot-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Project config (.csproj, NuGet) | godot-csharp-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
