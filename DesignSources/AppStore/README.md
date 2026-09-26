# App Store screenshots

Captured from Healthy Heroes commit 6ce2713 (main screen recaptured with the subsequent working-tree progress fix) on iPhone 17 Pro Max / iOS 26.5 on 17 September 2026. These are native simulator captures of the existing local profile, with no scaling or compositing.

## Available

- `iphone-6.9/main-1320x2868.jpg`: main screen, existing Knight profile, 100 XP. Recaptured after the progress-scale correction: 50% at 100 XP, verified in the running app.
- `iphone-6.9/map-1320x2868.jpg`: dynamic map at step 10/20, both upcoming reward nodes visible.

Both files were visually inspected and checked with `sips`: 1320 × 2868 pixels, no alpha. This portrait dimension is accepted for the 6.9-inch iPhone set in [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), checked on the capture date. iPhone portrait follows the later Telegram decision.

The iPhone Start capture `iphone-6.9/start-1320x2868.jpg` was recaptured on 26 September on iPhone 17 Pro Max / iOS 26.5 with a fresh profile after capping the logo to its source pixel width. Logo, Play and tagline were visually checked. Native JPEG, 1320 × 2868, no alpha.

## iPad 13-inch

Captured on iPad Pro 13-inch (M5), iOS 26.5, in landscape orientation:

- `ipad-13/start-2752x2064.jpg`: Start screen before creating a profile.
- `ipad-13/map-2752x2064.jpg`: map at 30 XP / step 3 after the first food and quest.

Both original native JPEG captures were visually inspected; dimensions are 2752 × 2064 and alpha is absent, checked with `sips`. Neither image was resized or composited. On 25 September, `map-landscape-left-2752x2064.jpg` and `map-landscape-right-2752x2064.jpg` were captured after selecting each named Simulator orientation. The full route, hero, both reward nodes, Back and progress panel remain visible; both JPEGs are 2752 × 2064 with no alpha.

## Remaining

The 25 named canvas presets are now supplied in `canvas-presets.json` and `canvases/`. iPhone dimensions are portrait under the later Telegram decision; iPad dimensions remain landscape. These blank, opaque-base SVG templates are editable placement canvases, not submission images. Export JPEG or flatten PNG alpha and verify the resulting dimensions. Some smaller presets are legacy target sizes from the issue, not a claim that Apple currently accepts each as a separate submission set. These files are partial capture deliverables, not evidence that HEA-21/22 or the complete app are accepted. No App Store upload has been performed. Recapture after visible UI changes before submission.
