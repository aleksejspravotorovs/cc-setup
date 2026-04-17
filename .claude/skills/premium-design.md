---
name: premium-design
description: Premium design quality standards — color strategy, section rhythm, typography rules, card patterns. Triggers when editing page layouts, section backgrounds, or color tokens.
---

# Premium Design Quality Standards

Apply these rules when building or editing page sections, layouts, and color schemes.

## Section Color Rhythm

Never place two bold-background sections adjacent. Follow the breathing pattern:

```
BOLD → Neutral → BOLD → Neutral → BOLD
```

Apply the **60-30-10 rule**:
- **60%** Neutral backgrounds (white, off-white, warm cream)
- **30%** Brand-color backgrounds (primary accent, dark charcoal)
- **10%** Gradient/special backgrounds (hero, CTA)

## Background-Specific Text Rules

### On White / Light Backgrounds
- Headings: dark primary color
- Body: gray secondary
- Overlines: brand primary, uppercase, `letter-spacing: 0.1em`
- CTAs: dark button or brand-colored button

### On Brand Primary Background
- Headings: white
- Body: `white/90` (rgba 0.9 opacity)
- Secondary: `white/70`
- CTAs: **inverted** — `bg-white text-[brand-primary]`
- Cards: `bg-white/15 backdrop-blur-sm border border-white/20` OR solid white
- Verify WCAG AA contrast (4.5:1 body, 3:1 large text)

### On Dark Charcoal Background
- Headings: white
- Body: `white/70` or muted gray
- CTAs: white or brand button
- Cards: `bg-white/5 border border-white/10`
- Overlines: lighter accent color

## Card Adaptation

Cards MUST adapt to their background:
- **On light**: borders + subtle shadows
- **On brand color**: glass effect (`backdrop-blur`) or solid white
- **On dark**: transparent with faint borders, or white for pop

## Typography Hierarchy

- Display: `clamp(3rem, 8vw, 5rem)`, weight 700, tracking `-0.04em`
- H1: `clamp(2rem, 5vw, 4rem)`, weight 700, tracking `-0.03em`
- H2: `clamp(1.5rem, 4vw, 3rem)`, weight 700, tracking `-0.03em`
- Body-lg: `clamp(1rem, 1.5vw, 1.25rem)`, weight 400, tracking `-0.02em`
- All headings: `text-wrap: balance`

## Spacing

Bold colors amplify bad spacing. On colored sections:
- Section padding: `py-28 lg:py-36` minimum
- Generous heading breathing room
- Card gaps: generous (`gap-8` minimum)
- Description text: `max-w-2xl`

## Anti-Patterns

- No monotone palettes (all-white sections = scroll blindness)
- No timid accent usage (brand color in overlines only = wasted)
- No identical section layouts (vary: sticky splits, bento grids, asymmetric)
- No hover-only interactions (must work on mobile tap)
- No raw hex in JSX (use tokens or CSS variables)
- No decorative-only animation (every motion must express cause-effect)

## Reference

See `research/design/bold-design-principles.md` for full theory, trust-excitement matrix, and per-page progression examples.
