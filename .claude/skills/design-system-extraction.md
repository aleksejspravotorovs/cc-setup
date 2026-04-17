---
name: design-system-extraction
description: Guide for extracting and documenting a design system from a reference website — color, typography, spacing, animation, component patterns. Use when analyzing a reference site for a new project.
---

# Design System Extraction Guide

When analyzing a reference website to build a design system, extract these categories in order.

## 1. Color Palette

Extract and document:
- [ ] Background colors (primary, warm, light, dark)
- [ ] Text colors (primary, secondary, muted, inverse)
- [ ] Accent colors (primary brand, secondary, warm)
- [ ] Border colors (default, subtle)
- [ ] Gradient definitions (hero overlay, section fades, dark sections)
- [ ] Color application rules (which bg gets which text)
- [ ] WCAG contrast verification for each text/bg pair

## 2. Typography

Extract and document:
- [ ] Font families (body, display, mono)
- [ ] Type scale table: Display, H1-H4, Body-lg, Body, Body-sm, Caption, Overline
- [ ] For each: size (desktop + mobile), weight, line-height, letter-spacing
- [ ] CSS patterns: hero headline, section headline, body text, overline
- [ ] Responsive sizing (use `clamp()` for fluid type)

## 3. Spacing & Layout

Extract and document:
- [ ] Spacing scale (base unit, typically 4px or 8px)
- [ ] Container widths (sm, md, lg, xl, 2xl)
- [ ] Section padding (vertical + horizontal, responsive)
- [ ] Grid system (12-col standard, 16-col for premium asymmetric)
- [ ] Responsive breakpoints

## 4. Border Radius & Shadows

Extract and document:
- [ ] Radius tokens (sm, md, lg, xl, pill, full)
- [ ] Shadow tokens (sm, md, lg, xl, nav)
- [ ] Any scroll-animated radius patterns (e.g., 160px → 0)

## 5. Animation System

Extract and document:
- [ ] Easing functions (list all cubic-bezier values)
- [ ] Duration variables (fast, normal, slow, reveal, hero)
- [ ] Stagger delay (typically 83ms or 100ms)
- [ ] Reveal animation CSS (base state → visible state)
- [ ] Text reveal pattern (line-by-line with stagger)
- [ ] Hero entrance animation (keyframes + delays)
- [ ] Scroll-driven patterns (parallax, sticky scenes, counters)
- [ ] Image loading pattern (blur-up, progressive)
- [ ] Reduced motion handling

## 6. Component Patterns

Extract and document:
- [ ] Navigation (hamburger vs horizontal, scroll behavior, pill shape)
- [ ] Cards (radius, shadow, hover effect, glass variant)
- [ ] Buttons (shape, hover mechanics, active state, inversion rules)
- [ ] Section templates (hero, content, dark, CTA)
- [ ] Footer layout

## Output Format

Save the extracted system to `research/design/design-system-[project].md` using the template structure in `research/design/premium-design-system-template.md`.

## Reference

See `research/design/premium-design-system-template.md` for the full fillable template with all CSS patterns and code examples.
