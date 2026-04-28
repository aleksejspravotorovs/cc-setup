@AGENTS.md

<!-- BEGIN: FRONTEND_SKILL_POLICY (managed by propagate-frontend-policy.sh — do not edit between markers) -->
## Frontend Skill Policy (SPSS)

**Active baseline:** shadcn/ui + Tailwind. Use shadcn theme tokens
(`bg-background`, `text-foreground`, `border-border`, `bg-primary`) — never
inline hex into globals.css, tailwind config, or className strings.

**Dormant by default** — activate only via slash command or explicit keyword:
- `/svg-animations`, `/algorithmic-art`, `/scroll-animations`,
  `/framer-motion`, `/gsap`, `/three`
- `/design-bold`, `/scroll-video`, `/section-transitions`,
  `/premium-palette`

**No auto-mix:** invoking one effect skill does NOT activate siblings.

**Z-index contract:** bg ≤ 0 (full-viewport, pointer-events:none required),
chrome 1–9, content 10–19, overlays 20–49, toasts/Radix-portals 50+.
Sticky scroll scenes never exceed 19.

**Conflict resolution:** most-recent invocation wins layout/animation;
earliest invocation (the SPSS baseline) wins color/typography.

**Before claiming a UI task done:** run
`qa/visible-content-checklist.md` — all 5 checks must pass.

Full policy: see `FRONTEND_SKILL_POLICY.md` at the vault root.
<!-- END: FRONTEND_SKILL_POLICY -->
