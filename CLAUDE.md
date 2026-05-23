# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6.2
- **Language**: GDScript (gameplay/UI scripting), C# (performance-critical systems), C++ via GDExtension (native only)
- **Version Control**: Git with trunk-based development
- **Build System**: .NET SDK + Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

### User-Friendly Decision Language

When asking the user for decisions — **and when communicating any
thinking, findings, analysis, options, or recommendations the user must
read in order to make a decision** — use plain English, not technical
jargon. The user is the design authority but may not be familiar with
engine-specific terms, formula notation, signal-contract vocabulary, ADR
IDs, or file-path shorthand. **The user can only make correct decisions
if they understand what is being asked. Technical jargon in your
reasoning, findings, or options blocks them from choosing correctly — so
translation is not optional.**

This rule applies equally to:

- `AskUserQuestion` widgets (every option's player-experience description)
- The thinking, findings, and analysis you write in chat replies
- Trade-off explanations, summaries, and recommendations
- Any output the user must read in order to choose between paths

The bullets below apply to **both** widgets and in-chat reasoning unless
explicitly scoped otherwise.

- **Plain English in chat replies, too (added 2026-05-02)**: The
  translate-before-asking rule applies to your in-chat thinking and
  findings, not just widget options. If your reply contains terms like
  "Rule 9", "F1's clamp", "tk_prep_floor", "ADR-0003", "geometry_baked
  signal", or `signal-contract violation` without a plain-English gloss,
  the user cannot judge it and cannot decide. Lead with what the player
  or product experiences; reference the technical name in parentheses or
  a follow-up line if needed for the audit trail. The chat reply is part
  of the decision interface, not just the widget.
- **Translate before asking**: Rephrase technical issues as player-facing
  or product-facing decisions. Example: instead of "Should `tk_prep_floor`
  be removed from F1's clamp?", ask "Should the prep phase always wait at
  least 45 seconds even when the player presses Ready immediately?"
- **Surface the trade-off, not the implementation**: Explain what each
  choice means for the player or the project, not what code changes it
  requires.
- **Every option must say what the player sees, hears, does, or feels
  (added 2026-05-01)**: Every option's description in `AskUserQuestion`
  MUST explicitly include player-experience language — "the player sees
  X", "the player can Y", "the player will feel Z", or "the player sees
  nothing — this is bookkeeping". An option that describes only what the
  system stores, what the document records, or what the architecture
  changes — without saying what the human at the keyboard experiences —
  is incomplete and the widget must be revised before sending. Silent
  absence of player-experience language reads as inscrutable jargon to
  the user even when each individual word is plain. **If the genuine
  answer is "the player sees nothing right now," say that out loud** —
  that is itself a valid and honest description.
- **After the user replies — preserve the round trip (mandatory)**:
  Convert their plain-English decision back into the technical terms the
  downstream process needs (GDD edits, ADR updates, AC rewrites, story
  files, code comments, session logs, registry entries). **Always
  include the user's original plain-English response verbatim as a
  quoted rationale, comment, or rationale field alongside the technical
  translation**, so the audit trail captures both layers. This is
  non-negotiable regardless of destination — the technical version is
  what tooling and downstream agents read, the plain-English version is
  what humans return to when context is lost weeks or months later.

This rule applies to all skills, all agents, all closing widgets, **and
all in-chat communication where the user must understand something in
order to act on it**.

#### Required `AskUserQuestion` widget format (enforced by hook, added 2026-05-23)

Every option's `description` field in an `AskUserQuestion` widget MUST contain
BOTH of these markers, or the call is hard-blocked by
`.claude/hooks/validate-ask-user-question.sh`:

1. **Plain-English marker** — one of:
   - `What you'll experience` / `What you will experience`
   - `The player sees / hears / feels / will / can / won't`
2. **Technical marker** — the word `Technical` (typically as a `**Technical:**`
   subsection containing the jargon, file paths, ADR IDs, or variable names)

**Canonical option format:**

```markdown
**What you'll experience:** <plain-English description — what the player
sees, hears, feels, or what changes visibly. "The player sees nothing —
this is bookkeeping" is a valid and honest description.>

**Technical:** <jargon, file paths, ADR IDs, variable names,
signal-contract terms — the audit-trail layer.>
```

**Why both, always, in every option:** This preserves the user's plain-English
understanding (so they can decide correctly) AND keeps the technical
translation in the widget itself (so downstream agents, session logs, and audit
trails don't lose it). The widget becomes the audit record — no separate
"round-trip translation" step required.

**If the hook blocks a widget**, the error message names which options are
missing which marker. Rewrite those options in the dual-content format and
retry the call.

**Example pairs (anti-pattern → corrected):**

- ❌ "Approve Section F (Dependencies)? Maps upstream (engine + 1 system + 4 ADRs)…"
- ✅ "Approve the dependency map? **The player sees nothing different from
  this approval** — it's a record-keeping step that prevents this design
  doc from contradicting other docs we'll write later."
- ❌ "`cell_size_px = 64`. Bake budget ~6-10 outline vertices…"
- ✅ "Make one grid square 64 pixels wide. **The player will see** zombies
  about thumb-sized on screen, two lanes filling about two-thirds of
  their screen, and walls sized to match."
- ❌ "Approve Section G (Tuning Knobs)? Eight Lane/Map-owned knobs…"
- ✅ "Lock the list of values designers can adjust later? **The player
  won't see any change today** — but if zombies feel too fast or lanes
  too cramped in playtests later, this list tells the designers which
  numbers they're allowed to tweak to fix it."
- ❌ (in-chat findings reply) "ADR-0002 (crowd-pathfinding) imposes a
  flow-field recompute boundary that conflicts with Rule 9 of
  lane-map-system.md. Recommend revising Rule 9 or marking ADR-0002
  stale."
- ✅ (in-chat findings reply) "Heads-up before we keep going: an earlier
  decision about how zombies pick their path doesn't quite line up with
  one of the lane rules we just wrote. **What the player would feel** is
  zombies occasionally recalculating their route mid-lane, which could
  look like a small stutter. **Two ways forward**: (a) change the lane
  rule so a zombie commits to its path once it enters; (b) revisit the
  pathfinding decision. Which do you want to dig into first? *(Audit
  trail: option (a) edits Rule 9 of lane-map-system.md; option (b) marks
  ADR-0002 stale.)*"

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
