# Premium Design System Template — Extracted Reference

> **This template demonstrates how to extract and document a design system from a reference website. Replace all values with your project's specifics.**
>
> To use: analyze your [Reference Site], extract exact CSS values, and fill in each section below.
> Two complementary approaches are shown — an **interpreted spec** (Sections 1-8) with implementation-ready patterns, and a **raw extraction** (Appendix A-E) with verbatim CSS pulled directly from the source. Use whichever level of detail your project needs, or combine both.

---

## 1. Color Palette

### Primary Colors

| Token               | Hex                      | Usage                                      |
|----------------------|--------------------------|---------------------------------------------|
| `--bg-primary`       | `#______` *(replace)*    | Main page background                        |
| `--bg-warm`          | `#______` *(replace)*    | Alternate section backgrounds               |
| `--bg-light`         | `#______` *(replace)*    | Subtle section alternates, card backgrounds |
| `--bg-dark`          | `#______` *(replace)*    | Dark contrast sections, footer background   |
| `--text-primary`     | `#______` *(replace)*    | Headings, primary text                      |
| `--text-secondary`   | `#______` *(replace)*    | Body text, descriptions                     |
| `--text-muted`       | `#______` *(replace)*    | Captions, labels, placeholders              |
| `--text-inverse`     | `#______` *(replace)*    | Text on dark backgrounds                    |
| `--accent-primary`   | `#______` *(replace)*    | Primary brand accent (links, CTAs)          |
| `--accent-secondary` | `#______` *(replace)*    | Secondary accent tone                       |
| `--accent-warm`      | `#______` *(replace)*    | Warm accent highlights                      |
| `--border-default`   | `#______` *(replace)*    | Default borders, dividers                   |
| `--border-subtle`    | `#______` *(replace)*    | Subtle borders, card edges                  |

### Opacity Variants

```
/* Document any semi-transparent color values found in the reference CSS */
/* Example pattern: */
#______33     /* primary dark at 20% opacity -- borders */
#______1a     /* primary dark at 10% opacity -- subtle borders */
#______4d     /* primary dark at 30% opacity -- stronger borders */
/* Replace with actual extracted values */
```

### Gradient Definitions

```css
/* Hero gradient overlay -- for text readability over images/video */
--gradient-hero-overlay: linear-gradient(
  180deg,
  rgba(___,___,___, 0) 0%,
  rgba(___,___,___, 0.6) 50%,
  rgba(___,___,___, 0.95) 100%
);

/* Section fade -- transition between background tones */
--gradient-section-fade: linear-gradient(
  180deg,
  #______ 0%,     /* replace: warm bg */
  #______ 100%    /* replace: primary bg */
);

/* Dark section gradient -- for footer/dark sections */
--gradient-dark: linear-gradient(
  180deg,
  #______ 0%,     /* replace: dark bg */
  #______ 100%    /* replace: dark secondary */
);

/* Accent gradient -- for decorative elements */
--gradient-accent: linear-gradient(
  135deg,
  #______ 0%,     /* replace: secondary accent */
  #______ 100%    /* replace: primary accent */
);
```

### Color Application Rules

- **Section alternation**: Alternate between primary and warm/light backgrounds for visual rhythm
- **Dark sections**: Use sparingly (footer, hero overlays, impact/CTA sections)
- **Accent usage**: Primary accent for interactive elements only (links, buttons, focus states)
- **Warm tones**: Subtle warm accents for backgrounds and highlights
- *(Add reference-specific color philosophy notes here)*

---

## 2. Typography

### Font Stack

```css
/* Primary font stack -- replace with reference site's font or closest alternative */
--font-sans: '[Primary Font]', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

/* Display/heading font -- if different from body */
--font-display: '[Display Font]', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

/* Import (if using Google Fonts or similar) */
@import url('https://fonts.googleapis.com/css2?family=[Font]+[Weights]&display=swap');
```

> **Note**: If the reference site uses a custom/proprietary typeface, identify the closest publicly
> available alternative. Common premium alternatives: Inter, Manrope, Satoshi, General Sans, Plus Jakarta Sans.

### Type Scale

| Element        | Size (desktop)   | Size (mobile)    | Weight | Line-Height | Letter-Spacing | Notes                    |
|----------------|------------------|------------------|--------|-------------|----------------|--------------------------|
| **Display/H1** | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Hero headlines           |
| **H2**         | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Section headings         |
| **H3**         | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Sub-section headings     |
| **H4**         | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Card titles, CTAs        |
| **Body Large** | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Lead paragraphs          |
| **Body**       | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Default body text        |
| **Body Small** | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Secondary text, captions |
| **Caption**    | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Labels, overlines, dates |
| **Overline**   | ___px / ___rem   | ___px / ___rem   | ___    | ___         | ___em          | Section labels, uppercase|

> If the reference site has additional type styles (bigNumber, navLink, timeline titles, etc.),
> add rows as needed.

### Typography Patterns

```css
/* Hero headline -- large, bold, tight leading */
.hero-headline {
  font-size: clamp(___rem, ___vw, ___rem);   /* replace: mobile min, fluid, desktop max */
  font-weight: ___;
  line-height: ___;
  letter-spacing: ___em;
  color: var(--text-primary);
}

/* Section headline */
.section-headline {
  font-size: clamp(___rem, ___vw, ___rem);
  font-weight: ___;
  line-height: ___;
  letter-spacing: ___em;
  color: var(--text-primary);
}

/* Body text -- generous line height for readability */
.body-text {
  font-size: ___rem;
  font-weight: ___;
  line-height: ___;
  color: var(--text-secondary);
}

/* Overline label (e.g., section categories) */
.overline {
  font-size: ___rem;
  font-weight: ___;
  letter-spacing: ___em;
  text-transform: uppercase;
  color: var(--text-muted);
}
```

### Global Text Features

```css
/* Document any font rendering or advanced text features found */
-webkit-font-smoothing: antialiased;
-moz-osx-font-smoothing: grayscale;
/* font-kerning, text-rendering, text-box-trim, white-space rules, etc. */
```

### Base Font Size

```css
html {
  /* Document the base font size strategy */
  /* Common patterns: */
  /* 1rem = 16px (browser default) */
  /* 1rem = 10px (html { font-size: 62.5% } or html { font-size: 10px }) */
  font-size: ___;
}
/* Responsive scaling breakpoints if used: */
/* @media (min-width: ___px) and (max-width: ___px) { font-size: calc(100vw * (___/___)) } */
```

---

## 3. Spacing & Layout System

### Spacing Scale

```css
/* Base unit: ___px (replace with reference's base unit -- commonly 4px or 8px) */
--space-1:  ___px;    /* ___rem */
--space-2:  ___px;    /* ___rem */
--space-3:  ___px;    /* ___rem */
--space-4:  ___px;    /* ___rem */
--space-5:  ___px;    /* ___rem */
--space-6:  ___px;    /* ___rem */
--space-8:  ___px;    /* ___rem */
--space-10: ___px;    /* ___rem */
--space-12: ___px;    /* ___rem */
--space-16: ___px;    /* ___rem */
--space-20: ___px;    /* ___rem */
--space-24: ___px;    /* ___rem */
--space-32: ___px;    /* ___rem */
```

### Container Widths

```css
--container-sm:  ___px;     /* Narrow content (text blocks) */
--container-md:  ___px;     /* Medium content */
--container-lg:  ___px;     /* Standard content */
--container-xl:  ___px;     /* Wide content, main container */
--container-2xl: ___px;     /* Maximum content width */
```

### Section Spacing

```css
/* Full-width sections -- generous vertical padding */
.section {
  padding-top: clamp(___rem, ___vw, ___rem);
  padding-bottom: clamp(___rem, ___vw, ___rem);
  padding-left: clamp(___rem, ___vw, ___rem);
  padding-right: clamp(___rem, ___vw, ___rem);
}

/* Content container within sections */
.section-content {
  max-width: var(--container-xl);
  margin: 0 auto;
}

/* Hero sections -- extra tall */
.section-hero {
  min-height: 100vh;
  padding-top: clamp(___rem, ___vw, ___rem);
  padding-bottom: clamp(___rem, ___vw, ___rem);
}
```

### Grid System

```css
/* Base grid -- document column count and gaps */
.grid {
  display: grid;
  grid-template-columns: repeat(___, 1fr);    /* replace: column count (e.g. 12, 16) */
  gap: clamp(___rem, ___vw, ___rem);
}

/* Common grid patterns */
.grid-2 { grid-template-columns: repeat(2, 1fr); }
.grid-3 { grid-template-columns: repeat(3, 1fr); }
.grid-4 { grid-template-columns: repeat(4, 1fr); }

/* Responsive: stack on mobile */
@media (max-width: ___px) {
  .grid-2, .grid-3, .grid-4 {
    grid-template-columns: 1fr;
  }
}
```

### Grid Column Width Calculation (if applicable)

```css
/* Some premium sites use calculated column widths with gutters and padding */
--grid-columns: ___;
--gutter-width: ___rem;
--base-padding: ___rem;
--grid-column-width: calc(
  (100vw - (2 * var(--base-padding)) - (var(--grid-columns) - 1) * var(--gutter-width))
  / var(--grid-columns)
);
```

### Responsive Breakpoints

```css
--breakpoint-sm:  ___px;
--breakpoint-md:  ___px;
--breakpoint-lg:  ___px;
--breakpoint-xl:  ___px;
--breakpoint-2xl: ___px;
```

| Name         | Query                                                        | Design Width |
|--------------|--------------------------------------------------------------|--------------|
| **Mobile**   | `max-width: ___px`                                          | ___px        |
| **Tablet**   | `(min-width: ___px) and (max-width: ___px)`                 | ___px        |
| **Desktop**  | Default                                                      | ___px        |
| **Large**    | `min-width: ___px`                                          | ___px        |

---

## 4. Border Radius

```css
--radius-sm:   ___px;       /* Small elements, inputs */
--radius-md:   ___px;       /* Cards, small panels */
--radius-lg:   ___px;       /* Large cards, sections */
--radius-xl:   ___px;       /* Feature panels */
--radius-full: 9999px;      /* Buttons, pills, tags */
```

### Component-Specific Radius

| Component           | Desktop              | Mobile            |
|---------------------|----------------------|-------------------|
| **Buttons**         | ___                  | ___               |
| **Cards / Panels**  | ___                  | ___               |
| **Images / Media**  | ___                  | ___               |
| **Navigation pill** | ___                  | ___               |
| **Inputs**          | ___                  | ___               |

### Scroll-Animated Border Radius (if applicable)

```css
/* Some premium sites animate border-radius driven by scroll progress (0 to 1) */
border-radius:
  calc(___px * (1 - var(--border-radius-progress)))   /* top-left */
  calc(___px * (1 - var(--border-radius-progress)))   /* top-right */
  calc(___px * var(--border-radius-out))              /* bottom-left */
  calc(___px * var(--border-radius-out));             /* bottom-right */
```

---

## 5. Animation System (CRITICAL)

### 5.1 Easing Functions

```css
/* Document all easing functions found in the reference CSS */
/* Common premium easing set: */
--ease-linear:          cubic-bezier(0.25, 0.25, 0.75, 0.75);
--ease-in-sine:         cubic-bezier(0.12, 0, 0.39, 0);
--ease-out-sine:        cubic-bezier(0.61, 1, 0.88, 1);
--ease-in-out-sine:     cubic-bezier(0.37, 0, 0.63, 1);
--ease-in-cubic:        cubic-bezier(0.32, 0, 0.67, 0);
--ease-out-cubic:       cubic-bezier(0.33, 1, 0.68, 1);
--ease-in-out-cubic:    cubic-bezier(0.65, 0, 0.35, 1);
--ease-in-quart:        cubic-bezier(0.5, 0, 0.75, 0);
--ease-out-quart:       cubic-bezier(0.25, 1, 0.5, 1);
--ease-in-out-quart:    cubic-bezier(0.76, 0, 0.24, 1);
--ease-out-expo:        cubic-bezier(0.16, 1, 0.3, 1);
--ease-in-out-expo:     cubic-bezier(0.87, 0, 0.13, 1);
--ease-out-back:        cubic-bezier(0.34, 1.56, 0.64, 1);
--ease-in-out-back:     cubic-bezier(0.68, -0.6, 0.32, 1.6);

/* Identify the PRIMARY easing (used most often): */
/* --ease-primary: cubic-bezier(___,___,___,___);  -- replace */

/* Identify any SIGNATURE easing (unique to the brand): */
/* --ease-signature: cubic-bezier(___,___,___,___);  -- replace */
```

### 5.2 Animation Duration Variables

```css
/* Document all timing/stagger variables found */
--title-stagger:  ___ms;
--title-duration: ___s;
--title-from-y:   ___rem;
--title-to-y:     0rem;
--text-stagger:   ___ms;
--text-duration:  ___s;
--text-from-y:    ___rem;
--text-to-y:      0rem;
--round-duration: ___s;
--stack-delay:    ___s;
--line-delay:     ___ms;
--line-ease:      var(--ease-___);
--line-duration:  ___s;
--link-transition: transform ___s var(--ease-___);
```

### 5.3 Core Animation System -- Intersection Observer

Scroll-triggered animations: elements are hidden by default and revealed as they enter the viewport.

```javascript
/**
 * Scroll-triggered reveal animation system
 * Uses Intersection Observer for performance
 */
class ScrollReveal {
  constructor(options = {}) {
    this.threshold = options.threshold || 0.15;   /* replace with reference value */
    this.rootMargin = options.rootMargin || '0px 0px -50px 0px';  /* replace */

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            // Once revealed, stop observing (one-time animation)
            this.observer.unobserve(entry.target);
          }
        });
      },
      {
        threshold: this.threshold,
        rootMargin: this.rootMargin,
      }
    );
  }

  observe(selector = '[data-reveal]') {
    document.querySelectorAll(selector).forEach((el) => {
      this.observer.observe(el);
    });
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  const reveal = new ScrollReveal({
    threshold: 0.15,
    rootMargin: '0px 0px -50px 0px',
  });
  reveal.observe('[data-reveal]');
});
```

### 5.4 Reveal Animation CSS -- Fade Up

The primary reveal animation: elements slide up and fade in.

```css
/* Base state -- hidden, shifted down */
[data-reveal] {
  opacity: 0;
  transform: translateY(___px);   /* replace: typical values 20-40px */
  transition:
    opacity ___s cubic-bezier(___,___,___,___),     /* replace: duration + easing */
    transform ___s cubic-bezier(___,___,___,___);
  will-change: opacity, transform;
}

/* Revealed state -- visible, in position */
[data-reveal].is-visible {
  opacity: 1;
  transform: translateY(0);
}

/* Stagger delays for groups of elements */
[data-reveal-delay="1"] { transition-delay: 0.1s; }
[data-reveal-delay="2"] { transition-delay: 0.2s; }
[data-reveal-delay="3"] { transition-delay: 0.3s; }
[data-reveal-delay="4"] { transition-delay: 0.4s; }
[data-reveal-delay="5"] { transition-delay: 0.5s; }
[data-reveal-delay="6"] { transition-delay: 0.6s; }
[data-reveal-delay="7"] { transition-delay: 0.7s; }
```

### 5.5 Text Reveal Animations

Sequential text line reveals -- headings appear line by line.

```css
/* Container for staggered text lines */
.text-reveal {
  overflow: hidden;
}

.text-reveal .line {
  opacity: 0;
  transform: translateY(100%);
  transition:
    opacity ___s cubic-bezier(___,___,___,___),     /* replace */
    transform ___s cubic-bezier(___,___,___,___);
}

.text-reveal.is-visible .line:nth-child(1) { transition-delay: 0s;    opacity: 1; transform: translateY(0); }
.text-reveal.is-visible .line:nth-child(2) { transition-delay: ___s;  opacity: 1; transform: translateY(0); }
.text-reveal.is-visible .line:nth-child(3) { transition-delay: ___s;  opacity: 1; transform: translateY(0); }
.text-reveal.is-visible .line:nth-child(4) { transition-delay: ___s;  opacity: 1; transform: translateY(0); }
```

### 5.6 Hero Text Animation

The hero section typically uses a specific animation pattern with staggered delays:

```css
/* Hero text entrance animation */
@keyframes heroFadeUp {
  0% {
    opacity: 0;
    transform: translateY(___px);   /* replace */
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

.hero-text-line {
  opacity: 0;
  animation: heroFadeUp ___s cubic-bezier(___,___,___,___) forwards;   /* replace */
}

/* Stagger pattern -- document the delays found in the reference */
.hero-text-line:nth-child(1) { animation-delay: ___s; }
.hero-text-line:nth-child(2) { animation-delay: ___s; }
.hero-text-line:nth-child(3) { animation-delay: ___s; }
.hero-text-line:nth-child(4) { animation-delay: ___s; }
```

### 5.7 Scroll-Linked Parallax

Lightweight parallax for background images and decorative elements:

```javascript
/**
 * Lightweight scroll-linked parallax
 * Uses requestAnimationFrame for smooth 60fps updates
 */
class ParallaxScroll {
  constructor() {
    this.elements = document.querySelectorAll('[data-parallax]');
    this.ticking = false;
    window.addEventListener('scroll', () => this.onScroll(), { passive: true });
  }

  onScroll() {
    if (!this.ticking) {
      requestAnimationFrame(() => {
        this.update();
        this.ticking = false;
      });
      this.ticking = true;
    }
  }

  update() {
    const scrollY = window.scrollY;
    this.elements.forEach((el) => {
      const speed = parseFloat(el.dataset.parallax) || 0.1;
      const rect = el.getBoundingClientRect();
      const centerY = rect.top + rect.height / 2;
      const offset = (centerY - window.innerHeight / 2) * speed;
      el.style.transform = `translateY(${offset}px)`;
    });
  }
}
```

```css
/* Parallax container */
[data-parallax] {
  will-change: transform;
  transition: none; /* Direct scroll-linked, no transition */
}
```

### 5.8 Scroll-Driven CSS Custom Property Animations

Premium sites often drive all major animations through CSS custom properties set by JavaScript,
rather than CSS scroll-timeline. JS sets `--progress`, `--animate-in`, `--translate-y-progress`,
etc. on elements based on scroll position. CSS `calc()` expressions translate these 0-1 values
into transforms:

```css
/* Examples of scroll-driven transform patterns */
transform: translateY(calc(-___rem * (1 - var(--translate-y-progress))));
opacity: calc(1 - var(--animate-in));
border-radius: calc(___px * (1 - var(--border-radius-progress)));
```

### 5.9 Smooth Scroll

```css
/* Native smooth scroll */
html {
  scroll-behavior: smooth;
}

/* For sections with anchor navigation */
html {
  scroll-padding-top: ___px; /* Account for fixed header height */
}
```

### 5.10 Image Blur-Up Loading

Progressive image loading with blur placeholder:

```css
/* Image container with blur-up effect */
.image-blur-up {
  position: relative;
  overflow: hidden;
  background-color: var(--bg-warm);
}

.image-blur-up img {
  transition: opacity 0.5s ease, filter 0.5s ease;
}

.image-blur-up img.loading {
  filter: blur(20px);
  transform: scale(1.05); /* Prevent blur edge artifacts */
}

.image-blur-up img.loaded {
  filter: blur(0);
  transform: scale(1);
}
```

### 5.11 Section Transition Animations

```css
/* Fade in from different directions */
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(___px); }   /* replace: 20-40px typical */
  to   { opacity: 1; transform: translateY(0); }
}

@keyframes fadeInDown {
  from { opacity: 0; transform: translateY(-___px); }
  to   { opacity: 1; transform: translateY(0); }
}

@keyframes fadeInLeft {
  from { opacity: 0; transform: translateX(-___px); }
  to   { opacity: 1; transform: translateX(0); }
}

@keyframes fadeInRight {
  from { opacity: 0; transform: translateX(___px); }
  to   { opacity: 1; transform: translateX(0); }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to   { opacity: 1; }
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.95); }
  to   { opacity: 1; transform: scale(1); }
}
```

### 5.12 Keyframe Animations (Reference-Specific)

```css
/* Document any unique keyframe animations found in the reference */

/* Example: text slide transitions */
@keyframes translate-out-in-x {
  0%      { opacity: 1; transform: translate(0); }
  49.99%  { opacity: 0; transform: translate(___rem); }
  50%     { opacity: 0; transform: translate(-___rem); }
  to      { opacity: 1; transform: translate(0); }
}

/* Example: underline hover animation */
@keyframes underline-in-out {
  0%      { transform-origin: 100%; transform: scaleX(1); }
  49.99%  { transform-origin: 100%; transform: scaleX(0); }
  50%     { transform-origin: 0;    transform: scaleX(0); }
  to      { transform-origin: 0;    transform: scaleX(1); }
}
```

### 5.13 Common Transition Values

```css
/* Document the transition patterns found across the reference site */

/* Color transitions */
transition: color ___s var(--ease-___);
transition: background-color ___s var(--ease-___);
transition: border ___s var(--ease-___);

/* Transform transitions */
transition: transform ___s var(--ease-___);     /* buttons */
transition: transform ___s var(--ease-___);     /* images */
transition: transform ___s var(--ease-___);     /* logo/brand */
transition: transform ___s var(--ease-___);     /* nav items */

/* Opacity transitions */
transition: opacity ___s var(--ease-___);

/* Nav / overlay transitions */
transition: transform ___s var(--ease-___) ___s;  /* staggered panels */
```

### 5.14 Counter/Stat Animation

For animated number statistics sections:

```javascript
/**
 * Animated number counter for statistics
 */
function animateCounter(element, target, duration = 2000) {
  const start = 0;
  const startTime = performance.now();

  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);

    // Ease out cubic for natural deceleration
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = Math.round(start + (target - start) * eased);

    element.textContent = current.toLocaleString();

    if (progress < 1) {
      requestAnimationFrame(update);
    } else {
      element.textContent = target.toLocaleString();
    }
  }

  requestAnimationFrame(update);
}
```

### 5.15 Timing Reference Table

| Animation            | Duration | Easing                                    | Delay        |
|----------------------|----------|-------------------------------------------|--------------|
| Reveal (fade-up)     | ___ms    | `cubic-bezier(___,___,___,___)`           | ___ms range  |
| Hero text entrance   | ___ms    | `cubic-bezier(___,___,___,___)`           | staggered    |
| Text line reveal     | ___ms    | `cubic-bezier(___,___,___,___)`           | ___ms range  |
| Image blur-up        | ___ms    | `ease`                                    | 0            |
| Hover transitions    | ___ms    | `cubic-bezier(___,___,___,___)`           | 0            |
| Button hover         | ___ms    | `ease-out`                                | 0            |
| Counter animation    | ___ms    | `ease-out-cubic`                          | 0            |
| Page section fade    | ___ms    | `ease`                                    | 0            |

**Primary easing function**: `cubic-bezier(___,___,___,___)` -- *(describe the character: e.g., "ease-out-expo feel, fast start, gentle landing")*

### 5.16 Hover Effects

```css
/* Link hover -- document the reference pattern */
/* Common patterns: opacity shift, underline animation, color change */

/* Card hover -- document the reference pattern */
/* Common patterns: lift effect, scale, shadow change, border-line draw */

/* Image hover -- document the reference pattern */
/* Common patterns: subtle scale, directional zoom, overlay reveal */

/* Button hover -- document the reference pattern */
/* Common patterns: darken + lift, text slide replacement, background pill expansion */

/* Sibling dimming -- some sites dim non-hovered siblings */
/* .list-item:hover ~ .list-item { opacity: 0.4; } */
```

---

## 6. Component Patterns

### 6.1 Navigation / Header

```
+----------------------------------------------------+
| [LOGO]    Link1  Link2  Link3  Link4    [CTA]      |
+----------------------------------------------------+
```

**Behavior:**
- Fixed/sticky at top
- *(Document: transparent on hero? solid on scroll? backdrop blur?)*
- Height: ___px
- Logo on left, nav links on right
- *(Document: hide on scroll down? show on scroll up?)*

```css
.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: ___;
  height: ___px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 clamp(___rem, ___vw, ___rem);
  transition: background-color ___s ease, backdrop-filter ___s ease;
}

.header--transparent {
  background-color: transparent;
  color: ___;      /* replace: text color on transparent bg */
}

.header--scrolled {
  background-color: rgba(___,___,___, ___);     /* replace */
  backdrop-filter: blur(___px);
  -webkit-backdrop-filter: blur(___px);
  border-bottom: 1px solid var(--border-subtle);
  color: var(--text-primary);
}

.header-nav-link {
  font-size: ___rem;
  font-weight: ___;
  letter-spacing: ___em;
  padding: ___rem ___rem;
  transition: opacity ___s ease;
}

.header-nav-link:hover {
  opacity: ___;
}
```

### 6.2 Hero Section

**Layout**: Full viewport height, centered text, optional video/image background.

```css
.hero {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: ___rem ___rem;
  overflow: hidden;
}

.hero-bg-video {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  z-index: 0;
}

.hero-overlay {
  position: absolute;
  inset: 0;
  background: var(--gradient-hero-overlay);
  z-index: 1;
}

.hero-content {
  position: relative;
  z-index: 2;
  max-width: ___px;
}

.hero-title {
  font-size: clamp(___rem, ___vw, ___rem);
  font-weight: ___;
  line-height: ___;
  letter-spacing: ___em;
  color: ___;
  margin-bottom: ___rem;
}

.hero-subtitle {
  font-size: clamp(___rem, ___vw, ___rem);
  font-weight: ___;
  line-height: ___;
  color: var(--text-secondary);
  max-width: ___px;
  margin: 0 auto;
}
```

### 6.3 Content Sections

**Pattern**: Alternating full-width sections with contained content.

```css
.section {
  padding: clamp(___rem, ___vw, ___rem) clamp(___rem, ___vw, ___rem);
}

.section--alt {
  background-color: var(--bg-warm);
}

.section--dark {
  background-color: var(--bg-dark);
  color: var(--text-inverse);
}

.section-header {
  text-align: center;
  margin-bottom: clamp(___rem, ___vw, ___rem);
  max-width: ___px;
  margin-left: auto;
  margin-right: auto;
}

.section-overline {
  font-size: ___rem;
  font-weight: ___;
  letter-spacing: ___em;
  text-transform: uppercase;
  color: var(--accent-primary);
  margin-bottom: ___rem;
}
```

### 6.4 Card Components

```css
.card {
  background: ___;
  border-radius: ___px;
  overflow: hidden;
  border: 1px solid var(--border-subtle);
  transition: transform ___s cubic-bezier(___,___,___,___),
              box-shadow ___s cubic-bezier(___,___,___,___);
}

.card:hover {
  transform: translateY(-___px);
  /* or: use border-line animation, opacity change, directional scale, etc. */
}

.card-image {
  width: 100%;
  aspect-ratio: ___ / ___;
  object-fit: cover;
}

.card-body {
  padding: ___rem;
}

.card-title {
  font-size: ___rem;
  font-weight: ___;
  line-height: ___;
  margin-bottom: ___rem;
  color: var(--text-primary);
}

.card-description {
  font-size: ___rem;
  line-height: ___;
  color: var(--text-secondary);
}
```

### Card Border Lines (alternative to box-shadow)

```css
/* Some premium sites use animated border lines instead of box-shadow on cards */
.borderLineBase {
  background-color: rgba(___, ___, ___, var(--item-border-opacity));
  width: 100%;
  height: 1px;
  position: absolute;
  top: 0;
}

.borderLine {
  transform-origin: 100%;  /* starts from right */
  background-color: var(--text-primary);
  height: 1px;
  transform: scaleX(0);
  transition: transform ___s var(--ease-___);
}

/* On hover: line draws from left */
.card:hover .borderLine {
  transform-origin: 0;
  transform: scaleX(1);
}
```

### 6.5 CTA Buttons

```css
/* Primary CTA */
.btn-primary {
  display: inline-flex;
  align-items: center;
  gap: ___rem;
  padding: ___rem ___rem;
  font-size: ___rem;
  font-weight: ___;
  letter-spacing: ___em;
  color: ___;
  background-color: ___;
  border: none;
  border-radius: ___px;     /* pill shape: 9999px or very large value */
  cursor: pointer;
  transition: background-color ___s ease-out, transform ___s ease-out;
}

.btn-primary:hover {
  background-color: ___;
  transform: translateY(-___px);
}

.btn-primary:active {
  transform: translateY(0);
}

/* Secondary/outline CTA */
.btn-secondary {
  display: inline-flex;
  align-items: center;
  gap: ___rem;
  padding: ___rem ___rem;
  font-size: ___rem;
  font-weight: ___;
  color: ___;
  background: transparent;
  border: ___px solid var(--border-default);
  border-radius: ___px;
  cursor: pointer;
  transition: border-color ___s ease-out, background-color ___s ease-out;
}

.btn-secondary:hover {
  border-color: var(--text-primary);
  background-color: rgba(___,___,___, 0.04);
}

/* Text link CTA with arrow */
.btn-text {
  display: inline-flex;
  align-items: center;
  gap: ___rem;
  font-size: ___rem;
  font-weight: ___;
  color: var(--text-primary);
  transition: gap ___s ease-out;
}

.btn-text:hover {
  gap: ___rem;    /* Arrow slides on hover */
}

.btn-text .arrow {
  transition: transform ___s ease-out;
}

.btn-text:hover .arrow {
  transform: translateX(___px);
}
```

### Button Hover Mechanic (Slide-Up Reveal -- if applicable)

```css
/* Some premium sites use a text-replacement hover: .buttonIn slides up,
   .buttonOut slides in from below with a scaling background pill */
.button:hover .buttonIn  { transform: translateY(-100%); }
.button:hover .buttonOut { transform: translate(0, 0); }
.buttonOut::before {
  background-color: var(--main-color);
  border-radius: var(--innerRadius);
  transform: scaleX(0.75);
  transition: transform ___s var(--ease-___);
}
.button:hover .buttonOut::before { transform: scaleX(1); }
```

### Button Variants

| Variant              | --main-color      | --background-color | --border-color    |
|----------------------|-------------------|--------------------|-------------------|
| **default**          | *(replace)*       | *(replace)*        | *(replace)*       |
| **filled**           | *(replace)*       | *(replace)*        | --                |
| **outlined**         | *(replace)*       | transparent        | *(replace)*       |
| **ghost**            | *(replace)*       | transparent        | transparent       |

### 6.6 Footer

```css
.footer {
  background-color: var(--bg-dark);
  color: var(--text-inverse);
  padding: clamp(___rem, ___vw, ___rem) clamp(___rem, ___vw, ___rem);
}

.footer-grid {
  display: grid;
  grid-template-columns: repeat(___, 1fr);
  gap: ___rem;
  max-width: var(--container-xl);
  margin: 0 auto ___rem;
}

.footer-heading {
  font-size: ___rem;
  font-weight: ___;
  letter-spacing: ___em;
  text-transform: uppercase;
  margin-bottom: ___rem;
  color: var(--text-muted);
}

.footer-link {
  display: block;
  font-size: ___rem;
  font-weight: ___;
  color: rgba(255, 255, 255, 0.7);
  padding: ___rem 0;
  transition: color ___s ease;
}

.footer-link:hover {
  color: white;
}

.footer-divider {
  border: none;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin: ___rem 0;
}

.footer-bottom {
  font-size: ___rem;
  color: rgba(255, 255, 255, 0.5);
}
```

### 6.7 Stats / Metrics Display

```css
.stats-grid {
  display: grid;
  grid-template-columns: repeat(___, 1fr);
  gap: ___rem;
  text-align: center;
}

.stat-value {
  font-size: clamp(___rem, ___vw, ___rem);
  font-weight: ___;
  line-height: ___;
  color: var(--text-primary);
  margin-bottom: ___rem;
}

.stat-label {
  font-size: ___rem;
  font-weight: ___;
  color: var(--text-secondary);
}

@media (max-width: ___px) {
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
```

### 6.8 Timeline Component (if applicable)

```css
.timeline {
  position: relative;
  max-width: var(--container-lg);
  margin: 0 auto;
}

.timeline::before {
  content: '';
  position: absolute;
  left: 50%;
  top: 0;
  bottom: 0;
  width: 1px;
  background: var(--border-default);
  transform: translateX(-50%);
}

.timeline-item {
  display: grid;
  grid-template-columns: 1fr ___px 1fr;
  gap: ___rem;
  align-items: start;
  margin-bottom: ___rem;
}

.timeline-year {
  font-size: ___rem;
  font-weight: ___;
  letter-spacing: ___em;
  text-transform: uppercase;
  color: var(--accent-primary);
  text-align: center;
  position: relative;
}

.timeline-year::after {
  content: '';
  width: ___px;
  height: ___px;
  border-radius: 50%;
  background: var(--accent-primary);
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

@media (max-width: ___px) {
  .timeline-item {
    grid-template-columns: ___px 1fr;
  }
  .timeline::before {
    left: ___px;
  }
}
```

### 6.9 Navigation Menu (Full-Screen Overlay -- if applicable)

```css
/* Document if reference uses a full-screen nav overlay */
/* Key patterns to capture: */
/* - Background overlay opacity and color */
/* - Panel slide direction and transition */
/* - Staggered color layer reveals (if multi-layer) */
/* - Nav link entrance animations and stagger delays */
/* - Hamburger to X animation */

.menu-overlay {
  opacity: ___;
  background-color: var(--bg-dark);
}

.menu-panel {
  background-color: ___;
  transform: translateY(-100%);
  transition: transform ___s var(--ease-___) ___s;
}

.menu-panel.open {
  transform: translateY(0);
}

.menu-link {
  transform: translateY(___rem);
  opacity: 0;
  transition: transform ___s var(--ease-___), opacity ___s var(--ease-___);
}

.menu-link.visible {
  transform: translateY(0);
  opacity: 1;
}
```

### 6.10 Hero Media Wrapper (Scroll-Driven Video/Image)

```css
/* Premium hero with scroll-driven parallax and animated border radius */
.mediaWrapper {
  z-index: 2;
  pointer-events: none;
  will-change: transform;
  width: 100%;
  height: 100dvh;
  position: absolute;
  top: 0;
  left: 0;
  overflow: hidden;

  /* Scroll-driven transform -- replace values */
  transform:
    translateY(calc(-___rem * (1 - var(--translate-y-progress))))
    translateY(calc(-100vh * (1 - var(--intro-animation-progress))));

  /* Animated bottom corners */
  border-radius:
    0px 0px
    calc(___vw * (1 - var(--border-radius-progress)))
    calc(___vw * (1 - var(--border-radius-progress)));
}
```

### 6.11 Hero Title (Scroll-Driven Opacity/Position)

```css
/* Hero title that fades and shifts based on scroll progress */
.hero-title-scroll {
  color: ___;
  z-index: 4;
  text-align: center;
  will-change: opacity;
  flex-direction: column;
  align-items: center;
  gap: ___rem;
  display: flex;
  position: absolute;
  left: 50%;
  transform: translate(-50%, calc(-100% + var(--animate-in) * ___rem));
  max-width: ___rem;
  opacity: calc(1 - var(--animate-in));
}
```

### 6.12 Text Slides (Rotating Caption with Progress Bar)

```css
/* Rotating text captions with vertical progress bar indicator */
.textSlides {
  width: ___rem;
  height: ___rem;
  color: ___;
  padding-left: ___rem;
  position: relative;
}

/* Progress bar (vertical left line) -- background track */
.textSlides::before {
  background-color: ___;
  opacity: 0.2;
  width: 2px;
  height: 100%;
  border-radius: 2px;
}

/* Progress bar -- active fill */
.textSlides::after {
  background-color: ___;
  width: 2px;
  height: 100%;
  border-radius: 2px;
  transform-origin: top;
  transform: scaleY(var(--slide-progress));
}
```

---

## 7. Visual Effects

### Box Shadows

```css
/* Elevation system */
--shadow-sm:  0 1px 2px rgba(0, 0, 0, ___);
--shadow-md:  0 4px 6px -1px rgba(0, 0, 0, ___),
              0 2px 4px -2px rgba(0, 0, 0, ___);
--shadow-lg:  0 10px 15px -3px rgba(0, 0, 0, ___),
              0 4px 6px -4px rgba(0, 0, 0, ___);
--shadow-xl:  0 20px 25px -5px rgba(0, 0, 0, ___),
              0 8px 10px -6px rgba(0, 0, 0, ___);
--shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, ___);
```

> **Note**: Some premium sites avoid box-shadows on cards entirely, using 1px border lines
> and opacity changes instead. Document what the reference actually does.

### Backdrop Blur

```css
/* Glass morphism for header and overlays */
.glass {
  background: rgba(___,___,___, ___);
  backdrop-filter: blur(___px);
  -webkit-backdrop-filter: blur(___px);
  border: 1px solid rgba(___,___,___, ___);
}
```

### Image Treatment

```css
/* Standard image rounding */
.image-rounded {
  border-radius: var(--radius-lg);
  overflow: hidden;
}

/* Full-bleed images */
.image-fullbleed {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* Aspect ratio containers */
.aspect-video  { aspect-ratio: 16 / 9; }
.aspect-wide   { aspect-ratio: 16 / 10; }
.aspect-photo  { aspect-ratio: 3 / 2; }
.aspect-square { aspect-ratio: 1 / 1; }
```

---

## 8. Implementation Notes

### Global Reset

```css
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

a {
  color: inherit;
  text-decoration: none;
}

button {
  cursor: pointer;
  background: none;
  border: none;
}

input {
  appearance: none;
  background: none;
  border: none;
  outline: none;
}

body {
  font-family: var(--font-___);
  background-color: var(--bg-primary);
  color: var(--text-primary);
  overscroll-behavior: none;
  font-size: ___rem;
}

html, body {
  max-width: 100vw;
}
```

### Recommended Tailwind Config Extensions (if using Tailwind)

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        // Replace all values with your extracted palette
        'bg-warm':        '#______',
        'bg-light':       '#______',
        'text-primary':   '#______',
        'text-secondary': '#______',
        'text-muted':     '#______',
        'border-default': '#______',
        'border-subtle':  '#______',
        'accent':         '#______',
        'accent-secondary': '#______',
      },
      fontFamily: {
        sans: ['[Primary Font]', ...defaultTheme.fontFamily.sans],
      },
      borderRadius: {
        'card':  '___px',
        'panel': '___px',
      },
      animation: {
        'fade-up':  'fadeInUp ___s cubic-bezier(___,___,___,___) forwards',
        'fade-in':  'fadeIn ___s ease forwards',
        'scale-in': 'scaleIn ___s cubic-bezier(___,___,___,___) forwards',
      },
      keyframes: {
        fadeInUp: {
          '0%':   { opacity: '0', transform: 'translateY(___px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        fadeIn: {
          '0%':   { opacity: '0' },
          '100%': { opacity: '1' },
        },
        scaleIn: {
          '0%':   { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
      },
    },
  },
};
```

### React Scroll Reveal Hook (if using React)

```tsx
import { useEffect, useRef, useState } from 'react';

export function useScrollReveal(options?: IntersectionObserverInit) {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      {
        threshold: 0.15,
        rootMargin: '0px 0px -50px 0px',
        ...options,
      }
    );

    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);

  return { ref, isVisible };
}

// Usage
function Section() {
  const { ref, isVisible } = useScrollReveal();
  return (
    <div
      ref={ref}
      className={`transition-all duration-800 ease-out
        ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}`}
    >
      Content here
    </div>
  );
}
```

### Staggered Children Component (if using React)

```tsx
interface StaggerProps {
  children: React.ReactNode[];
  delayMs?: number;
  className?: string;
}

export function StaggerReveal({ children, delayMs = 100, className }: StaggerProps) {
  const { ref, isVisible } = useScrollReveal();

  return (
    <div ref={ref} className={className}>
      {children.map((child, i) => (
        <div
          key={i}
          className={`transition-all duration-700 ease-out
            ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}
          style={{ transitionDelay: isVisible ? `${i * delayMs}ms` : '0ms' }}
        >
          {child}
        </div>
      ))}
    </div>
  );
}
```

### Tech Stack (document the reference site's stack)

- **Framework**: *(e.g., Next.js, Nuxt, Astro, SvelteKit)*
- **CSS**: *(e.g., SCSS Modules, Tailwind, vanilla CSS, CSS-in-JS)*
- **CMS**: *(e.g., Sanity, Contentful, Strapi, headless WordPress)*
- **Video CDN**: *(e.g., Cloudflare, Mux, Cloudinary)*
- **Fonts**: *(e.g., custom variable fonts, Google Fonts, Adobe Fonts)*
- **Animations**: *(e.g., scroll-driven via JS + CSS custom props, GSAP, Framer Motion)*
- **Deployment**: *(e.g., Vercel, Netlify, AWS)*
- **Image optimization**: *(e.g., CDN with blur placeholders, responsive srcset)*

---

## 9. Design Philosophy Summary

Document the core design principles observed in the reference site. Common patterns in premium sites:

1. **[Tone/Character]** -- *(e.g., "Dreamy but rooted in reality. Aspirational yet reassuring.")*
2. **Rounded corners and gentle curves** -- Sense of lightness and welcome
3. **Upward-guiding visual cues** -- Subtle directional hints in the design
4. **Signature color palette** -- *(describe the palette philosophy)*
5. **Clean geometric sans-serif typography** -- *(describe the type character)*
6. **Generous whitespace** -- Let content breathe; sections are spacious
7. **Progressive disclosure** -- Content reveals as you scroll, creating narrative flow
8. **Full-bleed imagery** -- Immersive visuals that take full viewport width
9. **Minimal UI chrome** -- Very few borders, shadows used sparingly
10. **Narrative scrolling** -- The page tells a story from top to bottom

### Key Design Principles Checklist

- [ ] No pure black (#000) or pure white (#fff) -- uses tinted neutrals
- [ ] Scroll-driven animations throughout (border radius, opacity, parallax, text reveals)
- [ ] Micro-interaction richness (underlines, button slides, hamburger animations)
- [ ] Generous section spacing (120-150px+ between major sections on desktop)
- [ ] Pill-shaped buttons (very large border-radius)
- [ ] Viewport-filling hero/media sections
- [ ] Variable font weight control (if using variable fonts)
- [ ] Staggered reveal animation delays
- [ ] Card styling via border lines / opacity, not heavy box-shadows

---

## Appendix: Section Spacing Reference

| Section              | Padding-top (D)      | Padding-bottom (D)   | Padding-top (M)  | Padding-bottom (M)  |
|----------------------|----------------------|----------------------|-------------------|----------------------|
| **Hero**             | --                   | ___                  | --                | ___                 |
| **Content Section**  | ___                  | ___                  | ___               | ___                 |
| **Features**         | ___                  | ___                  | ___               | ___                 |
| **Stats**            | ___                  | ___                  | ___               | ___                 |
| **CTA**              | ___                  | ___                  | ___               | ___                 |
| **Footer**           | ___                  | ___                  | ___               | ___                 |

### Internal Spacing

```css
/* Content gaps within sections */
gap: ___rem;     /* desktop content blocks */
gap: ___rem;     /* mobile content blocks */
gap: ___rem;     /* list items, links */
gap: ___rem;     /* button groups */
```

---

## Sources & References

- [Reference Site] website: *(URL)*
- Brand identity / design studio: *(URL if available)*
- Case study / portfolio: *(URL if available)*
- Additional sources: *(URLs)*
