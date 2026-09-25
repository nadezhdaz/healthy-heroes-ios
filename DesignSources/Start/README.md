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
- `Start/Start-play.png`: 421 × 406, transparent normal state.
- `play-pressed.svg` in this folder: transparent composition of the same Play image, centered scale 0.92 and brightness offset −0.08, with the canvas unchanged. Runtime animates over 0.12 s; Reduce Motion disables interpolation.

Use @3x for iPhone and @2x for iPad. Source resolution is a remaining limitation: the 997-pixel logo is insufficient for a 440-point @3x box; Play can need up to 450 pixels at @3x. Do not claim that enlarging these PNGs creates higher-resolution artwork. Obtain a vector or larger original for pixel-perfect maximum-size exports. Background scenery can also require scaling at the largest output dimensions.

## Export and verification

`../AppStore/canvases/` contains 25 named exact-size SVG canvases listed in `../AppStore/canvas-presets.json`. These are blank placement templates with an opaque white base, not submission screenshots. Place actual app captures in the named content group. Export JPEG (which has no alpha), or explicitly flatten PNG alpha; check output dimensions and alpha before submission. Do not submit SVG files or blank templates.

Run `python3 DesignSources/Start/check_handoff.py` from the repository root. It checks every canvas dimension, unique names, opaque base, SVG integrity, embedded image references, launch composition and logo/Play safe-area boxes. This is structural validation, not a full-device visual test. Earlier Quick Look thumbnails cropped the compositions to squares; they cannot establish full-frame visual acceptance. Native Start screenshots already exist in `../AppStore/`.

## Original-source audit — 19 September 2026

The local `DesignSources/LOGO/logo-simpl.png` and `DesignSources/UI buttons/Play.png` match the runtime dimensions (997×475 and 421×406). The 1300×1300 logo-kid image is a different opaque composition. The 2048×1536 Play-Start-screen export contains a small button on a mostly transparent full-screen canvas; its canvas size is not evidence of a higher-resolution button.

Figma metadata identifies a vector Play group at [node 5:124](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=5-124), with ellipse/vector children and a 421×406 design box. This is a concrete candidate for a resolution-independent source. Export has **not** been obtained: the connected desktop plugin reported `plugin not connected`, and cloud get_design_context returned the Starter-plan MCP call limit. Resume from this exact node when Figma export access is available; do not substitute a raster enlargement. No higher-resolution matching wordmark has been verified yet.
