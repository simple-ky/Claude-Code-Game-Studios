# Game Concept: Last Stand: Champions

_Created: 2026-04-22_
_Status: Draft_

---

## Elevator Pitch

> A top-down hero-defense roguelite where you pick a Champion with unique
> abilities, deploy a customizable squad of AI survivors as your "towers,"
> and defend humanity's last outpost against endless zombie hordes — your
> hero, your squad, your build, every run.

---

## Core Identity

| Aspect                | Detail                                                                                                       |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Genre**             | Top-down hero-defense roguelite (TD + hero-shooter hybrid)                                                   |
| **Platform**          | PC (Steam / itch)                                                                                            |
| **Target Audience**   | Roguelite + horde-defense players: fans of Gunfire Reborn, Vampire Survivors, Orcs Must Die!, Risk of Rain 2 |
| **Player Count**      | Single-player (V1). Co-op deferred to post-launch if architecture permits.                                   |
| **Session Length**    | 30-60 min per run; 10-wave structure with natural stopping point on run end                                  |
| **Monetization**      | Premium one-time purchase                                                                                    |
| **Estimated Scope**   | Large (12-18 months to V1, solo first-time dev)                                                              |
| **Comparable Titles** | Orcs Must Die! 3, Gunfire Reborn, Dungeon Defenders, Rogue Tower                                             |

---

## Core Fantasy

You are the commander of humanity's last outpost — the one hero who still
has a name, a face, and a reason to keep fighting. The horde is endless.
Everyone else is gone. But you have a squad, a signature weapon, and a
handful of skills no one else can use.

Every run is the story of a different last stand. Pick a different Champion,
and the story changes: a sharpshooter who slows time; an engineer who
turns zombie corpses into turrets; a medic who leads a pack of loyal
survivor-dogs; a berserker who heals by killing. Same apocalypse. Same
outpost. Wildly different experience.

The fantasy is not "survive the apocalypse." It's **"be the Champion who
defines this run's apocalypse."**

---

## Unique Hook

**"It's like Orcs Must Die! — AND ALSO — every Champion fundamentally
changes how the game plays, not just which numbers are bigger."**

Most TD-roguelites differentiate runs through _cards and upgrades_.
_Last Stand: Champions_ differentiates at a deeper level: the **Champion
pick itself reshapes the moment-to-moment feel of combat**, the pacing of
wave prep, and the kind of builds that make sense. A run with the
sharpshooter Champion plays like a tactical shooter. A run with the
engineer plays like a pure TD. A run with the berserker plays like
Vampire Survivors.

This is Hades' "weapon = game mode" principle applied to a top-down TD.
The card-roll system sits _on top of_ Champion identity, not as a
replacement for it.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic                                    | Priority        | How We Deliver It                                                                            |
| -------------------------------------------- | --------------- | -------------------------------------------------------------------------------------------- |
| **Sensation** (sensory pleasure)             | 3               | Neon-noir pixel art, juicy hit-feedback (screen shake, gibs, hit-stop), layered combat audio |
| **Fantasy** (make-believe, role-playing)     | 4               | "Last human commander" fantasy; each Champion is a distinct identity                         |
| **Narrative** (drama, story arc)             | 7               | Light lore through loading cards, Champion backstories, environmental detail — no cutscenes  |
| **Challenge** (obstacle course, mastery)     | 5               | Scalable difficulty via wave composition; mastery through build understanding, not reflexes  |
| **Fellowship** (social connection)           | N/A             | Solo-only in V1. Leaderboards (local) provide observational community.                       |
| **Discovery** (exploration, secrets)         | 6               | Card-combo discovery, Champion unlocks, hidden build synergies                               |
| **Expression** (self-expression, creativity) | **1 (primary)** | Champion pick + card-roll combos create "my run" identity every session                      |
| **Submission** (relaxation, comfort zone)    | 2               | Run structure is comforting and repeatable; low-stress death, quick restart                  |

### Key Dynamics (Emergent player behaviors)

- Players will **experiment with Champion × card combinations** to discover unexpected synergies ("what if I stack fire cards on the cryo-sharpshooter?")
- Players will **develop personal Champion preferences** ("I'm a medic main") — creating identity through taste
- Players will **share build discoveries** — streamers/content creators naturally showcase unusual combos
- Players will **rerun the same Champion with different card strategies** to feel their growing mastery without unlocking more content
- Players will **pick Champions based on mood**, not just optimization — because each Champion feels like a different game

### Core Mechanics (Systems we build)

1. **Champion-driven combat** — Each Champion has a signature weapon, a unique active skill, a unique passive, and distinct feel (fire rate, movement, VFX). 4 Champions at V1.
2. **Roguelite card-rolls between waves** — Between each wave the player picks from 3 rolled cards (stat boosts, synergies, new weapon variants, ability modifiers). Cards interact with Champion kits.
3. **Placeable AI squad units** — Between waves the player spends resources placing survivor-towers (rifleman, engineer drone, trap, barricade). Units act autonomously during waves.
4. **Wave-based horde escalation** — 10 waves per run, each with a designed zombie-type composition. Difficulty scales through _composition_ (more lane pressure, tougher specials), never HP inflation.
5. **Meta-progression unlocks (variety, not power)** — Between runs, meta-currency unlocks new Champions, new cards into the global pool, new maps, and cosmetic titles. Never numerical power boosts.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need                                      | How This Game Satisfies It                                                                               | Strength    |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------- | ----------- |
| **Autonomy** (freedom, meaningful choice) | Champion pick, card-roll selection, placement decisions, build direction. Every choice reshapes the run. | **Core**    |
| **Competence** (mastery, skill growth)    | Low skill floor (aim + click). Ceiling through build knowledge and wave management, not reflexes.        | **Core**    |
| **Relatedness** (connection, belonging)   | Solo-first. Leaderboards (local) + community sharing via streamers. No direct social features in V1.     | **Minimal** |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — **Primary.** Champion unlocks, wave clears, mastery tracks, cosmetic unlocks.
- [x] **Explorers** (discovery, understanding systems, finding secrets) — **Primary.** Every Champion × card combination is a discovery; build synergies reward system-thinking.
- [ ] **Socializers** (relationships, cooperation, community) — **Low.** No guilds, chat, or co-op in V1. Streaming/community is observational only.
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — **Low.** Leaderboards exist but are not central; no direct PvP.

### Flow State Design

- **Onboarding curve**: First run = forced Champion 1 (the most readable kit). Tutorial teaches movement, shooting, placement, card-roll — all in a scripted 3-wave practice run.
- **Difficulty scaling**: Runs auto-scale through wave composition. Optional difficulty modifiers unlock after first win (not hidden behind skill-gates).
- **Feedback clarity**: Kill numbers, combo streak meter, wave-clear summary screen. Every decision shows its consequence.
- **Recovery from failure**: Death always grants partial meta-currency. Restart is < 10 seconds (pick Champion, pick map, drop in). No punishment for trying.

---

## Core Loop

### Moment-to-Moment (30 seconds)

Shoot zombies with your Champion's signature weapon → reposition to avoid being surrounded → use active skill on cooldown → scan lanes for leaks → re-reinforce placements if resources allow. Streak meter builds on uninterrupted kills; losing the meter loses tempo.

Primary feedback: hit flash, gib effects, sound punch, screen shake (calibrated per Champion so each feels distinct). Every kill is visceral — "Satisfying Kills, Always."

### Short-Term (5-15 minutes)

**Wave cycle**: 30-60s prep → 2-4 min wave → 30s loot/card-roll.

- **Prep**: Spend earned resources to place/upgrade survivor units, repair walls, pick card from three rolled options.
- **Wave**: Scripted zombie composition attacks from 2-3 lanes. You fight live; units fire autonomously.
- **Loot/card-roll**: Rewards drop based on wave performance. Cards chosen from 3 rolled options — each reshapes your build mid-run.

The "one more wave" hook: next card roll always gets slightly better if you survive clean, creating forward pull.

### Session-Level (30-60 minutes)

A full run is **10 waves**:

- **Waves 1-3**: Establish build direction, drop first units, learn Champion cooldowns.
- **Waves 4-6**: Complication waves introduce new zombie types and first map hazard shift. Mini-boss at wave 5 creates a memorable mid-run peak.
- **Waves 7-9**: Apex waves — screen-filling pressure, rare card drops, forced build decisions.
- **Wave 10**: Boss fight. Survive → victory run. Die → defeat run. Both grant partial meta-currency.

Runs end with a clear stopping point AND a progression reward. Player can meaningfully quit or start another.

### Long-Term Progression

- **Champion unlocks** (4 total in V1): Run completions unlock Champions 2-4. Each unlock is ~2-4 hours of play apart.
- **Card pool expansion**: Meta-currency buys new cards into the global pool. Future runs can roll them. Encourages diverse runs.
- **Map unlocks** (3 total in V1): Unlocked through Champion mastery.
- **Per-Champion mastery track**: Cosmetic-only rewards (titles, color variants, portraits). No power creep — Pillar-mandated.
- **Daily/weekly seeded runs** (stretch): Same seed, same waves, leaderboard ranking.

### Retention Hooks

- **Curiosity**: "What does Champion 4 play like?" "What if I stack these cards?" "Can I beat wave 10 with the medic?"
- **Investment**: Meta-currency earned every run. Per-Champion mastery progress is visible. Unlocks are always close.
- **Social**: None in V1. Community forms externally through streamers and discussion.
- **Mastery**: Higher difficulty modifiers unlocked after first win. Build knowledge deepens; reflexes don't need to.

---

## Game Pillars

### Pillar 1: Every Champion Plays a Different Game

The choice of Champion must fundamentally change how a run _feels_, not
just which numbers scale. Combat rhythm, pacing, and strategy all shift
when the player picks a different Champion.

_Design test_: If a proposed mechanic would push all Champions toward the
same rhythm, reject it. If it amplifies Champion divergence, accept it.

### Pillar 2: Satisfying Kills, Always

Every zombie death is visceral — gibs, hit-flash, screen shake, sound
punch. No kill is ever "dry." Difficulty never trades juice for challenge.

_Design test_: When a feature competes with kill-feel polish for budget,
kill-feel wins.

### Pillar 3: Build Variety Beats Build Depth

The fun is in unlocking new _combinations_ each run, not in mastering the
deepest optimization of a known build. Breadth over depth in card and
skill systems.

_Design test_: Between two card systems, choose the one with more
combinatorial outcomes, not the one with higher individual power ceiling.

### Pillar 4: Low Skill Floor, High Expression Ceiling

Anyone who can aim and click should have fun on run 1. Mastery comes from
build creativity and system understanding, not mechanical skill.

_Design test_: If a system demands reflexes to engage with, it must be
assist-able or optional. The Champion-pick and build-roll layer stays
always-accessible.

### Anti-Pillars (What This Game Is NOT)

- **NOT a grind/power-creep economy**: Meta-progression unlocks _variety_ (Champions, cards into the pool), never _power_ (numerically stronger baselines). _Why: would compromise Pillar 3._
- **NOT twitch-skill-gated**: No frame-perfect dodges, no aim-check bosses, no parry-timing encounters. _Why: would compromise Pillar 4._
- **NOT difficulty-through-HP-inflation**: Harder waves come from composition (lane pressure, specials), not bullet-sponges. _Why: would compromise Pillar 2._
- **NOT a stat-variant roster**: No "Champion A but +10% fire rate." Each Champion has a unique mechanic or resource. _Why: would compromise Pillar 1._

---

## Visual Identity Anchor

_The single visual rule that every asset in this game must follow. This
section is the seed of the art bible._

### Direction: Neon-Noir Pixel Apocalypse

**One-line visual rule**: _"Muted world, neon threat."_ Every pixel is
deliberate; the palette is limited; only gameplay-critical things glow.

### Supporting Visual Principles

**Principle 1: Limited palette, neon reserved**

- Environment uses desaturated grays, browns, and deep blues (~#2A2E33 base).
- Hot neon (pink/cyan/yellow) is reserved exclusively for player abilities, threats, and loot.
- _Design test_: If a non-gameplay element is neon, it's wrong.

**Principle 2: Silhouette-first enemy design**

- Zombies are readable at any zoom by silhouette alone. Color is secondary.
- Champions are instantly distinguishable from each other by silhouette.
- _Design test_: Grayscale the screen — can you still tell everything apart?

**Principle 3: Pixel-art with dynamic lighting**

- Stylized pixel art, not realistic. Dynamic shadows from muzzle flashes, torches, and ability VFX define space.
- Lighting does the heavy mood work the palette intentionally holds back.

### Color Philosophy Summary

- **Environment**: Desaturated grays/browns/deep blues. Worn, lived-in, post-apocalyptic.
- **Champion signature colors**: Each Champion gets a distinct high-contrast color for their VFX, UI accents, and readable presence on screen.
- **Threat colors**: Hot neon pink/cyan/red for danger indicators (special zombie tells, charge attacks, boss telegraphs).
- **Loot / reward colors**: Hot yellow/gold. Always pops against the muted world.

### References

- Hotline Miami (palette discipline, muzzle flash lighting)
- Hyper Light Drifter (silhouette-first design, neon restraint)
- Nuclear Throne (readable chaos)

---

## Inspiration and References

| Reference             | What We Take From It                                                             | What We Do Differently                                                             | Why It Matters                                                                 |
| --------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Gunfire Reborn**    | Run-based build variety via weapons + runes; satisfying feedback; retention loop | Top-down (not FPS); Champion-defined playstyles (not just weapon swaps); TD hybrid | Validates the card-roll-between-waves retention pattern at a proven scale      |
| **League of Legends** | Hero-identity design — each Champion is a distinct playstyle, not a stat variant | Roguelite run-based (not PvP); 4 Champions (not 160); AI allies (not players)      | Validates that "pick-a-Champion = pick-a-game" is deeply replayable            |
| **World War Z**       | Visceral horde-killing satisfaction; horde as spectacle                          | Top-down (not TPS); tower-defense framing; Champion abilities                      | Validates the "satisfying mass kill" core sensation with a mainstream audience |
| **Orcs Must Die! 3**  | Hybrid TD + hero combat; placement + live fighting balance                       | Roguelite structure (run-based, card-driven); zombie theme                         | Validates the hybrid-TD feel we're targeting for our 50/50 mix                 |
| **Hades**             | "Weapon = game mode" principle (each weapon reshapes combat)                     | Applied to Champions in a TD context; no narrative-layer meta                      | Validates that high per-Champion authoring cost pays off in replayability      |
| **Vampire Survivors** | Satisfaction of mass kills; run pacing escalation; meta-unlock drip              | Player has aim and skill-use (not auto-fire); Champion identity (not build-only)   | Validates that pixel art + horde satisfaction is a mainstream appetite         |

**Non-game inspirations**:

- _Train to Busan_ (2016) — relentless horde pacing, ordinary-person-becomes-hero tonality.
- _Mad Max: Fury Road_ — neon-in-wasteland color discipline.
- _28 Days Later_ — urgency and silence, broken by chaos.

---

## Target Player Profile

| Attribute                     | Detail                                                                                                                                                              |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Age range**                 | 18-35                                                                                                                                                               |
| **Gaming experience**         | Mid-core. Plays multiple games per year, knows roguelite conventions.                                                                                               |
| **Time availability**         | 30-60 minute sessions on weeknights; longer weekend runs. Can be episodic — picking up between runs is seamless.                                                    |
| **Platform preference**       | PC primary; Steam Deck as secondary (game should be Deck-verified-friendly).                                                                                        |
| **Current games they play**   | Gunfire Reborn, Vampire Survivors, Risk of Rain 2, Orcs Must Die! 3, Dead Cells, Hades                                                                              |
| **What they're looking for**  | Roguelite replayability with a stronger _identity_ hook than "procedurally rolled builds on an anonymous character." Wants a distinct Champion-fantasy in each run. |
| **What would turn them away** | Grind-heavy meta-progression, skill-gated bosses, anemic hit-feedback, stat-variant characters, pay-to-unlock Champions, repetitive zombie-horde pacing.            |

---

## Technical Considerations

| Consideration                | Assessment                                                                                                                                                                                                                                                                                                                              |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Recommended Engine**       | **Godot 4.6.2** (already pinned). Excellent 2D pipeline, native pixel art support, GDScript productivity for solo dev, free and royalty-free.                                                                                                                                                                                           |
| **Key Technical Challenges** | (1) Crowd pathfinding and AI at 100+ zombies at 60fps. (2) Juice pipeline (hit-stop, screen-shake, particles, sound layering) as a reusable system. (3) Per-Champion balance + feel differentiation without exploding code complexity. (4) Robust save/load for meta-progression. (5) Card-combo balance (combinatorial test coverage). |
| **Art Style**                | 2D pixel art with dynamic lighting (Neon-Noir Pixel Apocalypse).                                                                                                                                                                                                                                                                        |
| **Art Pipeline Complexity**  | **Low-to-Medium.** Pixel art is the most forgiving 2D pipeline for a solo first-time dev. Dynamic lighting + VFX add moderate complexity.                                                                                                                                                                                               |
| **Audio Needs**              | Moderate. 1 main theme + 3-4 combat tracks + boss theme + ambient tracks. SFX library must support layered hit-feedback (Pillar 2).                                                                                                                                                                                                     |
| **Networking**               | None in V1. Architecture should not preclude local co-op as a future addition but should not be designed for netcode either.                                                                                                                                                                                                            |
| **Content Volume**           | V1 target: 4 Champions, 8-10 zombie types, 60-80 cards, 3 maps, 6-8 placeable tower types, 2 bosses. 20-40 hours of content to "see most of it."                                                                                                                                                                                        |
| **Procedural Systems**       | Wave-composition variation within designed encounters (limited randomness). Card-roll randomization. Map layouts are hand-crafted, not procedural.                                                                                                                                                                                      |

---

## Risks and Open Questions

### Design Risks

- **Champion differentiation cost is the whole game's hinge**: Pillar 1 demands each Champion play distinctly. Making 4 Champions feel wildly different without balance-breaking is the #1 creative challenge. Some Champions will go through 3-4 redesigns — this must be planned for, not treated as a slip.
- **First-run retention**: Roguelites live or die on minutes 1-30. New players must experience build expression before their first death or churn is high. The first Champion's tutorial run must show off the card-roll transformation clearly.
- **Difficulty curve without skill-gating**: Pillar 4 forbids reflex-gates, but players still need growth feeling. Difficulty must come from _build complexity handling_ (more cards, more synergies to manage), not harder aim.
- **Scope creep on Champion count**: The pressure to ship 6-8 Champions will be strong. 4 Champions done well > 8 done shallowly. Defend the roster size.

### Technical Risks

- **Godot 4.6 crowd AI performance**: 100+ zombies on screen with pathfinding is feasible but not automatic. Flow-field or shared pathing architecture should be prototyped early.
- **Juice pipeline as afterthought**: Pillar 2 requires systematic hit-feedback (hit-stop, screen-shake, particles, sound layers). If this is built per-weapon, it becomes unmaintainable. Build as a reusable system from day 1.
- **Save system robustness**: Roguelite meta-progression needs durable persistence. Corrupted saves kill retention. Invest in save versioning and recovery early.
- **Card-combo combinatorial testing**: 60-80 cards = thousands of combos. Manual testing alone won't cover broken synergies. Plan automated simulation tests for balance.

### Market Risks

- **Roguelite genre saturation**: "Why this one?" is a live question. Differentiation depends on nailing Pillar 1 (Champion-as-playstyle) and marketing it clearly — each Champion in the trailer must feel visibly different.
- **TD-roguelite is a smaller niche than pure roguelite**: Market validation exists (Orcs Must Die! 3, Rogue Tower, Dungeon Defenders), but audience is narrower than Vampire Survivors-likes.
- **Solo first-time dev market challenge**: Wishlisting and discoverability require deliberate marketing. Budget time for devlog presence, community-building, and Steam store page.

### Scope Risks

- **"Mix by Champion" is the most expensive action-feel choice**: Each Champion needs distinct combat feel, animations, VFX, balance tuning. This is the primary scope driver. Defend the Champion count (4) against expansion.
- **Card balance tail-end cost**: As cards approach 80, balance regressions compound. Budget 2-3 months of pure balance work in the Tier 1 timeline.
- **Single-developer bus factor**: Solo dev = zero redundancy. A 2-week illness is 2 weeks of project delay. Plan buffer.

### Open Questions

1. **How many waves per run feels right for the target session length?** — Current assumption: 10 waves, 30-60 min. Resolve in prototype.
2. **Does the card-roll frequency (every wave) overwhelm players during the action phase?** — Current assumption: 1 card-roll per wave. Resolve through playtesting; may reduce to every 2 waves.
3. **Is one active ability + one passive enough per Champion, or do we need more kit depth?** — Compare LoL's 4-ability model vs Hades' single-weapon-with-aspects model. Resolve in prototype through player feedback.
4. **Placeable tower count per run — how many is too many to manage?** — Decision fatigue vs. expression. Likely 3-6 placements per run maximum; resolve in prototype.
5. **How much meta-progression is enough for Achievers without violating "no power creep"?** — Test cosmetic-only unlocks vs. card-pool-expansion feel; may need A/B on Champion unlock cadence.

---

## MVP Definition

**Core hypothesis**: _Players find the Champion × card-roll × horde-defense
loop compelling enough to complete multiple runs in a session and return
for more runs the next day._

The MVP answers one binary question: **is the core loop fun?**

### Required for MVP

1. **2 Champions, dramatically distinct in feel** — proves Pillar 1 is achievable in practice.
2. **20 cards** — enough combinations to feel build variety on a single-Champion repeat session.
3. **1 map with 2 lanes** — proves placement + wave design on a minimal canvas.
4. **5 zombie types** (basic, runner, tank, charger, swarmer) — enough composition variety to make wave design matter.
5. **5-wave runs** — shorter than V1 so the MVP produces runs in ~10-15 minutes for rapid playtest iteration.
6. **Core juice pipeline** (hit-stop, screen-shake, particles, sound) — proves Pillar 2 as a reusable system.
7. **Functional card-roll between waves** — proves the retention hook.

### Explicitly NOT in MVP (defer to later)

- Meta-progression (unlocks)
- Bosses
- Map variety (2nd and 3rd maps)
- Cards 21-80
- Champions 3 and 4
- Cosmetic unlocks
- Leaderboards
- Tutorial scripting (MVP uses a dev tutorial prompt overlay only)
- Accessibility pass (keep keybinds sensible; full pass at Alpha)
- Audio polish (placeholder SFX fine at MVP)

### Scope Tiers (if budget/time shrinks)

| Tier                               | Content                                                                                     | Features                                                                                                                          | Timeline                                   |
| ---------------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| **Tier 0 — MVP**                   | 2 Champions, 1 map, 20 cards, 5 zombie types                                                | Core loop only, 5-wave runs, no meta-progression, no bosses, placeholder art                                                      | 3-4 months                                 |
| **Tier 1 — V1 Launch Target**      | 4 Champions, 3 maps, 60-80 cards, 8-10 zombie types, 2 bosses                               | 10-wave runs, meta-progression (Champions + cards), local leaderboards, full Neon-Noir Pixel Apocalypse art pass, full audio pass | 12-18 months                               |
| **Tier 2 — Stretch / Post-Launch** | 5th-6th Champion, 4th map, 3rd boss, daily/weekly seeded runs                               | Accessibility pass, cosmetic unlocks expansion, localization                                                                      | 18-24 months (or post-launch update cycle) |
| **Tier 3 — Long-term**             | Local co-op (only if architecture was co-op-ready from day 1, else becomes its own project) | Co-op-aware balance retune                                                                                                        | Post-launch, major update                  |

**Cut list (if Tier 1 runs long):**

1. Cosmetic unlocks (keep only Champion + card-pool unlocks)
2. Local leaderboards (defer to post-launch)
3. Fourth Champion (ship 3 instead of 4)
4. Third map (ship 2 instead of 3)
5. Second boss (ship 1 boss at wave 10 only)

---

## Next Steps

- [ ] Validate concept completeness with `/design-review design/gdd/game-concept.md`
- [ ] Engine is already configured (Godot 4.6.2 pinned in `docs/engine-reference/godot/VERSION.md`); run `/setup-engine` only if reference docs need a refresh
- [ ] Author the full visual identity specification with `/art-bible` (seeded by the Visual Identity Anchor above)
- [ ] Decompose the concept into systems with `/map-systems`
- [ ] Author per-system GDDs in dependency order with `/design-system [system]`
- [ ] Plan technical architecture with `/create-architecture`
- [ ] Record key architectural decisions with `/architecture-decision`
- [ ] Validate readiness for production with `/gate-check pre-production`
- [ ] Prototype the riskiest system first with `/prototype core-combat-loop`
- [ ] Validate prototype with `/playtest-report`
- [ ] Plan the first sprint with `/sprint-plan new`
