# Coding Readiness — What Can Start Now

> **Created**: 2026-04-25
> **Branch**: tower-defense-game
> **Audience**: Solo dev planning the start of code work

This doc answers three near-term questions:

1. What can I start coding right now?
2. Should I do all the work in VS Code, or somewhere else?
3. Should I build the entire game in C# (instead of GDScript) for Godot → Unity portability insurance?

---

## 1. What Can Start Coding Now

### TL;DR

**Almost nothing should land in `src/` yet.** Pre-production gate has not passed — GDDs are 0/45, ADRs are 0/7. Production code written against unfrozen contracts will be rewritten when those contracts change (and they *will* change — Champion `ModifierTarget`, Effect Taxonomy, Run State machine are all explicitly flagged as evolving in the systems index).

What *can* happen right now lives in **two safe zones**: project scaffolding and `prototypes/`.

### Status by area

| Area | Can start now? | Language | Blocker |
|------|---------------|----------|---------|
| Project skeleton (.csproj, Godot project setup, folder structure) | ✅ Yes | C# config | None |
| Test harness scaffolding (System #45) | ✅ Yes | GDScript + C# | None — TD review added this as MVP |
| `.gitignore`, `.gitattributes`, EditorConfig | ✅ Yes | n/a | None |
| CI workflow stub (`.github/workflows/test.yml`) | ✅ Yes | YAML | None |
| Crowd Pathfinding prototype (`prototypes/crowd-pathfinding/`) | ⏳ After ADR-002 | C# | ADR-002 must lock the architecture choice |
| Champion feel prototype (`prototypes/champion-feel/`) | ⏳ After ADR-001 + ADR-003 | GDScript (likely) | Run State + Language Routing must lock |
| 2-lane map paper-prototype | ✅ Yes (paper, not code) | n/a | None — pure design exercise |
| Foundation GDD code (Run State, Input, Camera, Audio Bus, VFX, Lane/Map) | ❌ No | — | GDD must be authored + reviewed first |
| Any Layer 2+ system code | ❌ No | — | GDDs + ADR-003 |

### What "scaffolding" means concretely

Things that are safe to write today because they don't depend on any unfrozen GDD:

- **`project.godot`** — Godot project file with display settings, autoloads list (empty), input map (placeholder), rendering = Forward+, physics = Jolt
- **`*.csproj` + `*.sln`** — .NET 8 SDK, Godot.NET.Sdk reference, target framework `net8.0`, nullable enabled, `<LangVersion>latest</LangVersion>`
- **Folder structure under `src/`** — `src/core/`, `src/gameplay/`, `src/ui/`, `src/data/`, `src/tests/` (mirrors `.claude/docs/directory-structure.md`)
- **Test harness skeleton** — GUT installed for GDScript, GodotXUnit chosen for C#, one passing smoke test in each just to prove the pipeline
- **CI** — GitHub Actions workflow that runs `godot --headless` test command on push (System #45 requirement)

That's it. Don't write gameplay code. Don't write a Champion class. Don't sketch a Card system. Those are downstream of GDDs that don't exist yet.

### Why prototypes are different

`prototypes/` is **explicitly throwaway**. Its job is to *invalidate assumptions* before the GDD freezes. The two flagged prototypes test specific risks:

- **Crowd Pathfinding** validates "can we hit 100+ zombies @ 60fps with Godot 4.6's NavigationServer2D / a flow-field / a hybrid?" The answer changes the Lane/Map GDD and the Zombie AI GDD. Has to happen *before* those GDDs lock. Cannot start until ADR-002 picks the approach to test.
- **Champion feel** validates "do two Champions actually feel different with our planned input + ability layout?" If they don't, the entire game's first pillar is broken. Has to happen *before* the Champion GDD locks the `ModifierTarget` contract.

Throwaway code in `prototypes/` is never promoted to `src/`. When you start the real implementation post-gate-check, you re-write the lessons learned, you don't copy-paste the prototype.

---

## 2. Where to Do the Work — VS Code vs. Godot Editor

**Both. They're complementary, not alternatives.**

| Activity | Tool |
|----------|------|
| Writing GDScript code (`.gd`) | Either — VS Code with `godot-tools` extension OR Godot's built-in script editor |
| Writing C# code (`.cs`) | VS Code (or Rider) — Godot's C# editor is barebones |
| Editing scenes (`.tscn`) | **Godot Editor only** — scenes are not hand-edited in text |
| Editing resources (`.tres`) | **Godot Editor** for the inspector workflow; VS Code if you know the format |
| Editing shaders (`.gdshader`) | Either — VS Code has syntax highlighting; Godot has live preview |
| Design docs, ADRs, GDDs | VS Code (this project — Markdown) |
| Architecture diagrams | VS Code (Mermaid in Markdown) |
| Sprite art | Aseprite (already in your toolchain per the workspace dirs) |
| Audio | Outside the project — DAW of choice |
| Running the game | Godot Editor (F5) or `godot --path .` from terminal |
| Headless tests | Terminal — `godot --headless --script tests/runner.gd` |
| Git operations | VS Code's terminal or git CLI — Godot's editor doesn't do git |

### Practical workflow

Both tools point at the **same project folder** (`c:\projects\game-projects\Claude-Code-Game-Studios`). They don't conflict — Godot saves scenes, you save code, git tracks both.

A typical session looks like:

1. **VS Code (this project)** — open. This is where Claude Code runs, where you read GDDs, write ADRs, edit code.
2. **Godot Editor** — open the same project folder. This is where you arrange scenes, hit play, inspect the running game.
3. **Aseprite** — open separately when you need to author sprites.

Claude Code (here in VS Code) cannot drive the Godot Editor directly — when you need a scene change, either describe what node tree you want and I generate the `.tscn` file, or you do it manually in the editor and I work with the result.

### What stays in *this* VS Code project

Everything that lives in this repo: code, design docs, ADRs, GDDs, prototypes, tests, CI config, the `.claude/` agent definitions. All your design-and-implementation work happens here. You won't have a separate "code project" elsewhere.

---

## 3. Should You Build the Whole Game in C# for Godot → Unity Portability?

### Short answer: **No.** Use the hybrid the project already specifies.

### Long answer

The premise — "if I write everything in C#, I can move from Godot to Unity later" — sounds reasonable and is mostly false. Here's why.

#### What actually ports between Godot C# and Unity C#

Only the parts that **don't touch the engine**:

```
PORTABLE (your code is the same):                NON-PORTABLE (full rewrite):
- Damage formulas                                - Node hierarchies (Godot scenes ≠ Unity prefabs)
- Balance math                                   - Lifecycle methods (_Ready vs Start)
- State machines (pure logic)                    - Input system (InputEvent vs Input/InputSystem)
- Save data schemas                              - Physics (Jolt-Godot vs PhysX-Unity)
- Content definitions (cards, weapons)           - Rendering (CanvasItem/Forward+ vs URP)
- Algorithms (RNG, deck shuffling)               - Animation (AnimationPlayer vs Animator)
- Pure data transformations                      - Signals (Godot signals vs UnityEvents/C# events)
                                                 - Resource loading (.tres vs ScriptableObject)
                                                 - Math types (subtle Vector2 differences)
                                                 - Tooling/editor extensions
```

For a top-down hero-defense game, the **non-portable side is most of the codebase**. Hitboxes, movement, collision, particles, sprites, animation, input, UI — all engine-bound. Writing them in C# instead of GDScript doesn't make them more portable — it just makes them slower to iterate in Godot.

#### What "portability through C#" *would* require

A real portable architecture is **hexagonal / clean architecture with engine adapters**:

```
┌───────────────────────────────────────┐
│    Engine layer (Godot OR Unity)      │  ← Rewrite per engine
│  - Node : CharacterBody2D             │
│  - Scene tree, signals, input         │
│  - Renders, plays sounds, reads input │
└────────────────┬──────────────────────┘
                 │ calls into
                 ▼
┌───────────────────────────────────────┐
│   Adapter / port interfaces (C#)      │  ← Defined once, implemented per engine
│   IRenderer, IInputSource, IAudio     │
└────────────────┬──────────────────────┘
                 │ used by
                 ▼
┌───────────────────────────────────────┐
│   Pure C# domain (engine-free)        │  ← Truly portable
│   DamageCalculator, RunState,         │
│   CardDeck, WaveScheduler, Champion-  │
│   Stats, ModifierStack                │
└───────────────────────────────────────┘
```

This works. But the cost for a solo dev:

- ~30-40% more code (interfaces + adapters everywhere)
- Slower iteration (every gameplay tweak goes through 2-3 layers)
- Forced upfront design (you can't sketch and refactor — you have to know the boundaries early)
- Solo-dev-killer: it doubles design cost on systems that **may never need to migrate**

Your V1 target is 12-18 months solo. The honest math: cost of hexagonal-from-day-one (months of extra work) vs. cost of a hypothetical Unity rewrite (also months — but in a future where the game is already proven and you'd want to redesign half of it anyway). The first cost is certain; the second is hypothetical.

#### What the systems index already specifies (and why it's right)

From the director-reviewed plan:

- **GDScript default** — fast iteration, Godot-native, the right tool for engine-glue and UI
- **C# for hot paths** — Crowd Pathfinding (#11), Damage & Health (#13), Wave/Spawn (#18), Build/Modifier math (#23). These are precisely the systems where:
  - Performance matters (justifies C#'s lower marshaling cost in tight loops)
  - Logic dominates over engine glue (C# is stronger at logic, GDScript is stronger at glue)
  - **Coincidentally, these are also the most portable systems** — Damage & Health math, Modifier stacking math, and Wave scheduling logic are all near-pure-logic and would survive a Unity port mostly intact

So the existing routing already gives you partial portability for the highest-value, most-likely-to-survive-a-rewrite parts of the codebase, without paying the all-C# tax on UI, scenes, and engine glue.

#### When all-C# *would* make sense

Three scenarios where I'd reverse this advice:

1. **You're certain you'll ship on Unity, not Godot.** Then write Unity, skip Godot.
2. **You're building a code-only product** (a server, a simulation engine, a library) where rendering is incidental. Then engines barely matter and C# is the right base.
3. **You have a team and budget** to absorb the hexagonal-architecture cost. Solo + 12-18 months is not that situation.

#### My recommendation

**Stick with the hybrid GDScript + C# routing already in the systems index.** If you want extra migration insurance for cheap, do these three things:

1. **Keep gameplay math pure in the C# systems.** When you write `DamageCalculator` (System #13), make `Calculate(...)` a static method that takes plain data structs and returns a result struct. No `Node` references, no signals fired from inside. The Godot wrapper calls `Calculate` and emits the signal. This costs you nothing extra and the math ports directly to Unity.
2. **Keep content data in plain JSON or `.tres` resources** with explicit schemas, not hardcoded in scenes. Card definitions, Champion stats, wave configs — all data files. This is already in your coding standards ("gameplay values must be data-driven"). Data ports trivially.
3. **Document the C#/GDScript boundary contracts.** The systems index already requires this for ADR-005 (`ModifierTarget`). Apply the same discipline to the other C# systems. A documented boundary is a documented rewrite seam.

That gives you **migration insurance for the 30% of the codebase that would actually port**, without paying for the 70% that wouldn't anyway.

---

## Decision Summary

| Question | Recommendation |
|----------|---------------|
| What can start coding now? | Project scaffolding, test harness, CI stub. Prototypes after their ADR gates. No `src/` gameplay code yet. |
| Where do I work? | VS Code (this project) for code + docs, Godot Editor for scenes, Aseprite for sprites. Same project folder, complementary tools. |
| Should I go all-C# for Godot→Unity portability? | No. Stick with the GDScript + C# routing already in the systems index. Get partial portability cheap by keeping C# system math pure, data-driven, and behind documented boundaries. |

---

## Next Action (if you want to start coding today, safely)

```
/architecture-decision
```

Author **ADR-003 (Language Routing Policy)** to lock the GDScript/C# boundary policy. That ADR is the official place to record:

- Which systems are GDScript, which are C#, and the rationale
- The boundary contract pattern (signals over direct calls)
- The "pure math" rule for C# systems (so they stay portable as a side effect)
- File extension routing (already in `.claude/docs/technical-preferences.md`)

Once ADR-003 is locked, project scaffolding can land safely because the language boundary won't shift under it.
