"""Grade renders and build matching native bundles. Requires Pillow 11.3.0."""

import hashlib
import json
import math
from pathlib import Path
import struct
import wave

from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parent
DESTINATIONS = (
    ROOT.parent / "ios/TowerTussle/RenderedArt",
    ROOT.parent / "android/app/src/main/assets/art",
)
ROSTER = ("knight", "archers", "giant", "duelist", "sharpshooter", "gremlins", "bones", "whelp")
COLORS = (
    (29, 102, 135), (85, 52, 136), (46, 102, 104), (78, 43, 111),
    (31, 88, 113), (31, 108, 78), (57, 66, 106), (43, 112, 108),
    (146, 49, 40), (80, 57, 151),
)


def grade(name):
    image = Image.open(ROOT / "renders" / f"{name}.png").convert("RGBA")
    alpha = image.getchannel("A")
    image = ImageEnhance.Color(image).enhance(1.30)
    image = ImageEnhance.Contrast(image).enhance(1.09)
    image.putalpha(alpha)
    return image


def portrait(card, index):
    image = grade(f"card_{card}")
    w, h = image.size
    base = COLORS[index]
    background = Image.new("RGBA", (w, h))
    pixels = background.load()
    for y in range(h):
        for x in range(w):
            distance = math.hypot((x - w * 0.5) / w, (y - h * 0.32) / h)
            light = max(0.24, 1.15 - distance * 0.92)
            pixels[x, y] = tuple(int(c * light) for c in base) + (255,)
    overlay = Image.new("RGBA", (w, h))
    draw = ImageDraw.Draw(overlay)
    center = (w / 2, h * 0.40)
    for i in range(12):
        a = i / 12 * math.tau
        b = a + 0.12
        draw.polygon([center, (center[0] + math.cos(a) * h, center[1] + math.sin(a) * h),
                      (center[0] + math.cos(b) * h, center[1] + math.sin(b) * h)], fill=(180, 231, 255, 12))
    draw.regular_polygon((w / 2, h * 0.40, w * 0.42), 6, outline=(202, 235, 255, 45), width=2)
    for i in range(15):
        x, y = (i * 173 + 27) % w, (i * 91 + 23) % h
        draw.ellipse((x, y, x + 2, y + 2), fill=(232, 244, 255, 110))
    background = Image.alpha_composite(background, overlay)
    return Image.alpha_composite(background, image)


def main():
    outputs = {}
    for i, card in enumerate((*ROSTER, "meteor", "volley")):
        outputs[f"card_{card}"] = portrait(card, i)
    for card in ROSTER:
        atlas = Image.new("RGBA", (1536, 512))
        for team in range(2):
            for frame in range(6):
                suffix = "_red" if team else ""
                atlas.paste(grade(f"unit_{card}_{frame}{suffix}"), (frame * 256, team * 256))
        outputs[f"units_{card}"] = atlas
    for name in ("hero", "emblem", "arena", "tower_keep_blue", "tower_keep_red", "tower_guard_blue", "tower_guard_red"):
        outputs[name] = grade(name)
    for destination in DESTINATIONS:
        destination.mkdir(parents=True, exist_ok=True)
        for name, image in outputs.items():
            image.save(destination / f"{name}.png", optimize=True)
    icon = Image.new("RGB", (1024, 1024), (7, 22, 43))
    draw = ImageDraw.Draw(icon)
    for radius in range(620, 0, -1):
        glow = max(0, 1 - radius / 620)
        draw.ellipse((512 - radius, 480 - radius, 512 + radius, 480 + radius), fill=(7 + int(glow * 10), 22 + int(glow * 34), 43 + int(glow * 40)))
    draw.rounded_rectangle((45, 45, 979, 979), radius=180, outline=(180, 139, 70), width=8)
    crown = outputs["emblem"].resize((950, 950), Image.Resampling.LANCZOS)
    icon.paste(crown, (37, 45), crown)
    catalog = ROOT.parent / "ios/TowerTussle/Assets.xcassets/AppIcon.appiconset"
    catalog.mkdir(parents=True, exist_ok=True)
    icon.save(catalog / "AppIcon.png")
    (catalog / "Contents.json").write_text(json.dumps({"images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    android_icons = ROOT.parent / "android/app/src/main/res/drawable-nodpi"
    android_icons.mkdir(parents=True, exist_ok=True)
    icon.resize((512, 512), Image.Resampling.LANCZOS).save(android_icons / "arcade_icon.png")
    for name, notes in {
        "tap": [(880, 0.065)],
        "deploy": [(392, 0.08), (587.33, 0.13)],
        "victory": [(523.25, 0.15), (659.25, 0.15), (783.99, 0.15), (1046.5, 0.45)],
        "defeat": [(392, 0.16), (349.23, 0.16), (261.63, 0.36)],
    }.items():
        samples = []
        for frequency, duration in notes:
            for i in range(int(duration * 22050)):
                t = i / 22050
                envelope = min(1, t / 0.008) * max(0, 1 - t / duration) ** 1.5
                value = (math.sin(math.tau * frequency * t) + 0.22 * math.sin(math.tau * frequency * 2 * t)) * envelope * 0.22
                samples.append(struct.pack("<h", int(value * 32767)))
        for destination in DESTINATIONS:
            with wave.open(str(destination / f"{name}.wav"), "wb") as sound:
                sound.setnchannels(1)
                sound.setsampwidth(2)
                sound.setframerate(22050)
                sound.writeframes(b"".join(samples))
    manifest = {}
    for name, image in outputs.items():
        paths = [destination / f"{name}.png" for destination in DESTINATIONS]
        hashes = [hashlib.sha256(path.read_bytes()).hexdigest() for path in paths]
        assert hashes[0] == hashes[1], f"Platform mismatch: {name}"
        assert image.getbbox(), f"Empty asset: {name}"
        manifest[name] = {"size": list(image.size), "sha256": hashes[0]}
    (ROOT / "assets.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Packaged and verified {len(outputs)} identical assets per platform.")


if __name__ == "__main__":
    main()
