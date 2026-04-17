# Video Smoothing Research: Fixing Scroll-Scrubbed Frame Stepping

## Context

- **Problem**: Scroll-scrubbed video shows visible frame stepping — discrete jumps between frames during scroll.
- **Typical setup**: `video.currentTime = progress * duration` via motion's `scroll()` callback, with a seek-queue pattern (wait for `seeked` event before next seek).
- **Video**: Standard encoding MP4 (NOT all-keyframe).
- **Stack**: Modern React + TypeScript + Tailwind + motion library

---

## Question-by-Question Findings

### Q1: Can CSS `will-change: transform` or GPU layer promotion smooth video display?

**No.** Video elements are already automatically promoted to their own compositor layer by all major browsers. Adding `will-change: transform`, `translateZ(0)`, or `backface-visibility: hidden` to the `<video>` element is redundant.

The frame stepping is a **decoding problem**, not a compositing/painting problem. When you set `video.currentTime`, the browser must seek to the nearest keyframe, then decode forward through all delta frames to reach the target. No CSS property can speed up video decoding.

**One indirect benefit**: applying `will-change: transform` to **surrounding animated elements** (the expanding video container, overlaid text) prevents them from competing with video decoding for GPU resources. This won't fix the stepping but prevents additional jank from layout/paint of nearby elements.

**Verdict**: Not a solution. Apply to surrounding elements only, not the video itself.

---

### Q2: Would rendering to canvas with frame interpolation/blending help?

**Theoretically yes, practically no — and unnecessary without re-encoding.**

The technique: draw two adjacent frames to canvas, blend them with `globalAlpha` to create an interpolated transition. Or use WebGL with a mix shader for better performance.

**Why it doesn't help here**:
- The core problem is that the video decoder can't produce frames fast enough during seeking. Canvas blending requires *two* decoded frames to blend between — but we can't reliably get the "next" frame without seeking to it (same decode latency).
- Drawing two 1080p frames per display frame doubles GPU work. On mobile this causes frame drops.
- No production site uses canvas frame blending for scroll-scrubbed video. The industry has converged on either image sequences or all-keyframe video.

**What IS useful from this research**: smoothing the scroll input signal (lerping the target `currentTime` toward the scroll position over a few frames) creates perceived smoothness without pixel-level blending. This is what GSAP's `scrub: 0.5` does. See Q5 for a better version of this idea.

**Verdict**: Not practical. Skip canvas blending.

---

### Q3: Can `requestVideoFrameCallback` API sync rendering to actual decoded frames?

**Partially, but it doesn't solve the core problem.**

`requestVideoFrameCallback` fires when a new video frame is sent to the compositor. The callback receives metadata including `mediaTime` (presentation timestamp of the current frame) and `presentedFrames` (cumulative frame count).

**What it CAN do**:
- Detect when a seek has actually completed and the new frame is visible (more precise than the `seeked` event)
- Verify which frame is currently displayed via `metadata.mediaTime`
- Gate UI updates to only fire when actual new frames are rendered

**What it CANNOT do**:
- Make the decoder produce frames faster
- Interpolate between frames
- Bypass keyframe-seeking latency

**Browser support**: 96.65% global coverage. Chrome 83+, Edge 83+, Firefox 132+, Safari 15.4+.

**Critical caveat from MDN**: "the video element does not guarantee frame-accurate seeking." This is an ongoing standards discussion. For truly frame-accurate work, the WebCodecs API is recommended (but has incomplete Safari support).

**Practical use**: Could be used to sync a blur/opacity mask — only show the frame when `requestVideoFrameCallback` confirms it's painted, keeping the previous frame visible during decode. This avoids the "half-decoded frame" flash.

**Verdict**: Useful as a supplementary technique, not a standalone fix.

---

### Q4: Would a tiny CSS blur transition mask frame steps?

**Yes — this is the most practical CSS-based perceptual trick.**

Apply `filter: blur(0.5px)` on the `seeking` event, remove it on `seeked` with `transition: filter 0.08s ease-out`. The blur acts as perceptual anti-aliasing that softens the hard frame transition.

**Details**:
- CSS `filter: blur()` on video does work and animates smoothly via CSS transitions
- A 0.5px blur is computationally very cheap (values under 2px have minimal GPU cost)
- Apple M-series chips handle it with no visible performance impact
- Intel integrated GPUs can struggle with higher blur values, but 0.5px is fine
- The transition duration (0.08-0.1s) should be short enough to feel immediate but long enough to smooth the visual step

**Implementation**:
```css
.scroll-video {
  transition: filter 0.08s ease-out;
}
.scroll-video.seeking {
  filter: blur(0.5px);
}
```

```typescript
video.addEventListener('seeking', () => video.classList.add('seeking'));
video.addEventListener('seeked', () => video.classList.remove('seeking'));
```

**Verdict**: Recommend implementing. Low effort, no downside, genuinely helps perception.

---

### Q5: Would calling `video.play()` for brief segments then pausing give smoother inter-frame interpolation?

**In theory yes, but impractical for scroll scrubbing.**

During `play()`, the browser's full media pipeline is active — video decoder, frame scheduler, and compositor work together for smooth display. When seeking via `currentTime`, this pipeline is bypassed.

**Why it fails for scroll scrubbing**:
- Scroll direction and speed are unpredictable — `play()` only goes forward
- Starting playback introduces latency (the video takes time to begin playing)
- Creates a complex state machine (play/pause/reverse/speed management)
- Needs two video elements for bidirectional playback (one forward, one reverse)
- During direction switches, last frame of outgoing video stays visible for 50-250ms

**A related technique that IS useful — `playbackRate` adjustment**:
Instead of seeking, keep the video playing and adjust `video.playbackRate` based on scroll velocity. Results are reportedly smoother (per GSAP forum users). However, this requires two videos for bidirectional playback and creates flash artifacts on direction changes.

**Verdict**: Not recommended. The complexity and artifacts outweigh the smoothness gains.

---

### Q6: Any CSS motion-blur or cross-fade trick that works on video elements?

**No native CSS motion blur exists.** The W3C CSSWG issue #3837 proposed `motion-rendering: blur` and `motion-shutter-angle` properties, but Tab Atkins confirmed it would only apply to CSS transforms, not video content. No browser has implemented it.

**What does work**:
1. **Brief `filter: blur(0.5px)`** during seeking (see Q4) — the best available CSS trick
2. **`opacity` flash** — briefly reduce opacity during seek, restore on `seeked`. Visually inferior to blur.
3. **Double-buffer with cross-fade** — two `<video>` elements layered, cross-fading via CSS `opacity` transitions. Impractical for scroll scrubbing because both elements suffer the same keyframe decode latency.

**What does NOT work**:
- `mix-blend-mode` — breaks smooth opacity transitions and adds GPU work
- `backdrop-filter` — documented to cause choppiness in video on Intel GPUs
- `image-rendering` — only affects scaling algorithm, no effect on seeking smoothness

**Verdict**: Stick with the blur trick from Q4. No other CSS-based approach is worth the complexity.

---

### Q7: Does non-keyframe-optimized encoding make direct seeking inherently choppy? Is `-g 1` the ONLY real fix?

**Yes, standard encoding makes seeking inherently choppy. No, `-g 1` is not the ONLY fix, but it is the BEST fix.**

Standard H.264 uses GOP (Group of Pictures) with keyframes every 60-250 frames. Seeking to any non-keyframe position requires the decoder to:
1. Find the nearest preceding I-frame (keyframe)
2. Decode ALL intermediate P-frames and B-frames forward to the target
3. Present the result

**Encoding options (ranked by smoothness)**:

| Encoding | Seeking | File Size Impact | Notes |
|----------|---------|-----------------|-------|
| `-g 1` (all keyframes) | Smoothest | ~2-3x | Every frame independently decodable |
| `-g 2` (keyframe every 2) | Very good | ~1.5-2x | Sweet spot for quality/size |
| `-profile:v baseline` | Good | ~1.2x | Baseline profile excludes B-frames by design |
| `-bf 0` (no B-frames) | Decent | ~1.2-1.4x | B-frames are most expensive to reconstruct |
| `-g 5` | OK in Chrome/Safari | ~1.1x | Firefox still stutters |
| Standard encoding | Choppy | 1x | The problem |

**The Jeff Pamer "mega command"** (widely cited for scroll-scrub encoding):
```bash
ffmpeg -i input.mp4 -vcodec libx264 -pix_fmt yuv420p \
  -profile:v baseline -level 3 -an \
  -vf "scale=-1:1440" -preset veryslow -g 2 output.mp4
```

**Verdict**: Re-encoding is the single highest-impact fix. Without it, all other techniques are band-aids.

---

### Q8: What do production sites actually do — image sequences or video with tricks?

**Almost all premium production sites use image sequences on canvas. None use standard video with CSS tricks.**

#### Apple.com (AirPods Pro, MacBook, iPhone pages)
- **148 sequential JPEG images** loaded from CDN
- Canvas dimensions: 1158x770
- Images preloaded into memory, drawn with `context.drawImage()` based on scroll position
- Frame index: `Math.floor(scrollFraction * totalFrames)`
- Total payload: ~55MB, mitigated by aggressive CDN optimization

#### OPTIKKA (Codrops case study)
- Started with HTML5 video, **switched to image sequences** due to "stuttering and lag, particularly on mobile"
- 1,182 frames on desktop, 880 on mobile
- Staged loading: 10 frames immediately, rest async via parallel queue

#### GSAP-based sites (budget-tier)
- All-keyframe video (`-g 1` or `-g 2`) with direct `currentTime` seeking
- GSAP's `scrub: 0.5` smooths the scroll input signal
- This is the "good enough" approach for non-Apple-budget projects

#### Emerging: WebCodecs decode-to-canvas
- Library: `diffusionstudio/webcodecs-scroll-sync`
- **Not production-ready**: Safari support incomplete

**Production approach summary**:

| Approach | Used By | Payload | Smoothness | Complexity |
|----------|---------|---------|-----------|------------|
| Image sequences on canvas | Apple, Samsung, OPTIKKA | 10-60MB | Perfect | Medium |
| All-keyframe video + seeking | GSAP-based sites | 5-15MB | Good | Low |
| WebCodecs decode-to-canvas | Experimental | 3-5MB | Good | High |
| Standard video + CSS tricks | Nobody in production | 3-5MB | Poor | Low |

---

## Practical Recommendations (Without Re-encoding)

If ffmpeg is NOT available, here is what can actually be done right now, ranked by impact:

### Tier 1: Implement Now (High Impact)

#### 1. Smooth the scroll input signal (lerp/ease the target time)
```typescript
let currentVideoTime = 0;
const LERP_FACTOR = 0.15; // Lower = smoother but laggier

scroll((progress: number) => {
  const targetTime = progress * video.duration;
  currentVideoTime += (targetTime - currentVideoTime) * LERP_FACTOR;
  seekTo(currentVideoTime);
}, { target: section, offset: ['start start', 'end end'] });
```

This mimics GSAP's `scrub: 0.5` behavior.

#### 2. Apply brief blur during seeking
```css
.scroll-video { transition: filter 0.08s ease-out; }
.scroll-video.seeking { filter: blur(0.5px); }
```

#### 3. Increase scroll distance (section height)
Increase from 300vh to 400-500vh for finer granularity per scroll unit.

### Tier 2: Consider (Medium Impact)

#### 4. Use `requestVideoFrameCallback` for frame-gate
```typescript
function seekTo(time: number) {
  video.currentTime = time;
  video.requestVideoFrameCallback((now, metadata) => {
    video.classList.remove('seeking');
  });
  video.classList.add('seeking');
}
```

#### 5. Debounce rapid small seeks
```typescript
const MIN_SEEK_DELTA = 0.04; // seconds
let lastSeekedTime = 0;

function seekTo(time: number) {
  if (Math.abs(time - lastSeekedTime) < MIN_SEEK_DELTA) return;
  lastSeekedTime = time;
  video.currentTime = time;
}
```

### Tier 3: Requires External Action

#### 6. Get a re-encoded video
The single highest-impact change. Use HandBrake, Cloudconvert, or `brew install ffmpeg`.

#### 7. Switch to image sequence (nuclear option)
The Apple approach — guarantees perfect smoothness but requires ffmpeg and dramatically increases payload.

---

## Recommended Implementation Order

1. **Lerp the scroll input** (Tier 1, #1) — biggest bang for zero external dependencies
2. **CSS blur mask** (Tier 1, #2) — 5 minutes of work, noticeable improvement
3. **Increase section height** to 400-500vh (Tier 1, #3) — one-line change
4. **`requestVideoFrameCallback` frame-gate** (Tier 2, #4) — moderate effort, good polish
5. **Debounce small seeks** (Tier 2, #5) — small effort, reduces decoder thrashing
6. **Get re-encoded video** (Tier 3) — pursue in parallel, this is the real fix

---

## Sources

- [CSS-Tricks: Apple-Style Scroll Animations](https://css-tricks.com/lets-make-one-of-those-fancy-scrolling-animations-used-on-apple-product-pages/)
- [Codrops: OPTIKKA Scroll-Synchronized Animation](https://tympanus.net/codrops/2025/10/16/creating-smooth-scroll-synchronized-animation-for-optikka-from-html5-video-to-frame-sequences/)
- [Jeff Pamer: FFmpeg Mega Command for Smooth Scrubbing](https://gist.github.com/jeffpamer/f3134c5145238d0fd4752221b2d75eb7)
- [MDN: requestVideoFrameCallback](https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/requestVideoFrameCallback)
- [web.dev: Efficient per-video-frame operations](https://web.dev/articles/requestvideoframecallback-rvfc)
- [GSAP Forum: Smooth Video Scrolling with playbackRate](https://gsap.com/community/forums/topic/23817-smooth-video-scrolling-using-playbackrate-instead-of-currenttime/)
- [GSAP Forum: Scrub through video smoothly](https://gsap.com/community/forums/topic/25730-scrub-through-video-smoothly-scrolltrigger/)
- [Smashing Magazine: CSS GPU Animation](https://www.smashingmagazine.com/2016/12/gpu-animation-doing-it-right/)
- [Ghosh.dev: Video Scrubbing Animations](https://www.ghosh.dev/posts/playing-with-video-scrubbing-animations-on-the-web/)
- [Eric Park: Smooth Scrubbing Videos](https://ericswpark.com/blog/2022/2022-11-07-smooth-scrubbing-videos/)
- [GitHub: diffusionstudio/webcodecs-scroll-sync](https://github.com/diffusionstudio/webcodecs-scroll-sync)
- [W3C CSSWG Issue #3837: CSS Motion Blur](https://github.com/w3c/csswg-drafts/issues/3837)
