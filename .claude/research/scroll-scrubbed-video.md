# Scroll-Scrubbed Video Research

## 1. Executive Summary

**Recommended approach: `video.currentTime` driven by motion's `scroll()` callback, with the video re-encoded at keyframe interval 1-2 and preloaded via `fetch()` + `createObjectURL()`.**

For a typical MP4 under 20MB, the `video.currentTime` approach is the pragmatic winner. It avoids the massive bandwidth cost of image sequences (hundreds of individual files), keeps the implementation simple, and integrates cleanly with the motion `scroll()` pattern. The video must be re-encoded with frequent keyframes (`-g 1` or `-g 2`) for smooth seeking. Canvas + image-sequence is the Apple-grade approach but is overkill for a single hero video. WebCodecs is promising but has incomplete Safari support.

---

## 2. Detailed Analysis

### 2.1 Canvas + Image Sequence vs. `video.currentTime`

#### Canvas + Image Sequence (Apple's approach)

**How it works:** Extract every frame from the video as individual images (JPEG/WebP), preload them all, then draw the appropriate frame to a `<canvas>` on scroll using `context.drawImage()`.

**Pros:**
- Frame-perfect seeking with zero decode latency (frames are pre-decoded bitmaps)
- No codec/keyframe concerns — every "frame" is independently accessible
- Works identically across all browsers and devices
- Supports forward and reverse scrubbing equally well
- Apple uses this on product pages (AirPods Pro, MacBook, etc.)

**Cons:**
- Massive bandwidth: A 10-second video at 30fps = 300 individual images. Even at WebP quality 80, this can be 10-50MB+ total
- Complex preloading pipeline (staged loading, parallel queues)
- Memory pressure: holding 300+ decoded bitmaps in memory
- Requires an ffmpeg extraction step + hosting infrastructure for hundreds of files

**When to use:** High-budget product showcases where frame-perfect smoothness is non-negotiable and bandwidth is acceptable (Apple-scale CDN).

#### `video.currentTime` Direct Seeking

**How it works:** Set `video.currentTime = progress * video.duration` on scroll. The browser's native video decoder handles frame rendering.

**Pros:**
- Single file — no additional bandwidth
- Simple implementation (~30 lines of code)
- Integrates directly with motion `scroll()` callback
- Good browser support for H.264 baseline profile

**Cons:**
- Seeking to non-keyframes causes visible lag (browser must decode from nearest keyframe)
- Reverse scrubbing can be slightly less smooth than forward
- File size increases 2-5x when re-encoding with frequent keyframes
- Safari handles delta-frame reconstruction better than Chrome; Firefox is weakest

**When to use:** When video file size is manageable (<20MB after re-encoding), the video is a background/atmospheric element (not pixel-critical), and development simplicity matters.

#### Canvas + Video Source (Hybrid)

**How it works:** Use a hidden `<video>` element as the source, seek to the target time, then `context.drawImage(video, 0, 0)` on a visible `<canvas>`.

**Pros:**
- Single video file (no image sequence)
- Canvas gives you compositing/filter control

**Cons:**
- Still depends on video seeking performance (same keyframe issues)
- Adds complexity without solving the core seeking problem
- The `drawImage()` call must wait for the seek to complete (`seeked` event)
- No real advantage over direct video display for this use case

**Verdict:** Adds complexity without benefit. Skip this approach.

#### WebCodecs API (Emerging)

**How it works:** Use the WebCodecs API to demux and decode video frames directly in the browser, rendering individual `VideoFrame` objects to canvas.

**Pros:**
- Direct frame access without hacks
- Intelligent buffer window (decode frames around current position)
- Best possible frame-accurate seeking

**Cons:**
- **Safari support is incomplete** — only available on iOS 26+ / Safari 26+, not yet widely deployed
- Very limited documentation and AI-assistant support (prone to hallucinated APIs)
- Requires manual memory management (`VideoFrame.close()`)
- Complex backward seeking (must find nearest keyframe, decode forward)
- Overkill for a single hero video

**Verdict:** Not ready for production. Revisit in 2027 when Safari support matures.

---

### 2.2 Video Encoding for Seeking

**The keyframe problem:** Standard H.264 encoding places keyframes (I-frames) every 60-250 frames. Seeking to any position between keyframes requires decoding from the nearest keyframe forward — this is what causes visible stutter during scroll scrubbing.

**Solution:** Re-encode with every frame (or every 2nd frame) as a keyframe.

#### Recommended ffmpeg Command

```bash
# All-keyframe encoding (smoothest, ~2x file size)
ffmpeg -i input.mp4 \
  -vcodec libx264 \
  -pix_fmt yuv420p \
  -profile:v baseline \
  -level 3 \
  -an \
  -vf "scale=1920:-1" \
  -crf 23 \
  -preset veryslow \
  -g 1 \
  -x264-params "keyint=1:scenecut=0" \
  output-scrub.mp4
```

**Flag breakdown:**

| Flag | Purpose |
|------|---------|
| `-vcodec libx264` | H.264 for universal browser support |
| `-pix_fmt yuv420p` | Maximum compatibility pixel format |
| `-profile:v baseline -level 3` | Maximum device compatibility (incl. older mobile) |
| `-an` | Strip audio (not needed for scroll scrubbing) |
| `-vf "scale=1920:-1"` | Cap width at 1920px, maintain aspect ratio |
| `-crf 23` | Good quality-to-size ratio (lower = higher quality) |
| `-preset veryslow` | Best compression for given quality |
| `-g 1` | Keyframe every frame (smoothest seeking) |
| `-x264-params "keyint=1:scenecut=0"` | Enforce strict keyframe interval, disable scene-change detection |

**File size impact:**
- `-g 1` (every frame): ~2-3x original size
- `-g 2` (every 2 frames): ~1.5-2x original size
- `-g 5` (every 5 frames): ~1.2x original size — works for Chrome/Safari but Firefox stutters

**Recommendation:** Start with `-g 1` and check file size. If over 15MB, try `-g 2` with `-crf 25`. For cross-browser smoothness, `-g 2` is the sweet spot.

#### Optional: Dual-format for Firefox

Firefox handles MP4 seeking worse than Safari/Chrome. For best cross-browser results:

```bash
# WebM for Firefox
ffmpeg -i input.mp4 \
  -vcodec libvpx-vp9 \
  -pix_fmt yuv420p \
  -an \
  -vf "scale=1920:-1" \
  -crf 30 -b:v 0 \
  -g 1 \
  output-scrub.webm
```

Then use `<source>` elements to serve WebM to Firefox and MP4 to others.

---

### 2.3 Scroll-to-Video Mapping with motion `scroll()`

#### How it integrates

The motion library's `scroll()` API provides a callback-based pattern for scroll-driven animations:

```typescript
// Sticky scroll scene pattern:
scroll(
  (progress: number) => setProgress(progress),
  { target: section, offset: ['start start', 'end end'] }
);

// Video scrubbing follows the same pattern:
scroll(
  (progress: number) => {
    video.currentTime = progress * video.duration;
  },
  { target: sectionElement, offset: ['start start', 'end end'] }
);
```

#### RAF Throttling — NOT Needed

Motion's `scroll()` internally uses a single `requestAnimationFrame` callback with batched reads/writes. It does **not** fire on every scroll event — it fires once per frame. This means:

- No need for manual RAF debouncing
- No need for a `ticking` flag pattern
- Motion handles the frame scheduling automatically
- When the browser supports `ScrollTimeline`, motion offloads to native browser scheduling

The `scroll()` callback is already frame-rate-limited. Setting `video.currentTime` inside it is the correct approach.

#### Offset Configuration

For a hero video that plays through as the user scrolls past it:

```typescript
offset: ['start start', 'end end']
// Video starts playing when section top hits viewport top
// Video finishes when section bottom hits viewport bottom
```

For the section to be "sticky" (video fills viewport while user scrolls through extended content):

```typescript
// Section: height 300vh (or more)
// Inner content: position sticky, height 100vh
offset: ['start start', 'end end']
```

---

### 2.4 Preloading Strategy

**The problem:** If the video isn't fully buffered, seeking to unbuffered regions causes the video to stall or show a blank frame while loading.

#### Recommended: `fetch()` + `createObjectURL()`

```typescript
async function preloadVideo(src: string): Promise<string> {
  const response = await fetch(src);
  const blob = await response.blob();
  return URL.createObjectURL(blob);
}
```

**Why this works:**
- `fetch()` downloads the entire file into memory as a blob
- `createObjectURL()` creates a local URL pointing to the in-memory blob
- The browser can seek to any position instantly because the entire file is local
- No dependency on browser's heuristic `preload="auto"` behavior

**Why not `preload="auto"`:**
- Browsers treat `preload` as a hint, not a guarantee
- Many mobile browsers ignore it entirely to save bandwidth
- You have no way to know when buffering is "complete enough"

#### Implementation Pattern

```typescript
const [videoSrc, setVideoSrc] = useState<string | null>(null);

useEffect(() => {
  let objectUrl: string | undefined;

  fetch('/video/hero-video.mp4')
    .then(res => res.blob())
    .then(blob => {
      objectUrl = URL.createObjectURL(blob);
      setVideoSrc(objectUrl);
    });

  return () => {
    if (objectUrl) URL.revokeObjectURL(objectUrl);
  };
}, []);
```

Only enable scroll scrubbing after `videoSrc` is set and the video's `loadedmetadata` event has fired.

---

### 2.5 iOS Safari Considerations

#### Known Issues

1. **Autoplay restrictions:** iOS Safari blocks video autoplay unless the video is muted and `playsinline` is set. For scroll scrubbing we don't call `play()` at all — we set `currentTime` directly — but the element still needs `muted playsInline` attributes for proper initialization.

2. **Scroll event throttling:** iOS Safari aggressively throttles scroll events during momentum scrolling. However, motion's `scroll()` uses `ScrollTimeline` where available, which bypasses this throttling. On older iOS versions that don't support `ScrollTimeline`, motion falls back to JS-based scroll tracking.

3. **Video seeking performance:** Safari actually handles `video.currentTime` seeking **better** than Chrome in many cases — it "recreates delta frames on the fly" more efficiently. This is an advantage for the `video.currentTime` approach.

4. **Canvas + video `drawImage`:** On iOS Safari, calling `canvas.drawImage(videoElement)` can produce blank frames if the video hasn't finished seeking. Always wait for the `seeked` event.

5. **Memory pressure:** iOS has stricter memory limits. A preloaded video blob (~10-15MB) is fine, but an image sequence of 300+ frames could trigger memory warnings.

#### Required HTML Attributes

```html
<video
  muted
  playsInline
  preload="auto"
  src={videoSrc}
/>
```

`playsInline` is critical on iOS — without it, Safari may try to enter fullscreen mode on interaction.

---

### 2.6 Performance Considerations

#### GPU Compositing

- The `<video>` element is automatically composited on its own GPU layer in most browsers
- For canvas approaches, add `will-change: transform` to promote to a compositor layer
- Avoid animating other layout-triggering properties simultaneously with video seeking

#### Canvas Size

If using canvas (not recommended for most projects), match the canvas element size to the video's display size, not its native resolution. Use `devicePixelRatio` scaling for retina:

```typescript
canvas.width = displayWidth * devicePixelRatio;
canvas.height = displayHeight * devicePixelRatio;
canvas.style.width = `${displayWidth}px`;
canvas.style.height = `${displayHeight}px`;
context.scale(devicePixelRatio, devicePixelRatio);
```

#### Frame Rate

- motion's `scroll()` fires at the browser's native refresh rate (typically 60fps, up to 120fps on ProMotion displays)
- Setting `video.currentTime` 60 times per second is fine — the browser coalesces seeks
- No need to manually throttle below the frame rate

#### Sticky Section Height

For a smooth scrubbing experience, the scroll distance should be proportional to video duration:

- Short video (3-5s): `200vh-300vh` section height
- Medium video (5-10s): `300vh-500vh` section height
- This gives the user enough scroll distance for fine-grained control

---

## 3. Final Recommendation

### Approach: `video.currentTime` + motion `scroll()` callback

#### Implementation Steps

1. **Re-encode the video** with all-keyframe encoding:
   ```bash
   ffmpeg -i input.mp4 \
     -vcodec libx264 -pix_fmt yuv420p \
     -profile:v baseline -level 3 \
     -an -crf 23 -preset veryslow \
     -g 1 -x264-params "keyint=1:scenecut=0" \
     output-scrub.mp4
   ```

2. **Create `useScrollVideo` hook** following existing scroll animation patterns:
   - Accept `sectionRef`, `videoRef`, and options (offset)
   - Preload video via `fetch()` + `createObjectURL()`
   - Use motion `scroll()` callback to set `video.currentTime = progress * duration`
   - Expose `{ isLoaded, progress }` state
   - Clean up: revoke object URL, cancel scroll listener

3. **Create scroll video section**:
   - Outer section: `300vh` height (provides scroll distance)
   - Inner sticky container: `100vh`, `position: sticky`, `top: 0`
   - `<video>` element: `muted playsInline`, fill container, `object-fit: cover`
   - Show placeholder/loading state until video is preloaded
   - Fade in video once loaded

4. **HTML video attributes:**
   ```html
   <video
     ref={videoRef}
     muted
     playsInline
     preload="auto"
     style={{ objectFit: 'cover', width: '100%', height: '100%' }}
   />
   ```

5. **Respect `prefers-reduced-motion`:** Show static first frame instead of scroll scrubbing.

#### Why This Approach

- **Matches scroll animation patterns:** Same `scroll()` callback as sticky scroll scenes and scroll counters
- **Minimal bandwidth:** Single re-encoded MP4 (~10-15MB) vs. 300+ images
- **Simple implementation:** ~50-80 lines of hook code
- **Good cross-browser support:** H.264 baseline works everywhere
- **iOS Safari compatible:** Video seeking works well on Safari; `playsInline` + `muted` handles restrictions
- **motion handles RAF:** No manual frame scheduling needed

#### Risk Mitigation

- If Firefox seeking is choppy: add WebM fallback with same `-g 1` encoding
- If re-encoded file exceeds 15MB: try `-g 2` with `-crf 25`, or reduce resolution to 1280px
- If seeking feels sluggish on low-end devices: reduce video resolution for mobile via `<source media="(max-width: 768px)">`

---

## 4. Sources

- [Scrubbing videos using JavaScript — Muffin Man](https://muffinman.io/blog/scrubbing-videos-using-javascript/) — Encoding settings, cross-browser comparison, keyframe impact
- [Scroll to Scrub Videos — Chris How / Medium](https://medium.com/@chrislhow/scroll-to-scrub-videos-4664c29b4404) — fetch() preloading, IntersectionObserver, Manager pattern
- [Apple-style scroll animations — CSS-Tricks](https://css-tricks.com/lets-make-one-of-those-fancy-scrolling-animations-used-on-apple-product-pages/) — Image sequence approach, canvas rendering, Apple's implementation
- [OPTIKKA: HTML5 Video to Frame Sequences — Codrops](https://tympanus.net/codrops/2025/10/16/creating-smooth-scroll-synchronized-animation-for-optikka-from-html5-video-to-frame-sequences/) — Why teams move to image sequences, staged loading, mobile frame counts
- [WebCodecs Video Scroll Synchronization — Keng Lim / Medium](https://lionkeng.medium.com/a-tutorial-webcodecs-video-scroll-synchronization-8b251e1a1708) — WebCodecs API, buffer management, browser support status
- [FFmpeg Smooth Scrubbing Mega Command — Jeff Pamer / GitHub Gist](https://gist.github.com/jeffpamer/f3134c5145238d0fd4752221b2d75eb7) — Production ffmpeg flags for scroll-scrub encoding
- [scroll() API — Motion.dev](https://motion.dev/docs/scroll) — scroll() callback signature, options, ScrollTimeline integration
- [Motion frame API — Motion.dev](https://motion.dev/docs/frame) — Internal RAF batching, read/write scheduling
- [GTA VI website analysis — Motion Magazine](https://motion.dev/blog/supercharging-the-gta-vi-website-with-motion) — ScrollTimeline performance, 90% less processing vs GSAP
- [Web Animation Performance Tier List — Motion Magazine](https://motion.dev/magazine/web-animation-performance-tier-list) — Hardware acceleration tiers, ScrollTimeline benefits
