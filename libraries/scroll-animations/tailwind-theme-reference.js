/**
 * Tailwind CSS Theme Reference — Scroll Animation Design Tokens
 *
 * Copy the relevant sections into your project's tailwind.config.js > theme > extend.
 * Colors are placeholders — replace with your brand palette.
 *
 * Dependencies: motion (npm install motion)
 * Fonts: Inter (body), Manrope (display) — swap to your own
 */

/** @type {import('tailwindcss').Config['theme']['extend']} */
export const themeExtensions = {
  // ─── COLORS (replace with your brand) ───
  colors: {
    'warm-cream': '#F5F4F0',
    'warm-light': '#F7F6F4',
    charcoal: '#101828',
    'accent-primary': '#2563EB',
    'accent-sky': '#7CB9E8',
    'accent-warm': '#EC610F',
    'deep-dark': '#0A1628',
    'light-accent': '#C1DFEF',
  },

  // ─── FONT FAMILIES ───
  fontFamily: {
    sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
    display: ['"Manrope"', 'sans-serif'],
  },

  // ─── RESPONSIVE TYPE SCALE (clamp-based) ───
  fontSize: {
    'display': ['clamp(3rem, 8vw, 5rem)', { lineHeight: '0.95', letterSpacing: '-0.04em', fontWeight: '700' }],
    'heading-1': ['clamp(2rem, 5vw, 4rem)', { lineHeight: '1.0', letterSpacing: '-0.03em', fontWeight: '700' }],
    'heading-2': ['clamp(1.5rem, 4vw, 3rem)', { lineHeight: '1.0', letterSpacing: '-0.03em', fontWeight: '700' }],
    'heading-3': ['clamp(1.25rem, 3vw, 2rem)', { lineHeight: '1.0', letterSpacing: '-0.02em', fontWeight: '600' }],
    'heading-4': ['clamp(1.125rem, 2vw, 1.5rem)', { lineHeight: '1.2', letterSpacing: '-0.01em', fontWeight: '600' }],
    'body-lg': ['clamp(1rem, 1.5vw, 1.25rem)', { lineHeight: '1.3', letterSpacing: '-0.02em', fontWeight: '400' }],
    'body': ['1rem', { lineHeight: '1.3', letterSpacing: '-0.01em', fontWeight: '400' }],
    'body-sm': ['0.875rem', { lineHeight: '1.3', letterSpacing: '-0.01em', fontWeight: '400' }],
    'caption': ['0.75rem', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '500' }],
  },

  // ─── BORDER RADIUS TOKENS ───
  borderRadius: {
    card: '8px',
    panel: '24px',
    pill: '56px',
  },

  // ─── SHADOW TOKENS ───
  boxShadow: {
    'nav': '0 1px 1px rgba(0, 0, 0, 0.23)',
    'nav-cta': '0 1.837px 1.837px rgba(0, 0, 0, 0.25)',
    'card': '0 1px 3px rgba(0, 0, 0, 0.06), 0 1px 2px rgba(0, 0, 0, 0.04)',
    'card-hover': '0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -4px rgba(0, 0, 0, 0.04)',
    'elevated': '0 20px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.03)',
  },

  // ─── CONTAINER WIDTHS ───
  maxWidth: {
    'container-sm': '640px',
    'container-md': '768px',
    'container-lg': '1024px',
    'container-xl': '1280px',
  },

  // ─── ANIMATION EASING ───
  transitionTimingFunction: {
    'reveal': 'cubic-bezier(0.16, 1, 0.3, 1)',
    'snappy': 'cubic-bezier(0.2, 0.21, 0, 1)',
    'out-cubic': 'cubic-bezier(0.33, 1, 0.68, 1)',
  },

  // ─── KEYFRAMES ───
  keyframes: {
    'fade-up': {
      '0%': { opacity: '0', transform: 'translateY(60px)', filter: 'blur(6px)' },
      '100%': { opacity: '1', transform: 'translateY(0)', filter: 'blur(0)' },
    },
    'fade-in': {
      '0%': { opacity: '0' },
      '100%': { opacity: '1' },
    },
    'fade-in-left': {
      '0%': { opacity: '0', transform: 'translateX(-30px)' },
      '100%': { opacity: '1', transform: 'translateX(0)' },
    },
    'fade-in-right': {
      '0%': { opacity: '0', transform: 'translateX(30px)' },
      '100%': { opacity: '1', transform: 'translateX(0)' },
    },
    'scale-in': {
      '0%': { opacity: '0', transform: 'scale(0.95)' },
      '100%': { opacity: '1', transform: 'scale(1)' },
    },
    'hero-fade-up': {
      '0%': { opacity: '0', transform: 'translateY(1.9rem)' },
      '100%': { opacity: '1', transform: 'translateY(0)' },
    },
  },

  // ─── ANIMATION PRESETS ───
  animation: {
    'fade-up': 'fade-up 1.2s cubic-bezier(0.16, 1, 0.3, 1) forwards',
    'fade-in': 'fade-in 0.8s ease forwards',
    'fade-in-left': 'fade-in-left 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards',
    'fade-in-right': 'fade-in-right 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards',
    'scale-in': 'scale-in 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards',
    'hero-fade-up': 'hero-fade-up 0.667s cubic-bezier(0.2, 0.21, 0, 1) forwards',
  },
};
