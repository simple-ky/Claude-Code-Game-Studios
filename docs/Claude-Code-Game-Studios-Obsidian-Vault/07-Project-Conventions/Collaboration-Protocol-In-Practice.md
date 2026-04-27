---
title: Collaboration Protocol — In Practice
tags: [conventions, protocol, collaboration]
---

# Collaboration Protocol — In Practice

Concrete examples of [[02-Core-Concepts/Collaboration-Protocol]] in action. Use this as a reference when an agent's behavior surprises you.

---

## The five steps, quick reference

1. **Question** — Agent surfaces what it needs
2. **Options** — Agent presents alternatives with trade-offs
3. **Decision** — User picks
4. **Draft** — Agent shows the draft
5. **Approval** — User says yes (or asks for change)

Skipping any step shifts authority from user to agent. Don't let it.

---

## Example 1: GDD authoring

### What you'd see

```
Agent (game-designer via /design-system): I'm authoring the Combat GDD.
Section 1 — Overview. I'd like to know:

  Q: What's the role of crits in combat?
  Options:
    A) Frequent (every 3-5 hits) — keeps damage feel exciting but less
       strategic
    B) Rare (1 in 20 hits) — strategic moments, but most attacks feel
       homogeneous
    C) Skill-based (e.g. timing, targeting weak points) — adds
       mechanical depth, more code complexity

  Which fits your vision?

You: B, with weak-point bonuses on top

Agent: Got it. Drafting the Overview section...

[draft of section 1]

May I write this as section 1 of design/gdd/combat.md?

You: Approved.

Agent: Writing section 1.
```

The Question, Options, Decision, Draft, Approval are visible at every level.

---

## Example 2: Multi-file refactor

```
Agent (lead-programmer via /code-review): I see an opportunity to refactor
the damage path. Three files would change:

  - src/gameplay/combat/damage_service.cs (extract pure function)
  - src/gameplay/combat/attack_handler.gd (call signature change)
  - tests/unit/combat/damage_service_test.cs (test refactor for new
    function)

Diff for damage_service.cs (the most impactful):

[diff]

May I make all three edits?

You: Approve damage_service.cs change. Hold on the other two until I
review the diff.

Agent: Approved scope: damage_service.cs only. Showing diffs for the
other two now without applying.

[diffs of the other two]

Apply these too?

You: Yes for attack_handler.gd. Skip the test refactor — I want to write
that one.

Agent: Applying attack_handler.gd. Skipping test refactor.
```

Note how scope was tightened twice. The agent re-asked for each expansion.

---

## Example 3: Disagreement between agents

```
Agent (orchestrating /design-system damage):

  game-designer: "Damage should scale with weapon weight (heavier =
  more damage but slower)."

  systems-designer: "That makes the formula non-monotonic; players who
  swing fast still need viable options."

  Two perspectives:
    A) game-designer's view (weight-based, simpler)
    B) systems-designer's view (independent stats, more configurable)

  This is a design decision. Which direction?

You: I want both effects, but as independent stats. Damage stat AND
weight stat per weapon.

Agent: Both agents now aligned. Drafting Section 4 (Formulas) with
weapon.damage and weapon.weight as independent variables...
```

The orchestrator surfaced the disagreement instead of choosing silently.

---

## Example 4: Read-only agent (no protocol)

```
Agent (via /sprint-status — Haiku tier, read-only):

Sprint 3 — Day 6 / 14
Stories: 8 total, 3 done, 2 in-progress, 3 ready
Blockers: 1 (sprint-3/combat-hitbox.md — waiting on ADR-008)
Burndown: tracking 12% behind plan
```

No Question/Options/Decision because nothing is being written. Read-only operations skip the protocol.

---

## Example 5: When the user is terse

The protocol doesn't require verbose user responses. All of these are valid:

```
You: yes
You: ok
You: A
You: change "frequent" to "very frequent"
You: skip section 5
You: stop, I want to refocus
```

The agent's job is to make the **opportunity** to intervene clear, not to demand a long response.

---

## Common pitfalls (and what to do)

### Pitfall: Agent jumps to writing

```
Agent: I'll create design/gdd/combat.md with sections...

[ writes file ]
```

**Bad.** No Draft, no Approval. Stop the agent and say *"Show me the draft first."*

### Pitfall: Agent presents one option as a foregone conclusion

```
Agent: For the damage formula, I'll use linear scaling because it's
standard. Drafting now.
```

**Bad.** Should be Options + Decision. Say *"What were the alternatives?"*

### Pitfall: User's approval scope unclear

```
Agent: May I write these three files?
You: Sure
```

Did "sure" approve all three? Both sides should be precise:

```
Agent: I'll create three files: A.md, B.md, C.md. May I create A first
and show you the draft of B before creating it?
You: Yes — create A. Show B's draft.
```

### Pitfall: User says "just do it"

```
You: Just do it, you don't need to ask every time

Agent: Acknowledged. I'll skip approval for trivial section drafts but
still ask before creating new files or making destructive changes.
```

The protocol can be relaxed by the user, but the agent should keep boundaries on **destructive** or **scope-expanding** actions.

---

## When to invoke the protocol explicitly

Sometimes you need to remind an agent of the protocol:

- "Show me the draft before writing"
- "What were the other options you considered?"
- "Only edit file X, not anything else"
- "Stop and let me think"

These are valid interventions. Agents should respond to them without resistance.

---

## See also

- [[02-Core-Concepts/Collaboration-Protocol]] — the principle
- [[02-Core-Concepts/Skills-vs-Agents-vs-Docs]] — where it applies
- `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` — the original protocol doc
- `.claude/docs/templates/collaborative-protocols/` — per-agent-type protocols
