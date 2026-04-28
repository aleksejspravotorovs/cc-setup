---
title: Visible-Content Checklist
team: frontend-skill-policy
status: canonical
version: 1.1
applies_to: every UI task before being marked complete
upstream: FRONTEND_SKILL_POLICY.md
---

# Visible-Content Checklist

Run all five checks against the live dev server before claiming any frontend task done. Each check is **yes / no**. All five must be **YES**. If any check is NO, the task is not complete — fix and re-verify.

A layer is **decorative** when it has no interactive children (no buttons, links, inputs, dismiss-on-click behavior) and exists purely for visual effect. **Functional** overlays — Radix `DialogOverlay` / `SheetOverlay` / `AlertDialogOverlay`, vaul `Drawer`, cmdk command palette, Sonner toasts — are NOT decorative even when they tint the viewport, and the checks below explicitly exempt them.

## The five checks

1. **No literal hex in theme surfaces — YES / NO.**
   `grep -E '#[0-9a-fA-F]{3,8}' app/globals.css tailwind.config.* src/**/*.css` returns no hits in `:root`, `.dark`, or any `--bg-*` / `--fg-*` / `--text-*` / `--accent-*` declaration. All theme color decisions go through shadcn tokens (`--background`, `--foreground`, `--primary`, `--border`, etc.).

2. **Decorative full-viewport layers are pointer-safe and beneath content — YES / NO.**
   Every **decorative** `position: fixed` or `position: absolute` element that covers more than 50% of the viewport in either axis has BOTH `pointer-events: none` AND `z-index ≤ 0`. This includes p5.js canvases, hero videos, gradient meshes, particle fields, scroll-scrubbed video panels, and animated SVG backgrounds. **Functional overlays are exempt** — Radix Dialog/Sheet/AlertDialog/Drawer overlays, Sonner toasts, and cmdk command-palette overlays correctly use `pointer-events: auto` at z-50+ and are not flagged by this check.

3. **No decorative sticky / scroll-pinned scene exceeds the Content tier — YES / NO.**
   Every **scroll-pinned or parallax sticky scene** (decorative section that pins or transforms during scroll) has `z-index ≤ 19`. **Sticky app chrome is exempt** — `<header className="sticky top-0 z-50">` and equivalent navs/sidebars/footers are allowed at `z-50` per the canonical shadcn pattern. No ancestor of a Radix portal target (Dialog, Sheet, Popover, Tooltip, DropdownMenu) has a `transform`, `filter`, or `perspective` that creates a stacking context which traps the portal below sticky content.

4. **Every Radix portal opens, paints fully on top, and accepts clicks — YES / NO.**
   Visited the dev server with `agent-browser` (or manual browser). Opened each Dialog / Sheet / Drawer / Popover / Tooltip / DropdownMenu present in the changed surface. Each one rendered fully visible above all page content, was clickable, and closed cleanly. No portal appeared blank, off-screen, or behind a sticky scene.

5. **Body text and interactive labels are readable on every section — YES / NO.**
   Visited the dev server. Walked through every page section affected by this change (light AND dark variants, hero AND body). All body copy, button labels, and form labels are visibly contrasted against their background. No `text-foreground` resolving to the same color as its container. No element disappears when its parent receives a hover/focus state.
