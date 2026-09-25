# Start and launch handoff

The later Telegram decision applies: iPhone portrait, iPad landscape. These editable SVG compositions use the existing app artwork, embedded as independent PNG image layers; they are not traced vector art or runtime screenshots.

## Files and placement

| Composition | Logical viewport | Safe top/bottom |
| --- | --- | --- |
| phone-small | 320 × 568 pt | 20 / 0 pt |
| phone-modern | 393 × 852 pt | 59 / 34 pt |
| tablet-landscape | 1376 × 1032 pt | 24 / 20 pt |

Each has a matching `-launch.svg` with only the sky color and logo, mirroring `HealthyHeroes/Resources/LaunchScreen.storyboard`. No Play control appears on the static launch composition. The `safe-area-guides` layer is hidden by default; change its display property to show it. Safe insets are reference inputs, not universal device constants.

Logo is centered in the safe width, 24 pt below its top. Its layout box is min(440 pt, 82% of width) by min(200 pt, 25% of safe height), preserving artwork aspect ratio. Play is centered above the tagline: min(150 pt, 30% of width) by min(150 pt, 23% of safe height), minimum runtime target 44 × 44 pt. Runtime uses flexible vertical space; SVG tagline metrics approximate native text and can vary with installed fonts. Keep the native StartView authoritative for runtime layout.

## Separate source assets

Existing exports are in `../../HealthyHeroes/Resources/Design/`:

- `Start/Start-scenery.png`: 2048 × 1536, opaque, no logo or Play.
- `Phone UI/Phone_Forest-background.png`: 1179 × 2556, opaque portrait scenery.
- `Start/Start-logo.png`: 997 × 475, transparent.
- `Start/Start-play.png`: 1263 × 1218, transparent @3x normal state exported from the original Figma vector. The 421 × 406 design box is cropped from Figma's shadow-expanded 476 × 476 export before rasterization, preserving the existing runtime aspect ratio.
- `play-figma-source.svg`: original scalable Play export from [Figma node 5:124](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=5-124), including its shadow and filters.
- `play-pressed.svg`: transparent vector state in the same 421 × 406 design box, derived from that source, centered at 92% scale and darkened by 0.08. Runtime animates over 0.12 s; Reduce Motion disables interpolation.

Use @3x for iPhone and @2x for iPad. The vector-derived Play export exceeds its 450-pixel @3x maximum display size. The 997-pixel logo remains insufficient for a 440-point @3x box; obtain a larger matching original for pixel-perfect maximum-size exports. Background scenery can also require scaling at the largest output dimensions.

## Export and verification

`../AppStore/canvases/` contains 25 named exact-size SVG canvases listed in `../AppStore/canvas-presets.json`. These are blank placement templates with an opaque white base, not submission screenshots. Place actual app captures in the named content group. Export JPEG (which has no alpha), or explicitly flatten PNG alpha; check output dimensions and alpha before submission. Do not submit SVG files or blank templates.

Run `python3 DesignSources/Start/check_handoff.py` from the repository root. It checks every canvas dimension, unique names, opaque base, SVG integrity, embedded image references, launch composition and logo/Play safe-area boxes. This is structural validation, not a full-device visual test. Full-frame SVG renders were inspected at 320 × 568, 393 × 852 and 1376 × 1032 points on 25 September. Logo, Play and tagline are visible in each, and the static launch compositions omit Play. The iPad scenery itself has characters extending past its bottom edge in the supplied original, as the native capture also shows. Native Start screenshots exist in `../AppStore/`.

## Original-source audit — 19 September 2026

The local `DesignSources/LOGO/logo-simpl.png` is the same 997 × 475 logo. `DesignSources/UI buttons/Play.png` remains the earlier 421 × 406 raster; the runtime button now uses the matching vector-derived @3x export. The 1300 × 1300 logo-kid image is a different opaque composition. The 2048×1536 Play-Start-screen export contains a small button on a mostly transparent full-screen canvas; its canvas size is not evidence of a higher-resolution button.

Figma metadata identifies the vector Play group at [node 5:124](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=5-124), with a 421 × 406 design box. On 25 September the cloud asset export succeeded: the original SVG is stored here, the matching runtime PNG was rendered at @3x, and both states were visually inspected. Figma access still has a Starter-plan call limit for broader design requests. No higher-resolution matching wordmark has been verified yet.
