# Art Bible: Last Stand: Champions

*Created: 2026-04-23*
*Status: Complete — 9 sections authored 2026-04-23*
*Primary direction: Propaganda Poster Apocalypse (D2)*
*Documented fallback: Neon-Noir Pixel Apocalypse (activates if month-1 palette-swap shader prototype fails)*

> **Art Director Sign-Off (AD-ART-BIBLE)**: Skipped — review mode is `lean`. Not a PHASE-GATE in this mode.

> **Next dependency gate**: Month-1 palette-swap shader prototype (see Section 1 Fallback Clause).

---

## 1. Visual Identity Statement

### Direction: Propaganda Poster Apocalypse

**One-line visual rule**: *"Every frame of this game looks like a wartime propaganda poster found in the rubble — bold shapes, flat color fills, heroic scale, and nothing soft."*

This is the **single rule** that resolves any future visual ambiguity on the project. When in doubt, ask: *would this image work as a printed propaganda poster?* If yes, the choice is aligned.

### Supporting Visual Principles

#### Principle 1 — Flat color fills with hard ink outlines, zero gradients

Every visible element — environment, characters, VFX, UI — uses flat opaque color fills with consistent hard outlines (2–3 px at standard zoom). No gradients. No ambient occlusion. No soft shadows. Lighting mood is communicated through deliberate color choices on tiles, not through a lighting pass.

- **Design test**: If an element has a gradient, remove it and replace with two adjacent flat tones. If it still reads, the flat version is correct.
- **Pillar served**: **Pillar 2 — Satisfying Kills, Always.** Flat art is the best substrate for VFX contrast. Particle systems, gib clouds, and hit-flashes become the only source of visual softness and motion on screen, so every kill effect reads dramatically louder than the entire environment.

#### Principle 2 — A restricted four-color map palette, rotated per Champion

Each Champion run uses a four-color base palette for the environment (e.g. deep navy / cream / brick red / black for one Champion; desaturated teal / bone / rust / ink for another). When the player picks a different Champion, the environment palette *shifts* — the whole world's color temperature changes, not just the Champion's VFX. Same map geometry, different color story per run.

- **Design test**: When ambiguous about an environment color, find its equivalent hue in the current Champion's assigned palette. Never pull a color from outside the active four.
- **Pillar served**: **Pillar 1 — Every Champion Plays a Different Game.** This is the most aggressive visual implementation of Pillar 1 available. The visual identity of the run shifts with the Champion, not just the VFX.

#### Principle 3 — Champions drawn at heroic scale against the horde

Champion sprites are rendered 30–40 % larger than their mechanical hitbox implies, with the silhouette conventions of propaganda-poster heroism (strong stance, confident silhouette). Zombies are deliberately drawn smaller and more uniform, emphasizing the horde's anonymity. The Champion is always the visual anchor of the frame.

- **Design test**: If a Champion sprite could be confused for a survivor-unit or a zombie in a crowded frame, scale it up. The player's eye must never lose the Champion.
- **Pillar served**: **Pillar 4 — Low Skill Floor, High Expression Ceiling.** New players in a 100+ zombie crowd must never lose track of their own character. Heroic scale guarantees this at the art-direction level, not at the UI level.

### What This Direction Is NOT

- Not "neon-noir" — muted world with neon accents is a different direction. Here, every color on screen is intentional and drawn from the active palette.
- Not "realistic" — no lighting pass, no textural realism, no horror-survival register.
- Not "pixel art" in the conventional sense — resolution reads clean, not chunky; outlines are the visual signature, not pixel grids.

### Fallback Clause — Neon-Noir Pixel Apocalypse

The palette-swap-per-Champion system (Principle 2) is the primary technical risk of this direction. To de-risk, we bind the art-direction decision to a **month-1 shader prototype gate**:

**Prototype gate (end of month 1 of production)**: The palette-swap shader must demonstrate
- Swapping a 4-color environment TileMap to any of 4 defined palettes at runtime with no frame stutter.
- Working at the game's target zoom with 100+ zombie sprites rendered over it.
- Being authorable (artists can set a new palette with ≤10 min of work, not days).

**If the prototype passes**: D2 is confirmed. Proceed.

**If the prototype fails or proves production-blocking**: The project falls back to **Neon-Noir Pixel Apocalypse** (the direction from the original game-concept Visual Identity Anchor): desaturated gray/brown/deep-blue environment; hot neon reserved for player abilities, threats, and loot; silhouette-first enemy design; pixel art with dynamic lighting. References under fallback: Hotline Miami, Hyper Light Drifter, Nuclear Throne. The fallback is **not a defeat** — it is a proven genre aesthetic and the MVP can be built in it from day 1 of month 2 without wasted asset work, because both directions can share early prop and environment concepting.

**No production art is committed to D2 until the prototype gate passes.** Concept art and mood boards are fine; tileable environment assets, character sprites, and palette authoring are gated.

---

## 2. Mood & Atmosphere

### Mood Arc Across a Run

A full 10-wave run is a mood progression from **quiet ownership → white-knuckle survival → a single decisive moment → a clean emotional landing.** Because Principle 1 forbids a dynamic lighting pass, mood is carried entirely by palette choice and compositional density. Color saturation and palette temperature function as the run's pressure gauge. The Champion's 4-color palette is the throughline and is deliberately violated exactly four times across nine states, each violation earning its weight as a story beat.

### State Definitions

| # | State | Primary Emotion | Energy | Color Story | Diagnostic Visual Element |
|---|-------|-----------------|--------|-------------|---------------------------|
| 1 | **Prep Phase** | Ownership — craftsman at a known workbench, with a time limit | Measured | Champion palette in full authority at moderate saturation. Outpost center + placed units carry the warmest accent. | The outpost boundary line as an unbroken perimeter in the Champion's primary outline color — reads as "intact, mine, capable." |
| 2 | **Early Wave (1–3)** | Rhythm-finding — a musician finding the beat | Measured → Engaged | Zombies enter as near-black ink shapes. Background cools one step. Champion accent remains single most saturated cluster in frame. | **Negative space** between zombie clusters. Frame should feel sparse; if it's dense, density arrived too early. |
| 3 | **Mid Wave (4–6)** | Managed tension — holding something together that wants to come apart | Engaged | Palette cools one deliberate step. New zombie types rendered at palette's second-darkest value (visual taxonomy, not decoration). Mini-boss at wave 5 approaches Champion's scale without exceeding it. | The **mini-boss silhouette interrupting horde rhythm by scale alone** — horde shapes around it like water around stone. No palette violation yet. |
| 4 | **Apex Wave (7–9)** | Controlled chaos — pilot in a spiral with hands still on the controls | Frenetic | Horde's near-black fills majority of ground. Champion accent becomes urgent by contrast. Kill VFX is the frame's primary warmth source. Rare card drops use palette's ceiling value for single-frame flash (see Violation 4). | **Can you still instantly locate the Champion in a dense Apex frame?** If yes, Principle 3 works and mood is correct. If no, reduce horde count or increase Champion scale — do NOT adjust palette. |
| 5 | **Wave 10 Boss Fight** | Singular dread sharpening into focus — inevitability, earned | Explosive with imposed stillness between phases | **Violation 1 active.** Universal crimson on boss silhouette and attack telegraphs. Environment desaturates one extra step toward neutral. Champion accent and boss crimson are the two competing forces in frame. Horde recedes to texture. | **Boss attack telegraphs as flat crimson shapes on the ground** with hard edges, no glow. Teaches "this color means danger, move." If telegraph doesn't read against Champion palette, adjust the crimson value until it does. |
| 6 | **Victory Run-End** | Earned triumph with visible cost — soldier's photograph after the armistice, not ticker-tape | Still | **Violation 2 active.** Gold/amber above the palette's ceiling in scoring UI + Champion victory pose accent + restored outpost boundary. Environment background desaturates further toward palest neutral. Frame feels emptied-out and bright. | **The intact outpost is the first thing the eye finds** — Champion stands in front of what they defended, not a void. Composition centers on the defended thing. |
| 7 | **Defeat Run-End** | Specific, recognizable failure with no softening — quiet of a thing that has ended | Still | **Violation 3 active.** Champion accent **suppressed** (dimmed below neutral — not erased; the run still belongs to that Champion). Flat ash-gray bleeds into background, colder than anything in any Champion's palette. Outpost shown as dark or broken geometry. Frame feels heavy and compressed. | **The absent Champion accent color.** Player's eye searches for its warmth and finds nothing. If Champion accent appears at full saturation anywhere in the Defeat composition, it is wrong. |
| 8 | **Champion Select** | Identity preview — examining an unfamiliar tool, curiosity with stakes | Contemplative | Each Champion renders their full 4-color palette at maximum expression. Moving cursor between Champions changes the **entire screen's color temperature**. Neutral UI chrome uses a true neutral near-black that belongs to no Champion palette. | **The 50%-opacity overlap test:** screenshot Sharpshooter-selected and Berserker-selected, overlap at 50%. If any region reads as the same mid-gray blend, palettes are too similar and must be pushed apart. |
| 9 | **Card-Roll Screen** | Decision-weight without pressure — chess player examining a position | Contemplative | Active Champion's palette dominates. 3 cards use 3 different values from the 4-color set as backgrounds (no two share). Environment **swaps to a one-step-desaturated palette variant** (not a post-process; a flat palette variant authored for the swap system). Card hover uses palette's ceiling as flat outline stroke. | **The three cards are the only full-saturation elements in frame.** If environment competes for saturation, mood has failed. Everything else should feel like it is waiting. |

### Cross-State Contrast Rules

- **Prep → Early Wave**: transition happens the moment zombie silhouettes cross the map edge. Frame goes from balanced/geometric to not.
- **Early → Mid**: negative space narrows; palette cools; new silhouette types break horde homogeneity.
- **Mid → Apex**: negative space disappears entirely. Horde occupies the floor.
- **Apex → Boss**: the many becomes the one. Violation-crimson enters.
- **Boss → Victory**: tension releases. Crimson gone. Gold replaces it (same structural role — fifth color violation — opposite emotional register).
- **Boss → Defeat**: tension also releases but into heaviness. Ash replaces crimson.
- **Victory vs Defeat**: Victory's dominant value is the palette's **palest neutral** (bright, emptied). Defeat's dominant value is the palette's **darkest neutral** (heavy, compressed). They are visually inverse.
- **Defeat → next run's Champion Select**: the full-saturation Champion palette restored — a visible reset.

### Intentional Palette Violations

The 4-color palette is the game's primary visual contract with the player. Each violation is a load-bearing story beat. **No additional violations may be introduced without art-director approval.**

| # | Where | Color | Purpose | Authoring Rule |
|---|-------|-------|---------|----------------|
| **V1** | Boss Fight (State 5) | **Universal crimson** (deep warm near-black, distinctly red-warm at close attention) — identical across all Champion runs | Boss entity silhouette fill + attack telegraphs. Signals "this operates by different rules." | Must NOT appear in States 1–4. If the player has seen this color before wave 10, the violation has failed — audit earlier states to confirm its absence. |
| **V2** | Victory (State 6) | **Gold/amber at full saturation**, above any Champion's palette ceiling | Scoring UI + Champion victory-pose accent + intact outpost boundary. Triumph, no copy required. | Used only in State 6. Warm pole. |
| **V3** | Defeat (State 7) | **Flat ash-gray**, cooler than anything in any Champion's assigned palette | Environment background bleed + suppression of Champion accent | Champion accent is **suppressed, not replaced** — the run still belongs to that Champion, but its warmth is dimmed. |
| **V4** | Rare card drop (during Apex Wave) | **Palette's ceiling value at full saturation** — not technically a new color, but held in reserve | Single-frame brightness flash when a rare card drops | **Reserve, then spend.** The palette ceiling must not be used at full intensity in States 1–3, so when it fires in Apex Wave, it reads as the first time. |

### Cross-Direction Compatibility (Fallback Note)

These mood targets are written as *mood intentions that color execution serves*, so they remain valid under both D2 (Propaganda Poster) and the Neon-Noir Pixel fallback. Under the fallback, Violations 1–3 still apply structurally — boss gets a warm neon-red the player hasn't seen; victory gets a hot gold; defeat suppresses the Champion neon and pushes the environment further toward charcoal. The diagnostic visual elements (outpost perimeter, mini-boss scale, negative space density, absent accent) survive the direction change.

---

## 3. Shape Language

Shape discipline is palette-agnostic — every rule in this section survives the D2 / Neon-Noir fallback choice. Silhouette reads are the game's primary readability system, not color.

### 3.1 Character Silhouette Philosophy

**Core rule**: At Apex Wave density (~100 near-black zombies on ground), the player must locate their Champion by **outline shape alone** — no color, no animation, no VFX. Shape carries identity before anything else. *(Pillars 1 + 4.)*

#### Champion silhouette rules (one load-bearing trait each, must read at 32×32 px)

| Champion | Load-bearing silhouette trait |
|---|---|
| **Sharpshooter** | Long diagonal weapon line extending past body at down-right angle; narrow vertical body; cap forms flat horizontal top edge. Sprite is ~30% weapon line, 70% narrow vertical body. |
| **Engineer** | Asymmetric shoulder load (one elevated arm, one low) + a rectangular backpack protrusion on upper-right. **Only entity in the game with a hard rectangular shoulder bump.** Top edge is never symmetrical. |
| **Medic** | **Double-mass silhouette** — Champion + dog rendered as one joined form, dog always at a fixed lower-left offset. Only Champion with a curved shoulder profile. Only entity with this double-mass outline. |
| **Berserker** | Widest lateral mass of any Champion. T/Y shoulder profile with arms extended outward. Shortest-and-widest of the four. Shoulder-to-waist ratio exaggerated. |

**Cross-Champion rule**: No two Champions may share a dominant silhouette trait.

**Medic's dog companion — implementation rule (locked)**: The dog renders at a **fixed visual offset** from the Medic sprite, always in the same relative position (lower-left). This is a rendering rule, not an AI rule — the dog is part of the Medic's silhouette as far as the shape system is concerned. The AI companion behavior (pathfinding, targeting) is a separate system and must not be allowed to break the visual offset.

#### Diagnostic Test — 32×32 Silhouette Matrix

Render all four Champions as solid black fills at 32×32 px on white. Show side-by-side to someone unfamiliar with the game.
- **Pass**: Viewer describes a uniquely identifying feature for each within 10 seconds, unprompted.
- **Fail**: Any two Champions produce similar descriptors — widen the silhouette divergence.
- **Run at**: first concept pass, first sprite sheet, any weapon/stance revision.

---

### 3.2 Zombie Shape Hierarchy

**Core rule**: Zombies render as near-black ink fills (Principle 1). Silhouette and scale are their only visual distinction. The horde reads as a single mass; individual types break that mass through outline shape. *(Pillar 4 — readability is absolute.)*

#### Five base zombie silhouette rules (MVP set)

| Type | Silhouette rule | Density behavior |
|---|---|---|
| **Basic** | Baseline upright humanoid, symmetrical, no protrusions. The horde's rhythm pattern. Everything else breaks from this. | The unit of horde density |
| **Runner** | Forward-leaning 30–45° diagonal silhouette, head protruding past body center, arms trailing. | A narrow angled wedge breaking vertical rhythm |
| **Tank** | Shoulder width ≈ 2× basic. Head smaller relative to body mass, buried in shoulder line. | Boulder in a stream — horde visibly routes around it |
| **Charger** | Forward lean like runner, but with **raised forward arms** creating a wide forward-facing V at top of silhouette. | Arms break upward from horde silhouette mass |
| **Swarmer** | Notably smaller (60–70% of basic). Appears in clusters of 4–6. Individual = not a threat read; cluster IS the threat. | A granular texture field, negative-space turbulence |

**Swarmer enforcement rule (locked)**: The game engine spawns swarmers as **cluster units with cohesion behavior** — they share pathfinding and are held within a cohesion radius. The cluster only breaks when killed down to 1–2 survivors. Individual swarmer pathfinding is explicitly forbidden at the AI-design layer because it would destroy the collective silhouette the shape rules depend on. This is a cross-system rule (shape + AI); the AI programmer must honor it.

#### Special zombie break axes

Zombies 6–10 (V1 roster beyond the base five) must each break from basic rhythm by at least **one** of these axes:
1. **Scale** — larger or smaller than basic
2. **Proportion** — distorted limb/torso ratio
3. **Protrusion** — shape extending clearly past humanoid bounding box
4. **Posture** — non-upright stance (quadrupedal, curled, arms-up)

A special that doesn't break one of these is a reskin, not a valid special.

#### Scale escalation (hard tier boundaries)

| Tier | Scale vs basic | Visual contract |
|---|---|---|
| Basic horde | 1.0× | The pattern rhythm |
| Runner, Swarmer | 0.6–0.9× | Speed implied by compactness |
| Tank, Charger | 1.4–1.6× | Danger implied by mass |
| Elite variants | 1.6–2.0× | Clearly breaks horde ceiling |
| Mini-boss (wave 5) | 2.5–3.0× | Approaches Champion scale without exceeding it |
| Boss (wave 10) | 4.0–5.0× | Singular silhouette unlike any horde shape. Unique protrusion vocabulary. |

**Hard rule**: no enemy tier may reach or exceed the tier above it in scale.

#### Diagnostic Test — Horde-Strip Rhythm

Render a horizontal strip of 20 zombies: 15 basics interspersed with one of each base type. All as solid black fills at game-scale zoom.
- **Pass**: viewer locates each non-basic within 5 seconds per type by silhouette alone.
- **Secondary test (density)**: at Apex density (~80+ rendered), can you locate the tank and charger without color? If not, increase scale multiplier.

---

### 3.3 Environment Geometry Grammar

In a flat-art world with no lighting pass, **geometry is the depth cue**. *(Pillar 4.)*

| Vocabulary | Used for | Angle rules |
|---|---|---|
| **Orthogonal (primary)** | Walls, floors, tower foundations, outpost boundaries, all placed structures | 90° corners only. No curves, no diagonals. |
| **Controlled diagonal (secondary)** | Debris, fallen walls, collapsed barriers, broken windows, damaged props | Locked to **30°, 45°, or 60°** only — never arbitrary angles. |
| **Organic edge (tertiary)** | Dead trees, sand dunes, water/terrain boundaries at map edges | Only allowed element — reserved for map-edge atmospheric layer |

**Use constraint**: no more than 3 diagonal props per tile-screen's worth of geometry. Diagonal overuse destroys the built-vs-destroyed distinction.

#### Hero environment shapes (anchor the eye)

- **Outpost center structure** — geometrically most confident shape on the map; the eye's rest point between threats.
- **Boss arena set-dressing** — specific per boss; frames the boss silhouette (arena recedes orthogonal, boss dominates).
- **Lane endpoints** — recognizable chamfered/angled "mouth" shape; players recognize lane origins by shape alone.

#### Champion scale interaction rule

- No wall or prop may exceed **80% of Champion sprite height** in its tallest axis.
- No doorway or gap may be narrower than **1.5× Champion sprite width**.
- Exception: outpost center may exceed (it's always background-anchored).

#### Diagnostic Test — Geometry Triage

Grayscale a mid-game frame. Categorize:
- Orthogonals should dominate (majority of pixels).
- Diagonals sparse (≤10–15% of frame's edge lines), always clearly debris.
- Organics edge-of-screen only.

**Fail**: diagonals scattered without damage rationale, or curves on placed structures.

---

### 3.4 UI Shape Grammar

The UI does not sit in a separate register — it IS part of the propaganda-poster world. No soft drop shadows, no modern "glass," no rounded rects with gradients. *(Pillar 4.)*

#### UI shape primitives

| Primitive | Used for | Corner rule |
|---|---|---|
| **Hard-cornered rectangles** (primary) | Informational panels, health bar, wave counter, resource display | No corner radius, ever |
| **Chamfered rectangles** (interactive signal) | Ability cooldown indicators, card-roll selection boxes | Single 45° chamfer on bottom-right corner — the only permitted corner deviation |
| **Hard-outlined badges** | Champion portraits, tower-type icons, status effects | Octagon, diamond, or clipped rectangle + 2–3 px outline + flat fill + stenciled icon |
| **Stenciled icons** | All iconography | Hard-edge, no anti-aliasing, no gradient fill, no shadow. Must read at 16×16 px. |
| **Ribbon-form banners** | Wave number, boss name reveal, victory/defeat title cards | Full-width rectangle with diagonal-cut ends |

**Chamfered = interactive rule**: chamfer signals "selectable/interactive." If any non-interactive element uses a chamfer for aesthetic reasons, the convention breaks. Formal UI rule to be documented in Section 7.

#### Critical HUD element shapes

- **Health bar**: hard-cornered rectangle, drains left-to-right, notch markers at 25% / 50%. Low-health signal is a **color shift toward the Champion's coldest palette value** (not a pulse, not a glow — color change only).
- **Ability cooldown**: chamfered rectangle, fills clockwise as segmented flat color (not a radial gradient pie). On ready, outline strokes to Champion accent for one held frame.
- **Wave counter**: ribbon-form at top-center. Three segments: past (dim), current (full + accent outline), upcoming (empty outline only).
- **Card-roll**: three chamfered rectangles, each using a different value from the active Champion's 4-color palette. Card icon in top 40%, card name in ribbon inset at lower third.
- **Resource counter**: diamond badge + stenciled number. Bottom-left, lowest visual priority.

#### Diagnostic Test — Poster-Tear

Could this HUD be torn off the screen and pinned on a wall next to the game's world art and still look like it came from the same source?
- **Pass**: hard edges, flat fills, stencil aesthetics, ribbon form — same design vocabulary as world.
- **Fail**: rounded corners, drop shadows, gradients, modern-UI gloss anywhere.
- **Density secondary test**: in an Apex Wave screenshot, does UI-color-mass compete with Champion and zombie mass when blurred? If yes, reduce UI contrast or scale.

---

### 3.5 Hero Shapes vs Supporting Shapes

In flat art, visual hierarchy is not automatic — it must be **enforced by compositional rules**. *(Pillars 2 + 4.)*

#### Five recurring compositional motifs (hero shapes)

1. **Champion Against the Tide** — Champion center-frame facing the horde approach vector. The single saturated shape against an ink wall. *Construction rule*: Champion must always have negative space on at least one side (the direction they're moving toward). If negative space = 0 on all sides, density or Champion scale must be adjusted.

2. **Outpost Perimeter Line** — the continuous outline in the Champion's primary outline color that orients new players without UI prompting. *Construction rule*: the perimeter line must be the **longest continuous edge** in any Prep Phase frame.

3. **Kill Moment** — the only frame where visual softness enters the world (radial VFX, hit-flash, gib spray). *Construction rule*: VFX color pulled from Champion accent so it contrasts against both zombie ink-fill and environment; shape radially symmetric at any zoom.

4. **Lone Boss** — wave 10 transition from many-small-shapes to one-large-shape. *Construction rule*: boss's largest dimension ≥ 20% of screen width. Below this, it reads as "large zombie," not "boss."

5. **Tower Grid** — player's visual evidence that they built something. *Construction rule*: each tower type must have a silhouette rule as strict as Champion silhouette rules — a rifleman tower and a barricade must not share a dominant shape trait. (Per-tower silhouette rules authored in Section 5.)

#### Supporting-shape rules (how shapes recede)

Ground tiles, non-damaged walls, basic zombie fill, and generic props must satisfy all four:
1. **Uniformity** — repeated, not unique
2. **Low-contrast fill** — mid-range palette value, not accent
3. **No protrusion** — fits within standard bounding box
4. **Orthogonal alignment** — straight edges

**Receding-shape test**: Gaussian-blur the frame heavily. Hero shapes should read as distinct colored masses. Supporting shapes should disappear into their background value. If any supporting shape is brighter or more distinct than the Champion's blur-mass, it's competing for attention — push it back.

#### Frame budget at Apex density (100+ entities)

| Tier | Elements | Visual budget |
|---|---|---|
| **T1 — Locate** | Champion sprite | Always the brightest accent mass in frame |
| **T2 — Threat-read** | Tank, Charger, Mini-boss breaking horde | Readable by protrusion/scale within 2s scan |
| **T3 — State read** | Kill VFX, ability VFX, card-drop flash | Registers as event, not noise |
| **T4 — Context** | Outpost perimeter, placed towers | Peripheral, stable |
| **T5 — Mass** | Basic zombies, runners, swarmer cloud | Background texture, not individual reads |
| **T6 — Background** | Environment tiles, props, sky/terrain | Below active attention |

**No lower-tier element may have higher visual prominence than any higher-tier element.** If a T5 zombie draws the eye before a T2 special, its fill must be darkened until it reads as mass.

#### Diagnostic Test — Five-Second Scan

Show an Apex Wave screenshot to an unfamiliar tester. Allow 5 seconds, then ask:
1. Point to the player's Champion. *(Tests T1)*
2. Is anything unusually large or threatening visible? *(Tests T2)*
3. Did anything flash or explode while you were looking? *(Tests T3)*

**Fail**: the viewer's finger lands on a zombie or environment element for #1, OR the viewer can't locate the special for #2 despite one being present. Trigger Principle 3 scale adjustment or silhouette hierarchy revision before further asset production.

---

### Cross-Direction Compatibility (Fallback Note)

All shape rules survive the Neon-Noir fallback unchanged — the silhouette hierarchy, geometry vocabulary, UI shape primitives, and compositional motifs are palette-agnostic. Under the fallback, dynamic lighting adds perceived depth that D2 doesn't have, which means some density tests (particularly the blur test in 3.5) may be less critical. **Still run them** — they're the minimum threshold, not the full solution.

---

## 4. Color System

### 4.1 Palette Architecture

**Why 4 colors.** 4 is the ceiling of a single-pass palette-swap shader. Each source color in the environment tile sheet maps 1:1 to one output color at runtime — four source colors means four swappable entries, zero additional passes, and a trivial data structure (four hex values per Champion). Going to 5 requires a second pass or per-tile metadata, both of which violate the month-1 prototype gate from the fallback clause in Section 1.

**The 4-slot structure**:

| Slot | Name | Lightness | Saturation rule |
|---|---|---|---|
| **P1** | Anchor / Darkest | L 5–18 (near-black, not pure black) | Low saturation with slight hue tint — reads as "ink" not "void" |
| **P2** | Cold Mid | L 28–42 | Lower saturation of the mids — the world's shadow value |
| **P3** | Warm Mid | L 50–65 | Higher saturation of the mids — the world's light value |
| **P4** | Ceiling / Accent | L 72–88 | Highest saturation in the set — Champion signature, frame's brightest warm |

**P2 and P3 form a warm-cool pair within the same hue family — not complementary.** Complementary pairs tiled across a fullscreen environment produce simultaneous contrast that fatigues the eye and forces every kill VFX to fight harder to register. A warm-cool pair within one hue family is cohesive as a tiled floor while still providing adequate value differentiation.

**6-role mapping against 4 slots**:

| Role | Slot | Notes |
|---|---|---|
| Darkest ink | P1 | Environment darkest, outline base, deepest fills |
| Environment mid-tone | P2 | Primary floor/ground tile — the "neutral" the eye rests on |
| Environment accent | P3 | Props, rubble, wall faces, variation tiles |
| Champion accent | P4 | Champion sprite fill + outline; frame's warmest saturated mass |
| Highlight / ceiling | P4 (reserved) | Same hex as Champion accent but held at **60% saturation in States 1–3**; full saturation fires only at V4 |
| Danger | P1 (context-switched) | Zombie ink fill shares P1 with environment darkest — intentional: the horde IS the world's shadow asserting itself. Under V1 Boss state, Universal Crimson hijacks the danger role temporarily. |

Highlight and Champion Accent share P4 because they are the same semantic object at different intensities. Danger sharing P1 with zombies is load-bearing narrative, not a compromise.

---

### 4.2 The Four Champion Palettes (Locked)

All four palettes satisfy the 50%-overlap test from Section 2 State 8: overlapping any two at 50% must not produce a mid-gray that erases both identities.

#### Champion 1 — Sharpshooter → "Cold Telescopic"

| Slot | Hex | Name | Role |
|---|---|---|---|
| P1 | `#1A1F2E` | Deep Navy Ink | Darkest ink / zombie fill |
| P2 | `#2E3E55` | Gunmetal Shadow | Environment mid-tone |
| P3 | `#7A9BB5` | Overcast Steel | Environment accent |
| P4 | `#C8E8F5` | Arctic Sight | Champion accent / ceiling |

**Hue relationship**: blue-gray family throughout. P2→P3 is the warm-cool pair. P4 breaks to near-white-blue — icy, distant, precise.

**Glance read**: coast-defense installation seen through fog. The only warmth in frame is pale arctic blue on the Champion — clarity-through-cold, not heat.

#### Champion 2 — Engineer → "Rust Assembly"

| Slot | Hex | Name | Role |
|---|---|---|---|
| P1 | `#1C1410` | Charred Soot | Darkest ink / zombie fill |
| P2 | `#3D2B1F` | Iron Shadow | Environment mid-tone |
| P3 | `#8C5A32` | Copper Wear | Environment accent |
| P4 | `#E8A44A` | Foundry Amber | Champion accent / ceiling |

**Hue relationship**: red-brown family. P2→P3 warm-warm pair differentiated by orange lean in P3. P4 is welding-arc amber.

**Glance read**: scorched industrial site — brick dust, oil, heat-stained concrete. Engineer glows warm amber in a world that looks BUILT.

#### Champion 3 — Medic → "Blight Green"

| Slot | Hex | Name | Role |
|---|---|---|---|
| P1 | `#121A12` | Deep Root Ink | Darkest ink / zombie fill |
| P2 | `#243424` | Brackish Shadow | Environment mid-tone |
| P3 | `#5C8A4A` | Field Lichen | Environment accent |
| P4 | `#A8E870` | Vital Pulse | Champion accent / ceiling |

**Hue relationship**: green throughout. P2 swamp-dark pole, P3 warm-lit mossy pole. P4 is aggressive acidic yellow-green — life as biological process, not sterile health-pack green.

**Glance read**: suburb being reclaimed by jungle. Alive, growing, not under control. Medic + dog are the only things in frame that feel genuinely alive.

#### Champion 4 — Berserker → "Bloodfire Char"

| Slot | Hex | Name | Role |
|---|---|---|---|
| P1 | `#180A08` | Ash-Black | Darkest ink / zombie fill |
| P2 | `#3A1210` | Clotted Dark | Environment mid-tone |
| P3 | `#8C2E20` | Dried Blood | Environment accent |
| P4 | `#E84020` | Kill-Flash Red | Champion accent / ceiling |

**Hue relationship**: red family. P2 deep claret, P3 mid-value dried blood, P4 hot vermillion. The environment itself is red — the Berserker does not fight IN a world, the Berserker IS the world.

**Glance read**: scorched and angry. Dark reds and near-blacks, burning-out embers. Every kill VFX reads volcanic because it fires against a pre-heated environment.

---

### 4.3 Semantic Color Vocabulary

Every color in this game communicates a specific thing. **No decoration-only colors exist — if a color appears in a frame that does not map to this table, it is a production error.**

| Color | Source | Meaning | Presence rule |
|---|---|---|---|
| Champion Accent (P4) | Active palette | "This is the player. Alive. The run's identity." | Present in all states except V3 Defeat. Full saturation only at V4 flash + during ability use. Held at 60% sat in States 1–3. |
| Environment Mid-tone (P2) | Active palette | "The world. The space. The ground." | Constant. Dominant tile fill. The eye's neutral rest point. |
| Darkest (P1) | Active palette | "Threat-by-mass. The horde. Approaching end." | Sparse in States 1–3, bounded by geometry. Dominant in States 4–5. **Increasing proportion of P1 IS the tension curve.** |
| Environment Accent (P3) | Active palette | "Constructed detail. Deliberate placement. World's secondary register." | Constant on props/rubble/wall faces. **Never on Champions or zombies.** |
| **V1 Boss Crimson `#7A1515`** | Fixed | "Different rules. Singular threat. Something irreversible is happening." | Only State 5. Boss silhouette fill + attack telegraphs. **Must NOT appear in States 1–4** — audit and remove if it does. |
| **V2 Victory Gold `#F0C040`** | Fixed | "Run complete. Worth doing. Something earned." | Only State 6. Scoring UI + Champion victory accent + intact outpost boundary. **Never reused as generic loot/coin color in-run.** |
| **V3 Defeat Ash `#7A7E85`** | Fixed | "Run over. Absence without replacement." | Only State 7. Environment background bleed. Champion P4 **suppressed to 40% saturation** (locked). Ash does not appear on the Champion sprite. |
| **V4 Rare Card Flash** | Active P4 at full saturation | "Exceptional. Above normal tier." | Single-frame at Apex. Jarring because P4 has been held at 60% throughout the run. |
| Zombie ink fill | P1 (shared) | "Undifferentiated horde. Mass, not individuals." | All states with active enemies. Shared with environment darkest is intentional — horde and world-shadow are the same color. |
| **In-run loot amber `#E8A44A`** | Fixed (= Engineer's P4, reused) | "Reward. In-run drop. Valuable but not Victory." | Applied to all in-run loot/reward pickups regardless of active Champion. Accepts slight tonal overlap when Engineer is the active Champion. Victory Gold `#F0C040` is distinct and reserved. |

---

### 4.4 UI Palette Rule

**One-sentence specification**: *"HUD panels fill with P2, outlines and text use P1, interactive and attention states use P4. Champion Select chrome uses static neutral `#1A1A1F`. No other colors appear in the UI layer."*

- **Panel fills**: P2 (same as floor tiles) — the HUD feels cut from the world, not dropped over it.
- **Outlines + text**: P1 — hard 2 px outlines consistent with world art.
- **Interactive / ready states**: P4 — reserved for attention-demanding moments (ability ready, card selectable, confirmation prompts).
- **Inactive / depleted**: P2 fill + P1 outline, no accent.
- **P3 does not appear in the HUD.** P3 is the world's secondary register; the HUD is not the world.

**Palette swap behavior**: when the Champion palette swaps, UI's P4 and P1 swap with it. P2 sits in a similar lightness/saturation range across all 4 palettes by design, so the HUD chrome feels continuous across Champion changes. **Implementation**: HUD reads active Champion's hex values as tint parameters on the draw calls — this is data assignment, not a second shader pass.

**Champion Select exception**: UI chrome stays on static neutral `#1A1A1F` (belongs to no Champion palette). When player hovers a Champion, the background/accent areas shift to that Champion's full palette but selection frame stays neutral — prevents the palette preview from being contaminated by UI color.

---

### 4.5 Colorblind Safety Net

**Minimum standard at this design stage**: no game-critical information may be communicated by palette color alone in a way that fails under **deuteranopia** (the most common form, ~6% of males). Every palette-encoded message must have a backup cue that functions under deuteranopia without requiring the color. Protanopia and tritanopia backstops are advisory; full accessibility pass deferred to Alpha per MVP definition.

#### Cross-Champion distinguishability analysis

| Condition | Risk pair | Assessment | Backup cue |
|---|---|---|---|
| **Deuteranopia** | **Engineer vs Berserker** | **HIGH RISK** — both warm-range. P4 values collapse toward similar warm-yellow. P2 nearly identical. | Silhouette (Section 3 rules are load-bearing). Champion name in UI. Champion-specific hover audio. |
| Deuteranopia | Sharpshooter vs Medic | LOW — blue/green retain enough lightness contrast | Silhouette (dog doubles Medic's mass) |
| Protanopia | Engineer vs Berserker | HIGH RISK (same as deuteranopia + red channel loss) | Same as above |
| Protanopia | Berserker vs Boss Crimson | MEDIUM — lightness gap L≈55 vs L≈25 is the backstop | Boss scale (4–5×), ground-positioned attack telegraphs (shape+position cue), unique boss audio |
| Tritanopia | Sharpshooter vs Engineer | MEDIUM — hue separation weakens, lightness preserves | Silhouette |
| Tritanopia | Victory Gold vs V4 Flash | LOW — different game states, never simultaneous | State context |

#### Violation-color risks

- **V1 Boss Crimson (`#7A1515`)**: under protanopia/deuteranopia loses red identity, collapses toward dark neutral. Backstop: boss scale + ground-shape telegraphs + unique audio.
- **V2 Victory Gold**: under tritanopia approaches warm gray. Backstop: "VICTORY" ribbon text + Champion victory pose animation.
- **V3 Defeat Ash**: lowest CB risk. Backstop: state context + broken outpost composition.
- **V4 Rare Card Flash**: risk matches active Champion's P4. Backstop: unique audio cue + card rarity icon tier marks.

#### Alpha retrofit forecast (flagged, deferred)

1. Run all 4 palettes through Coblis/Coolors deuteranopia + protanopia simulators; verify P4 values remain distinct per Champion.
2. Verify Boss Crimson vs Berserker under protanopia at target boss scale.
3. Author tritanopia pass for Sharpshooter/Engineer combination.
4. Confirm Champion Select includes name + silhouette preview simultaneously — color alone cannot be the Champion identifier even in-run.

---

### 4.6 Per-Map Color Temperature Differentiation

V1 ships 3 maps. Palette stays Champion-owned — maps vary by **dominant palette slot proportion**, not palette identity.

| Map | Dominant slot | Identity | Ground-tile rule |
|---|---|---|---|
| **Map 1 — "The Block"** (suburb / street grid) | P2 dominant | Cool, shadowed, enclosed — streets and concrete | P2 ≥ 55% of tile footprint; P3 ≤ 25%; P1 ≤ 20% |
| **Map 2 — "The Yard"** (industrial / open terrain) | P3 dominant | Lit, worn, exposed, kinetic — wide sightlines | P3 ≥ 45%; P2 ≤ 35%; P1 ≤ 20% |
| **Map 3 — "The Last Line"** (fortified / boss staging) | P1 upper / P3 lower | Heavy, compressed — upper screen dark, lower ground is arena | P1 ≥ 40% of upper two-thirds; P3 ≥ 40% of lower third; P2 accent only |

**Why maps don't get independent palettes**: the palette-swap-per-Champion rule (Section 1, Principle 2) exists to make the Champion choice feel like a different world. If maps also had independent palettes, "I'm playing Sharpshooter" vs "I'm in Map 2" becomes ambiguous. Dominant-slot approach keeps the Champion as palette owner while still giving maps distinguishable color mass.

**Cross-Champion test required**: dominant-slot proportions must be authored to work with all 4 palettes, not just the obvious pairing (Map 3 dark + Berserker is easy; Map 3 dark + Medic green-black must also read correctly). Since P1 across all palettes is near-black by design, Map 3's heavy upper register reads consistently across all Champions.

---

### Locked Values Summary (for quick reference)

- **V1 Boss Crimson** = `#7A1515` — wave-10 boss only
- **V2 Victory Gold** = `#F0C040` — run-end victory only
- **V3 Defeat Ash** = `#7A7E85` — run-end defeat only; Champion P4 suppressed to 40% saturation
- **V4 Rare card drop** = active Champion's P4 at 100% saturation (held at 60% otherwise)
- **In-run loot amber** = `#E8A44A` (= Engineer's P4, reused universally)
- **Champion Select neutral chrome** = `#1A1A1F`
- **P4 held-back saturation in States 1–3** = 60%

These values are locked at the art-bible layer. Any production deviation requires a formal art-bible revision.

---

## 5. Character Design Direction

This section is a **rule framework**, not a character catalog. Individual Champions, zombies, and towers are designed in their own character design docs — this section establishes the rules those docs must satisfy.

### 5.1 Champion Archetype Conventions

**Rule 5.1.1 — The Three-Detail Rule.** Every Champion sprite carries exactly **3** personal visual markers unique to that Champion. Not class markers ("soldier has a gun") but personal ones ("cracked lens scope taped to a battered rifle stock"). Acceptable types:
- A clothing accessory no other Champion has (Medic's field-cross armband; Engineer's tool-belt silhouette break at the hip)
- A weapon modification or wear state (cracked scope, wrapped grip, welded barrel extension)
- A non-functional personal effect at a fixed body position (patch, tag, torn sleeve — identity only, not gameplay)

**Rule 5.1.2 — Head Profile as Identity Anchor.** Each Champion has a **distinct head-top profile** readable at 32×32. Flat cap (Sharpshooter, locked in Section 3), helmet/visor, hair/hood mass — no two Champions share a head-top profile. In top-down flat art, the head profile is the substitute for facial identity.

**Rule 5.1.3 — Clothing Detail: Purposeful Scarcity.** Maximum **2–3 interior detail lines per body region**. Lines must do double duty: define clothing form AND reinforce the Champion's thematic vocabulary. Engineer = mechanical/rectilinear paths. Medic = rounded/organic paths. The line language matches the character.

**Rule 5.1.4 — Palette Saturation Contrast as Person-Signal.** Champions use P4 at 60% saturation (Section 4) against zombie P1 near-black. **The saturation gap IS the "named vs anonymous" signal.** All other identity rules support this — none replace it.

#### Animation Register: "Cartoon Realism with Weight"

Not stiff (reads as unfinished). Not floaty (undermines propaganda-poster gravity). Every pose is physically plausible but slightly exaggerated toward drama — WPA-mural figures in motion, with commitment and held weight.

**Rule 5.1.5 — The Held Pose Principle.** Champion attack peaks at a single held frame that is the most silhouette-readable moment. Attack arc is rapid; the held pose lingers **2–3 frames** longer than strictly physical. The held frame is the kill confirmation moment. *(Pillar 2.)*

**Rule 5.1.6 — Ability Signature Pose.** Each Champion has one ability-specific pose that appears *only* during that ability, differing from Attack at the silhouette level. Per-Champion spec:

| Champion | Ability pose rule |
|---|---|
| **Sharpshooter** (slow-time) | **Freeze-frame** at full weapon extension. Weapon line goes fully horizontal. Sprite is literally static during the ability; all other sprites continue at reduced frame rate. *The freeze IS the slow-time visual signal.* |
| **Berserker** (spin/cleave) | Silhouette transitions from T/Y shoulder profile → **circular radial mass** during spin (arms/weapon merge into outline) → **hard snap** back to T/Y at ability end. Screen-shake handled by VFX; art contract is the pose endpoints. |
| **Engineer** | Asymmetric silhouette **deepens** — backpack protrusion becomes the leading visual element as Engineer deploys/activates. Body hunches toward protrusion side. |
| **Medic** | **Dog detaches** from fixed lower-left offset (offset distance grows or dog shifts to forward-leading position). Medic body shifts to leaning-forward stance. Double-mass silhouette ratio changes — dog mass grows relative to Medic. |

---

### 5.2 Survivor-Tower Unit Conventions

Towers must read as allied in under 500 ms. They are visually subordinate to the Champion by design — **towers never compete with the Champion for the frame's visual anchor**. *(Pillar 4.)*

**Rule 5.2.1 — The Warm-Base Rule.** All survivor-towers use **P2/P3 warm-neutral** (environment palette band from Section 4), **never P1** (zombie territory) and **never P4** (Champion territory). Towers read as "part of the built world you own" — the faction signal is positional and architectural, not chromatic rivalry.

**Rule 5.2.2 — Construction Line Vocabulary.** Towers use **rectilinear/mechanical interior lines only** (no organic curves). This distinguishes them from both zombie chaos and Champion personal-marker lines. *Exception*: the Medic's dog follows organic rules (see mobile units).

**Rule 5.2.3 — No Color Identity Competition.** Towers do NOT have individual signature palette colors:
- Base fill: P2/P3 warm-neutral
- Structural edge: 2 px hard outline (world-art standard)
- **Status indicators** (active / damaged / destroyed) use the shared universal **`#E8A44A` (in-run loot amber)** as the active-state highlight. This is the **one** place towers use a saturated color — it reinforces "these are your resources."

Per-tower differentiation is **silhouette only**, not palette. The palette is uniform across all tower types.

**Rule 5.2.4 — Tower Silhouette Framework.** Each tower type is specified by:

| Property | Definition |
|---|---|
| **Base footprint** | Tile-aligned ground mass. Square / rectangular / L-shaped. No two towers share identical footprint. |
| **Vertical profile** | Height:width ratio. Squat (≤1:1), medium (1:2), tall (≥1:3). No two towers share identical profile at identical footprint. |
| **Signature protrusion** | One element that breaks the base rectangle uniquely — barrel / antenna / claw / tire stack / sandbag mound. Identifiable at 32×32. |

**Congruence test**: if two tower silhouettes could be swapped and the player wouldn't notice, they fail. The signature protrusion is the differentiator.

**Rule 5.2.5 — Mobile Unit Conventions (Medic's dog, Engineer's drone).** Mobile units are not towers:
- Organic line vocabulary permitted (dog = curves; drone = mixed mechanical/smooth)
- Always visually smaller than the Champion
- Same P2/P3 warm-neutral base fill
- **1 px outline** (not 2 px) to signal "allied non-primary unit" — lighter presence than Champion or towers
- Dog is a Champion appendage (fixed offset per Section 3), not a tower. Never exceeds 50% of Medic's on-screen visual mass.

**Rule 5.2.6 — Stationary Unit Conventions.** Barricades, turrets, traps have: idle / active-firing / damaged / destroyed states. **Damaged and destroyed are the same sprite + a single break-line or collapse-angle** — not a full new sprite. Production scope.

---

### 5.3 Zombie Visual Character

**Rule 5.3.1 — The Minimal Mark System.** Zombies are NOT 100% filled silhouettes. Pure flat fill renders groups as indistinguishable blobs. Each zombie gets:
- **1 eye-dot** at head position — a single dot or slash. The asymmetry signals wrongness. Readable at 16×16 px. (In Neon-Noir fallback: becomes a glowing cyan dot — same rule, different color.)
- **1 wound / tear edge** — a jagged line break on outline or interior. Reinforces the zombie type's character (tank's tear is at the shoulder suggesting ripped clothing; runner's is along the torso).
- **No additional marks.** Face features, clothing detail, personal effects are reserved for Champions.

**Rule 5.3.2 — Interior Line Opposition.** Where Champion interior lines are **purposeful and directional** (Rule 5.1.3), zombie marks are **irregular and non-directional** — scratchy, diagonal, without pattern. Reinforces "chaotic mass vs intentional individual."

**Rule 5.3.3 — The Corruption Marker System** (within-type variation for buffed/elite zombies).

When a wave modifier or card effect buffs a zombie, the visual contract is a single **Corruption Marker**: a small spike / growth / extrusion added to the existing silhouette at a **fixed position per zombie type**:
- Same P1 fill — no color identity
- Adds to outline; does not replace existing protrusion
- Max size: 20% of zombie's total silhouette area
- **Position is consistent across all elites of that type** (specific positions resolved during per-zombie character design — positions are placeholders until then, authored against Section 3 silhouette maps)
- In Neon-Noir fallback: Corruption Marker outline receives the accent neon color — only visual difference at fallback

This avoids needing new silhouette types (and new art) for elites.

**Rule 5.3.4 — Boss Distinguishing Conventions.** Beyond silhouette scale and V1 crimson (Sections 3, 4):
- **Named announcement** on wave 10 using a Champion-scale illustration (see 5.5 portrait spec) — the one moment a zombie-faction entity gets named-individual treatment, deliberately borrowed from Champion visual language
- **Interior detail exception**: boss gets **3 marks** (not the zombie maximum of 2). The extra mark is a **mouth/jaw line** — the only zombie with a face feature. Signals "has will; is the other named entity on the field."
- **Entry held-pose**: boss enters the field with a stationary held-pose (mirroring Champion Held Pose Principle), ~1.5 seconds before first movement. This pause is the player's threat-read moment.
- **Arena presence**: boss does NOT use zombie lane entry points. Entry position + visual mass ensure it appears at center-bottom of screen (or the most unambiguous visible threat position per map). Boss sprite is unmissable at any reasonable camera zoom.

---

### 5.4 Expression, Pose, and Animation Style

**Rule 5.4.1 — The State-Change Model.** Every animation is a transition between **defined silhouette states**. At 32×32 there is no sub-silhouette motion that reads; animators author states, not curves. Smooth interpolation is optional (helps at higher LODs); state endpoints are the actual animation content.

**Champion core pose states (5 required per Champion):**

| State | Definition |
|---|---|
| **Idle** | Resting silhouette. Must match Section 3 silhouette test exactly. Reference pose. |
| **Move** | Locomotion variant. Slight lean into direction. Weapon carry position differs from Idle. Subtle at 32×32. |
| **Attack** | Attack peak silhouette (Rule 5.1.5). Most dramatic departure from Idle. Held frame. |
| **Ability** | Signature ability pose (Rule 5.1.6). Differs from Attack at silhouette level. |
| **Hit-react** | Backward lean or contracted silhouette. Body compresses toward center — the anti-Attack. Brief (1–2 frames). |

**Zombie core pose states (3 required per type):**

| State | Definition |
|---|---|
| **Move** | Default state — zombies are always approaching. Per-type characteristic arm/body position (basic: arms-forward shamble; runner: low crouched sprint-lean; tank: upright heavy-step). |
| **Attack** | Lunge/strike at target. Silhouette extends toward target per type. |
| **Death** | See Kill Visual Contract below. |

**Rule 5.4.2 — The Kill Visual Contract (Pillar 2 core).** Every kill produces:
1. **Hit-flash** (1 frame): zombie sprite inverts to pure white for one frame. Universal, regardless of kill source. "Confirmed damage" signal.
2. **Death pose** (held 2–4 frames): distinct death silhouette, different from Move. Follows the killing force direction (shot from right → collapse left; melee → collapse toward attacker).
3. **Removal**: sprite removed, not faded. Hard cut. In Neon-Noir fallback a brief pixel-splatter VFX fires; in Propaganda Poster the removal is clean — satisfaction comes from hit-flash + held death pose, not from gore VFX.

**Rule 5.4.3 — Champion Post-Kill Beat (deferred to Alpha).** A brief post-kill "weapon return" micro-beat (1–2 frames after the attack held-pose, only on confirmed kill) is an Alpha polish target, not a V1 requirement. V1 kill feel relies on the Rule 5.4.2 contract alone.

**Rule 5.4.4 — Pose-VFX Synchronization.** VFX is authored against specific Champion pose states. The ability pose is the VFX anchor frame — VFX begins on the first frame of ability-pose entry. **On desync (performance, frame drops), Champion pose takes precedence; VFX may drop frames.** Example: Sharpshooter slow-time — sprite is literally static during the ability; VFX layer (particle field, screen desaturation) runs over a held single frame. This is simplification, not limitation — reinforces "world slows, I do not."

---

### 5.5 LOD Philosophy

**Rule 5.5.1 — Authored Sprite Sizes (locked).**

| Entity | Authored Resolution | In-game display |
|---|---|---|
| Champion (in-game) | **48×48 px** | ~3–4% of screen width at typical top-down camera |
| Zombie (base) | **32×32 px** | — |
| Zombie (tank / elite) | 40×40 px | — |
| Tower unit | 32×32 px | Matches zombie scale — reinforces non-Champion status |
| Boss (wave 10) | **64×64 px** | Unmissable at any camera zoom |

The Section 3 32×32 silhouette test remains the **readability floor** — designs failing at 32×32 fail in game — but final authored resolution is 48×48 for Champions. Reconfirm at architecture phase if tile grid shifts the camera altitude significantly.

**Rule 5.5.2 — Three Scale Contexts:**

| Context | Displayed Size | Detail Level |
|---|---|---|
| **Gameplay** | 48–72 px | Silhouette only. Shape + palette. No facial detail. Interior marks are readability aids, not narrative. |
| **Champion Select / UI Card** | 128–256 px | Silhouette + clothing detail + 3 personal markers + head accessory detail. Face remains minimal. |
| **Card Portrait / Menu Illustration** | 256–512 px | Full flat-art detail. Minimal face visible (flat-art no-gradient rule). Clothing wear readable. Weapon personalization detail. **The only scale where the player learns the Champion as an individual.** |

**Rule 5.5.3 — Portrait-Scale Additions (what is added vs scaled up).** Champion-select and card portrait assets are **separately authored flat-art illustrations**, NOT upscaled gameplay sprites.

*Permitted additions at portrait scale:*
- Face features — minimal (1 eye pair, 1 mouth line, no shading)
- Clothing texture marks — additional interior lines consistent with the Champion's line-direction vocabulary
- Background color block — Champion's P4 at full saturation (the only context outside ability use where Champion P4 goes to 100% sat on-screen)
- Held expression consistent with archetype (Sharpshooter: focused/distant; Berserker: forward aggression; Medic: calm; Engineer: preoccupied, looking off-frame)

*Forbidden at portrait scale:*
- Gradients or shading
- Drop shadows on figure (background block may have hard-edge shadow only)
- New silhouette — portrait must be identifiable as the same silhouette as gameplay sprite. Player must recognize the portrait as the thing they control.

**Rule 5.5.4 — Card Portrait Asset Spec.**
- Format: authored at 256×256 (confirm with UI programmer against card UI frame)
- Naming: `char_[champion]_portrait_card.png`
- **Framing: three-quarter view PERMITTED** at portrait scale only. This is the ONE asset where the top-down constraint is relaxed — it is a UI element, not a game-world element. Hero presentation moment. Top-down everywhere else.
- All flat-art rules still apply (no gradients, no soft shadows)
- Background: flat color block = Champion's P4 at full saturation
- Zombies do NOT get card portraits. Cards referencing zombie types use simplified icons instead.

---

## 6. Environment Design Language

### 6.1 Architectural Style & Cultural Origin

**The setting**: Mid-20th Century American Industrial Vernacular — the postwar working infrastructure of a mid-sized American city, circa 1950–1975. Not aspirational America, not downtown commerce. The America that built things — warehouse districts, grid-street residential blocks, municipal works yards, concrete retaining walls behind state-route storefronts.

| Map | Location type | Narrative premise |
|---|---|---|
| **Map 1 — "The Block"** | Residential-commercial street grid — two-story brick rowhouses, cracked asphalt, overhead power lines on timber poles | *People slept here.* This was a neighborhood. |
| **Map 2 — "The Yard"** | Municipal works / light industrial — corrugated metal outbuildings, gravel + concrete ground, chain-link perimeter, fuel tanks, loading docks | *People worked here.* This was a facility. |
| **Map 3 — "The Last Line"** | Fortified edge made from salvaged materials — bus shelter panels, chain-link rolls, jersey barriers, sandbag walls, repurposed dumpsters, **a reinforced shipping container as the outpost anchor** | *People made a stand here.* This is the end of the line. |

#### Why this setting serves the propaganda-poster register

1. **Composed of rectangles.** Brick faces, loading dock doors, warehouse walls, fencing grid, road markings — all orthogonal and grid-referencing. Aligns with Section 3's Orthogonal Primacy rule with zero design compromise.
2. **Generates bold readable silhouettes.** Timber utility poles, chain-link diamonds, fire hydrants, dumpsters, jersey barriers — all have been graphically simplified into WPA-mural visual language by real artists since the 1930s. We inherit a solved graphic vocabulary.
3. **Immediately legible** to the target demographic without lore context.
4. **The deterioration language IS the game's narrative** — the same environment reads "functional infrastructure" (clean orthogonals) vs "last stand" (compromised by controlled-diagonal damage props).

#### Narrative arc through architecture (hope → collapse → last stand)

- **Hope remnant** (permanent built world) — walls, roads, power poles, facades. Clean orthogonals. Says "people lived and worked here according to a plan."
- **Collapse evidence** (authored into tilemap) — diagonal debris, fallen signage, collapsed doorframes, overturned vehicles. Controlled 30°/45°/60°. **Collapse clusters near zombie lane entry points** — the fall direction points toward where the threat came from.
- **Last Stand layer** (player-placed towers + authored outpost) — orthogonal again. Human intentionality reimposed on a broken world. The gameplay loop restated in visual grammar: each prep phase, the grid reasserts; each apex wave, the P1 horde threatens to overwhelm it.

#### Rejected architectural registers

| Rejected | Reason |
|---|---|
| Fantasy-castle / medieval | Curves, arches, organic profiles — wrong vocabulary entirely |
| Sci-fi chrome / futurist | Diagonal gestures as design intent would break the "built=straight, broken=angled" contract |
| Abstract / geometric | Propaganda posters derive power from recognizable subject matter, not abstraction — no storytelling surface |
| Brutalist-only monumental | Conflicts with Champion scale interaction rule (wall ≤80% Champion height) |
| Generic post-apocalyptic wasteland | No "before." Our industrial-vernacular choice preserves both |
| Eastern European post-industrial / Stalinist bloc | Valid graphically but imports unintended political conflict narrative. *Reserved as possible V2 map style.* |

#### Diagnostic Test — Civilization Legibility

Show a grayscale screenshot of each map (characters removed) to an unfamiliar viewer.
- **Pass**: viewer names ≥ 3 specific real-world infrastructure elements per map within 30 seconds ("loading dock," "power poles," "jersey barrier").
- **Fail**: viewer uses abstract or genre-fiction language ("dungeon," "space station"). Add civilization-specific anchor objects.

---

### 6.2 Texture Philosophy for Flat-Fill

In flat-fill art with no gradients or lighting, "texture" comes from **interior detail lines, tile variation, and outline weight** — not shading.

#### Surface-type interior line grammars (locked)

| Surface | Grammar | Spacing | Used for |
|---|---|---|---|
| **Brick / masonry** | Horizontal coursing + vertically offset joints (running bond) | Coursing every 4 px; joint breaks every 8 px | Rowhouse walls, alley barriers, outpost perimeter walls |
| **Poured concrete** | Dot-scatter, 1 dot per 10×10 px, random within cell | 1 px dots, no two adjacent | Ground slabs, jersey barriers, bunker walls |
| **Corrugated metal** | Parallel vertical lines | Uniform 3 px spacing (strict) | Warehouse walls, shed roofs, fence panels |
| **Asphalt / road** | No interior lines — **tile variation only** | 3 sub-tiles at ±3 L variation of P2 fill | Road lanes, parking lots |
| **Gravel / rubble** | Heavier dot-scatter than concrete | 1 dot per 6×6 px, size variation (1–2 px) | Industrial yard ground, post-collapse floor |
| **Chain-link / wire** | Diamond grid | 4 px spacing, 1 px lines | Perimeter fencing, compound walls |
| **Timber / wood** | Parallel grain lines (horizontal for horizontal boards, vertical for vertical) | 3 px spacing, 80–100% plank-width length variation | Utility poles, boarded windows, barricade planks |

**One grammar, one surface.** Mixed-grammar tiles are forbidden — they read as noise.

#### Tile variation & prop detail rules

- **Rule 6.2.1 — 3-tile maximum** per repeating surface: base tile + alternate (minor variation within same grammar) + damage-overlay tile. More variants tax the palette-swap shader without visual return.
- **Rule 6.2.2 — Alternate frequency** ≤ 1 in 5 tiles. Below: surface reads uniform. Above: alternation becomes the visual pattern.
- **Rule 6.2.3 — Damage tiles cluster directionally** toward horde threat vector (same rule as Collapse Markers).
- **Rule 6.2.5 — 5-line prop interior detail max.** No prop sprite contains more than 5 interior detail lines. Hard ceiling. Count at gameplay zoom, not 400% art-program zoom.
- **Rule 6.2.6 — Line purpose hierarchy**: (1) object boundary where two surfaces meet, (2) surface grammar, (3) damage/wear state. Decorative-only lines are removed.
- **Rule 6.2.7 — Interior lines use P1 only** (darkest). Never P3 or P4. This keeps props at T6 (background) in Section 3.5's visual budget.

#### Industrial-object exception — Octagon Rule

Cylindrical objects (fuel drums, cable reels, tire stacks) render as **octagons**, never smooth circles. Preserves "hard geometry only" while allowing object recognition. No other organic-curve exceptions exist.

#### TileMap + palette-swap compatibility

- **Rule 6.2.8 — Source art uses 4 neutral palette values**, not Champion-specific hex codes. The palette-swap shader replaces them with the active Champion's P1–P4 at runtime. All tiles work across all 4 Champions without re-authoring.
- **Rule 6.2.9 — No per-tile shading.** Lighting variation between tiles is forbidden (no lighting pass). Value differences are fill-slot choices (P2 vs P1), not shader effects.
- **Rule 6.2.10 — Fallback compatibility.** Interior line grammars are identical under Neon-Noir. Fallback adds dynamic lighting over the existing tile art — grammars are enhanced, not competed with.

#### Diagnostic Test — Texture Grammar Read

At gameplay zoom, cover all sprites (characters, towers, VFX) and look at environment alone.
- **Pass**: each major surface is identifiable by grammar within 5 seconds ("that's brick, that's corrugated metal, that's asphalt") without object recognition.
- **Fail**: any surface reads as generic "flat fill with random marks." Identify the violated grammar rule and correct the tile set.
- **Over-budget fail**: any prop draws the eye more strongly than adjacent Champion-level entities. Apply Section 3.5 blur test.

---

### 6.3 Prop Density & Environmental Composition

The environment must NOT pre-fill the negative space the horde occupies. An over-propped map defeats Section 2's tension arc before wave 1.

#### Base rules

- **Rule 6.3.1 — 60% clear-floor rule**: at any game-camera zoom, ≥ 60% of visible floor must be clear ground tile (no prop footprint overlapping). This is the horde's negative-space reserve.
- **Immediate test**: empty-map screenshot. If the frame feels "full," density is too high. Empty map should feel sparse, almost severe.

#### Per-zone prop coverage ceilings

| Zone | Max prop coverage | Rationale |
|---|---|---|
| **Lane approach** (5-tile corridor spawn → outpost) | ≤ 20% | Lanes must stay visually clear for zombie-mass reading |
| **Outpost perimeter** (2-tile border of defended zone) | ≤ 30% | Player places towers here; pre-placed props compete with tower readability |
| **Outpost center** | 1 hero object + ≤ 2 supporting props | Section 2 Victory diagnostic — center is the compositional anchor |
| **Interstitial zones** (between lanes, flanking) | ≤ 45% | Not primary attention zones, but capped to avoid noise spill |
| **Map-edge atmosphere strip** (outer 2-tile ring) | ≤ 75% | Organic-edge territory; visual frame around playfield |

Coverage measured by sprite footprint, not bounding box.

#### Compositional structure

- **Rule 6.3.2 — Three density zones per map**: sparse approach (lowest) → medium build (mid) → dense frame (highest). Spatial rhythm.
- **Rule 6.3.3 — Density gradient points toward outpost**: slightly denser at map edges, sparser near the outpost perimeter. Visual clarity increases as the eye approaches the defended thing.

#### Lane readability (absolute rules — Pillar 4)

- **Rule 6.3.4 — Lane Spine Rule**: each lane has a continuous clear ground-tile path, minimum 3 tiles wide, spawn → outpost. No prop in the spine. Props flank it within density limits.
- **Rule 6.3.5 — Lane Entry Shape preserved**: no prop within 1.5 tiles of the Section 3 lane-endpoint chamfered mouth shape.
- **Rule 6.3.6 — Lane-to-outpost value shift**: lane approach ground uses the map's dominant slot fill; outpost perimeter tiles switch to P1-adjacent (slightly darker) value. Authored tile swap, not a lighting effect. Survives palette-swap (all P1 values are near-black).
- **Rule 6.3.7 — No tall props in lane corridors**: lane flanking props ≤ 40% Champion height (vs 80% elsewhere). Tall props in the spine occlude zombie silhouettes and break Pillar 4.

#### Per-map density specifications

| Map | Lane prop ceiling | Outpost perimeter props | Dominant interstitial props | Identity note |
|---|---|---|---|---|
| **Map 1 "The Block"** | 2 per 10-tile lane | ≤ 6 | Orthogonal vehicles with 30°/45° damage tilt variants, lamp posts, fire hydrants | Dense street grid, deliberately cleared lanes — urban order partially preserved |
| **Map 2 "The Yard"** | 1 per 10-tile lane | ≤ 4 | Fuel drums (octagons), chain-link segments, stacked pallets, equipment cabinets | Wider, more exposed — interstitials have machinery clusters |
| **Map 3 "The Last Line"** | **0 authored props in primary lanes** (player towers only) | ≤ 8 (highest of any map) | Jersey barriers, sandbag walls, tire stacks, reinforced vehicle chassis | Environment's built layer IS fortification. Lanes cleared intentionally by defenders. |

**Map 3 hero object (locked): a repurposed shipping container** anchored as the outpost command structure. Clean rectangular, maximum orthogonal authority, stackable for visual height. The survivors dragged and anchored it — story told by silhouette.

#### Diagnostic Test — Negative Space Reserve

Apex Wave screenshot — identify floor tiles not covered by zombie mass.
- **Pass**: 25–35% of floor area is visible between zombie sprites at Apex density.
- **Fail (over-propped)**: zombie mass reads as a third layer on top of already-busy environment. Strip props from lanes and interstitials.
- **Fail (under-propped)**: early-wave frames feel empty. Add props to interstitial zones only (never lanes).

---

### 6.4 Environmental Storytelling

No cutscenes, no in-world text, no dialogue during runs. **The tilemap and props are the primary lore delivery system.** Narrative props are T6 (background) in Section 3.5's visual budget — the player absorbs them peripherally or glances sideways when the lane is clear enough to afford it.

#### Four narrative prop categories

| Category | What it is | Fill | Placement rule |
|---|---|---|---|
| **A — Civilian Remnants** | Objects placed by people with ordinary lives (child's bicycle, lawn chair, overflowing mailbox, shopping cart) | **P3 only** | Tell the "before" story by existence |
| **B — Collapse Markers** | Apocalypse-event damage (partly-broken boarded window, door hanging from one hinge, chain-link bent inward) | Orthogonal base + controlled diagonal break | **Cluster near lane entries**; diagonal lean points toward zombie spawn direction |
| **C — Survivor Evidence** | Defender-placed intentional items under duress (improvised weapon cache, pinned map rectangle, food-tin stack, light-bracket without light) | P3 fill, orthogonal | **Denser near outpost center**, sparser toward lane entries — they built toward what they defended |
| **D — Consequence Markers** | Zombie-corpse debris piles + blood spatter ground-overlay tiles | **P1 fill, no interior lines** (abstract spatter shapes, not legible objects) | **Highest density on the "worst lane"** — one lane per map gets more — environmental telegraph of asymmetric difficulty |

**Rule 6.4.5 — Consequence Markers authored as V1 art** (not runtime system). Hand-placed per map to tell the "worst lane" story. Runtime accumulation system reserved as a V2 upgrade path.

**Rule 6.4.6 — 5-line budget applies to narrative props** (same as all props).
**Rule 6.4.7 — Narrative props are standard tilemap sprites, reusable.** Naming: `env_[object]_[descriptor]_small.png`. No single-use bespoke assets.
**Rule 6.4.8 — Narrative props must survive palette-swap.** Identity carried by silhouette shape, not color-specific association.
**Rule 6.4.9 — Fallback-compatible**: props are identical in shape/placement under Neon-Noir; dynamic lighting only adds shadow legibility.

#### Forbidden environmental storytelling

| Forbidden | Why |
|---|---|
| **Text in environment** (readable graffiti, legible signage) | Graphic-posterized register. Rendered text at game zoom is noise or attention-steal. *Exception*: single symbols permitted (painted X, tally mark, directional arrow). |
| **Named personal items** | No narrative specificity at game-zoom scale; named items belong in card text. |
| **High-contrast color storytelling** (realistic-orange fire, out-of-palette blood) | Every color must be in active 4-color palette. Fire as environmental prop = P3 fill + corrugated-vertical hot-surface texture, not a 5th color. |
| **Cutaway interior detail** | Cross-section realism requires depth cues the art system can't provide. Broken wall = wall + diagonal break line, not a wall with a scene behind it. |
| **Horror-register gore** | Wrong tonal register — propaganda-poster, not horror-survival. Consequence Markers handle aftermath abstractly. |
| **Organic curves on constructed objects** (except the Octagon Rule from 6.2) | Map-edge organics only. Everything else hard-geometric. |

#### Per-map narrative voice

**Map 1 "The Block" — "This was a neighborhood. People chose to make a stand here."**
- Civilian remnants: half-packed moving box at a doorstep, swing-set frame in a back-yard zone, overflowing trash with P1 overflow pile
- Defender details: boarded windows (plank-line overlays on window rectangles), sandbag barricades near outpost, rough painted downward-arrow symbol on road reading "SAFE ZONE"
- **Worst lane**: the widest street approach — the obvious entry, the one they couldn't hold forever

**Map 2 "The Yard" — "This was a workplace. People came back because it had walls and a supply cache."**
- Civilian remnants: rare (never a home)
- Survivor Evidence dominates: weapon cache crates, marked-map rectangle on a fence post, jury-rigged timber-post watchtower frame
- Collapse Markers dramatic: section of chain-link bent back at 45°, overturned fuel drum as controlled-diagonal
- Outpost anchor: loading-bay wall structure — this place had defensible space already

**Map 3 "The Last Line" — "This is what was built in the final hours. It shows."**
- Civilian remnants: nearly absent (no time)
- Every prop is fortification or consequence
- Jersey barriers with tire stacks wedged behind, dumpsters dragged across lanes, hand-stenciled arrow symbol pointing inward
- Highest Consequence Marker density of the three maps
- Outpost anchor: **repurposed shipping container** (locked), stackable, reads immediately as "reinforced structure survivors dragged into position"
- Emotional register: whoever built this knew it wouldn't be enough. The anxious thoroughness near the outpost (8-prop max, highest of any map) against cleared lanes — defenders cleared lanes not from confidence but because they needed to see what was coming.

#### Diagnostic Test — Environmental Narrative Read

Show character-free / HUD-free map screenshot to an unfamiliar viewer for 10 seconds. Ask:
1. Was this place a home or a workplace? *(tests Civilian-Remnant vs Survivor-Evidence ratio)*
2. Does this look like a place people planned to be, or a place they ended up? *(tests Survivor-Evidence density and distribution)*
3. Which direction would you expect danger to come from? *(tests Collapse + Consequence Marker directional clustering)*

- **Pass**: correct-or-close on all three, using environmental detail (not map layout) as evidence.
- **Fail Q3**: Collapse/Consequence markers not clustered directionally enough. Reinforce toward lane entries.
- **Fail Q1**: Civilian-Remnant vs Survivor-Evidence ratio is inverted for that map. Audit prop list.

---

## 7. UI / HUD Visual Direction

This section combines the art-direction and UX-alignment decisions. Shape primitives are locked in Section 3.4; palette rules are locked in Section 4.4. This section specifies register, typography, icon grammar, animation feel, per-Champion inflection, information hierarchy, interaction patterns, and accessibility commitments.

### 7.1 Diegetic vs Screen-Space Register

**Strictly screen-space. Wartime Operations-Center Aesthetic.** *(Not diegetic. Not field-journal. Not radio-broadcast.)*

The UI does not pretend to exist in the game world. It looks like status boards a field coordinator would mount to a wall — printed, cut, and pinned next to the propaganda poster of the game's world, not grown from a surface within it.

Rejected registers:
- **Wartime radio broadcast** — biases toward circular dials/waveforms, conflicts with hard-cornered rectangle grammar
- **Field journal** — organic, hand-drawn, diagonal scrawl; conflicts with Principle 1 + the "diagonal = damage" rule
- **Survivor radio HUD / damaged-display overlay** — diegetic registers, contradict the Poster-Tear Test

**What Operations-Center means in execution**:
- HUD panels are status boards mounted to the wall — not windows into the game world
- Wave counter is a stenciled-label board updated by authoritative hand — not a floating number
- Ability cooldown fills like an ink-progress indicator on a printed form — not digital software motion
- Card-roll presents 3 cards like field-briefing cards laid face-up on a planning table — not a dealer's hand

**No glass. No reflection maps. No "floating digital readout" convention.** Fallback-compatible — register, shape vocabulary, and typography are palette-agnostic.

---

### 7.2 Typography

**Primary typeface: Condensed Industrial Stencil caps, one weight only.** Hierarchy built from **scale + case + color**, not weight variance. A status board has one stamp, used at different sizes.

#### Scale hierarchy

| Level | Element | Size (at 1280×800) | Typeface |
|---|---|---|---|
| **L1 Announcement** | Ribbon banner: wave number, boss name, Victory/Defeat title | 56–64 px | Stencil caps |
| **L2 HUD data** | Wave counter, ability name, resource count number | 28–32 px | Stencil caps |
| **L3 Card text** | Card name, card category label | 18–20 px | Stencil caps |
| **L4 Secondary info** | Resource label, status effect duration, secondary card text | 14 px (floor) | **Compressed-caps grotesque fallback** (Barlow Condensed equivalent) — below 16 px, stencil gaps become noise |

**Steam Deck readability standard**: minimum legible body text = 14 px at 1280×800 logical resolution. Base (L3 card name) = 18–20 px. Scale tests must be run on actual Steam Deck hardware before V1 ship.

#### Numerical display conventions

- **Damage numbers — Champion kills only** (not tower kills). Compressed grotesque (not stencil — these are transient VFX-adjacent, not status-board text). Champion P4 color. Scale proportional to damage magnitude, capped at 2× L2 size. Appear at zombie position, not at Champion. **Hard-cut fade at 0.5 s** — no glow, no soft fade.
- **Resource count**: L2 stencil numeral, left-aligned in diamond badge, no leading zeros.
- **Wave counter**: `WAVE 7` format. Total (`/10`) lives in the ribbon wave-indicator, not inline — preserves hierarchy between current state and total context.
- **Cooldown**: the chamfered fill IS the data. No overlay numeral (except `—` at 0%).

---

### 7.3 Iconography

**"Stenciled" = physically cut from paper/metal, inked through.** Two legitimate styles:

- **Silhouette-only** — opaque cutout, no internal detail. Identity from outer contour alone. Mandatory at 16×16.
- **Outlined-silhouette with structural break-lines** — mechanically justified artifacts of stencil bridges. ≤ 2 break-lines at 16×16; ≤ 4 at 32×32.

**Forbidden**: internal gradient fill, anti-aliasing, tonal variation inside the shape. The jagged pixel edge at 16×16 IS the aesthetic.

#### Icon grammar by category

| Category | Authored / HUD size | Badge | Fill |
|---|---|---|---|
| **Champion ability** | 32×32 / 24×24 | Chamfered rectangle (interactive signal) | P4 on P1 (ready) / P1 on P2 (cooldown) |
| **Tower type** | 24×24 / 16×16 | Diamond | P3 on P1 — silhouette matches tower's Section 5.2.4 signature protrusion |
| **Card category** | 32×32 / 24×24 | Octagon | P2 on P1 (standard tier) / Champion P4 at 100% sat (rare tier — V4 visual language) |
| **Resource** | 16×16 | Diamond | Loot amber `#E8A44A` on P1 — silhouette-only at 16×16 |
| **Status effect** | 16×16 | Clipped rectangle | P1 on P2 (debuff) / P4 on P1 (buff). One distinct outer contour per type: slow = downward chevron, burn = upward spire, stun = radial 4-point burst, heal = cross. |

**16×16 floor = authoring floor, not display constraint**: designs must SURVIVE 16×16 (readability test — see below). Display size may be larger when layout permits; **prefer 24×24 in all HUD contexts** except status-effect clusters forced to 16×16 by space.

**16×16 pass test**: render at exactly 16×16 on a 2× display (32×32 physical). A non-designer identifies the icon category correctly in under 3 seconds from a set of all icons shown simultaneously. Fail = redesign outer contour; do not attempt to add detail.

---

### 7.4 Animation Feel

**Ground rule: flat transition, no tween softness.** UI animation = physical operations-center state changes, not digital interface motion.

- **Instantaneous fills** (single-frame advance, never tweened)
- **Hard cuts** (appear/disappear with no cross-fade)
- **Rigid-body slides** (constant pixel velocity, no ease-in / ease-out — only where motion duration itself communicates urgency)

**Easing is forbidden** on all UI elements. 60 fps Steam Deck budget = all UI animations are Control-node transforms, no shaders.

#### Per-element animation rules

| Element | Rule |
|---|---|
| **Card-roll reveal** | **Simultaneous drop** — all 3 cards enter from 32 px below final position at 4 px/frame (~0.13 s total). No rotation, no scale, no stagger. Card background fill is already the card's palette slot color before motion begins — the fill isn't a reveal, only position. Rare cards get a 4-frame P4 stroke flash on outline after landing. |
| **Ability cooldown** | Fills in discrete **10% segments**, instant step per threshold. At 60 s max cooldown = 6 s per segment. **On ready: 2-frame P4 outline flash, non-repeating.** Single hard pulse, captures attention without competing with gameplay. |
| **Ribbon banner (in-game)** | **Total visible time ≤ 1.5 s.** 60% screen width maximum during gameplay (full-width reserved for Victory/Defeat). Slide in at 8 px/frame from left → hold briefly → slide out to right. Consistent direction = reads as document feed, not pop-up. **Text is pre-printed on ribbon when it enters** — no typing-on, no fade-in. |
| **Victory/Defeat screen entry** | **Hard cut** from gameplay → result screen. No cross-fade, no dissolve. Permitted exception: 4-frame (~0.07 s) black frame between gameplay and result if needed for cognitive landing — NOT a fade, a brief blackout. The emotional register of the cut is the point. |
| **Champion portrait on Victory/Defeat** | One-time 0.3 s vertical position settle (16 px over 18 frames, constant deceleration). The only concession to "weight" — must read as settling under gravity, not drifting. |
| **Hover states** | Color-only change, instant switch. No scale change, no position shift, no drop shadow. Inactive = P2 fill + P1 outline. Hover = P2 fill + P4 outline. Pressed/selected = P1 fill + P4 outline + P4 fill at 60% sat (ink-stamp inversion — element gets pressed down, not raised). |

---

### 7.5 Per-Champion UI Inflection

**Palette-only swap is the rule. One structural exception: the ability cooldown indicator.**

Per-Champion structural variation (different tick marks, weight changes, typography styles) is rejected — it multiplies QA surface, risks readability drift across 4 aesthetic registers, and contradicts the operations-center register (institutional authority stays consistent regardless of who's running).

**The single permitted structural inflection**: an 8×8 px stencil marker inside the cooldown indicator, centered, not affecting fill behavior:

| Champion | Cooldown marker | Visual logic |
|---|---|---|
| **Sharpshooter** | Single horizontal scope-reticle tick-mark | Precision — minimal, horizontal |
| **Engineer** | Wrench silhouette (simplified) | Construction, personal tool |
| **Medic** | Cross-bar with single break (field-medic shorthand, NOT full medical cross — the full cross is the Medic's personal character marker, Section 5.1.1) | Care under operational constraint |
| **Berserker** | Downward wedge / impact point | Aggression downward, striking toward |

Everything else — health bar, wave counter, resource counter, card-roll panels — is identical chrome; only P1, P2, P4 palette values swap per Champion.

**Champion Select exception** (locked in Section 4.4 already): chrome stays on static neutral `#1A1A1F` until hover fires — the Select screen's neutrality prevents palette preview contamination.

---

### 7.6 Critical Information Hierarchy (Continuous Reads)

Six information reads must be continuously accessible during combat. (Tower status and streak state are continuous, not supplementary — wave structure makes them so.)

| # | Read | Why critical | Failure mode | Spatial location |
|---|---|---|---|---|
| 1 | **Champion health** | Primary survival signal | Player dies without realizing hit count | Lower-left, large horizontal bar with notches at 25%/50% |
| 2 | **Ability cooldown** | When can I use my defining move | Player presses ability, nothing fires, thinks it's broken | Near-center-bottom, chamfered indicator with Champion marker |
| 3 | **Wave progress** | How far into this wave, when does it end | Player has no sense of duration remaining → no tactical planning | Top-center ribbon-form 3-segment indicator |
| 4 | **Resources / loot count** | What can I afford to place next Prep | Player over- or under-invests | Bottom-left diamond badge |
| 5 | **Tower status** (damaged / destroyed) | Which placement just failed | Player doesn't notice a lane collapsed | **World-space badges on the tower sprites themselves**, NOT in the HUD — keeps HUD ≤ 20% visual weight |
| 6 | **Streak meter** (kill combo) | Pillar 2 feedback loop | Player loses the "unbroken kills" signal → tempo reward lost | Small inline with resource counter (secondary priority). Primary kill feedback lives in world-space (hit-flash, death pose). HUD streak is reinforcement, not the primary signal. |

---

### 7.7 Interaction Patterns

**Input scheme**: keyboard/mouse primary; gamepad secondary (partial per technical-preferences — tower placement via cursor, menus gamepad-navigable). UI structure supports both without bifurcating: **every interactive element must be focusable via cursor AND D-pad navigation, with the chamfered-corner cue marking interactivity identically for both input modes.**

#### Card-roll interaction
- **All 3 cards show full information simultaneously** — no hover-to-reveal, no sequential read. Pillar 4 wins: new players must not lose information.
- Hover highlights a card (P4 outline swap per Rule 7.4 hover state).
- Click to commit selection.
- **100 ms grace-beat on commit** — input within 100 ms of card landing is ignored. Invisible to deliberate players, prevents the most common first-session misclick frustration.
- Time-pressure indicator (30 s prep timer): small corner ribbon showing remaining seconds, no flash/pulse until final 5 s (when ribbon fires a single P4 outline flash per second).

#### Tower placement
- **Grid-snapped to tile grid**.
- **Preview-before-commit**: ghost tower sprite follows cursor, renders in P2 (inactive) with P4 outline when placement position is valid.
- **Placement validity cues use P4 (valid) vs P1 (blocked), NOT green/red.** Red is reserved for Boss Crimson V1 — using red for UI state would contaminate the violation-color semantic.
- **Cancel-after-commit** permitted within 2 seconds of placement at full resource refund; after 2 s, partial refund only (number TBD by economy designer).

#### Cooldown / ability feedback
- Cooldown indicator (chamfered rectangle, per Section 3.4) fills clockwise in 10% segments.
- Ready state: 2-frame P4 outline flash (per Rule 7.4).
- Ability blocked (e.g. mid-animation, out of range) — indicator flashes P1 outline for 2 frames instead. Same shape language, inverse color, reads as "denied."

#### Pause behavior
- Mid-wave pause brings up an overlay menu (not a world-space pause).
- Overlay uses the same UI shape language: P2-fill panel with P1 outline. **No modal gradient, no world dimming with a blur.** Instead, the overlay panel sits on a flat P1 screen-fill at 80% opacity — a hard-edge black plate, not a gradient. Respects Principle 1 without losing "pause is different from gameplay" signal.

---

### 7.8 Accessibility & Readability Commitments

**Minimum standard committed at this stage** — full accessibility pass deferred to Alpha per MVP definition.

#### Colorblind backup — the Champion Silhouette Badge

**The Engineer/Berserker deuteranopia palette-collision** (Section 4.5 high-risk) is resolved at the UI layer through a permanent **Champion Silhouette Badge** displayed in the HUD at all times — a 24×24 stencil icon showing the active Champion's silhouette (per Section 3.1 load-bearing trait). The badge uses the Champion's P1 fill on P2 background. Its outline only shifts to P4 on ability-ready state (the same cue as the cooldown indicator — reinforcement, not independent signal).

This converts the Engineer/Berserker risk from "UI fails under deuteranopia" to "UI carries non-color Champion identity permanently." The player reading the silhouette badge knows which Champion is active regardless of palette-swap state.

**Additional backups**:
- Tower placement validity: P4 vs P1 outline + shape change (valid = ghost tower visible; blocked = tower ghost hidden, grid cell gets a hard X overlay)
- Status effect icons: each has a distinct outer contour (not color-dependent)
- Wave number: always accompanied by the stenciled numeral, never color-coded

#### Text and scale
- **Steam Deck (1280×800)**: 14 px floor, 18–20 px body base
- **Desktop 1920×1080+**: scales proportionally; UI layout anchors to corners + center, does not float on absolute positions
- DPI handling: UI renders against logical resolution, not physical — 4K displays use the same logical sizes scaled 2×

#### Motion sensitivity
- No animated element may flash faster than **3 Hz** (flicker threshold for photosensitive-epilepsy guidance)
- No high-contrast strobing permitted anywhere in the UI
- The 2-frame ability-ready flash fires once per ability reset — does not repeat, does not create a flicker pattern
- Ribbon-banner slide velocity (8 px/frame) is constant, not oscillating

#### Input affordance
- Interactive elements carry the **chamfered corner** cue (Section 3.4) + a default P1 outline + hover P4 outline. Three orthogonal cues (shape + default outline + hover outline state change) ensure affordance is visible even under tritanopia.
- Keyboard-focused element gets a second outline layer in P4 dashed (the only place a dashed line appears in the UI — reserved exclusively for keyboard focus).

#### Reading order
- Card-roll: **left-to-right**, confirmed by card-entry simultaneous drop + card label placement (card names anchor to top of each card body)
- Champion Select: left-to-right through Champion tiles
- HUD default reading pattern: lower-left (health/resources) → center-bottom (abilities) → top-center (wave) → world (tower status in world-space)

---

### 7.9 Consolidated Rule Summary

- Operations-center aesthetic; no diegetic HUD
- Stencil caps for L1–L3; grotesque fallback at L4 only
- Icons: 16×16 authoring floor, prefer 24×24 display
- No easing on UI; hard cuts + rigid-body slides only
- Ribbon banners ≤ 1.5 s total visible time in gameplay
- Ability-ready flash = 2 frames, non-repeating
- Card-roll = simultaneous drop + 100 ms commit grace-beat
- Damage numbers = Champion kills only, compressed grotesque in P4
- Tower placement validity = P4 vs P1 (never green/red)
- Champion Silhouette Badge in HUD permanently (colorblind backstop for Engineer/Berserker)
- Per-Champion UI inflection = palette swap + 8×8 cooldown marker only
- Victory/Defeat transition = hard cut (permitted: 4-frame black frame, never a fade)

---

## 8. Asset Standards

This section consolidates art-direction preferences and Godot 4.6 engine-constraint specifics. Items marked **[VERIFY 4.6]** require confirmation against live Godot 4.6 documentation during `/setup-engine` or the first technical implementation task — the LLM's knowledge pre-dates changes in Godot 4.4 / 4.5 / 4.6.

### 8.1 File Formats

#### Source files (not in Godot import path)

- **All sprite art, tiles, props, characters → Aseprite (.aseprite / .ase)**
  - Native indexed-color enforces 4-color palette at authoring time
  - Layer-per-animation-state maps to Section 5.4 state system
  - Tag-based animation export automates the naming convention
- **Card portraits and Champion-Select illustrations → Aseprite** (same toolchain, no separate illustration pipeline for solo dev)

Source files live in `assets/src/` — git-tracked but excluded from Godot's import scanner.

#### Export / game-build files

| Asset class | Format | Bit depth |
|---|---|---|
| Sprites, tiles, props, VFX | **PNG lossless** | 32-bit RGBA (8-bit indexed acceptable but 32-bit is the practical default — Godot 4.6 indexed-PNG importer behavior **[VERIFY 4.6]**) |
| Card portraits | PNG lossless | 32-bit RGBA (256×256 with interior line detail) |
| UI backgrounds, full-screen overlays | PNG lossless | 32-bit RGBA |

**No WebP.** Lossy compression destroys hard pixel edges; lossless adds toolchain friction with no meaningful size benefit at pixel-art resolutions.
**No JPEG anywhere.**

### 8.2 Naming Convention

#### Pattern

`[category]_[name]_[variant]_[size].[ext]` — snake_case throughout.

#### Category codes (authoritative)

| Code | Asset class |
|---|---|
| `char_` | Champions, bosses — any named entity |
| `zomb_` | Zombie types (maintains Section 5.3 anonymous/named distinction) |
| `env_` | Environment tiles, props, narrative objects |
| `ui_` | HUD elements, icons, buttons, panels |
| `vfx_` | Visual effect sprites and sheets |
| `twr_` | Tower and survivor-unit sprites |
| `card_` | Card illustration and icon assets |
| `bg_` | Full-screen backgrounds, map atmosphere |

#### Name, variant, size

- **Name** — descriptive snake_case, no abbreviations. `char_sharpshooter_idle_48.png`, not `char_ss_idle_48.png`.
- **Variant** — state or sub-type: `idle` / `move` / `attack` / `ability` / `hit_react` / `death` / `base` / `alt` / `damaged` / `default` / `hover` / `pressed` / `disabled` / `gameplay` / `select` / `portrait`.
- **Size** — authored resolution shorthand: `_16`, `_24`, `_32`, `_40`, `_48`, `_64`, `_128`, `_256`. For sprite sheets: `_48x6` (48 px × 6 frames). For full-screen: `_1920x1080`, `_1280x800`.
- **Frame index** — multi-frame exports append `_01`, `_02` after size. Single-frame assets omit.

#### Versioning

**Git is the version history.** No `_v1` / `_v2` / `_final` / `_final2` suffixes, ever. Parallel alternatives (concept exploration) live in a `/drafts/` subdirectory within the source folder, gitignored from Godot's import scan path.

### 8.3 Directory Structure

```
assets/
├── src/                          # Source files — NOT in Godot import path
│   ├── characters/               # .aseprite for Champions, bosses
│   ├── zombies/                  # .aseprite for zombie types
│   ├── environment/              # .aseprite for tiles and props
│   ├── ui/                       # .aseprite for UI elements
│   ├── vfx/                      # .aseprite for VFX sprites
│   └── cards/                    # .aseprite for card illustrations
│
├── art/                          # Exported PNG — Godot import path
│   ├── characters/               # char_[champion]_[state]_[size].png
│   ├── zombies/                  # zomb_[type]_[state]_[size].png
│   ├── environment/
│   │   ├── tiles/                # env_[surface]_[variant]_[size].png
│   │   └── props/                # env_[object]_[descriptor]_[size].png
│   ├── ui/                       # ui_[element]_[state]_[size].png
│   ├── vfx/                      # vfx_[effect]_[variant]_[size].png
│   ├── towers/                   # twr_[type]_[state]_[size].png
│   ├── cards/                    # card_[name]_[variant]_[size].png
│   └── backgrounds/              # bg_[scene]_[variant]_[size].png
```

`assets/src/` is in `.gdignore` (or equivalent Godot-specific mechanism **[VERIFY 4.6]**) but IS committed to git — source files are project history, not build artifacts.

### 8.4 Texture Resolution Tiers

| Tier | Authored resolution | Contents | Scaling |
|---|---|---|---|
| **T0 — Icon floor** | 16×16 | Status effect icons, resource icons (Section 7.3 floor) | Nearest-neighbor only, never scaled below authored |
| **T1 — Gameplay unit** | 24–64 px (per Section 5.5.1 locked sizes) | In-game sprites: Champion 48×48, zombie 32×32, tank 40×40, boss 64×64, tower 32×32 | Nearest-neighbor only |
| **T2 — UI element** | 24×24 / 32×32 | HUD icons, badges, button icons, cooldown indicators | Nearest-neighbor. Panel backgrounds via Godot NinePatch, not stretched single textures |
| **T3 — Champion select / in-game card** | 128×128 | Champion-select portraits; card art icon panel | Nearest-neighbor. Separately authored, NOT an upscale of T1 |
| **T4 — Card portrait / illustration** | 256×256 | Full card portrait (three-quarter view permitted). Boss announcement illustrations. | Nearest-neighbor. 1:1 at card UI size |
| **T5 — Full-screen background** | 480×270 authored → 4× nearest-neighbor to 1920×1080 display | Map atmosphere, menu backgrounds, Victory/Defeat plate | **Authored at 480×270** — the pixel grid must be visible as coarse register art, propaganda-poster "blown up from a photograph." Steam Deck 1280×800 = 320×200 × 4. |
| **T6 — Tilemap** | 16×16 per tile (confirm against Godot TileMap tile-size setting during technical setup **[VERIFY 4.6]**) | All environment tiles (Section 6.2 grammar) | Nearest-neighbor. TileMap handles repetition |

### 8.5 LOD / Scale Philosophy

**Principle: separately authored assets per scale context, NOT scaled-up sprites.**

Section 5.5 locks this for characters. The same applies across all asset classes:

| Scale context | Authored asset | Source file strategy |
|---|---|---|
| Gameplay (T1) | `char_[champion]_[state]_48.png` — silhouette + palette + minimal marks | Aseprite 48×48 with animation tags per state |
| Champion Select (T3) | `char_[champion]_select_128.png` — full clothing detail + 3 personal markers + head accessory | Separate Aseprite file at 128×128 |
| Card portrait (T4) | `char_[champion]_portrait_card.png` — three-quarter, full detail, P4 background block | Separate Aseprite file at 256×256 |

**Zombies do NOT get T3/T4 assets.** Card references to zombies use simplified T1-derived badge silhouettes.

**Boss exception**: each boss gets a single T4 announcement illustration — `char_[bossname]_announcement_256.png`. The only zombie-faction entity with named-individual illustration treatment (Section 5.3.4).

### 8.6 Godot 4.6 Import Pipeline

#### Mandatory import settings for pixel art

| Setting | Required value | Reason |
|---|---|---|
| **Filter** | `Nearest` | Default `Linear` blurs pixels at non-integer zoom. Nearest is load-bearing. |
| **Mipmaps** | **Disabled** | Mipmaps cause blurring at non-integer scales — anti-feature for fixed-camera 2D |
| **Compress mode** | `Lossless` (PNG-preserved) or `VRAM Lossless` | Lossy compression shifts exact hex values and silently breaks the palette-swap shader |
| **Fix Alpha Border** | Enabled | Prevents dark-halo artifact at transparent borders |
| **Detect 3D** | Disabled | Per asset — prevents import regression |
| **sRGB handling** | Match project color space | **[VERIFY 4.6]** Palette hex codes in Section 4 are sRGB; confirm shader samples in sRGB, not linear |

#### Import presets (create named presets, apply consistently)

| Preset | Apply to | Key settings |
|---|---|---|
| `pixel_sprite` | Champion / zombie / boss / tower sprites | Nearest, no mipmaps, lossless, fix-alpha ON |
| `pixel_sheet` | All sprite sheets | Nearest, no mipmaps, lossless, fix-alpha ON, texture_type=2D **[VERIFY 4.6]** |
| `pixel_tileset` | TileSet textures for all 3 maps | Nearest, no mipmaps, lossless. Must NOT use repeat mode |
| `pixel_ui` | UI icons | Nearest, no mipmaps, lossless. Separate atlas from world sprites |
| `card_portrait` | 256×256 portraits | Nearest, no mipmaps, lossless |

#### Common import mistakes (silent failures)

- **Bilinear filter left on** — outlines soften at any non-integer zoom; art direction reads as watercolor
- **Mipmaps enabled on sprites** — soft halos on outlines; zombie mass reads as blurry blob
- **Lossy VRAM compression on tileset** — exact hex values shift, palette-swap silently fails (tiles render wrong colors)
- **Fix Alpha Border disabled** — dark fringe pixel on all outline edges, worst on Steam Deck at slightly scaled viewport
- **Wrong sRGB handling** — P4 accent colors sample darker than authored
- **Legacy TileMap vs TileMapLayer node** — Godot 4.4 split `TileMap` into `TileMapLayer`. **[VERIFY 4.6]** — confirm how materials and layered stacks work in 4.6

### 8.7 Texture Atlas Strategy

Godot 4's 2D renderer auto-batches when consecutive sprites share texture. **Atlas cohesion is the primary draw-call optimization.**

| Atlas | Contents | Target size | Rationale |
|---|---|---|---|
| **Per-Champion atlas** (4 total, only active one resident) | All animation states for one Champion | 512×512 (max 1024×512) | Only 1 Champion active per run; other 3 atlases deferred — no wasted VRAM |
| **Zombie atlas** (single) | All 8–10 zombie types, all states | 2048×1024 starting (may grow to 2048×2048) | Zombies render adjacent — single atlas = minimum texture switches. **Split only if Steam Deck profiling shows cache pressure.** |
| **Per-map tileset atlas** (3 total, only active resident) | All tiles + variants for one map | 2048×2048 per map | Only one map active per run |
| **UI icon atlas** (single) | All HUD icons: ability × 4 Champions, tower × 8, card category, resource, status effects | 512×512 | All HUD icons render on UI CanvasLayer — single atlas means 1 draw call |

Card portraits (256×256) do NOT belong in the UI icon atlas — they load on card-roll screen entry, not continuously.

**[VERIFY 4.6]**: Godot 4.6 uses D3D12 as default on Windows. Confirm 2D batching behavior is identical under D3D12 vs Vulkan.

### 8.8 Performance Budgets

#### Draw call allocation at Apex Wave (1500 ceiling)

| Category | Max draw calls | Notes |
|---|---|---|
| Zombie sprites | 3 | Single atlas; possible 2nd material for elites / Corruption Markers |
| Champion + Medic's dog | 2 | Same atlas; dog sorts separately |
| Tower sprites | 3 | Single atlas; states (active / damaged / destroyed) |
| TileMapLayer nodes | 6 (ceiling), 4 (preferred) | One draw call per layer minimum |
| UI | 20 | HUD has multiple Control nodes; icon atlas batches most |
| VFX / particles | 20 | Most variable category |
| **Subtotal** | **~54** | |
| Safety margin | ~50 | CanvasLayer transitions, viewport clears, state changes |
| **Reserve** | ~1400 | 1500 is a hard ceiling; realistic target is 50–150 actual draw calls |

Profile at Apex density via Godot's Debugger → Rendering → Draw Calls panel **[VERIFY 4.6]**.

#### TileMapLayer stack (4 preferred, 6 ceiling)

1. Ground base (dominant P2 floor)
2. Ground detail / variation (alternates, gravel scatter, damage overlays)
3. Environment objects — lower tier (sit on ground)
4. Environment objects — upper tier (overlap characters, if any)

Optional (only if required):
5. Atmospheric edge layer
6. Consequence Marker overlay (Section 6.4)

#### VFX budgets

- **Particles per effect**: 32 max
- **Concurrent emitters**: 10 max simultaneous
- **Particle system**: `CPUParticles2D` mandatory for kill and ability VFX. Reason: Steam Deck integrated RDNA2 GPU shares memory bandwidth with CPU; `GPUParticles2D` compute pass is expensive on Deck. **[VERIFY 4.6]** CPU vs GPU particles tradeoffs under D3D12.
- **Hit-flash**: NOT a particle effect — implemented as `modulate = WHITE` for 1 frame on the existing sprite material. Zero additional draw calls.
- **Death pose**: sprite animation state, NOT particles. No draw call added.

#### Memory budgets (approximate)

| Category | Texture memory (peak) |
|---|---|
| Active Champion atlas (1 of 4) | ~4 MB |
| Zombie atlas | ~16 MB |
| Active map tileset (1 of 3) | ~16 MB |
| UI icon atlas | ~1 MB |
| Card portraits (loaded at card-roll) | ~6 MB |
| VFX sheets | ~4 MB |
| **Total runtime peak** | **~47 MB uncompressed, ~12 MB with VRAM Lossless** |

2 GB RAM ceiling is not a texture concern at this scope — the pressure is GDScript object overhead and audio.

### 8.9 Palette-Swap Shader Specification (Month-1 Prototype Gate)

Section 1's month-1 gate: *swap 4-color TileMap to any of 4 palettes at runtime, no frame stutter, 100+ zombies rendered over it, authorable in ≤10 min.*

#### Architecture

- **Shader type**: `shader_type canvas_item;` as a `.gdshader` file. **NOT** VisualShader (makes the exact color-comparison logic harder to audit).
- **Assigned as**: `ShaderMaterial` on the `TileMapLayer` node's material slot. Shared instance across all active TileMapLayer nodes in the scene.
- **Palette passed as**: uniform array of 8 colors (4 source slots + 4 output slots). **[VERIFY 4.6]** — `uniform vec4 array[4]` syntax in CanvasItem shaders.

#### Source art encoding (LOCKED)

Source tile art is painted in **pure primary hex values** as slot markers — NOT neutral grays, NOT Champion palette colors:

| Slot | Source hex | Replaced at runtime with |
|---|---|---|
| Source P1 | `#FF0000` (pure red) | Active Champion P1 |
| Source P2 | `#00FF00` (pure green) | Active Champion P2 |
| Source P3 | `#0000FF` (pure blue) | Active Champion P3 |
| Source P4 | `#FFFF00` (pure yellow) | Active Champion P4 |

**Rationale**: pure primaries are unambiguous. They cannot accidentally overlap with any Champion palette value (no Champion uses pure primaries). Source tile art displays as red/green/blue/yellow mosaics in the paint program — this is intentional, the "ugly" proxy colors make encoding errors visible immediately.

**Authoring rule**: all tile source art uses ONLY these 4 proxy hex values + full transparency. Any pixel with a different value is a production error. A Godot import-time validation script flagging violations is strongly recommended.

**Scope**: the palette-swap shader applies to **TileMapLayer nodes only**. Champion sprites, zombie sprites, and tower sprites do NOT go through the swap shader — they use direct palette-assigned hex values or `modulate` for state tinting (hit-flash, V3 Defeat saturation suppression).

#### Shader algorithm (pseudocode)

```
uniform vec4 source_colors[4]; // RGB+Y proxies
uniform vec4 target_colors[4]; // active Champion P1-P4

for each pixel sampled from the tile texture:
    if (distance(pixel, source_colors[0]) < 0.01) output target_colors[0];
    else if (distance(pixel, source_colors[1]) < 0.01) output target_colors[1];
    else if (distance(pixel, source_colors[2]) < 0.01) output target_colors[2];
    else if (distance(pixel, source_colors[3]) < 0.01) output target_colors[3];
    else discard;
    preserve input alpha;
```

Tolerance = 0.01 normalized — protects against float precision drift; tight enough that the 4 primaries cannot blur into each other.

#### Runtime swap trigger

```gdscript
func apply_champion_palette(tilemap_layer: TileMapLayer, palette: ChampionPalette) -> void:
    var mat := tilemap_layer.material as ShaderMaterial
    mat.set_shader_parameter("target_colors", [
        palette.p1, palette.p2, palette.p3, palette.p4
    ])
```

`ChampionPalette` is a `.tres` Resource with 4 Color fields. All TileMapLayer nodes in the active scene share the ShaderMaterial instance — one call updates everything.

**[VERIFY 4.6]** — method name `set_shader_parameter` (was `set_shader_param` in earlier 4.x).

**No stutter on swap**: uniform write, no shader recompile, no material rebuild, no draw-call flush. Swap is visually instantaneous on the same frame the parameter is written.

**Authorability (≤10 min rule)**: new palette = (1) create `.tres` ChampionPalette resource [2 min], (2) assign hex values from art bible [3 min], (3) verify in-editor via `apply_champion_palette` tool call [5 min]. No shader editing.

### 8.10 Steam Deck Constraints

- **Native resolution**: 1280×800. Godot logical resolution = 1280×800 base viewport. Do NOT render at higher internal resolution and scale down (wastes GPU on the Deck's shared-memory RDNA2).
- **Integer scale only**: stretch mode configured so game scales at integer multiples from 1280×800 base. 1920×1080 desktop = 1.5× (non-integer — letterbox acceptable, or use `canvas_items` with `keep_aspect`). **[VERIFY 4.6]** recommended stretch mode for pixel art on multiple resolutions.
- **Thermal throttle target**: 60 fps cold + **55 fps sustained throttled after 30 minutes** of continuous Apex-density play. Below 45 fps throttled = optimization required.
- **Overdraw**: flat-fill pixel art has minimal overdraw; still monitor via Debug → Wireframe/Overdraw mode. Cap at 3× overdraw in any zombie cluster region.
- **Shader cost**: palette-swap runs per-pixel on the full tilemap (1,024,000 pixels at 1280×800 × 4 comparison ops = ~4M operations/frame for tilemap). Measure on actual Deck hardware.

### 8.11 Forbidden Technical Approaches

#### Forbidden by art direction

| Forbidden | Breaks | Enforcement |
|---|---|---|
| `DirectionalLight2D` / `PointLight2D` / `SpotLight2D` | Principle 1 (no lighting pass) | No Light2D nodes in world scenes |
| `LightOccluder2D` + normal maps | Principle 1 | Normal map import field blank on all sprites |
| `WorldEnvironment` with Glow / DOF / SSAO / SSIL enabled | Hard-edge art direction | **[VERIFY 4.6]** — glow reworked in 4.6; confirm disable path. All post-process effects OFF. |
| `CanvasModulate` with gradient or animated colors | Palette contamination | Only flat palette-derived colors, no gradients, no animations |
| Anti-aliasing on 2D sprites | Hard-ink-outline look | Project settings: MSAA 2D = Disabled. **[VERIFY 4.6]** exact setting name |

#### Forbidden by performance

| Forbidden | Cost | Enforcement |
|---|---|---|
| Unique `ShaderMaterial` per zombie instance | Breaks batching — 100 draw calls per 100 zombies | All same-type zombies share one ShaderMaterial instance |
| Per-sprite palette-swap shader on zombies | Each unique shader param set = own draw call | Palette swap applies to TileMapLayer only |
| `GPUParticles2D` for kill VFX at Apex density | Compute pass spikes on Deck | `CPUParticles2D` mandatory for kill/ability VFX |
| `RichTextLabel` for damage numbers | Per-character rendering overhead at 15 kills/sec | Pooled Label nodes or custom `_draw()` on CanvasItem |
| Real-time GI (SDFGI, VoxelGI) | 3D features, must confirm OFF | **[VERIFY 4.6]** |
| Unatlased sprites (1 texture per sprite node) | Destroys batching | Every frequently-rendered sprite in an atlas per 8.7 |
| Shadow-casting 2D sprites | Both art violation + cost | Zero `LightOccluder2D` permitted |

### 8.12 Style Consistency Gates (Three-Gate System)

Gates are solo-dev-calibrated — lightweight but rigorous enough to catch drift before it accumulates.

#### Gate 1 — Silhouette Test (at first complete draft)

Asset passes the relevant Section 3 diagnostic:
- Characters → 32×32 silhouette matrix
- Towers → congruence test (silhouettes non-interchangeable)
- Zombies → horde-strip rhythm
- UI icons → 16×16 pass test
- Environment → geometry triage

**Authority**: author self-checks. Pre-condition for further work.

#### Gate 2 — Palette Compliance (before export)

Verified via Aseprite palette panel or inspection:
- **Sprite / tile source art**: ONLY the 4 primary proxy values (`#FF0000`, `#00FF00`, `#0000FF`, `#FFFF00`) + transparency. Zero additional colors.
- **Champion / zombie / tower sprites** (non-tile): ONLY the active Champion palette values (P1–P4) + transparency. No out-of-palette colors.
- **Portraits (T4)**: ONLY the Champion's P1–P4 + transparency.
- **UI elements**: ONLY palette values from Section 4.4 + fixed violation / chrome values from the Locked Values Summary.

**Authority**: author self-checks. Export is gated. **A failed Gate 2 silently breaks the palette-swap shader at runtime — most consequential gate in the pipeline.**

#### Gate 3 — Art-Direction Consistency (before integration)

| Check | Pass condition | Reference |
|---|---|---|
| Poster-Tear test | Flat fills, hard outlines, no gradients, no lighting, no soft effects | Section 1 |
| Silhouette distinctness | Correct on Section 3 diagnostics; no identity confusion | Section 3 |
| Palette authority | Respects slot ownership (P4 = Champion, P1 = horde/ink) | Section 4 |
| Interior detail budget | ≤ 5 lines per prop; ≤ 3 personal markers per Champion | Sections 5.1, 6.2 |
| Scale context | Authored at correct resolution tier; separately authored not scaled | Sections 5.5, 8.4 |
| Naming convention | File matches `[category]_[name]_[variant]_[size].ext`, snake_case | Section 8.2 |

**Authority**: solo dev = author-as-gatekeeper. Failed check blocks integration; correction noted in commit message (production trail).

**Escalation rule**: if uncertain, tiebreaker = *"Does this conflict with any locked section (1–7)?"* If yes → fails. If ambiguous → document in commit message and proceed (V1 is a living document, not a perfection gate).

### 8.13 Knowledge-Gap Resolution Checklist

During `/setup-engine` or the first technical-implementation sprint, resolve the following `[VERIFY 4.6]` items against live Godot 4.6 docs:

1. sRGB vs linear color space handling in CanvasItem shaders (affects palette fidelity)
2. Shader texture-type flag name after 4.4 changes (import presets)
3. TileMapLayer vs legacy TileMap architecture in 4.6 (scene structure)
4. `uniform vec4 array[4]` support in canvas_item shaders (if unsupported, shader architecture changes)
5. `set_shader_parameter` method name confirmation (was `set_shader_param`)
6. D3D12 vs Vulkan 2D batching semantics on Windows (draw-call estimates)
7. `CPUParticles2D` vs `GPUParticles2D` under D3D12 on Deck (particle system choice)
8. 2D MSAA setting name in project settings (checklist item)
9. Glow rework in 4.6 — WorldEnvironment disable path (art direction enforcement)
10. Stretch mode for pixel art at multiple resolutions (Deck scaling strategy)
11. `.gdignore` or equivalent for excluding `assets/src/` from import scan (directory structure)
12. Godot 4.6 indexed-PNG importer behavior (affects 8-bit vs 32-bit PNG choice)
13. TileMap tile-size setting vs T6 authored 16×16 assumption (tier definition)

---

## 9. Reference Direction

Five curated references. Each is additive — no two teach the same lesson — and each comes with explicit guidance on what NOT to take, to prevent uncritical borrowing that would drift the direction.

### R1 — Hyper Light Drifter (game)

**Take**: The rule of silhouette-first design at small sprite resolution. At 32×32, the outer contour must carry 100% of identity before color enters. Silhouette test is a pass/fail gate, not a guideline — if the shape doesn't read as a black fill against white, the design hasn't started yet.

**Avoid**: The neon-restraint application. Hyper Light Drifter uses neon as isolated accents against a desaturated world — this is the **Neon-Noir Pixel fallback** logic, not the D2 Propaganda Poster primary direction. Borrowing its "hot spot in a muted field" instinct will pull design toward the fallback.

**Maps to**: Section 3 (Shape Language) — the 32×32 Silhouette Matrix diagnostic for Champions, the Horde-Strip Rhythm test for zombies, and Section 5.4's State-Change Model. Answers: *"How little information does a sprite need for shape to do its full job?"*

### R2 — Nuclear Throne (game)

**Take**: Readable chaos at high entity density. Nuclear Throne's achievement is that a screen with 60+ small enemies never becomes an undifferentiated mass — each type has ONE dominant break from the "basic enemy" shape, and that break is visually loud enough to survive in a crowd. The method is contrast-of-proportion: tiny-and-fast, huge-and-slow, mid-mass-laterally-wide. Threat-read is automatic because silhouette differentials are peripheral-scale.

**Avoid**: The kill VFX register. Nuclear Throne's kill feedback is loud, messy, omnidirectional — blood, gore, screen-filling particles on every kill. Appropriate for its horror-humor register but undermines Rule 5.4.2's clean hit-flash + held-death-pose contract, which depends on the kill moment being visually spare (satisfaction from pose snap, not from visual explosion).

**Maps to**: Section 3.2 (scale escalation table, Horde-Strip Rhythm) and Section 3.5 (Frame Budget tiers — T2 threat-reads vs T5 mass). Evidence that the 4 break-axes rule (scale / proportion / protrusion / posture) works at production scale in the same genre.

### R3 — Mad Max: Fury Road (film)

**Take**: The "single saturated thing against a desaturated world" compositional technique. In Fury Road, the War Rig is the only consistently warm-saturated mass in frame across most sequences — dust, sky, and enemy vehicles are all pushed toward pale ochre and gray, so the viewer's eye locks onto the hero object without conscious effort. **Implemented as a production rule, not a per-scene decision**: the director/cinematographer agreed in pre-production that the world would be bleached and the hero would hold its color. Discipline is absolute.

**Avoid**: **The sand-and-orange palette itself.** Fury Road's specific ochre-tan-orange-red world is evocative, but importing it collapses the 4-palette Champion distinction — every Champion would look like they're in the same desert. The lesson is the *technique* (one saturated anchor vs desaturated field), not the specific hues.

**Maps to**: Section 4.3 (Champion Accent P4 = always the frame's most saturated mass) and Section 3.5 (T1 locate tier). The "where is my Champion" problem is solved the same way Fury Road solves "where is the War Rig" — total saturation discipline on everything else.

### R4 — 28 Days Later (film)

**Take**: The visual rhythm of silence-then-density. 28 Days Later's early sequences — particularly the deserted London streets — are held deliberately long and quiet before any threat enters. When the threat arrives, the frame density change is total and instantaneous. **The film never eases into danger; it cuts.** This is the structural equivalent of Section 2's State 1–2 negative-space rule and the State 2→3→4 transition. Evidence that players can read density-change as danger without additional signaling.

**Avoid**: The hand-held documentary-fragment visual language. 28 Days Later was shot on miniDV — unstable camera, grain-heavy, temporally fragmented. None of that belongs in the flat, static, propaganda-poster register. Borrowing its urgency-through-framing would require adding camera shake, desaturation passes, or noise overlays — all of which contradict Principle 1.

**Maps to**: Section 2 (State Definitions + Cross-State Contrast Rules) and Section 6.3's 60% clear-floor rule. Reference evidence for WHY the density-based mood arc works without palette violations doing the heavy lifting.

### R5 — Train to Busan (film)

**Take**: The horde-as-single-mass visual model. Zombie crowds are composed and directed as a single fluid shape — pouring, stacking, filling, routing around obstacles — rather than as collections of individual characters. Individual identities within the horde are irrelevant; **the mass has direction, momentum, and silhouette.** Costume design reinforces this: zombies are in office clothes and civilian dress, not costumed — anonymous by intentional design at the mass level.

**Avoid**: The individual zombie character moments. Train to Busan has scenes of individual zombie recognition — a face the protagonist knew — which lands because the film has 40+ minutes of setup first. The game has no runtime for character investment in zombie identities. Any temptation to add expressive or individuated zombie designs because the film does it misreads how that device works.

**Maps to**: Section 5.3 (Minimal Mark System — 1 eye + 1 wound only) and Section 3.2's Swarmer density rule. The most precise external reference for why the Swarmer Enforcement Rule (cluster spawn + cohesion behavior) exists: **the cluster IS the creature, not the individuals.**

---

### Reference Dropped (With Reasoning)

**Hotline Miami** is removed from the primary curated set. Its palette discipline (desaturated world + hot-neon agent) is the **Neon-Noir Pixel fallback** logic, not the D2 Propaganda Poster primary direction. Keeping it active risks constant pull toward the fallback aesthetic during production.

**Fallback activation note**: If the month-1 palette-swap prototype gate fails and the project moves to the Neon-Noir fallback, **Hotline Miami becomes the governing primary game reference** — revise this section at that time. The lessons Hotline Miami teaches (muzzle-flash lighting, neon restraint, silhouette-first characters) are already covered in more D2-aligned form by the 5 references above. Dropping is not a loss — it is a scope decision matching the committed direction.

**Gameplay-only references dropped**: Gunfire Reborn, Vampire Survivors, Orcs Must Die! 3, Risk of Rain 2, Dead Cells, Hades. All offer mechanical reference (run structure, economy, pacing, ability design) with no specific visual lesson not already covered by the curated set. Risk of Rain 2 has a readable-chaos argument similar to Nuclear Throne's, but Nuclear Throne is a closer register match (top-down 2D flat art). These references belong in the GDD, not the art bible.

---

### Reference Usage Rule

**When the solo dev is stuck on a visual decision, consult in this order:**

| Problem type | First reference | Why |
|---|---|---|
| "Does this silhouette read?" — Champion or zombie shape readability | **Hyper Light Drifter** | Purpose-built for this question at small pixel resolution. Trust the 32×32 black-fill test. |
| "Is this horde readable?" — density, threat-tier differentiation, mass vs individual | **Nuclear Throne** | Same genre, same problem, production-proven solution. |
| "Is this palette/saturation choice right?" — who owns which color, is the Champion the most saturated thing in frame | **Mad Max: Fury Road** | Single saturated anchor, desaturated world. If the Sharpshooter's Arctic Sight isn't the warmest thing in frame, something else is wrong. |
| "Does this feel too dense / too empty?" — negative space in waves, tension pacing through composition | **28 Days Later** | Silence-then-density. If the early-wave frame doesn't feel "wrong" when a zombie enters, it was too busy to start. |
| "Is this horde mass reading correctly?" — whether zombie groups feel like a collective force or a crowd of individuals | **Train to Busan** | The reference for horde-as-single-shape. If individual zombie sprites are drawing the eye, the mass has failed. |

**Secondary rule**: if none of the above resolves the decision, return to the **Section 1 one-line rule** — *"Would this image work as a printed wartime propaganda poster?"* — before consulting any reference. The reference set clarifies specific sub-problems; the Section 1 rule resolves everything else.

---

### Fallback Reference Substitution (if Neon-Noir activates)

If the month-1 palette-swap prototype gate fails, swap the primary reference set as follows:

| Slot | D2 Propaganda Poster | → Neon-Noir Pixel fallback |
|---|---|---|
| Palette discipline | Mad Max: Fury Road | **Hotline Miami** (desaturated world + hot neon threat) |
| Silhouette-first | Hyper Light Drifter | **Hyper Light Drifter** (no change — lesson holds under either direction) |
| Readable chaos | Nuclear Throne | **Nuclear Throne** (no change) |
| Mood density | 28 Days Later | **28 Days Later** (no change) |
| Horde-as-mass | Train to Busan | **Train to Busan** (no change) |

Four of five references survive the direction shift unchanged. Only the palette-discipline slot swaps — this is the one area where Propaganda Poster and Neon-Noir have genuinely different governing logic.
