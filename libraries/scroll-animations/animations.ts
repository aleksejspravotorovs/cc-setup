import { useEffect, useRef, useState, useCallback, type ReactNode, createElement } from 'react';

// ============================================
// Constants
// ============================================

const REVEAL_EASING = 'cubic-bezier(0.16, 1, 0.3, 1)';
const DEFAULT_THRESHOLD = 0.15;
const DEFAULT_ROOT_MARGIN = '0px 0px -80px 0px';
const DEFAULT_STAGGER_DELAY = 83;

// ============================================
// useScrollReveal — Intersection Observer hook
// ============================================

interface ScrollRevealOptions {
  threshold?: number;
  rootMargin?: string;
  once?: boolean;
}

/**
 * Hook that observes an element and returns visibility state.
 * When the element scrolls into view, `isVisible` becomes true.
 * Adds `.visible` class to the element automatically.
 */
export function useScrollReveal(options: ScrollRevealOptions = {}) {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    // Respect prefers-reduced-motion
    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReduced) {
      setIsVisible(true);
      element.classList.add('visible');
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          entry.target.classList.add('visible');
          if (options.once !== false) {
            observer.unobserve(entry.target);
          }
        }
      },
      {
        threshold: options.threshold ?? DEFAULT_THRESHOLD,
        rootMargin: options.rootMargin ?? DEFAULT_ROOT_MARGIN,
      }
    );

    observer.observe(element);
    return () => observer.disconnect();
  }, [options.threshold, options.rootMargin, options.once]);

  return { ref, isVisible };
}

// ============================================
// useScrollRevealAll — batch observer for many .reveal elements
// ============================================

/**
 * Sets up a single Intersection Observer that watches all `.reveal`
 * elements within a container. Adds `.visible` when they enter viewport.
 * Call once at the top of a page/layout.
 */
export function useScrollRevealAll(
  containerRef?: React.RefObject<HTMLElement | null>,
  options: ScrollRevealOptions = {}
) {
  useEffect(() => {
    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const root = containerRef?.current ?? document;

    const elements = root.querySelectorAll(
      '.reveal, .reveal--from-left, .reveal--from-right, .reveal--scale, .reveal--fade, .reveal--blur, .text-reveal'
    );

    if (prefersReduced) {
      elements.forEach((el) => el.classList.add('visible'));
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('visible');
            observer.unobserve(entry.target);
          }
        });
      },
      {
        threshold: options.threshold ?? DEFAULT_THRESHOLD,
        rootMargin: options.rootMargin ?? DEFAULT_ROOT_MARGIN,
      }
    );

    elements.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, [containerRef, options.threshold, options.rootMargin]);
}

// ============================================
// useParallax — lightweight parallax effect
// ============================================

interface ParallaxOptions {
  speed?: number; // 0.0 to 1.0, default 0.1
}

/**
 * Applies a translateY parallax effect based on scroll position.
 * Attach the returned ref to the element you want to parallax.
 */
export function useParallax(options: ParallaxOptions = {}) {
  const ref = useRef<HTMLDivElement>(null);
  const ticking = useRef(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReduced) return;

    const speed = options.speed ?? 0.1;

    const update = () => {
      const rect = element.getBoundingClientRect();
      const centerY = rect.top + rect.height / 2;
      const offset = (centerY - window.innerHeight / 2) * speed;
      element.style.transform = `translateY(${offset}px)`;
      ticking.current = false;
    };

    const onScroll = () => {
      if (!ticking.current) {
        requestAnimationFrame(update);
        ticking.current = true;
      }
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    update(); // Initial position

    return () => window.removeEventListener('scroll', onScroll);
  }, [options.speed]);

  return ref;
}

// ============================================
// useCountUp — animated number counter
// ============================================

interface CountUpOptions {
  duration?: number;  // ms, default 2000
  startOnVisible?: boolean; // default true
}

/**
 * Animates a number from 0 to `target` with ease-out-cubic easing.
 * Returns { ref, value } — attach ref to the container element.
 * Animation starts when element enters viewport (via Intersection Observer).
 */
export function useCountUp(target: number, options: CountUpOptions = {}) {
  const ref = useRef<HTMLDivElement>(null);
  const [value, setValue] = useState(0);
  const hasAnimated = useRef(false);

  const duration = options.duration ?? 2000;
  const startOnVisible = options.startOnVisible !== false;

  const animate = useCallback(() => {
    if (hasAnimated.current) return;
    hasAnimated.current = true;

    const startTime = performance.now();

    const step = (currentTime: number) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      // Ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      const current = Math.round(target * eased);
      setValue(current);

      if (progress < 1) {
        requestAnimationFrame(step);
      } else {
        setValue(target);
      }
    };

    requestAnimationFrame(step);
  }, [target, duration]);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    if (!startOnVisible) {
      animate();
      return;
    }

    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReduced) {
      setValue(target);
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          animate();
          observer.disconnect();
        }
      },
      { threshold: 0.3 }
    );

    observer.observe(element);
    return () => observer.disconnect();
  }, [animate, startOnVisible, target]);

  return { ref, value };
}

// ============================================
// StaggerReveal — wraps children with stagger delays
// ============================================

interface StaggerRevealProps {
  children: ReactNode[];
  delayMs?: number;
  className?: string;
  as?: keyof HTMLElementTagNameMap;
}

/**
 * Wraps each child in a reveal container with staggered transition delays.
 * Children animate in sequence when the container scrolls into view.
 */
export function StaggerReveal({
  children,
  delayMs = DEFAULT_STAGGER_DELAY,
  className = '',
  as = 'div',
}: StaggerRevealProps) {
  const { ref, isVisible } = useScrollReveal();

  const wrappedChildren = children.map((child, i) =>
    createElement(
      'div',
      {
        key: i,
        className: `reveal ${isVisible ? 'visible' : ''}`,
        style: { transitionDelay: isVisible ? `${i * delayMs}ms` : '0ms' },
      },
      child
    )
  );

  return createElement(
    as,
    { ref, className },
    ...wrappedChildren
  );
}

// ============================================
// Utility: calculate stagger delay
// ============================================

/**
 * Returns a CSS transition-delay string for staggered animations.
 * @param index - The item's index in the list (0-based)
 * @param baseDelay - Base delay in ms (default 100)
 */
export function getStaggerDelay(index: number, baseDelay = DEFAULT_STAGGER_DELAY): string {
  return `${index * baseDelay}ms`;
}

/**
 * Returns a style object with transition delay for use in React.
 */
export function staggerStyle(index: number, baseDelay = DEFAULT_STAGGER_DELAY) {
  return { transitionDelay: `${index * baseDelay}ms` };
}

// ============================================
// useScrollScale — scroll-driven scale/fade animation using Motion
// ============================================

/**
 * Attaches a scroll-driven animation to an element that scales it
 * from a starting scale and fades it in as the user scrolls through it.
 * Uses the Motion library's scroll() and animate() APIs.
 */
export function useScrollScale(options: {
  scaleFrom?: number;
  opacityFrom?: number;
  offset?: [string, string];
} = {}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReduced) return;

    let stop: VoidFunction | undefined;

    const scrollOffset = options.offset ?? ['start end', 'end 80%'];

    import('motion').then(({ animate, scroll }) => {
      const scaleFrom = options.scaleFrom ?? 0.9;
      const opacityFrom = options.opacityFrom ?? 0;

      stop = scroll(
        animate(element, {
          transform: [`scale(${scaleFrom})`, 'scale(1)'],
          opacity: [opacityFrom, 1],
        }),
        {
          target: element,
          // @ts-expect-error Motion ScrollOffset type not exported
          offset: scrollOffset,
        }
      );
    });

    return () => { stop?.(); };
  }, [options.scaleFrom, options.opacityFrom, options.offset]);

  return ref;
}

// ============================================
// useScrollFadeIn — scroll-driven opacity + translateY
// ============================================

/**
 * Attaches a scroll-driven fade-in + slide-up animation to an element.
 */
export function useScrollFadeIn(options: {
  yFrom?: number;
  offset?: [string, string];
} = {}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReduced) return;

    let stop: VoidFunction | undefined;

    const scrollOffset = options.offset ?? ['start end', 'center 70%'];

    import('motion').then(({ animate, scroll }) => {
      const yFrom = options.yFrom ?? 60;

      stop = scroll(
        animate(element, {
          opacity: [0, 1],
          transform: [`translateY(${yFrom}px)`, 'translateY(0px)'],
        }),
        {
          target: element,
          // @ts-expect-error Motion ScrollOffset type not exported
          offset: scrollOffset,
        }
      );
    });

    return () => { stop?.(); };
  }, [options.yFrom, options.offset]);

  return ref;
}

// ============================================
// Exports reference for easing
// ============================================

export { REVEAL_EASING, DEFAULT_STAGGER_DELAY };
