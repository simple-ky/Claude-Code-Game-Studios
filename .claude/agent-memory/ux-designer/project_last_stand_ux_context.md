---
name: Last Stand Champions — UX Context
description: Key UX decisions and conflict flags from the Section 7 art bible draft; informs future HUD, card-roll, and accessibility work
type: project
---

The UX-alignment draft for art bible Section 7 (subsections 7.6–7.9) was authored 2026-04-23 for synthesis with art-director's visual direction draft. Key decisions recorded here so future UX work does not contradict them.

**Critical information hierarchy (six must-reads during combat):**
1. Champion health — bottom-left hard-cornered bar; low-health = outline width blink (2-frame, ≤3 Hz)
2. Ability status — bottom-center chamfered badge; three states (cooldown/ready/blocked) using P4 outline hold + icon opacity delta
3. Wave state/timer — top-center ribbon; 2-frame fill flash on phase transition
4. Resource count — bottom-left diamond badge below health; dims (50% opacity) during active wave
5. Tower status — world-space badges on towers, not HUD; screen-edge directional arrow on off-screen tower destroy
6. Kill feedback/streak — world-space hit-flash (primary); HUD streak row of diamond badges (secondary)

**Interaction model decisions:**
- Card-roll: examine-then-commit; all 3 cards visible simultaneously; hover expands to 120% hard scale; no confirm dialog; accidental-click grace beat (100ms delay if zero examine time); auto-select middle card on timeout
- Tower placement: ghost-preview snapping to tile grid; P4 outline = valid; P1 outline = invalid (no red — red reserved for enemies)
- Pause: full-screen hard-cornered panel, P2 fill, no blur/vignette; game world visible behind panel
- Unified input: one UI layout serves keyboard/mouse and gamepad; same P4 outline hover = mouse; same P4 outline focus = gamepad D-pad navigation

**Accessibility commitments:**
- Minimum text: 18px wave ribbon, 16px card name, 14px descriptions at 1280x800
- Colorblind backup: Champion silhouette icon badge (P1/P2, 24x24px) anchored to health bar — non-color champion identity anchor
- No color-only state changes anywhere in HUD (every color state has shape/opacity backup)
- Reduce Motion setting required before Alpha: halves screen shake + flash intensity
- Low-health blink: 1 Hz (1-second cycle, 2 frames on) — well below photosensitive threshold

**Conflict flags with art direction (6 flagged in 7.9):**
1. Ability-ready dwell — UX wins (Pillar 4); P4 outline held continuously, not one-frame flash
2. Tower damage badge color — recommend in-run loot amber (#E8A44A) rather than P3 (P3 forbidden from HUD per 4.4)
3. Icon display size — authored at 16x16 (per spec), displayed at 24x24 (1.5x integer upscale); nearest-neighbor filter; UX wins on Pillar 4
4. Ribbon dwell time — shared win; wave ribbon ≤1.5s, boss ribbon ≤2.5s; art owns visual form
5. Hover affordance — outline weight 2px→3px on hover as secondary signal (within the locked 2–3px range); no gradient/glow
6. Colorblind champion name text — Champion name text uses P1 on P2 always; P4 never used as text color (UX wins on Section 4.5 + Pillar 4)

**Why:** These decisions are load-bearing for the synthesis with the art-director draft. Future card-roll, HUD, and champion-select UX specs must not contradict these positions without re-opening the conflict flags.

**How to apply:** When authoring design/ux/ specs (hud.md, interaction-patterns.md, etc.), use these as canonical starting positions. Do not re-derive from scratch — extend or refine.
