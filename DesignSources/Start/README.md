# Start and launch handoff

The later Telegram decision applies: iPhone portrait, iPad landscape. These editable SVG compositions use the existing app artwork, embedded as independent PNG image layers; they are not traced vector art or runtime screenshots.

## Files and placement

| Composition | Logical viewport | Safe top/bottom |
| --- | --- | --- |
| phone-small | 320 × 568 pt | 20 / 0 pt |
| phone-modern | 393 × 852 pt | 59 / 34 pt |
| phone-large | 440 × 956 pt | 62 / 34 pt |
| tablet-landscape | 1376 × 1032 pt | 24 / 20 pt |

Each has a matching `-launch.svg` with only the sky color and logo, mirroring `HealthyHeroes/Resources/LaunchScreen.storyboard`. No Play control appears on the static launch composition. The `safe-area-guides` layer is hidden by default; change its display property to show it. Safe insets are reference inputs, not universal device constants.

Logo is centered in the safe width, 24 pt below its top. Its runtime layout box is min(440 pt, 997 / displayScale pt, 82% of width) by min(200 pt, 25% of safe height), preserving artwork aspect ratio. This caps the @3x phone logo at 332⅓ points; the storyboard uses 332 points in compact width and 440 points in regular width. Play is centered above the tagline: min(150 pt, 30% of width) by min(150 pt, 23% of safe height), minimum runtime target 44 × 44 pt. Runtime uses flexible vertical space; SVG tagline metrics approximate native text and can vary with installed fonts. Keep the native StartView authoritative for runtime layout.

Knight and Princess are independent fit-mode layers inside the safe area. Their centers are at 23% / 77% of safe width and 48% of safe height in portrait, 62% in landscape. Each box is 35% of width in portrait / 20% in landscape, with height min(300 pt, 600 / displayScale pt, 30% of safe height in portrait / 60% in landscape). The opaque scenery uses aspect-fill behind the safe area; only scenery may be cropped. Decorative layers are hidden from accessibility and cannot intercept Play. SwiftUI's fit/fill behavior was checked through [Sosumi](https://sosumi.ai/documentation/swiftui/view/aspectratio(_:contentmode:)).

## Separate source assets

Existing exports are in `../../HealthyHeroes/Resources/Design/`:

- `Start/Start-scenery.png`: 2048 × 1536, opaque, no characters, logo or Play; original image fill from [Figma node 66:39](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=66-39).
- `Start/Start-knight.png`: 447 × 600, transparent, complete character from [node 66:36](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=66-36).
- `Start/Start-princess.png`: 394 × 716, transparent, complete character from [node 66:37](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=66-37).
- `Start/Start-logo.png`: 997 × 475, transparent.
- `Start/Start-play.png`: 1263 × 1218, transparent @3x normal state exported from the original Figma vector. The 421 × 406 design box is cropped from Figma's shadow-expanded 476 × 476 export before rasterization, preserving the existing runtime aspect ratio.
- `play-figma-source.svg`: original scalable Play export from [Figma node 5:124](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=5-124), including its shadow and filters.
- `play-pressed.svg`: transparent vector state in the same 421 × 406 design box, derived from that source, centered at 92% scale and darkened by 0.08. Runtime animates over 0.12 s; Reduce Motion disables interpolation.

Use @3x for iPhone and @2x for iPad. The vector-derived Play export exceeds its 450-pixel @3x maximum display size. The runtime logo fits within its 997 source pixels at both densities; a larger matching original is unnecessary for these capped placements. Background scenery can still require scaling at the largest output dimensions.

The character rectangles in Figma use CROP and cut off the original art. On 27 September, native Figma MCP `get_image_bytes` retrieved their complete 2048 × 1536 transparent source canvases. Removed only transparent padding with native `sips`, retaining the original pixels: Knight bounds (409, 842)–(856, 1442), Princess bounds (1240, 791)–(1634, 1507). Pixel comparisons against those source regions are identical. Original image hashes: Knight `eef00385bce233566012f5a3018c1a9b761bd35b`, Princess `3c8f9560e34eaa57788ab1580debd6be1f29f3f5`, scenery `4972cfb9c225d3ceb2bfa2bfa23f7d004c0ea5f0`. Figma originals were not modified.

## Export and verification

`../AppStore/canvases/` contains 25 named exact-size SVG canvases listed in `../AppStore/canvas-presets.json`. These are blank placement templates with an opaque white base, not submission screenshots. Place actual app captures in the named content group. Export JPEG (which has no alpha), or explicitly flatten PNG alpha; check output dimensions and alpha before submission. Do not submit SVG files or blank templates.

Run `python3 DesignSources/Start/check_handoff.py` from the repository root. It checks every canvas dimension, unique names, opaque base, SVG integrity, embedded image references, launch composition, logo/Play/hero safe-area boxes and source resolution at @3x phone / @2x iPad density. All eight Start/launch compositions pass. Two PhoneFlowTests passed on iPhone 17 Pro Max / iOS 26.5 (`/private/tmp/hh-full-start-characters.xcresult`); inspected loaded hosted renders at 320 × 568, 440 × 956, 1376 × 1032 and 375 × 516 points. These renders are supplementary, not real iPad window resizing. On a separate fresh iPad Pro 13-inch / iOS 26.5, inspected Start in portrait and both landscape orientations after three consecutive physical Simulator rotations; complete heroes, logo and Play fit, and Play → Create Hero → Back works. The new landscape captures are `../AppStore/ipad-13/start-2752x2064.jpg` and `start-opposite-2752x2064.jpg`, exact native JPEGs without alpha. The earlier Princess source gap is resolved.

## Original-source audit — 19 September 2026

The local `DesignSources/LOGO/logo-simpl.png` is the same 997 × 475 logo. `DesignSources/UI buttons/Play.png` remains the earlier 421 × 406 raster; the runtime button now uses the matching vector-derived @3x export. The 1300 × 1300 logo-kid image is a different opaque composition. The 2048×1536 Play-Start-screen export contains a small button on a mostly transparent full-screen canvas; its canvas size is not evidence of a higher-resolution button.

Figma metadata identifies the vector Play group at [node 5:124](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=5-124), with a 421 × 406 design box. On 25 September the cloud asset export succeeded: the original SVG is stored here, the matching runtime PNG was rendered at @3x, and both states were visually inspected. Figma cloud access still has a Starter-plan call limit for broader requests; native Figma MCP retrieved the complete character/scenery originals on 27 September. Critical assets fit their source pixels. The decorative background still scales beyond its 2048 × 1536 original on large devices; a larger matching source has not been verified.

The final hosting-layout check passed after removing the forced root frame (`/private/tmp/hh-full-start-safe-layout.xcresult`, two tests, zero failures/warnings). All four final renders were inspected. The native phone Start capture was also replaced on 27 September: `../AppStore/iphone-6.9/start-1320x2868.jpg`, 1320 × 2868 JPEG without alpha; full heroes/logo/Play/tagline fit and Play opens Create Hero.
