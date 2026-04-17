# Scroll-Driven UI Improvement Roadmap -- Template

> **This is a template.** Replace [BRACKETED] items with your project specifics.

**Date:** [YYYY-MM-DD]
**Status:** Ready for implementation
**Reference:** [DESIGN_REFERENCE_SITE] (e.g. a premium site you're using as visual benchmark), `Reference/` screenshots, `scroll-animation-1/`
**Frontend agent:** [PATH_TO_FRONTEND_AGENT_OR_LEAD_DEVELOPER]
**New dependencies:** None (motion v12+ already installed)

---

## Executive Summary

The [PROJECT_NAME] site needs to evolve from a template-feeling layout into a premium, scroll-driven experience inspired by [DESIGN_REFERENCE_SITE]. The core problem: every section uses the same IntersectionObserver fade-up, the same centered heading -> subtitle -> card grid layout, and there are zero images, zero trust signals, and zero scroll-driven motion.

**The fix:** Replace time-based IntersectionObserver reveals with scroll-position-driven animations using the `motion` library's `scroll()` API. Implement premium patterns: sticky scroll scenes, rounded section transitions, desktop hamburger menu, massive typography, and generous whitespace. No gradients anywhere.

**Key reference materials:**
- `Reference/sc1.png` -- Hero with hamburger menu on desktop
- `Reference/sc2.png` -- Full-screen menu overlay
- `Reference/sc3-sc9.png` -- Scroll-driven section transition sequence
- `scroll-animation-1/src/` -- Working `motion` library scroll animation example

---

## Design Principles (Mandatory)

1. **Scroll-driven, not time-driven** -- Animations are tied to scroll position via `motion` `scroll()` API. NOT IntersectionObserver timeouts.
2. **No gradients** -- Zero `bg-gradient-*`, zero gradient text, zero gradient overlays, zero gradient section fades. Use solid flat colors, opacity layers, and shadows for depth.
3. **No inline styles** -- Use CSS classes or Tailwind utilities only.
4. **No emoji icons** -- [ICON_LIBRARY] SVGs exclusively. (e.g. lucide-react, heroicons, etc.)
5. **Premium spacing** -- Generous whitespace. Think 15rem section padding, not 5rem.
6. **Massive typography** -- Display headings at 6-10rem with heavy negative letter-spacing.
7. **[REFERENCE]-style nav** -- Hamburger on ALL viewports (desktop included). Full-screen overlay on open.

> **Configurability note:** These principles are the baseline. Adapt rules 4 and 7 to your project needs. Rules 1-3 and 5-6 are strongly recommended for any premium scroll-driven site.

---

## Current State Assessment

### What works
- [LIST_CURRENT_WORKING_FEATURES]
- e.g. Hero video with cinematic overlay
- e.g. Mobile menu with clip-path animation
- e.g. Contact form with proper states
- e.g. Legal pages with sticky TOC sidebar
- e.g. Responsive grid layouts (basic)

### What must change
| Problem | Current | Target |
|---------|---------|--------|
| Animation system | IntersectionObserver fade-up (time-based) | Scroll-driven via `motion` `scroll()` API |
| Navigation | Horizontal nav bar on desktop, hamburger on mobile | Hamburger on ALL viewports, full-screen overlay |
| Section transitions | Flat hard edges between sections | Rounded corners (160px->0) on section entry |
| Layout | Every section = centered heading + card grid | Varied: sticky splits, bento grids, asymmetric |
| Visual richness | Zero images/illustrations | SVG illustrations, scroll-scaled images |
| Trust signals | None | [TrustBadge], [SecurityStrip], stat counters |
| Typography | [CURRENT_FONT] everywhere, no variation | [DISPLAY_FONT] display + [BODY_FONT] body |
| Color depth | Flat solid blocks, no variation | Opacity layers, shadows, scroll-driven color shifts |
| [OTHER_BUG] | [CURRENT_VALUE] | [TARGET_VALUE] |

### Coded but unused assets
| Asset | Location | Action |
|-------|----------|--------|
| `reveal--from-left/right/scale/blur/fade` | index.css | Migrate to scroll-driven equivalents |
| `useParallax`, `useScrollScale`, `StaggerReveal` | animations.ts | Use in scroll scenes |
| `.glass` / `.glass-dark` | index.css | Apply to cards on dark sections |
| `.text-reveal .line` | index.css | Use for hero text entrance |
| `[DISPLAY_FONT_CLASS]` | tailwind.config.js | Apply to display headings |
| `scroll-animation-1/` | repo root | Reference for scroll API patterns |

---

## P0 -- Bug Fixes (Ship Immediately)

### 0.1 [FIX_COLOR_COLLISION_OR_OTHER_P0_BUG]
Example: Two color tokens map to the same hex value. Differentiate:
```js
// tailwind.config.js
'[token-a]': '#[HEX_A]',  // [USAGE_A]
'[token-b]': '#[HEX_B]',  // [USAGE_B]
```

### 0.2 [FIX_PAGE_MISSING_ANIMATIONS]
[Page Name] never calls `useScrollRevealAll()` -- entire page is static.

---

## Wave 1 -- Scroll-Driven Animation System + Menu (~8-10hr)

### 1. Replace IntersectionObserver with Scroll-Driven Animations

#### 1.1 Core scroll animation pattern
Replace the current `reveal` CSS class system (which uses IntersectionObserver + CSS transitions triggered by `.visible`) with `motion` library's `scroll()` API.

**Current pattern (time-based, BAD):**
```js
// animations.ts -- IntersectionObserver adds .visible class after element enters viewport
observer.observe(el); // triggers CSS transition after a timeout
```

**Target pattern (scroll-driven, GOOD):**
```js
import { animate, scroll, cubicBezier } from 'motion';

// Element transforms based on scroll position, not time
scroll(
  animate(element, {
    opacity: [0, 1],
    transform: ['translateY(1.9rem)', 'translateY(0)']
  }, {
    easing: cubicBezier(0.33, 1, 0.68, 1)
  }),
  {
    target: parentSection,
    offset: ['start end', 'start 0.4']
  }
);
```

**Reference:** `scroll-animation-1/src/script.js` -- working example with layered scroll animations, staggered reveals, and image scaling all driven by scroll position.

- **Where**: Replace `useScrollRevealAll()` in every page with a new `useScrollAnimations()` hook
- **Effort**: L | **Impact**: HIGH -- transforms the entire site feel

#### 1.2 Sticky scroll scenes (Reference SC3-SC9 pattern)
Create full-viewport scroll scenes where content transforms as user scrolls through extra-height sections.

**Pattern:**
```css
/* Outer section with extra scroll height */
.scroll-scene {
  min-height: 300vh;
}
/* Inner content stays pinned */
.scroll-scene__content {
  position: sticky;
  top: 0;
  height: 100vh;
  overflow: hidden;
}
```

```js
// Animate properties across the scroll distance
scroll(
  animate('.scroll-scene__title', {
    scale: [0.25, 1],
    opacity: [0, 1]
  }, {
    easing: cubicBezier(0.65, 0, 0.35, 1)
  }),
  {
    target: document.querySelector('.scroll-scene'),
    offset: ['start start', 'end end']
  }
);
```

**Where to apply:**
- **[Main Page] hero -> first content section**: Title scales up as user scrolls past video
- **[Main Page] stats section**: Numbers count up tied to scroll position
- **[Services Page] key capabilities**: Cards reveal one by one as user scrolls through sticky scene

- **Effort**: L | **Impact**: HIGH

#### 1.3 Rounded section transitions
Sections enter viewport with `border-radius: 160px 160px 0 0` that flattens to `0` as user scrolls.

```js
scroll(
  animate(sectionElement, {
    borderRadius: ['160px 160px 0 0', '0 0 0 0']
  }),
  {
    target: sectionElement,
    offset: ['start end', 'start start']
  }
);
```

**Where**: Every section that transitions from a different-colored section. This replaces wave/diagonal dividers with a more premium approach.

- **Effort**: M | **Impact**: HIGH -- creates premium-level section transitions

#### 1.4 Image thumbnail -> full-size expansion on scroll
An image starts as a small rounded thumbnail in center, expands to fill its container as user scrolls.

```js
// Container scales from small to full
scroll(
  animate('.image-container', {
    scale: [0.2, 1],
    borderRadius: ['80px', '16px']
  }, {
    easing: cubicBezier(0.65, 0, 0.35, 1)
  }),
  {
    target: stickySection,
    offset: ['start start', '60% end']
  }
);

// Inner image counter-scales (Ken Burns effect)
scroll(
  animate('.image-container img', {
    scale: [3, 1]
  }),
  {
    target: stickySection,
    offset: ['start start', '60% end']
  }
);

// Body text fades in only after image is mostly expanded
scroll(
  animate('.body-text', {
    opacity: [0, 0, 1],
    transform: ['translateY(1.4rem)', 'translateY(1.4rem)', 'translateY(0)']
  }, {
    offset: [0, 0.6, 0.8]
  }),
  {
    target: stickySection,
    offset: ['start start', 'end end']
  }
);
```

**Where**: [Main Page] "How We Work" section, [About Page] "Story" section
- **Effort**: M | **Impact**: HIGH

#### 1.5 Easing curves
```js
const easings = {
  outCubic: cubicBezier(0.33, 1, 0.68, 1),
  inOutCubic: cubicBezier(0.65, 0, 0.35, 1),
  outQuart: cubicBezier(0.25, 1, 0.5, 1),
  inOutQuart: cubicBezier(0.76, 0, 0.24, 1),
  snappy: cubicBezier(0.2, 0.21, 0, 1),
};
```
Store in `src/lib/easings.ts` for consistent use across all scroll animations.

### 2. Full-Screen Hamburger Menu (All Viewports)

#### 2.1 Replace desktop horizontal nav with hamburger
- **What**: Remove the horizontal nav links on desktop. Show only: logo (left), hamburger icon (left of logo or top-left), [PRIMARY_CTA_LINK] (right). On ALL screen sizes.
- **Where**: `src/components/Header.tsx` -- complete rewrite
- **How** (from reference research):
  - Hamburger: two pseudo-element lines (`width: 3.3rem, height: 2px`), spaced 5px apart
  - On hover: lines animate out/in with scaleX keyframes
  - TopNav pill: `background: [PILL_COLOR]; border-radius: 56px; box-shadow: 0 1px 1px rgba(0,0,0,0.23)` appears on scroll

#### 2.2 Full-screen menu overlay
- **What**: When hamburger clicked, full-screen overlay with solid [PRIMARY_COLOR] background
- **Layout** (from reference):
  - Center/right: large nav items ([Main Page], [Services Page], [About Page], [Contact Page], etc.)
  - `font-size: 6.4rem; font-weight: 500; letter-spacing: -0.192rem; line-height: 100%`
  - Left side: social links, legal links (small text)
  - Bottom: company info
- **Transition**: Overlay slides in from top (`translateY(-100%)` -> `translateY(0)`), 0.73s ease-in-out-cubic
- **Nav items**: Each starts `opacity: 0; translateY(4rem)` and staggers in
- **Close**: Hamburger lines rotate to X

#### 2.3 Button hover pattern (double-layer)
```css
.button { overflow: hidden; position: relative; border-radius: 12rem; }
.button__in { transition: transform .35s var(--ease-out-cubic); }
.button__out { position: absolute; transform: translateY(calc(100% + 4px)); transition: transform .3s; }
.button:hover .button__in { transform: translateY(-100%); }
.button:hover .button__out { transform: translate(0, 0); }
```

#### 2.4 Link underline animation
```css
a::after {
  content: ""; background-color: currentColor;
  width: 100%; height: 1px; position: absolute; bottom: -2px; left: 0;
}
a:hover::after {
  animation: underline-in-out .6s var(--ease-power4-inOut);
}
@keyframes underline-in-out {
  0%     { transform-origin: 100%; transform: scaleX(1); }
  49.99% { transform-origin: 100%; transform: scaleX(0); }
  50%    { transform-origin: 0;   transform: scaleX(0); }
  100%   { transform-origin: 0;   transform: scaleX(1); }
}
```

- **Effort**: L (full Header rewrite) | **Impact**: HIGH

### 3. Typography Upgrade

#### 3.1 Display font for headings
Use `[DISPLAY_FONT_CLASS]` on major section headings. Font already loaded.
- **Where**: Hero text, all `<h1>`, key `<h2>` section headings
- **Effort**: S | **Impact**: HIGH

#### 3.2 Massive typography
Increase key heading sizes. Reference uses 6.4-8rem headings with tight tracking.
- Hero text: `clamp(3rem, 10vw, 8rem)` with `letter-spacing: -0.04em`
- Section headings: `clamp(2.5rem, 6vw, 6rem)`
- **Where**: `src/index.css` type scale adjustments
- **Effort**: S | **Impact**: HIGH

#### 3.3 Text-wrap balance
```css
h1, h2, h3 { text-wrap: balance; }
```
- **Effort**: S | **Impact**: MEDIUM

#### 3.4 FitText for hero (stretch text to viewport width)
```tsx
function FitText({ children, className }) {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.style.fontSize = '10px';
    el.style.whiteSpace = 'nowrap';
    el.style.width = 'fit-content';
    const scale = el.parentElement.clientWidth / el.clientWidth;
    el.style.transform = `scaleX(${scale})`;
    el.style.transformOrigin = 'left';
  }, []);
  return <span ref={ref} className={className}>{children}</span>;
}
```
- **Where**: [Main Page] hero section title
- **Effort**: M | **Impact**: HIGH

### 4. Trust Signals

#### 4.1 TrustBadge component
Create `src/components/TrustBadge.tsx` with [ICON_LIBRARY] `ShieldCheck`. Variants: default (accent on white), light (white on accent), compact.
- **Effort**: S | **Impact**: HIGH

#### 4.2 SecurityStrip component
Horizontal row of trust indicators. Example items: [TRUST_SIGNAL_1], [TRUST_SIGNAL_2], [TRUST_SIGNAL_3]. Uses Lock, Shield, Landmark icons.
- **Where**: [Main Page] (near CTA), [Contact Page] (above form)
- **Effort**: S | **Impact**: HIGH

### 5. Visual Richness (No Gradients)

#### 5.1 Dot grid background pattern
```css
.bg-dot-grid {
  background-image: radial-gradient(circle, #E4E7EC 1px, transparent 1px);
  background-size: 24px 24px;
}
.bg-dot-grid-light {
  background-image: radial-gradient(circle, rgba(255,255,255,0.08) 1px, transparent 1px);
  background-size: 24px 24px;
}
```
Note: these use `radial-gradient` for dot generation, NOT as a visual gradient effect.
- **Effort**: S | **Impact**: MEDIUM

#### 5.2 Abstract SVG illustration
Inline SVG with animated connecting lines/nodes representing [YOUR_DOMAIN_CONCEPT]. Uses SVG `<animate>` for zero-JS overhead.
- **Where**: [Main Page] "How We Work", [About Page] "Story"
- **Effort**: M | **Impact**: HIGH

#### 5.3 Noise texture overlay
```css
.noise-overlay::after {
  content: ''; position: absolute; inset: 0; opacity: 0.03;
  background-image: url("data:image/svg+xml,...turbulence...");
  pointer-events: none; mix-blend-mode: overlay;
}
```
Subtle print-like feel on dark sections.
- **Effort**: S | **Impact**: MEDIUM

### 6. Layout Breaking

#### 6.1 Bento grid for process steps
[Main Page] "How We Work": step 1 spans 2x2 with accent bg, remaining steps normal size.
- **Effort**: M | **Impact**: HIGH

#### 6.2 60/40 sticky split
[Services Page] key capabilities: left heading sticky, right cards scroll alongside.
- **Effort**: M | **Impact**: HIGH

#### 6.3 16-column grid system
For key sections, use a 16-column grid with specific column spans for asymmetric layouts:
```css
.grid-16 {
  display: grid;
  grid-template-columns: repeat(16, 1fr);
  gap: 0 1.6rem;
  padding: 0 4rem;
}
```
- **Effort**: M | **Impact**: HIGH

### 7. Card Enhancements

#### 7.1 Glassmorphism cards on dark sections
```css
.glass-blue {
  background: rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}
```
- **Effort**: M | **Impact**: HIGH

#### 7.2 Spring-physics card hovers
```tsx
<motion.div
  whileHover={{ y: -6, boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1)' }}
  transition={{ type: 'spring', damping: 20, stiffness: 300 }}
/>
```
- **Effort**: M | **Impact**: HIGH

### 8. Micro-Interactions

#### 8.1 Button press scale
`active:scale-[0.97]` on all CTAs.
- **Effort**: S | **Impact**: MEDIUM

#### 8.2 Form input focus animation
Animated underline expansion from center on focus via `::after` pseudo-element.
- **Effort**: S | **Impact**: MEDIUM

#### 8.3 Scroll indicator
Vertical line that grows/shrinks based on scroll progress (reference has this at bottom-center).
- **Effort**: S | **Impact**: LOW

---

## Wave 2 -- Content & Polish (~4-5hr)

### 9. Additional Scroll Scenes
- **9.1** Stats section: numbers count up tied to scroll position (not IntersectionObserver) (M)
- **9.2** [Services Page] alternating sections: directional scroll reveals -- left content slides from left, right from right (M)
- **9.3** [About Page] story: text reveals line-by-line tied to scroll (S)

### 10. Visual Polish
- **10.1** Enhanced stat counters with sub-labels + `tabular-nums` (S)
- **10.2** Border glow on card hover: `box-shadow: 0 0 0 1px rgba([R],[G],[B],0.3)` (S)
- **10.3** Overlapping card on "[WHY_US_SECTION]" (negative margin) (S)

### 11. Additional Typography
- **11.1** FitText on CTA headings (M)
- **11.2** Tighter letter-spacing on all headings: `-0.03em` to `-0.05em` (S)

### 12. Animation Refinement
- **12.1** Hero video parallax: video translates up slightly as user scrolls past (S)
- **12.2** Text stagger: hero lines enter with 83ms stagger, 667ms duration (already coded, verify scroll-driven) (S)
- **12.3** Floating geometric shapes on dark CTA sections (CSS animation, not scroll -- acceptable for decorative bg) (S)

---

## Wave 3 -- Deep Polish (~3-4hr)

- **13.1** Page transition animations between routes (M)
- **13.2** Scroll-synced pagination dots (vertical, side of page) (M)
- **13.3** Image Ken Burns counter-scale inside scroll-expanded containers (S)
- **13.4** Parallax depth layers (multiple z-planes moving at different scroll speeds) (M)

---

## Per-Page Breakdown

### [Main Page]
| Section | Current | Target |
|---------|---------|--------|
| Hero | Video + time-based fade-up | Video + scroll-driven text reveal, FitText title, hamburger menu |
| What We Do | Fade-up, flat white cards | Scroll-driven reveal, glassmorphism cards, dot-grid-light bg |
| How We Work | Uniform 4-col grid | Bento grid, SVG illustration, scroll scene |
| Stats | Time-based counter | Scroll-driven count-up, blur-to-focus reveal |
| Who We Serve | Fade-up, flat cards | Glassmorphism cards, scroll-driven stagger |
| Why [PROJECT_NAME] | Standard 2-col | Directional scroll reveals, TrustBadge, overlapping card |
| CTA | Fade-up | Scroll-driven scale reveal, SecurityStrip |

### [Services Page]
| Section | Target |
|---------|--------|
| Hero | Keep, add rounded entry transition |
| Service sections | Directional scroll reveals (content slides from alternating sides) |
| Key Capabilities | 60/40 sticky split, 16-col grid |
| CTA | Scroll-driven reveal, rounded section entry |

### [About Page]
| Section | Target |
|---------|--------|
| Story | Directional scroll reveals, SVG illustration |
| Values | Glassmorphism cards, scroll-driven stagger |
| Mission | Scroll-driven directional reveal, TrustBadge |
| Expertise | Spring-physics card hovers |
| CTA | Scroll-driven scale reveal |

### [Contact Page]
| Section | Target |
|---------|--------|
| Hero | Fix missing animations, TrustBadge |
| Form | SecurityStrip, input focus animations, scroll-driven reveal |

### [Additional Page]
| Section | Target |
|---------|--------|
| All sections | Scroll-driven alternating directional reveals |
| CTA | Rounded section entry, scroll reveal |

---

## Global Technical Approach

### Scroll Animation Architecture
```
src/lib/
  easings.ts              -- Easing curves (outCubic, inOutCubic, snappy, etc.)
  scroll-animations.ts    -- Scroll-driven animation hooks replacing useScrollRevealAll
  animations.ts           -- Keep for spring-based interactive states (hover, tap)
```

**New hook: `useScrollReveal()`**
```ts
import { animate, scroll, cubicBezier } from 'motion';

export function useScrollReveal(ref, options = {}) {
  useEffect(() => {
    const el = ref.current;
    if (!el || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    const stop = scroll(
      animate(el, {
        opacity: [0, 1],
        transform: [`translateY(${options.fromY || '1.9rem'})`, 'translateY(0)']
      }, {
        easing: cubicBezier(0.33, 1, 0.68, 1)
      }),
      {
        target: options.target || el,
        offset: options.offset || ['start end', 'start 0.6']
      }
    );

    return () => stop?.();
  }, []);
}
```

### Color System (No Gradients)
| Token | Hex | Usage |
|-------|-----|-------|
| `--bg-primary` | `#FFFFFF` | Pure white sections |
| `--bg-accent` | `[PRIMARY_HEX]` | Primary accent sections |
| `--bg-accent-alt` | `[SECONDARY_HEX]` | Secondary accent (differentiated) |
| `--bg-dark` | `#0e1620` | Dark/charcoal sections |
| `--bg-cream` | `#f5f4df` | Warm cream (optional) |
| `--accent` | `[ACCENT_HEX]` | Buttons, icons, badges |

**Depth without gradients:** opacity layers, `box-shadow`, scale transforms, z-index stacking, rounded border-radius transitions, backdrop-filter blur on glass cards.

### Tailwind Limitations & Workarounds
| Limitation | Workaround |
|-----------|------------|
| No scroll-driven animations | `motion` library `scroll()` API |
| No backdrop-filter shorthand | Custom `.glass-[name]` utility class |
| No clip-path utilities | Not needed -- using border-radius transitions instead |
| No 16-column grid preset | Custom `.grid-16` class |
| No spring animations | `motion` library for interactive states |
| Template-feeling layouts | Custom CSS + intentional asymmetric composition |

### Custom CSS to Add (index.css)
```css
/* Glassmorphism */
.glass-blue { background: rgba(255,255,255,0.12); backdrop-filter: blur(16px); ... }

/* Dot grid patterns */
.bg-dot-grid { background-image: radial-gradient(circle, #E4E7EC 1px, transparent 1px); ... }
.bg-dot-grid-light { ... white variant ... }

/* Noise texture */
.noise-overlay::after { ... SVG turbulence at 3% opacity ... }

/* 16-column grid */
.grid-16 { display: grid; grid-template-columns: repeat(16, 1fr); ... }

/* Scroll scene containers */
.scroll-scene { min-height: 300vh; }
.scroll-scene__content { position: sticky; top: 0; height: 100vh; overflow: hidden; }

/* Button double-layer hover */
.button-premium { overflow: hidden; position: relative; border-radius: 12rem; }

/* Link underline animation */
@keyframes underline-in-out { ... scaleX out right, in left ... }

/* Form input animated underline */
.input-animated::after { ... expand from center on focus ... }
```

### New Components to Create
| Component | Purpose |
|-----------|---------|
| `TrustBadge.tsx` | Trust badge (3 variants) |
| `SecurityStrip.tsx` | Trust/security indicators row |
| `IllustrationSVG.tsx` | Abstract domain-specific illustration |
| `FitText.tsx` | Text that scales to fill container width |
| `ScrollScene.tsx` | Reusable sticky scroll scene wrapper |
| `MenuOverlay.tsx` | Full-screen hamburger menu overlay |

---

## Anti-Patterns (NEVER Do)

- **No gradients** -- no `bg-gradient-*`, no gradient text, no gradient overlays, no gradient fades
- **No time-based content reveals** -- use scroll-driven, not IntersectionObserver fade-ups
- **No emoji icons** -- [ICON_LIBRARY] SVGs only
- **No inline styles** -- CSS classes or Tailwind utilities
- **No traditional horizontal nav** -- hamburger on all viewports
- **No template layouts** -- every section must have unique intentional composition
- **No animating width/height/top/left** -- transform + opacity only
- **No animation > 500ms** for UI micro-interactions (scroll animations are different -- they're position-based)
- **No raw hex in JSX** -- use Tailwind tokens or CSS variables
- **No hover-only interactions** -- must work on mobile tap
- **No generic AI color palettes** -- choose colors appropriate to your industry's authority signals
- **No playful design patterns** -- professional, authoritative, trustworthy
- **No decorative-only animation** -- every motion must express cause-effect

---

## Implementation Priority

| Phase | Focus | Effort | Impact |
|-------|-------|--------|--------|
| P0 | Bug fixes (color collisions, missing animations) | 30 min | HIGH |
| Wave 1 | Scroll system + Menu + Typography + Trust | 8-10hr | HIGH |
| Wave 2 | Additional scroll scenes + Polish | 4-5hr | MEDIUM |
| Wave 3 | Deep polish + Page transitions | 3-4hr | MEDIUM |

---

## Acceptance Criteria

### Build
- [ ] `npm run build` passes with zero errors
- [ ] `npm run typecheck` passes
- [ ] No new npm dependencies

### Animation
- [ ] ALL content reveals are scroll-driven (zero IntersectionObserver fade-ups remain)
- [ ] `prefers-reduced-motion` disables scroll animations, shows static content
- [ ] At least 2 sticky scroll scenes on [Main Page]
- [ ] Rounded section transitions (border-radius 160px->0) on 3+ sections

### Navigation
- [ ] Hamburger menu on desktop AND mobile
- [ ] Full-screen overlay with large nav items on open
- [ ] Smooth open/close transition

### Design Quality
- [ ] WCAG AA contrast (4.5:1 body, 3:1 large text)
- [ ] Touch targets 44x44px minimum
- [ ] Zero gradients anywhere on site
- [ ] [DISPLAY_FONT] on display headings
- [ ] Trust signals on [Main Page] and [Contact Page]
- [ ] At least 2 layout patterns that break the centered-grid formula
- [ ] Mobile responsive at 375 / 768 / 1024 / 1440px
- [ ] No horizontal scroll on mobile

---

## Reference Materials

| Resource | Location | Purpose |
|----------|----------|---------|
| Design reference screenshots | `Reference/sc1-sc9.png` | Visual reference for all patterns |
| SC2 | Menu overlay | Full-screen hamburger menu layout |
| SC3-SC9 | Scroll sequence | Scroll-driven section transitions |
| scroll-animation-1 | `scroll-animation-1/src/` | Working `motion` scroll API example |
| Frontend agent | [PATH_TO_FRONTEND_AGENT] | Senior UI Designer role + rules |
| Design research | This document + researcher report | Technical implementation details |
