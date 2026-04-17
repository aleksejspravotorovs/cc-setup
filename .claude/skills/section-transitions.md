---
name: section-transitions
description: CSS/SVG section transition techniques — wave dividers, clip-path, gradient blending, skewed sections, overlapping elements. Triggers when creating section boundaries or dividers.
---

# Section Transition Techniques

Use these techniques when building transitions between differently-colored sections.

## Quick Reference

| Transition | Technique | Best For |
|---|---|---|
| Hero → Content | Subtle SVG curve + gradient fade | Drawing eye downward |
| Light → Dark | Diagonal clip-path (3-5deg) | Bold geometric break |
| Dark → Light | SVG wave (single, subtle) | Organic relief |
| Same-family (cream → white) | Gradient blend (no divider) | Seamless elegance |
| Accent section | Skewed pseudo-element | Stripe-like energy |
| Stats bridge | Overlapping cards (-mt-24) | Visual connection |
| CTA | Diagonal clip-path + gradient bg | Attention-grabbing |

## Technique A: SVG Wave Divider

```tsx
const WaveDivider = ({ fillColor = '#101828', variant = 'wave' }) => {
  const paths = {
    wave: 'M0,60 Q300,120 600,60 T1200,60 L1200,120 L0,120 Z',
    curve: 'M0,120 Q600,0 1200,120 Z',
    peaks: 'M0,120 L200,40 L400,80 L600,20 L800,60 L1000,30 L1200,80 L1200,120 Z',
  };
  return (
    <div className="w-full overflow-hidden leading-none">
      <svg viewBox="0 0 1200 120" preserveAspectRatio="none"
        className="w-full h-[clamp(40px,8vw,100px)]">
        <path d={paths[variant]} fill={fillColor} />
      </svg>
    </div>
  );
};
```

## Technique B: Diagonal Clip-Path

```tsx
<section style={{ clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 60px), 0 100%)' }}>
  {/* Content */}
</section>
<section className="-mt-[50px]"
  style={{ clipPath: 'polygon(0 60px, 100% 0, 100% 100%, 0 100%)' }}>
  {/* Next section */}
</section>
```

## Technique C: Gradient Blend

```tsx
<div className="h-32" style={{
  background: 'linear-gradient(180deg, var(--bg-warm) 0%, var(--bg-dark) 100%)',
}} />
```

## Technique D: Skewed Section

```tsx
<section className="relative py-24 overflow-hidden">
  <div className="absolute inset-0 bg-[var(--accent)] -z-10"
    style={{ transform: 'skewY(-3deg)', transformOrigin: 'top left' }} />
  <div className="max-w-7xl mx-auto px-6 relative">{children}</div>
</section>
```

## Technique E: Overlapping Cards

```tsx
<section className="bg-dark pt-24 pb-40">{/* Dark section */}</section>
<div className="max-w-7xl mx-auto px-6 -mt-24 relative z-10">
  <div className="grid md:grid-cols-3 gap-8">
    {/* Cards bridge both sections */}
  </div>
</div>
<section className="bg-warm pt-12 pb-24">{/* Light section */}</section>
```

## Performance Notes

- SVG dividers: ~200 bytes inline, negligible
- `clip-path`: GPU-accelerated
- `transform: skewY()`: GPU-accelerated
- Never animate `clip-path` values — animate `transform` instead
- Use `will-change: transform` on animated wave layers
- `preserveAspectRatio="none"` is essential for full-width SVG

## Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  .section-divider svg, .wave-animated { animation: none !important; }
}
```

## Reference

See `research/design/section-transitions-spec.md` for 6 full techniques with multi-layer parallax waves, animated gradients, CSS grid overlaps, responsive patterns, and Tailwind config additions.
