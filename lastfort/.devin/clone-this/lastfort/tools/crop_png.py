#!/usr/bin/env python3
"""Crop a PNG region (standard library only; reuses test/pixel_diff.py codecs).

Usage: python3 tools/crop_png.py IN.png OUT.png X,Y W,H

Used to produce same-sized reference/actual captures for the visual items in
state.json (the web viewport and the macOS window content area differ only by
the 28 px macOS title bar).
"""
import os
import sys

RUN_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RUN_DIR, "..", "..", "..", "test"))
from pixel_diff import parse_pair, read_png, write_png  # noqa: E402


def main() -> int:
    src, dst, origin, size = sys.argv[1:5]
    x, y = parse_pair(origin)
    w, h = parse_pair(size)
    width, height, rows = read_png(src)
    if x + w > width or y + h > height:
        raise SystemExit(f"crop {x},{y} {w}x{h} exceeds {width}x{height}")
    write_png(dst, w, h, [bytearray(r[x * 4 : (x + w) * 4]) for r in rows[y : y + h]])
    return 0


if __name__ == "__main__":
    sys.exit(main())
