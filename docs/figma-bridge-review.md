# Figma Bridge verification — 27 September 2026

Reviewed the connected `HH project ui sketch` through `figma-bridge`: document tree, image fills/crop transforms, absolute map layout and direct node exports. Figma supplies artwork and visual references; Telegram and the owner's decisions remain authoritative for adaptive behavior and reward content. No original Figma nodes were changed.

| Question | Finding and action |
| --- | --- |
| Are Start characters incomplete in the original? | No. The CROP transforms of 66:36/37 match their complete transparent bounds. Their parent, marketing frame 66:34, clips content at 630 units; the characters extend to 789/810. Corrected the previous diagnosis in Start/README and remaining acceptance. Runtime Knight 447×600 and Princess 394×716 remain pixel-identical to the full source character regions. These are reusable marketing image fills, not Start composition masters. |
| Is there a larger matching backdrop? | Larger marketing rectangles reuse the same image hash `4972cfb9c225d3ceb2bfa2bfa23f7d004c0ea5f0`; their dimensions do not establish a larger original. Keep the known 2048×1536 backdrop and existing critical-asset resolution caps. |
| Do the route tile sizes match? | Yes. Map 86:126 uses 10-unit yellow strokes and green `#bdf445` fills. Its turn halves are 261×226, matching runtime resources; the straight tile's 249×184 geometry plus centered stroke produces the 259×194 PNG used by the assembler. Reviewed existing native phone, narrow iPad and top-half iPad captures: joins remain continuous. Different row/column counts are required by dynamic assembly. |
| Are marker proportions correct? | Found a real discrepancy: runtime loaded full transparent source canvases while Figma crops them. Exported nodes 89:494/493/495 directly through Bridge into 252×288, 269×259 and 232×232 PNGs. Replaced the three resources and corresponding embedded layers in five editable SVGs. This corrects visible scale without changing route coordinates, marker centers or hit targets. |
| Does this Figma page specify milestone gifts? | The page contains separate Bronze/Silver/Gold icon groups 48:134, 51:157 and 53:15, but no named inventory gifts or readable milestone threshold definitions. Thresholds 30/60/100 come from the supplied milestone screenshot, and title/badge rewards from the owner's explicit approval. The existing HEA-18 gift-content follow-up remains necessary. |

Sources: [map](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=86-126), [marketing parent](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=66-34), [hero marker](https://www.figma.com/design/8EOrGXfqa08zOuegezFC2y/HH-project-ui-sketch?node-id=89-494).

Validation results and fresh map captures are recorded in remaining acceptance. This review does not substitute a new runtime window-resize check for the real checks already recorded in HEA-22.
