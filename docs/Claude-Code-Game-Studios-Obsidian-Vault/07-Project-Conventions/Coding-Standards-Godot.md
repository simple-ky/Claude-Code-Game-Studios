---
title: Coding Standards (Godot)
tags: [conventions, coding-standards, godot]
---

# Coding Standards (Godot)

What the codebase expects of all game code. Source: `.claude/docs/coding-standards.md` and `technical-preferences.md`.

> This project is configured for **Godot 4.6.2** with GDScript primary, C# for performance-critical systems, C++ via GDExtension for native-only.

---

## Universal rules

From `.claude/docs/coding-standards.md`:

1. **Doc comments on public APIs.** Every public method/class has a docstring.
2. **Every system has an ADR.** No system ships without an architecture record.
3. **Data-driven gameplay values.** External config files (JSON, .tres). Never hardcoded magic numbers.
4. **Dependency injection over singletons.** Public methods must be unit-testable.
5. **Commits reference design documents or task IDs.** Traceability is mandatory.
6. **Verification-driven development.** Tests first for gameplay systems; screenshots for UI; expected vs actual before "done."

---

## GDScript (`.gd` files)

**Owner agent:** `godot-gdscript-specialist`.

### Naming conventions

| Element | Style | Example |
|---------|-------|---------|
| Classes | PascalCase | `PlayerController` |
| Variables / functions | snake_case | `move_speed`, `take_damage()` |
| Signals | snake_case past tense | `health_changed`, `enemy_died` |
| Files | snake_case matching class | `player_controller.gd` |
| Scenes | PascalCase matching root node | `PlayerController.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH` |

### GDScript-specific rules

- **Static typing required.** `var health: int = 100` not `var health = 100`. Catches errors at compile time.
- **Signals over direct calls** within GDScript when crossing scene/node boundaries.
- **No `_process` for animations** — use `Tween` or `AnimationPlayer`.
- **Coroutines (`await`) preferred** over manual frame-counting.

### Common patterns

```gdscript
class_name PlayerController extends CharacterBody2D

const MOVE_SPEED: float = 300.0
const JUMP_VELOCITY: float = -500.0

signal health_changed(new_value: int)

@export var max_health: int = 100
var _current_health: int = max_health


func take_damage(amount: int) -> void:
    _current_health = max(0, _current_health - amount)
    health_changed.emit(_current_health)
    if _current_health == 0:
        die()


func die() -> void:
    queue_free()
```

---

## C# (`.cs` files)

**Owner agent:** `godot-csharp-specialist`.

### When to use C# instead of GDScript

Per this project's `technical-preferences.md`:
- Performance-critical systems (e.g. Crowd Pathfinding)
- Deterministic damage formulas (testability)
- Heavy mathematical workloads
- Systems that benefit from .NET libraries

### Naming conventions

| Element | Style | Example |
|---------|-------|---------|
| Classes | PascalCase, `partial` required | `public partial class PlayerController : Node` |
| Public properties / fields | PascalCase | `MoveSpeed` |
| Private fields | `_camelCase` | `_currentHealth` |
| Methods | PascalCase | `TakeDamage()` |
| Signal delegates | PascalCase + `EventHandler` suffix | `HealthChangedEventHandler` |
| Files | PascalCase matching class | `PlayerController.cs` |
| Constants | PascalCase | `MaxHealth` |

### C#-specific rules

- **`partial` keyword required** on Godot-derived classes (so the source generator can produce bindings).
- **`[Export]` attribute** for inspector-exposed properties.
- **`[Signal] delegate` for declared signals.**
- **`async` patterns** preferred over manual coroutines.

### Common patterns

```csharp
using Godot;

public partial class DamageService : Node
{
    [Export]
    public float GlobalDamageVariance { get; set; } = 0.1f;

    [Signal]
    public delegate void DamageCalculatedEventHandler(int amount);

    public int CalculateDamage(int baseDamage, int armor, bool isCrit, float seedValue)
    {
        float critMult = isCrit ? 2.0f : 1.0f;
        float variance = 1.0f + (seedValue - 0.5f) * GlobalDamageVariance * 2;
        int final = Math.Max(1, (int)((baseDamage - Math.Max(0, armor)) * critMult * variance));
        EmitSignal(SignalName.DamageCalculated, final);
        return final;
    }
}
```

---

## Cross-language rule (CRITICAL)

> **Prefer signals over direct method calls at the GDScript/C# boundary.**

This is enforced by ADR-003 in this project (Language Routing). Direct calls work but are forbidden.

```gdscript
# GOOD — via signal
func _ready() -> void:
    var damage_service: DamageService = $DamageService
    damage_service.damage_calculated.connect(_on_damage_calculated)


func _on_damage_calculated(amount: int) -> void:
    show_damage_number(amount)
```

```gdscript
# BAD — direct call across boundary
func _on_attack() -> void:
    var damage_service: DamageService = $DamageService
    var amount = damage_service.CalculateDamage(...)  # forbidden
    show_damage_number(amount)
```

---

## Shaders (`.gdshader`)

**Owner agent:** `godot-shader-specialist`.

- Use Godot Shading Language (GLSL-like)
- Either CanvasItem (2D) or Spatial (3D) shader type
- VisualShader resources allowed for prototyping; consolidate to .gdshader for production
- Profile shader cost in `/perf-profile` — they're often the GPU bottleneck

---

## GDExtension (`.gdextension`, native C++/Rust)

**Owner agent:** `godot-gdextension-specialist`.

- Native code only when GDScript + C# performance is insufficient
- Use `godot-cpp` (official) or `godot-rust` bindings
- Custom node types must follow Godot lifecycle (`_ready`, `_process`, etc.)
- Build system integration is expensive — justify before adding

---

## Performance budgets

From `.claude/docs/technical-preferences.md`:

| Metric | Budget |
|--------|--------|
| Target framerate | 60 fps |
| Frame budget | 16.6 ms |
| Draw calls | ≤ 1500 per frame |
| Memory ceiling | 2 GB RAM total |

`/perf-profile` enforces these. Stories that violate are flagged.

---

## Forbidden patterns (currently empty)

This project's `technical-preferences.md` has no forbidden patterns yet — they accumulate as ADRs are accepted. Examples that may appear:

- "Never use `_process` for animation"
- "Never store gameplay state in autoloads"
- "Never call `Resources.Load()` for gameplay assets"

Read the **control manifest** before implementing — it's where forbidden patterns live operationally.

---

## See also

- [[04-Agents/Engine-Specialists-Godot-Unity-Unreal]] — engine specialist routing
- [[06-Documents-Produced/Control-Manifest]] — operational forbidden patterns
- [[07-Project-Conventions/Naming-Conventions]] — naming detail
- [[07-Project-Conventions/Testing-Standards]]
- `.claude/docs/coding-standards.md` — full source
- `.claude/docs/technical-preferences.md` — engine + budget config
