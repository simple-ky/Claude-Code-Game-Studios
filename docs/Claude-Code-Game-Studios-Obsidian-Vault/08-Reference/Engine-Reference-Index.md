---
title: Engine Reference Index
tags: [reference, engine, godot, unity, unreal]
---

# Engine Reference Index

Why version-pinned engine docs exist, what's in them, and how engine specialists use them.

---

## The problem

LLMs have a **knowledge cutoff** — typically 1+ years before the engine's current release. For Godot:

| Version | Release | LLM knows? |
|---------|---------|-----------|
| 4.3 | 2024 | Yes (training cutoff ~May 2025) |
| 4.4 | Mid 2025 | Partially |
| 4.5 | Late 2025 | **NO** |
| 4.6 | Jan 2026 | **NO** |
| **4.6.2** (this project) | 2026 | **NO** |

Same problem for Unity and Unreal. Asking the LLM to "use the latest API" produces 1-year-old code.

---

## The solution

The repo includes **version-pinned engine reference docs** at `docs/engine-reference/<engine>/`. These are curated by skills + WebSearch to capture post-cutoff API changes, breaking changes, and current best practices.

```
docs/engine-reference/
├── README.md
├── godot/
│   ├── VERSION.md                  # Pinned version + knowledge gap warnings
│   ├── breaking-changes.md         # Per-version migration notes
│   ├── current-best-practices.md   # What to do
│   ├── deprecated-apis.md          # What to avoid
│   └── modules/
│       ├── animation.md
│       ├── audio.md
│       ├── input.md
│       ├── navigation.md
│       ├── networking.md
│       ├── physics.md
│       ├── rendering.md
│       └── ui.md
├── unity/
│   ├── VERSION.md
│   ├── PLUGINS.md                  # Per-plugin reference
│   └── ...same structure as godot/...
└── unreal/
    └── ...same structure...
```

Engine specialists **must consult these** before suggesting APIs. The agents are explicitly instructed to do so.

---

## VERSION.md (the gateway)

Each engine's `VERSION.md` looks like this (Godot 4.6.2 from this project):

```markdown
# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| Engine Version | Godot 4.6.2 |
| Release Date | January 2026 (4.6), patch 4.6.2 in 2026 |
| Project Pinned | 2026-04-20 |
| Last Docs Verified | 2026-04-20 |
| LLM Knowledge Cutoff | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4, 4.5,
and 4.6 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Godot API calls.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.5→4.6 migration: ...
- Changelog: ...
```

This is the **authority** for engine choice for the project.

---

## The module docs

Each `modules/<subsystem>.md` documents one engine subsystem:

- `animation.md` — animation tree, blend trees, state machines
- `audio.md` — bus configuration, audio streams, spatial audio
- `input.md` — input map, action handlers, post-cutoff variadic args
- `navigation.md` — navigation mesh, navigation agent, post-cutoff changes
- `networking.md` — multiplayer API, ENet, WebRTC
- `physics.md` — Jolt vs GodotPhysics, physics queries, Jolt becoming default in 4.6
- `rendering.md` — Forward+ vs Mobile vs Compatibility, Vulkan/D3D12, glow rework
- `ui.md` — Control nodes, Theme system, AccessKit accessibility (4.5+)

When an engine specialist suggests an API call, they consult the matching module doc.

---

## How specialists use the reference

Example: a `godot-shader-specialist` is asked to implement an outline shader. The flow:

1. Specialist checks `docs/engine-reference/godot/modules/rendering.md` for current shader patterns
2. Checks `breaking-changes.md` for any 4.4/4.5/4.6 shader changes (yes — texture type changes in 4.4, shader baker in 4.5)
3. Checks `current-best-practices.md` for the recommended outline approach
4. Uses APIs from the post-cutoff docs, not from training data
5. Notes the version requirement in code comments

This pattern prevents 90% of "this code worked in 4.3 but not 4.6" bugs.

---

## How the docs are populated

`/setup-engine` does the initial population:

1. User picks engine + version
2. Skill writes `VERSION.md`
3. If the version is post-cutoff, skill triggers WebSearch to populate:
   - `breaking-changes.md` from official migration docs
   - `current-best-practices.md` from changelog + community sources
   - `deprecated-apis.md` from official docs
   - `modules/*.md` from official subsystem docs

**Update cadence:** annually or when the engine releases a new minor version. Re-run `/setup-engine` to refresh.

---

## What's in this project

This project pins **Godot 4.6.2**:

```
docs/engine-reference/godot/
├── VERSION.md                  ← pinned 2026-04-20
├── breaking-changes.md
├── current-best-practices.md
├── deprecated-apis.md
└── modules/
    ├── animation.md
    ├── audio.md
    ├── input.md
    ├── navigation.md
    ├── networking.md
    ├── physics.md
    ├── rendering.md
    └── ui.md
```

The Unity and Unreal directories also exist (boilerplate) but aren't actively maintained for this project.

---

## When to verify the docs are still current

- **Before a new sprint starts** if the engine version has been bumped
- **When an engine specialist's suggestions feel stale** — re-check the reference
- **When a new engine release is announced** — schedule a `/setup-engine` refresh

---

## Common pitfalls

- **Not checking the reference.** Specialists will sometimes default to training data anyway. Catch this in `/code-review`.
- **Letting the docs go stale.** A 6-month-old engine reference is barely better than no reference. Refresh when minor versions release.
- **Trusting only training data for API calls.** If an API call seems unfamiliar, check the reference.

---

## See also

- `docs/engine-reference/godot/VERSION.md` — current pin
- [[04-Agents/Engine-Specialists-Godot-Unity-Unreal]] — who uses these
- [[05-Skills/Onboarding-Skills#setup-engine]] — populates the reference
- [[07-Project-Conventions/Coding-Standards-Godot]]
