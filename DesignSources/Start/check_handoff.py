"""Validate exported handoff structure without image or third-party dependencies."""
from pathlib import Path
import base64
import json
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
ns = {"s": "http://www.w3.org/2000/svg"}
presets = json.loads((root / "DesignSources/AppStore/canvas-presets.json").read_text())
assert len(presets) == 25
assert len({p["name"] for p in presets}) == 25
for preset in presets:
    svg = ET.parse(root / "DesignSources/AppStore" / preset["template"]).getroot()
    assert [int(svg.attrib[a]) for a in ("width", "height")] == [preset["width"], preset["height"]]
    background = svg.find("s:rect[@id='opaque-background']", ns)
    assert background is not None and background.attrib["fill"] == "white"
    assert background.attrib["width"] == svg.attrib["width"]
    assert background.attrib["height"] == svg.attrib["height"]

files = list(Path(__file__).parent.glob("*.svg"))
assert len(files) == 7
for path in files:
    svg = ET.parse(path).getroot()
    for image in svg.findall(".//s:image", ns):
        href = image.attrib["href"]
        assert href.startswith("data:image/png;base64,")
        assert base64.b64decode(href.split(",", 1)[1], validate=True).startswith(b"\x89PNG\r\n\x1a\n")
    if path.stem == "play-pressed":
        continue
    guide = svg.find("s:g[@id='safe-area-guides']/s:rect", ns)
    top, height = float(guide.attrib["y"]), float(guide.attrib["height"])
    for name in ("logo", "play-normal"):
        image = svg.find(f"s:image[@id='{name}']", ns)
        if name == "play-normal" and path.stem.endswith("-launch"):
            assert image is None
            continue
        assert image is not None
        x, y, w, h = (float(image.attrib[k]) for k in ("x", "y", "width", "height"))
        assert x >= 0 and x + w <= float(svg.attrib["width"])
        assert y >= top and y + h <= top + height
        if name == "play-normal":
            assert min(w, h) >= 44
print("Validated 25 canvases and 7 Start/launch compositions.")
