---
name: scroll-animations
description: Scroll-driven animation patterns using the Motion library — hooks, sticky scenes, rounded sections, parallax. Triggers when editing animation files, scroll components, or TSX with reveal/scroll patterns.
---

# Scroll-Driven Animation System

Use the Motion library's `scroll()` API for position-driven animations. Never use time-based IntersectionObserver fade-ups for content reveals.

## Core Pattern

```typescript
import { animate, scroll } from 'motion';

// Element transforms based on scroll POSITION, not time
scroll(
  animate(element, {
    opacity: [0, 1],
    transform: ['translateY(30px)', 'translateY(0)'],
  }),
  {
    target: element,
    offset: ['start end', 'start 0.6'],
  }
);
```

## Available Hooks (from `src/lib/`)

### `scroll-animations.ts` (Motion scroll() API — preferred)

| Hook | Usage |
|------|-------|
| `useScrollReveal(ref)` | Fade-up tied to scroll position |
| `useScrollRevealGroup(containerRef)` | Batch reveals for `[data-scroll-reveal]` children |
| `useStickyScrollScene(sectionRef, contentRef)` | Sticky scene with progress 0-1 |
| `useScrollCounter(ref, target)` | Scroll-driven number counter |
| `useRoundedSection(ref)` | Border-radius 160px→0 on scroll |
| `useScrollDirectional(ref, 'left'|'right')` | Directional reveal |
| `useScrollRef()` | Shorthand: creates ref + attaches reveal |

### `animations.ts` (IO-based — for simpler cases)

| Hook | Usage |
|------|-------|
| `useScrollReveal()` | IO visibility + `.visible` class |
| `useScrollRevealAll()` | Batch observer for `.reveal` elements |
| `useParallax({ speed })` | Lightweight translateY parallax |
| `useCountUp(target)` | Animated number on viewport entry |
| `useScrollScale()` | Scroll-driven scale + fade |
| `useScrollFadeIn()` | Scroll-driven fade + slide-up |

### `easings.ts`

```typescript
easings.outCubic    // cubicBezier(0.33, 1, 0.68, 1)  — primary
easings.inOutCubic  // cubicBezier(0.65, 0, 0.35, 1)  — symmetric
easings.snappy      // cubicBezier(0.2, 0.21, 0, 1)   — hero text
```

## Key Patterns

### Sticky Scroll Scene
```css
.scroll-scene { min-height: 300vh; }
.scroll-scene__content { position: sticky; top: 0; height: 100vh; overflow: hidden; }
```

### Rounded Section Entry
Sections enter with `border-radius: 160px 160px 0 0` that flattens to `0` as user scrolls past.

### Image Expansion on Scroll
Container scales from `0.2` → `1`, inner image counter-scales from `3` → `1` (Ken Burns).

### Stagger Timing
Default stagger: `83ms` between sequential items. Use `staggerStyle(index)` or `data-reveal-delay`.

## Rules

1. ALL content reveals must be scroll-driven (zero IO fade-ups)
2. `prefers-reduced-motion: reduce` must skip animations and show static content
3. Only animate `transform` + `opacity` (never width/height/top/left)
4. Motion's `scroll()` handles RAF — no manual throttling needed
5. Minimum 2 sticky scroll scenes on main page
6. Rounded section transitions on 3+ colored sections

## Video Scroll Scrubbing

For scroll-driven video, use `video.currentTime = progress * duration` in a `scroll()` callback. Video MUST be re-encoded with `-g 1` (all keyframes) via ffmpeg. See `.claude/research/scroll-scrubbed-video.md` for the full encoding guide.

## Reference

- `libraries/scroll-animations/` — Drop-in hook files
- `.claude/research/video-smoothing.md` — Frame stepping fixes
- `.claude/research/scroll-scrubbed-video.md` — Full video encoding research
