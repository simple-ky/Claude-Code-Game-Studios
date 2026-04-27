# Pixel Art Generation Lessons — pixel-mcp

> **Origin**: Retrospective after generating `champion_survivor.aseprite` (2026-04-26).
> **Use this file** as a pre-flight checklist before any pixel art generation session.

---

## The Core Mistake to Never Repeat

**Using `draw_pixels` as the primary drawing tool.**

`draw_pixels` is a precision correction tool — for eyes, neon accents, and single-pixel
detail touches. Using it to draw entire characters pixel-by-pixel is the equivalent of
painting a wall with a toothbrush: technically possible, extremely slow, poor result.

---

## Tool Hierarchy (use in this order)

```
1. Shape tools       → block in the silhouette fast
2. Fill tools        → flood-fill large color regions
3. Shading tools     → add depth automatically
4. Outline tools     → clean border in one call
5. draw_pixels       → ONLY for final detail touches (eyes, glow, accessories)
```

### Full Tool Reference

| Tool | Use For | Never Use For |
|---|---|---|
| `draw_rectangle` | Body/torso bounding box, legs block | Single pixels |
| `draw_circle` | Head oval | — |
| `draw_contour` | Full character outline in one call | — |
| `fill_area` | Flood-fill skin, jacket, pants, hair | — |
| `apply_auto_shading` | Add highlight + shadow to flat fills | — |
| `apply_outline` | Clean dark border around finished character | — |
| `duplicate_frame` | Copy a base frame → change only moving parts | — |
| `draw_pixels` | Eyes, neon stripe, accessories, corrections | Building entire shapes |
| `analyze_reference` | Extract palette from reference art | — |
| `import_image` | Bring in a pre-drawn base | — |

---

## Canvas Size Rule

| Size | Use When | Detail Level |
|---|---|---|
| 16×16 | Tiny enemy fodder / particles only | Near zero — eyes are 1 dot |
| **32×32** | **Default for all characters** | Face, shading, equipment readable |
| 48×48 | Hero characters, bosses | Full expression, accessories |
| 64×64+ | Cutscene / UI portraits | — |

**Never generate a player character at 16×16.** The neon-noir style (Hyper Light
Drifter, Hotline Miami references) requires at minimum 32×32 for the silhouette
clarity described in the game's art bible.

---

## Frame Reuse Strategy (Critical for Speed)

**Wrong approach (what was done):**
```
add_frame → draw 124 pixels (full character)
add_frame → draw 124 pixels (full character, only 8 pixels different)
add_frame → draw 124 pixels (full character, only 8 pixels different)
```

**Correct approach:**
```
1. Draw base frame fully (head + body + neutral legs)
2. duplicate_frame → only redraw 8–16 leg/arm pixels that change
3. duplicate_frame → only redraw 8–16 pixels for next pose
```

This reduces per-frame drawing calls by ~85%.

---

## Layer Architecture (use from the start)

Create named layers before drawing anything:

```
Layer: outline      ← draw_contour() — entire character border
Layer: base_color   ← fill_area() per zone
Layer: shading      ← apply_auto_shading() — do this after base is done
Layer: detail       ← draw_pixels() — eyes, neon, accessories only
```

Benefits:
- Can redo shading without touching outline
- Can update base color without losing detail layer
- `duplicate_frame` copies all layers correctly

---

## Correct Generation Sequence

```
Step 1:  create_canvas (32×32, rgb)
Step 2:  analyze_reference → extract neon-noir palette  [optional but recommended]
Step 3:  set_palette
Step 4:  add_layer("outline"), add_layer("base"), add_layer("shading"), add_layer("detail")
Step 5:  draw_contour (character silhouette)
Step 6:  fill_area × N (skin, hair, jacket, pants, boots — one call each)
Step 7:  apply_auto_shading (adds highlight + shadow automatically)
Step 8:  apply_outline (dark border pixel)
Step 9:  draw_pixels (eyes, neon stripe, glow spots — fine detail only)
Step 10: duplicate_frame → draw_pixels (only leg/arm delta for walk_A)
Step 11: duplicate_frame → draw_pixels (only leg/arm delta for walk_B)
Step 12: create_tag × N (idle, walk_down, walk_up, walk_side)
Step 13: save_as + export_spritesheet
```

---

## Animation Frame Budget

| Animation | Min Frames | Notes |
|---|---|---|
| idle | 2 | Subtle bob or neon pulse |
| walk_down | 2–4 | 2 is acceptable for prototype |
| walk_up | 2–4 | Back-of-head, crown highlight |
| walk_side | 2–4 | Right-facing only; flip_h for left |
| attack | 3–5 | Add later — not needed for movement test |

**For a basic movement character, 8 frames total (2 per direction) is the right target.**
Do not expand to 4 per direction until the prototype is validated in-engine.

---

## Visual Quality Checklist (Before Exporting)

- [ ] Silhouette is readable in grayscale (game pillar: silhouette-first design)
- [ ] Neon stripe (`#00C8FF`) is visible and not cluttered by surrounding colors
- [ ] At least 3 tones per major zone: base, highlight, shadow
- [ ] Dark outline separates character from any background color
- [ ] Eyes + facial feature visible even at 1× zoom
- [ ] Both leg positions in walk cycle are distinct (not just 1-pixel shifts)
- [ ] No isolated orphan pixels (1 stray pixel disconnected from shape)

---

## Palette for Champion Survivor (Neon-Noir Standard)

```
Hair dark:       #3D2B1F
Hair highlight:  #4A3520
Skin base:       #D4A574
Skin shadow:     #B07840
Eye:             #1A1A2A
Mouth:           #A06868
Jacket dark:     #1A2535
Jacket mid:      #2A3F60
Jacket light:    #3A5580
Neon cyan:       #00C8FF
Neon dim:        #0088BB
Pants dark:      #151520
Pants light:     #252535
Boot:            #0F0F0F
Outline:         #080C14
```

---

## Why the First Attempt Failed (Summary)

| Problem | Impact |
|---|---|
| Used `draw_pixels` for every pixel | 22 sequential API calls, 10+ minutes |
| 16×16 canvas | No room for detail, eyes were single dots |
| No frame reuse | Redrew 100+ identical pixels 6 times |
| No shading layer | Flat colors, zero depth |
| Planned all coordinates mentally | Slow, error-prone, no feedback loop |
| No reference analysis | Invented palette from memory |
| No shape/fill/contour tools | Never used the fast path |
