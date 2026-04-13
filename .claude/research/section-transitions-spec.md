# Section Transition Techniques — Research Spec

> Ready-to-use CSS/React code for smooth section-to-section transitions. Adapt colors and patterns to your project.

## Project Context (Replace with Your Palette)

```css
/* Example palette — replace with your own */
--bg-primary: #FFFFFF;        /* white */
--bg-warm: #ECEBE8;           /* warm cream */
--bg-light: #F7F6F4;          /* warm light */
--bg-dark: #101828;           /* charcoal */
--accent-primary: #2563EB;    /* primary accent */
--accent-secondary: #7CB9E8;  /* secondary accent */
--accent-warm: #D4A574;       /* warm accent */
```

**Existing animation system**: Reveal animations via Intersection Observer (`.reveal`, `.reveal--from-left`, etc.), custom easing `cubic-bezier(0.16, 1, 0.3, 1)`.

---

## Technique A: SVG Wave Dividers

**Best for**: Light to Dark transitions, Hero to Content, any color pair needing organic flow.

### Basic Wave Divider (React Component)

```tsx
interface WaveDividerProps {
  fillColor?: string;     // Color of the NEXT section
  className?: string;
  flip?: boolean;         // Flip vertically for top-of-section
  variant?: 'wave' | 'curve' | 'peaks' | 'blob';
}

const WaveDivider = ({ fillColor = '#101828', className = '', flip = false, variant = 'wave' }: WaveDividerProps) => {
  const paths = {
    wave: 'M0,60 Q300,120 600,60 T1200,60 L1200,120 L0,120 Z',
    curve: 'M0,120 Q600,0 1200,120 Z',
    peaks: 'M0,120 L200,40 L400,80 L600,20 L800,60 L1000,30 L1200,80 L1200,120 Z',
    blob: 'M0,60 C150,120 300,0 450,60 C600,120 750,30 900,80 C1050,130 1150,40 1200,70 L1200,120 L0,120 Z',
  };

  return (
    <div className={`w-full overflow-hidden leading-none ${flip ? 'rotate-180' : ''} ${className}`}>
      <svg
        viewBox="0 0 1200 120"
        preserveAspectRatio="none"
        className="w-full h-[clamp(40px,8vw,100px)]"
      >
        <path d={paths[variant]} fill={fillColor} />
      </svg>
    </div>
  );
};
```

### Multi-Layer Parallax Waves

**Visual effect**: Creates depth — 3 wave layers at different opacities moving at different speeds. Premium feel like Stripe's homepage.

```tsx
const ParallaxWaves = ({ nextColor = '#101828' }: { nextColor?: string }) => (
  <div className="relative w-full h-[120px] overflow-hidden">
    <svg viewBox="0 0 1200 120" preserveAspectRatio="none"
      className="absolute bottom-0 w-full h-full animate-[wave-slow_12s_ease-in-out_infinite]"
      style={{ fill: `${nextColor}33` }}>  {/* 20% opacity */}
      <path d="M0,40 Q300,100 600,40 T1200,40 L1200,120 L0,120 Z" />
    </svg>
    <svg viewBox="0 0 1200 120" preserveAspectRatio="none"
      className="absolute bottom-0 w-full h-full animate-[wave-medium_8s_ease-in-out_infinite]"
      style={{ fill: `${nextColor}80` }}>  {/* 50% opacity */}
      <path d="M0,60 Q300,120 600,60 T1200,60 L1200,120 L0,120 Z" />
    </svg>
    <svg viewBox="0 0 1200 120" preserveAspectRatio="none"
      className="absolute bottom-0 w-full h-full animate-[wave-fast_6s_ease-in-out_infinite]"
      style={{ fill: nextColor }}>
      <path d="M0,80 Q300,100 600,80 T1200,80 L1200,120 L0,120 Z" />
    </svg>
  </div>
);
```

**Keyframes to add to `tailwind.config.js`:**

```js
keyframes: {
  'wave-slow': {
    '0%, 100%': { transform: 'translateX(0)' },
    '50%': { transform: 'translateX(-3%)' },
  },
  'wave-medium': {
    '0%, 100%': { transform: 'translateX(0)' },
    '50%': { transform: 'translateX(-2%)' },
  },
  'wave-fast': {
    '0%, 100%': { transform: 'translateX(0)' },
    '50%': { transform: 'translateX(-1%)' },
  },
},
animation: {
  'wave-slow': 'wave-slow 12s ease-in-out infinite',
  'wave-medium': 'wave-medium 8s ease-in-out infinite',
  'wave-fast': 'wave-fast 6s ease-in-out infinite',
},
```

### Animated SVG Wave (SMIL animation — no JS needed)

```html
<svg viewBox="0 0 1200 120" preserveAspectRatio="none" class="w-full h-[80px]">
  <path fill="#101828">
    <animate
      attributeName="d"
      dur="10s"
      repeatCount="indefinite"
      values="
        M0,60 Q300,120 600,60 T1200,60 L1200,120 L0,120 Z;
        M0,80 Q300,40 600,80 T1200,80 L1200,120 L0,120 Z;
        M0,60 Q300,120 600,60 T1200,60 L1200,120 L0,120 Z
      "
    />
  </path>
</svg>
```

### Responsive Height

```css
/* Use clamp for responsive wave height */
.section-divider svg {
  height: clamp(40px, 8vw, 120px);
}

/* Or breakpoints */
@media (min-width: 640px)  { .section-divider svg { height: 60px; } }
@media (min-width: 1024px) { .section-divider svg { height: 80px; } }
@media (min-width: 1280px) { .section-divider svg { height: 120px; } }
```

---

## Technique B: CSS Clip-Path Sections

**Best for**: Diagonal/angled sections, geometric look, premium aesthetic.

### Slanted Section Divider

```css
:root {
  --slant-size: 50px;
  --slant-gap: 10px;
}

.section-top {
  clip-path: polygon(0 0, 100% 0, 100% 100%, 0 calc(100% - var(--slant-size)));
}

.section-bottom {
  clip-path: polygon(0 0, 100% var(--slant-size), 100% 100%, 0 100%);
  margin-top: calc(var(--slant-gap) - var(--slant-size));
}
```

### Tailwind Implementation (Slanted)

```tsx
{/* Section with diagonal bottom */}
<section
  className="relative bg-[var(--bg-dark)] text-white py-24"
  style={{ clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 60px), 0 100%)' }}
>
  {/* Content */}
</section>

{/* Next section overlaps upward */}
<section
  className="relative bg-[var(--bg-warm)] py-24 -mt-[50px]"
  style={{ clipPath: 'polygon(0 60px, 100% 0, 100% 100%, 0 100%)' }}
>
  {/* Content */}
</section>
```

### Arrow/Chevron Section Divider

```css
.section-arrow-top {
  clip-path: polygon(0 0, 100% 0, 100% calc(100% - 50px), 50% 100%, 0 calc(100% - 50px));
}

.section-arrow-bottom {
  clip-path: polygon(0 0, 50% 50px, 100% 0, 100% 100%, 0 100%);
  margin-top: -40px;
}
```

### Curved Section (Ellipse)

```tsx
{/* Section with curved bottom */}
<section className="relative bg-[var(--accent-primary)] text-white py-24 pb-32">
  {/* Content */}
  <div
    className="absolute bottom-0 left-0 w-full h-[80px]"
    style={{
      background: 'var(--bg-warm)', /* next section color */
      clipPath: 'ellipse(55% 100% at 50% 100%)',
    }}
  />
</section>
```

### Responsive Clip-Path with calc()

```css
/* The angle stays visually consistent regardless of viewport width */
.diagonal-section {
  --angle: 3deg;
  --offset: calc(100vw * tan(var(--angle))); /* modern browsers */
  clip-path: polygon(0 0, 100% 0, 100% calc(100% - var(--offset)), 0 100%);
}

/* Fallback for older browsers */
.diagonal-section {
  clip-path: polygon(0 0, 100% 0, 100% calc(100% - 5vw), 0 100%);
}
```

### Browser Support

- `clip-path: polygon()` — 97%+ global support (all modern browsers)
- `clip-path: ellipse()` — same support
- Transitions between clip-path values work IF same number of points
- Fully GPU-accelerated

---

## Technique C: Gradient Blending Between Sections

**Best for**: Subtle transitions, same-family color pairs, premium minimalist feel (Mercury-style).

### CSS Gradient Transition Strip

```tsx
{/* Section 1: Light background */}
<section className="bg-[var(--bg-warm)] py-24">
  {/* Content */}
</section>

{/* Gradient blend strip */}
<div
  className="h-32"
  style={{
    background: 'linear-gradient(180deg, var(--bg-warm) 0%, var(--bg-dark) 100%)',
  }}
/>

{/* Section 2: Dark background */}
<section className="bg-[var(--bg-dark)] text-white py-24">
  {/* Content */}
</section>
```

### Radial Gradient Spotlight Transition

```tsx
<div
  className="h-48 relative"
  style={{
    background: `
      radial-gradient(ellipse 80% 100% at 50% 0%, var(--bg-warm) 0%, transparent 70%),
      var(--bg-dark)
    `,
  }}
/>
```

### Extended Section Gradient (No Strip Needed)

```tsx
{/* The section itself fades at the bottom */}
<section
  className="py-24"
  style={{
    background: 'linear-gradient(180deg, var(--bg-warm) 0%, var(--bg-warm) 70%, var(--bg-dark) 100%)',
  }}
>
  <div className="max-w-7xl mx-auto px-6 pb-32">
    {/* Content stays in the solid-color zone */}
  </div>
</section>
```

### Animated Gradient Transition (CSS @property)

```css
@property --gradient-start {
  syntax: '<color>';
  initial-value: #ECEBE8;
  inherits: false;
}

@property --gradient-end {
  syntax: '<color>';
  initial-value: #101828;
  inherits: false;
}

.gradient-transition {
  background: linear-gradient(180deg, var(--gradient-start), var(--gradient-end));
  transition: --gradient-start 0.6s ease, --gradient-end 0.6s ease;
}
```

---

## Technique D: Diagonal/Skewed Sections (transform: skewY)

**Best for**: Bold, dynamic feel. Great for accent color sections. Stripe-like energy.

### Pseudo-Element Approach (Recommended)

```css
.skewed-section {
  position: relative;
  padding: 6rem 0;
}

.skewed-section::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, var(--accent-primary) 0%, var(--accent-secondary) 100%);
  transform: skewY(-3deg);
  transform-origin: top left;
  z-index: -1;
}
```

### Tailwind React Implementation

```tsx
const SkewedSection = ({
  children,
  bgClass = 'bg-[var(--accent-primary)]',
  angle = -3,
}: {
  children: React.ReactNode;
  bgClass?: string;
  angle?: number;
}) => (
  <section className="relative py-24 overflow-hidden">
    {/* Skewed background */}
    <div
      className={`absolute inset-0 ${bgClass} -z-10`}
      style={{
        transform: `skewY(${angle}deg)`,
        transformOrigin: 'top left',
      }}
    />
    {/* Content stays un-skewed */}
    <div className="max-w-7xl mx-auto px-6 relative">
      {children}
    </div>
  </section>
);
```

### Responsive Padding for Skewed Sections

```css
:root {
  /* tan(3deg) / 2 ≈ 0.02618 */
  --skew-magic: 0.02618;
  --skew-padding: calc(100vw * var(--skew-magic));
}

.skewed-section {
  padding-top: calc(4rem + var(--skew-padding));
  padding-bottom: calc(4rem + var(--skew-padding));
}
```

### Double Skew (Top and Bottom)

```tsx
<section className="relative py-32 my-16 overflow-hidden">
  <div
    className="absolute inset-[-5%] bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-secondary)] -z-10"
    style={{ transform: 'skewY(-3deg)' }}
  />
  <div className="max-w-7xl mx-auto px-6">
    {/* Content */}
  </div>
</section>
```

---

## Technique E: Overlapping Elements Between Sections

**Best for**: Cards, stats, testimonials that bridge two color zones. Creates visual connection.

### Overlapping Card Grid

```tsx
{/* Dark section */}
<section className="bg-[var(--bg-dark)] text-white pt-24 pb-40">
  <div className="max-w-7xl mx-auto px-6">
    <h2>Our Impact</h2>
  </div>
</section>

{/* Cards that overlap the boundary */}
<div className="max-w-7xl mx-auto px-6 -mt-24 relative z-10">
  <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
    <div className="bg-white rounded-xl p-8 shadow-xl">
      {/* Card content */}
    </div>
    {/* ... more cards */}
  </div>
</div>

{/* Light section continues */}
<section className="bg-[var(--bg-warm)] pt-12 pb-24">
  {/* Content */}
</section>
```

### Overlapping Image/Visual

```tsx
{/* Hero or intro section */}
<section className="bg-[var(--bg-dark)] text-white pt-24 pb-40">
  {/* Content */}
</section>

{/* Overlapping visual element */}
<div className="relative max-w-5xl mx-auto px-6 -mt-32 z-10">
  <div className="rounded-2xl overflow-hidden shadow-2xl">
    <img src="/dashboard-preview.png" alt="Dashboard" className="w-full" />
  </div>
</div>

{/* Next section with top padding to accommodate overlap */}
<section className="bg-white pt-24 pb-24">
  {/* Content */}
</section>
```

### CSS Grid Overlap (No Negative Margins)

```tsx
<div className="grid grid-rows-[1fr_auto_1fr]">
  <div className="bg-[var(--bg-dark)] row-start-1 row-end-3 col-start-1" />
  <div className="bg-[var(--bg-warm)] row-start-2 row-end-4 col-start-1" />
  {/* Overlapping content */}
  <div className="row-start-2 col-start-1 z-10 px-6">
    <div className="max-w-7xl mx-auto">
      {/* Cards here */}
    </div>
  </div>
</div>
```

---

## Technique F: Combined Approaches (Recommended Patterns)

### Pattern 1: Wave + Gradient (Hero to Content)

```tsx
{/* Hero */}
<section className="bg-[var(--bg-dark)] text-white min-h-screen relative">
  {/* Hero content */}
  {/* Bottom wave with gradient */}
  <div className="absolute bottom-0 left-0 w-full">
    <div className="h-16 bg-gradient-to-b from-transparent to-[var(--bg-dark)]/50" />
    <svg viewBox="0 0 1200 120" preserveAspectRatio="none"
      className="w-full h-[clamp(40px,8vw,100px)]" fill="var(--bg-warm)">
      <path d="M0,60 Q300,120 600,60 T1200,60 L1200,120 L0,120 Z" />
    </svg>
  </div>
</section>
<section className="bg-[var(--bg-warm)] py-24">
  {/* Content */}
</section>
```

### Pattern 2: Diagonal + Overlap (Feature Section)

```tsx
{/* Light section */}
<section className="bg-[var(--bg-warm)] py-24 pb-40">
  <div className="max-w-7xl mx-auto px-6">
    <h2>Our Services</h2>
    <p>Description text...</p>
  </div>
</section>

{/* Diagonal colored section with overlapping cards */}
<section className="relative py-32 -mt-20 overflow-hidden">
  <div
    className="absolute inset-[-5%] bg-gradient-to-br from-[var(--bg-dark)] to-[var(--bg-dark)]/80 -z-10"
    style={{ transform: 'skewY(-3deg)' }}
  />
  <div className="max-w-7xl mx-auto px-6 grid md:grid-cols-3 gap-8">
    {/* Service cards */}
  </div>
</section>
```

### Pattern 3: Gradient Melt (Subtle same-family)

```tsx
<section
  className="py-24"
  style={{ background: 'linear-gradient(180deg, var(--bg-warm) 0%, #FFFFFF 100%)' }}
>
  {/* Content */}
</section>
<section className="bg-white py-24">
  {/* Next content — seamless continuation */}
</section>
```

---

## Recommended Approach for Premium Websites

### Philosophy

For **professional/premium websites**, prefer:
- **Professional** — no playful waves, prefer geometric or subtle curves
- **Bold** — contrasting sections with clear visual breaks
- **Premium** — think Mercury, Stripe, Linear
- **Not childish** — avoid excessive animation or whimsical shapes

### Recommended Technique per Transition

| Transition | Technique | Why |
|---|---|---|
| **Hero to First Content** | Subtle curve SVG + gradient fade | Draws eye downward, premium feel |
| **White to Dark Section** | Diagonal clip-path (3-5deg) | Bold, geometric, professional |
| **Dark to Light Section** | SVG wave (single, subtle) | Organic break from dark, creates relief |
| **Light to Light (cream to white)** | Gradient blend (no divider) | Seamless, elegant |
| **Accent Color Section** | Skewed pseudo-element | Dynamic, Stripe-like energy |
| **Stats/Metrics Bridge** | Overlapping cards | Creates visual connection between sections |
| **CTA Section** | Diagonal clip-path + gradient bg | Bold, attention-grabbing |

### Priority Implementation Order

1. **SVG Wave Divider component** — most versatile, use everywhere
2. **Diagonal clip-path sections** — for bold dark/light breaks
3. **Overlapping card pattern** — for stats and feature highlights
4. **Gradient blending** — for subtle same-family transitions
5. **Skewed sections** — for accent color call-outs

---

## Accessibility & Performance

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  .section-divider svg,
  .wave-animated {
    animation: none !important;
  }
}
```

### Performance Notes

- SVG dividers are lightweight (~200 bytes inline)
- `clip-path` is GPU-accelerated
- `transform: skewY()` is GPU-accelerated
- Avoid animating `clip-path` values (CPU-heavy); animate `transform` instead
- Use `will-change: transform` on animated wave layers
- `preserveAspectRatio="none"` is essential for full-width SVG stretching

### Browser Support

| Technique | Support |
|---|---|
| SVG inline | 99%+ |
| clip-path: polygon() | 97%+ |
| clip-path: ellipse() | 97%+ |
| transform: skewY() | 99%+ |
| CSS mask | 96%+ (needs -webkit- prefix for Safari) |
| @property (animated gradients) | 93%+ (no Firefox before 128) |
| SMIL animate | 96%+ (no IE) |

---

## Tailwind Config Additions Needed

```js
// Add to tailwind.config.js > theme > extend
keyframes: {
  // ... existing keyframes
  'wave-slow': {
    '0%, 100%': { transform: 'translateX(0)' },
    '50%': { transform: 'translateX(-3%)' },
  },
  'wave-medium': {
    '0%, 100%': { transform: 'translateX(0)' },
    '50%': { transform: 'translateX(-2%)' },
  },
  'wave-fast': {
    '0%, 100%': { transform: 'translateX(0)' },
    '50%': { transform: 'translateX(-1%)' },
  },
},
animation: {
  // ... existing animations
  'wave-slow': 'wave-slow 12s ease-in-out infinite',
  'wave-medium': 'wave-medium 8s ease-in-out infinite',
  'wave-fast': 'wave-fast 6s ease-in-out infinite',
},
```

## Sources

- [SVG Shape Dividers | SVG Backgrounds](https://www.svgbackgrounds.com/elements/svg-shape-dividers/)
- [SVG Masks and Shape Dividers | SVG Genie](https://www.svggenie.com/blog/svg-masks-shape-dividers-web-design)
- [Section Divider Generator | css-generators.com](https://css-generators.com/section-divider/)
- [CSS Section Separator Generator | wweb.dev](https://wweb.dev/resources/css-separator-generator)
- [Create Diagonal Layouts | 9elements](https://9elements.com/blog/create-diagonal-layouts-like-its-2020/)
- [Understanding Clip Path | Ahmad Shadeed](https://ishadeed.com/article/clip-path/)
- [Clippy — CSS clip-path maker](https://bennettfeely.com/clippy/)
- [17 CSS Dividers | FreeFrontEnd](https://freefrontend.com/css-dividers/)
- [Section Divider Using CSS | freeCodeCamp](https://www.freecodecamp.org/news/section-divider-using-css/)
- [Shape Divider App](https://www.shapedivider.app/)
- [Smooth CSS Gradient Transitions | DZone](https://dzone.com/articles/smooth-cs-gradient-transitions)
- [Wave Divider | TailwindFlex](https://tailwindflex.com/@lukas-muller/wave-divider)
