# Scroll Animations Library

Drop-in React hooks for scroll-driven animations using the [Motion](https://motion.dev) library.

## Dependencies

```bash
npm install motion react
```

## Files

| File | Purpose |
|------|---------|
| `animations.ts` | IntersectionObserver-based hooks (simpler, lighter) |
| `scroll-animations.ts` | Motion `scroll()` API hooks (scroll-position-driven, premium feel) |
| `easings.ts` | Pre-configured cubic-bezier easing functions |
| `tailwind-theme-reference.js` | Tailwind CSS theme tokens (copy into your config) |

## Quick Start

Copy files into your project's `src/lib/` directory:

```bash
cp animations.ts scroll-animations.ts easings.ts your-project/src/lib/
```

## Hooks Reference

### IntersectionObserver-based (`animations.ts`)

| Hook | Purpose |
|------|---------|
| `useScrollReveal()` | Single element visibility + `.visible` class |
| `useScrollRevealAll()` | Batch observer for `.reveal` elements |
| `useParallax()` | Lightweight translateY parallax |
| `useCountUp(target)` | Animated number counter on viewport entry |
| `useScrollScale()` | Scroll-driven scale + fade (Motion) |
| `useScrollFadeIn()` | Scroll-driven fade + slide-up (Motion) |
| `StaggerReveal` | Component wrapper for staggered child reveals |

### Motion scroll() API-based (`scroll-animations.ts`)

| Hook | Purpose |
|------|---------|
| `useScrollReveal(ref)` | Scroll-driven fade-up reveal |
| `useScrollRevealGroup(ref)` | Batch reveals for `[data-scroll-reveal]` children |
| `useStickyScrollScene(sectionRef, contentRef)` | Sticky scroll scene with progress 0-1 |
| `useScrollCounter(ref, target)` | Scroll-driven number counter |
| `useRoundedSection(ref)` | Border-radius 160px -> 0 on scroll |
| `useScrollDirectional(ref, direction)` | From-left or from-right reveal |
| `useScrollRef()` | Shorthand: creates ref + attaches reveal |

## Accessibility

All hooks respect `prefers-reduced-motion: reduce`. When enabled, animations are skipped and content is shown immediately.

## Tailwind Integration

Copy the theme tokens from `tailwind-theme-reference.js` into your `tailwind.config.js`:

```js
import { themeExtensions } from './libraries/scroll-animations/tailwind-theme-reference';

export default {
  theme: {
    extend: {
      ...themeExtensions,
      // Override colors with your brand palette
      colors: { ...themeExtensions.colors, 'accent-primary': '#YOUR_COLOR' },
    },
  },
};
```
