import { useEffect, useRef, useState, type RefObject } from 'react';

// ============================================
// Shared helpers
// ============================================

function prefersReducedMotion(): boolean {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

// Motion's ScrollOffset type uses template literals that are too narrow for dynamic strings.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type ScrollOffset = any;

// ============================================
// useScrollReveal — fade-up tied to scroll position via motion scroll() API
// ============================================

interface ScrollRevealOptions {
  yFrom?: number;
  offset?: [string, string];
}

/**
 * Scroll-driven fade-up reveal for a single element.
 * Uses motion scroll() API instead of IntersectionObserver.
 */
export function useScrollReveal(
  ref: RefObject<HTMLElement | null>,
  options: ScrollRevealOptions = {}
) {
  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    if (prefersReducedMotion()) {
      element.style.opacity = '1';
      return;
    }

    let stop: VoidFunction | undefined;

    const yFrom = options.yFrom ?? 30;
    const scrollOffset = options.offset ?? ['start end', 'start 0.6'];

    import('motion').then(({ animate, scroll }) => {
      if (!ref.current) return;
      stop = scroll(
        animate(element, {
          opacity: [0, 1],
          transform: [`translateY(${yFrom}px)`, 'translateY(0)'],
        }),
        {
          target: element,
          offset: scrollOffset as ScrollOffset,
        }
      );
    });

    return () => {
      stop?.();
    };
  }, [ref, options.yFrom, options.offset]);
}

// ============================================
// useScrollRevealGroup — batch scroll reveals for [data-scroll-reveal] children
// ============================================

interface ScrollRevealGroupOptions {
  staggerMs?: number;
  yFrom?: number;
  offset?: [string, string];
}

/**
 * Batch scroll-driven reveal for all [data-scroll-reveal] children in a container.
 */
export function useScrollRevealGroup(
  containerRef: RefObject<HTMLElement | null>,
  options: ScrollRevealGroupOptions = {}
) {
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const elements = container.querySelectorAll<HTMLElement>('[data-scroll-reveal]');
    if (elements.length === 0) return;

    if (prefersReducedMotion()) {
      elements.forEach((el) => {
        el.style.opacity = '1';
      });
      return;
    }

    const stops: VoidFunction[] = [];
    const yFrom = options.yFrom ?? 30;
    const scrollOffset = options.offset ?? ['start end', 'start 0.6'];

    import('motion').then(({ animate, scroll }) => {
      if (!containerRef.current) return;

      elements.forEach((el) => {
        const stop = scroll(
          animate(el, {
            opacity: [0, 1],
            transform: [`translateY(${yFrom}px)`, 'translateY(0)'],
          }),
          {
            target: el,
            offset: scrollOffset as ScrollOffset,
          }
        );
        if (stop) stops.push(stop);
      });
    });

    return () => {
      stops.forEach((s) => s());
    };
  }, [containerRef, options.staggerMs, options.yFrom, options.offset]);
}

// ============================================
// useStickyScrollScene — sticky scroll scene (300vh container + sticky inner)
// ============================================

interface StickyScrollSceneOptions {
  offset?: [string, string];
}

/**
 * For sticky scroll scenes: returns refs for the outer section (300vh)
 * and inner content (sticky 100vh). Also provides a normalized progress value 0-1.
 */
export function useStickyScrollScene(
  sectionRef: RefObject<HTMLElement | null>,
  contentRef: RefObject<HTMLElement | null>,
  options: StickyScrollSceneOptions = {}
) {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const section = sectionRef.current;
    if (!section) return;

    if (prefersReducedMotion()) {
      setProgress(1);
      return;
    }

    let stop: VoidFunction | undefined;
    const scrollOffset = options.offset ?? ['start start', 'end end'];

    import('motion').then(({ scroll }) => {
      if (!sectionRef.current) return;
      stop = scroll(
        (p: number) => setProgress(p),
        {
          target: section,
          offset: scrollOffset as ScrollOffset,
        }
      );
    });

    return () => {
      stop?.();
    };
  }, [sectionRef, contentRef, options.offset]);

  return progress;
}

// ============================================
// useScrollCounter — scroll-driven number count-up
// ============================================

interface ScrollCounterOptions {
  offset?: [string, string];
}

/**
 * Scroll-driven number counter. Returns the current animated value.
 */
export function useScrollCounter(
  ref: RefObject<HTMLElement | null>,
  target: number,
  options: ScrollCounterOptions = {}
) {
  const [value, setValue] = useState(0);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    if (prefersReducedMotion()) {
      setValue(target);
      return;
    }

    let stop: VoidFunction | undefined;
    const scrollOffset = options.offset ?? ['start end', 'start 0.3'];

    import('motion').then(({ scroll }) => {
      if (!ref.current) return;
      stop = scroll(
        (p: number) => {
          setValue(Math.round(target * p));
        },
        {
          target: element,
          offset: scrollOffset as ScrollOffset,
        }
      );
    });

    return () => {
      stop?.();
    };
  }, [ref, target, options.offset]);

  return value;
}

// ============================================
// useRoundedSection — border-radius 160px->0 transition on scroll
// ============================================

interface RoundedSectionOptions {
  fromRadius?: number;
  offset?: [string, string];
}

/**
 * Scroll-driven border-radius animation: starts rounded, flattens to 0 as user scrolls.
 */
export function useRoundedSection(
  ref: RefObject<HTMLElement | null>,
  options: RoundedSectionOptions = {}
) {
  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    if (prefersReducedMotion()) return;

    let stop: VoidFunction | undefined;
    const fromRadius = options.fromRadius ?? 160;
    const scrollOffset = options.offset ?? ['start end', 'start start'];

    import('motion').then(({ animate, scroll }) => {
      if (!ref.current) return;
      stop = scroll(
        animate(element, {
          borderRadius: [`${fromRadius}px ${fromRadius}px 0 0`, '0 0 0 0'],
        }),
        {
          target: element,
          offset: scrollOffset as ScrollOffset,
        }
      );
    });

    return () => {
      stop?.();
    };
  }, [ref, options.fromRadius, options.offset]);
}

// ============================================
// useScrollDirectional — from-left or from-right reveal
// ============================================

interface ScrollDirectionalOptions {
  distance?: number;
  offset?: [string, string];
}

/**
 * Scroll-driven directional reveal (from-left or from-right).
 */
export function useScrollDirectional(
  ref: RefObject<HTMLElement | null>,
  direction: 'left' | 'right',
  options: ScrollDirectionalOptions = {}
) {
  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    if (prefersReducedMotion()) {
      element.style.opacity = '1';
      return;
    }

    let stop: VoidFunction | undefined;
    const distance = options.distance ?? 60;
    const scrollOffset = options.offset ?? ['start end', 'start 0.6'];
    const xFrom = direction === 'left' ? -distance : distance;

    import('motion').then(({ animate, scroll }) => {
      if (!ref.current) return;
      stop = scroll(
        animate(element, {
          opacity: [0, 1],
          transform: [`translateX(${xFrom}px)`, 'translateX(0)'],
        }),
        {
          target: element,
          offset: scrollOffset as ScrollOffset,
        }
      );
    });

    return () => {
      stop?.();
    };
  }, [ref, direction, options.distance, options.offset]);
}

// ============================================
// Convenience: useScrollRef — returns a ref + attaches useScrollReveal
// ============================================

/**
 * Shorthand: creates a ref and attaches useScrollReveal to it.
 */
export function useScrollRef<T extends HTMLElement = HTMLDivElement>(
  options: ScrollRevealOptions = {}
) {
  const ref = useRef<T>(null);
  useScrollReveal(ref, options);
  return ref;
}
