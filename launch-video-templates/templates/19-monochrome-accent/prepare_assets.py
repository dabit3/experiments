"""Create deterministic blue-selective crops without third-party Python modules."""

import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCES = HERE.parent.parent / "public" / "assets"
DEST = HERE / "assets"
BLUE_MIN_HUE = 194
BLUE_MAX_HUE = 224


def prepare(name, source, crop):
    x, y, width, height = crop
    info = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_entries", "stream=width,height",
        "-of", "json", str(SOURCES / source),
    ]))["streams"][0]
    assert 0 <= x <= info["width"] - width
    assert 0 <= y <= info["height"] - height
    rgb = subprocess.check_output([
        "ffmpeg", "-v", "error", "-i", str(SOURCES / source),
        "-vf", f"crop={width}:{height}:{x}:{y}",
        "-f", "rawvideo", "-pix_fmt", "rgb24", "pipe:1",
    ])
    treated = bytearray(rgb)
    preserved = 0
    desaturated = 0
    for i in range(0, len(rgb), 3):
        r, g, b = rgb[i:i + 3]
        low, high = min(r, g, b), max(r, g, b)
        delta = high - low
        hue = 240 - 60 * (g - r) / delta if delta and b == high else -1
        if delta > 8 and BLUE_MIN_HUE <= hue <= BLUE_MAX_HUE:
            preserved += 1
        else:
            gray = round(0.2126 * r + 0.7152 * g + 0.0722 * b)
            treated[i:i + 3] = bytes((gray, gray, gray))
            if delta > 8:
                desaturated += 1
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-f", "rawvideo",
        "-pix_fmt", "rgb24", "-s", f"{width}x{height}", "-i", "pipe:0",
        "-frames:v", "1", str(DEST / name),
    ], input=treated, check=True)
    return {
        "file": name, "source": source, "crop": crop,
        "pixels_retained_at_original_rgb": preserved,
        "colored_pixels_desaturated": desaturated,
        "retained_hue_degrees": [BLUE_MIN_HUE, BLUE_MAX_HUE],
    }


def main():
    DEST.mkdir(exist_ok=True)
    crops = [
        ("phone-maze.png", "devin-web-14.png", (700, 250, 550, 1100)),
        ("phone-wisp.png", "devin-web-10.png", (684, 236, 576, 1184)),
        ("phone-charts.png", "devin-web-18.png", (680, 236, 580, 1186)),
        ("native-review.png", "devin-web-18.png", (0, 0, 2978, 1626)),
        ("wisp-review.png", "devin-web-10.png", (1948, 140, 1042, 1484)),
        ("mac-session.png", "devin-web-13.png", (585, 660, 1980, 590)),
    ]
    results = [prepare(*crop) for crop in crops]
    (DEST / "provenance.json").write_text(json.dumps(results, indent=2) + "\n")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
