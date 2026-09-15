"""Create a small contact sheet from actual full-size rendered PNGs."""

import argparse
import math
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path, help="out/<slug>, containing frame-*.png")
    parser.add_argument("--columns", type=int, default=4)
    args = parser.parse_args()
    images = sorted(args.directory.glob("frame-*.png"))
    if not images or args.columns < 1:
        parser.error("Need at least one frame-*.png and positive columns")
    columns = min(args.columns, len(images))
    rows = math.ceil(len(images) / columns)
    output = args.directory / "contact-sheet.png"
    subprocess.run([
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-pattern_type", "glob", "-i", str(args.directory / "frame-*.png"),
        "-vf", f"scale=480:270:force_original_aspect_ratio=decrease,"
        f"pad=480:270:(ow-iw)/2:(oh-ih)/2:color=0xf7f6f5,"
        f"tile={columns}x{rows}:nb_frames={len(images)}:padding=8:margin=8:color=0xf7f6f5",
        "-frames:v", "1", str(output),
    ], check=True)
    print(output)


if __name__ == "__main__":
    main()
