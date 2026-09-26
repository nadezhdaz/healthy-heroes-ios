# Adaptive map handoff

Reference: https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=86-126

The later Telegram orientation decision supersedes the landscape-phone wording in HEA-22: iPhone portrait, iPad landscape as the design reference. The iPad build declares all orientations so iPadOS can resize its scene in Windowed Apps, as recommended by Apple TN3192. Figma supplies artwork and composition reference. Runtime builds the route from separate tiles for the current viewport.

## Layers and runtime resources

AssetResolver maps these stable IDs to bundled resources:

| Layer | Asset ID | Resource |
| --- | --- | --- |
| Background | map_phone_empty | PhoneMapEmpty |
| Upper scenery | map_phone_top | PhoneMapTop |
| Lower scenery | map_phone_bottom | PhoneMapBottom |
| Horizontal route | map_tile_2 | MapTile2 |
| Left turn halves | map_tile_3 / map_tile_6 | MapTile3 / MapTile6 |
| Right turn halves | map_tile_5 / map_tile_4 | MapTile5 / MapTile4 |
| Hero | map_hero_marker | MapHeroMarker |
| Simple node | map_simple_marker | MapSimpleMarker |
| Epic node | map_epic_marker | MapEpicMarker |

Markers are separate assets. The runtime does not use the flattened map-screen as its route. Tile positions and marker coordinates share AdaptiveMapLayout in HealthyHeroes/Features/Map/MapView.swift.

On 27 September, `figma-bridge` verified the original map and exported independent clipped nodes at scale 1: hero 89:494 (252×288), epic 89:493 (269×259), simple 89:495 (232×232). These replace padded 368×386, 300×319 and 319×341 source canvases, which shrank visible artwork inside runtime frames. The four editable route compositions and node-state sheet embed the same exports. Both reward hit boxes remain 269 route units with a 44-point minimum; their aspect ratios are preserved. The source's simple marker has a smaller 232×232 box, so equal runtime reward boxes are an explicit adaptation, not a literal copy of that reference.

## Coordinates and placement

adaptive-route-anchors.json was exported by executing the current Swift AdaptiveMapLayout, with its source SHA-256 recorded. It contains four reference viewports in logical points, with the safe top/bottom inset inputs. Coordinates are normalized to the full viewport, including safe areas: x * width and y * height recover the screen point. Left/right insets are zero in these reference tables.

There are twenty movement steps (1…20) plus the initial position 0. Thus each table has 21 entries; omitting position 0 would lose the start of the path. These are reference tables, not a replacement for runtime recomputation on resize. Do not reuse one table for a different viewport or safe-area configuration.

Background may extend behind system areas. Controls use the parent safe area; route layout receives those insets and reserves room for top/bottom scenery. Reward hit targets have a 44-point minimum. Hero has no hit testing so a colocated node remains tappable.

## States and motion

Upcoming: artwork opacity 0.65 with a lock badge. Current: full opacity, cream ring and location badge. Passed: full opacity and checkmark badge. Badges stay inside the marker frame. Pressed buttons scale to 0.92 and darken by 0.08 over 0.12 seconds; the hit rectangle stays unscaled. Reduce Motion disables this transition and route movement interpolation.

Hero movement follows cumulative route distance, including sampled turns, over 1.2 seconds. The last viewed position is stored after completed playback; cancellation preserves the last completed position for replay.

## Handoff status and verification

- HEA-22 is In Review after the real resizable-window acceptance check. Product mapping for rewards at positions 14 and 20, and actual milestone grants, are separate content decisions rather than missing asset/layout deliverables.
- `node-states.svg` supplies an editable two-marker, three-state artwork sheet. Original marker PNGs remain independent image layers; opacity, ring, badges and labels are separate editable vectors. Badge paths illustrate the states; SwiftUI SF Symbols named above remain authoritative for the final glyphs. Figma import is optional (Figma is preferred in HEA-22, not mandatory).
- Native opaque App Store map screenshots are supplied in `../AppStore/`; see its README for exact dimensions and capture provenance. All 25 named optional size presets are supplied in `../AppStore/canvases/` with a JSON index; they are blank placement templates, not screenshots.
- Full-screen Landscape Left, Landscape Right and [Portrait](../../docs/evidence/HEA-22/ipad-portrait-full-screen.jpg) were visually checked on iPad Pro 13-inch (M5); landscape native captures are in `../AppStore/ipad-13/`. On 26 September, Windowed Apps was enabled on that simulator and the rebuilt map was checked in full screen, a [narrow full-height window](../../docs/evidence/HEA-22/ipad-narrow-window.jpg) (about 375×1032 points), and a [top-half window](../../docs/evidence/HEA-22/ipad-top-half-window.jpg) (about 1376×516 points). The route recomputed; hero, both reward nodes, Back and STEP/XP remained visible. Back was moved below the system window controls after the first narrow-window capture exposed an overlap; it was tapped successfully in the top-half window. A real navigation interruption preserved map position 6 while progress had reached 7; reopening replayed the movement and then saved 7 ([video](../../docs/evidence/HEA-13/ipad-interrupted-replay.mp4)). The build omits `UIRequiresFullScreen` and supports all iPad orientations per [Apple TN3192](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key). Freeform corner-drag resizing and Stage Manager were not checked.

Use @3x for iPhone and @2x for iPad output scale. Logical-point coordinates above must not be interpreted as screenshot pixels. Keep original source artwork at its native resolution.

## Editable reference compositions

phone-small.svg (320×568), phone-modern.svg (393×852), tablet-landscape.svg (1194×834) and compact-window.svg (500×400) contain embedded original PNG assets as separate reusable symbols. Each route tile is independently positioned; layer groups separate background, scenery, route, reward markers, hero and guides. Artwork remains raster within these editable composition layers; it is not newly traced vector artwork.

The visible magenta guide layer contains the safe-area rectangle and all 21 numbered anchors. Hide `safe-area-and-anchors` for artwork review. Hero is shown at step 7; reward markers are base artwork without state badges. Native runtime controls and node-state overlays are specified above rather than baked into these files. These SVGs are source compositions, not App Store screenshots. All references resolve inside each file; no external image downloads are required.
