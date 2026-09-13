"""Reproducible chroma-key and cell extraction for the original generated sheets."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "Assets"
for sheet, names, boundaries in [
    ("a", ["rook", "vesper", "atlas"], [0, 310, 620, 1024]),
    ("b", ["sora", "kestrel", "jin"], [0, 330, 660, 1024]),
]:
    source = Image.open(ROOT / f"fighters-{sheet}-green.png").convert("RGBA")
    for row, name in enumerate(names):
        for col, pose in enumerate(["idle", "punch", "kick", "hurt"]):
            cell = source.crop(
                (col * 384, boundaries[row], (col + 1) * 384, boundaries[row + 1])
            )
            pixels = []
            for r, g, b, a in cell.getdata():
                green = g > 95 and g > r * 1.35 and g > b * 1.35
                pixels.append(
                    (r, min(g, max(r, b)) if green else g, b, 0 if green else a)
                )
            cell.putdata(pixels)
            box = cell.getbbox()
            if box:
                cell = cell.crop(box)
            cell.save(ROOT / f"{name}-{pose}.png")

source = Image.open(ROOT / "portraits.png")
for index, name in enumerate(["rook", "vesper", "atlas", "sora", "kestrel", "jin"]):
    x, y = (index % 3) * 512, (index // 3) * 512
    source.crop((x, y, x + 512, y + 512)).save(
        ROOT / f"{name}-portrait.jpg", quality=92
    )
