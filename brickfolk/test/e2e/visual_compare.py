#!/usr/bin/env python3
"""Normalized visual comparison between two client captures.

The web build is the visual baseline for the native clients. Both captures are
decoded with ffmpeg, optionally cropped (macOS window captures include the title
bar), box-downscaled by an integer factor so sub-pixel font anti-aliasing
differences between Skia/CanvasKit (web) and Impeller (native) cancel out, and
then compared per channel. Glyph advances differ by a pixel or two between the
two text stacks, so a reference pixel also counts as matched when a pixel
within `--shift` normalized cells of the actual capture matches it. A cell
whose best per-channel delta exceeds `--tolerance` is a differing pixel and
the comparison fails on the first one. The two rasterizers still disagree on
isolated anti-aliased glyph edges by less than that, so cells between
`--edge-tolerance` and `--tolerance` are reported as edge cells and bounded
separately: at most `--max-edge-cells` of them and no 8-connected run larger
than `--max-cluster` (a moved or recoloured element shows up as a cluster even
when every cell stays under the tolerance). Any masked region and every
threshold is listed explicitly in the metrics so the normalization stays
narrow and inspectable.

Outputs: normalized reference PNG, normalized actual PNG, a diff PNG (differing
cells in red and edge cells in orange over a dimmed reference) and a JSON
metrics file.
"""
from __future__ import annotations

import argparse
import json
import struct
import subprocess
import sys
import zlib
from pathlib import Path


def probe(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"{path} is not a PNG")
    width, height = struct.unpack(">II", data[16:24])
    return width, height


def decode_rgb(path: Path) -> tuple[int, int, bytes]:
    width, height = probe(path)
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        check=True,
        stdout=subprocess.PIPE,
    ).stdout
    if len(raw) != width * height * 3:
        raise SystemExit(f"unexpected raw size for {path}")
    return width, height, raw


def crop(width: int, height: int, raw: bytes, top: int, left: int, w: int, h: int) -> tuple[int, int, bytes]:
    rows = []
    for y in range(top, top + h):
        start = (y * width + left) * 3
        rows.append(raw[start : start + w * 3])
    return w, h, b"".join(rows)


def downscale(width: int, height: int, raw: bytes, factor: int) -> tuple[int, int, bytes]:
    ow, oh = width // factor, height // factor
    out = bytearray(ow * oh * 3)
    area = factor * factor
    for oy in range(oh):
        for ox in range(ow):
            r = g = b = 0
            for dy in range(factor):
                base = ((oy * factor + dy) * width + ox * factor) * 3
                for dx in range(factor):
                    i = base + dx * 3
                    r += raw[i]
                    g += raw[i + 1]
                    b += raw[i + 2]
            o = (oy * ow + ox) * 3
            out[o] = r // area
            out[o + 1] = g // area
            out[o + 2] = b // area
    return ow, oh, bytes(out)


def encode_png(width: int, height: int, raw: bytes) -> bytes:
    def chunk(kind: bytes, body: bytes) -> bytes:
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    stride = width * 3
    scanlines = b"".join(b"\x00" + raw[y * stride : (y + 1) * stride] for y in range(height))
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(scanlines, 9))
        + chunk(b"IEND", b"")
    )


def parse_rect(text: str) -> tuple[int, int, int, int]:
    x, y, w, h = (int(v) for v in text.split(","))
    return x, y, w, h


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--id", required=True, help="stable visual case id")
    ap.add_argument("--reference", required=True, type=Path)
    ap.add_argument("--actual", required=True, type=Path)
    ap.add_argument("--out-dir", required=True, type=Path)
    ap.add_argument("--reference-crop", type=parse_rect, help="x,y,w,h crop applied to the reference before scaling")
    ap.add_argument("--actual-crop", type=parse_rect, help="x,y,w,h crop applied to the actual capture before scaling")
    ap.add_argument("--scale", type=int, default=4, help="integer box-downscale factor")
    ap.add_argument("--tolerance", type=int, default=48, help="max per-channel difference (0-255) after downscale; any cell beyond it is a differing pixel")
    ap.add_argument("--shift", type=int, default=0, help="neighbourhood radius (normalized pixels) searched for a matching actual pixel")
    ap.add_argument("--edge-tolerance", type=int, default=None, help="cells above this (and within --tolerance) are counted as anti-aliasing edge cells (default: --tolerance, i.e. none)")
    ap.add_argument("--max-edge-cells", type=int, default=0, help="edge cells tolerated")
    ap.add_argument("--max-cluster", type=int, default=0, help="largest 8-connected run of edge or differing cells tolerated (0 = unlimited)")
    ap.add_argument("--mask", type=parse_rect, action="append", default=[], help="x,y,w,h region (in normalized pixels) excluded from the count")
    ap.add_argument("--note", default="", help="human-readable reason for every mask")
    args = ap.parse_args()
    edge_tolerance = args.tolerance if args.edge_tolerance is None else args.edge_tolerance
    if edge_tolerance > args.tolerance:
        raise SystemExit("--edge-tolerance must not exceed --tolerance")

    rw, rh, rraw = decode_rgb(args.reference)
    aw, ah, araw = decode_rgb(args.actual)
    if args.reference_crop:
        x, y, w, h = args.reference_crop
        rw, rh, rraw = crop(rw, rh, rraw, y, x, w, h)
    if args.actual_crop:
        x, y, w, h = args.actual_crop
        aw, ah, araw = crop(aw, ah, araw, y, x, w, h)
    if (rw, rh) != (aw, ah):
        raise SystemExit(f"dimension mismatch after crop: reference {rw}x{rh} vs actual {aw}x{ah}")

    nw, nh, nref = downscale(rw, rh, rraw, args.scale)
    _, _, nact = downscale(aw, ah, araw, args.scale)

    masked = bytearray(nw * nh)
    for mx, my, mw, mh in args.mask:
        for y in range(my, min(my + mh, nh)):
            for x in range(mx, min(mx + mw, nw)):
                masked[y * nw + x] = 1

    def delta(i: int, j: int) -> int:
        o, p = i * 3, j * 3
        return max(abs(nref[o] - nact[p]), abs(nref[o + 1] - nact[p + 1]), abs(nref[o + 2] - nact[p + 2]))

    def nearest_delta(i: int) -> int:
        best = delta(i, i)
        if best <= edge_tolerance or args.shift == 0:
            return best
        x, y = i % nw, i // nw
        for ny in range(max(0, y - args.shift), min(nh, y + args.shift + 1)):
            for nx in range(max(0, x - args.shift), min(nw, x + args.shift + 1)):
                best = min(best, delta(i, ny * nw + nx))
                if best <= edge_tolerance:
                    return best
        return best

    diff = bytearray(nw * nh * 3)
    different = 0
    edge_cells = 0
    masked_pixels = 0
    max_delta = 0
    differing = set()
    for i in range(nw * nh):
        o = i * 3
        if masked[i]:
            masked_pixels += 1
            diff[o] = diff[o + 1] = 0
            diff[o + 2] = 160
            continue
        d = nearest_delta(i)
        max_delta = max(max_delta, d)
        if d > args.tolerance:
            different += 1
            differing.add(i)
            diff[o], diff[o + 1], diff[o + 2] = 255, 0, 0
        elif d > edge_tolerance:
            edge_cells += 1
            differing.add(i)
            diff[o], diff[o + 1], diff[o + 2] = 255, 160, 0
        else:
            grey = (nref[o] * 30 + nref[o + 1] * 59 + nref[o + 2] * 11) // 100
            grey = 64 + grey * 3 // 4
            diff[o] = diff[o + 1] = diff[o + 2] = grey

    largest_cluster = 0
    unvisited = set(differing)
    while unvisited:
        stack = [unvisited.pop()]
        size = 0
        while stack:
            i = stack.pop()
            size += 1
            x, y = i % nw, i // nw
            for ny in range(max(0, y - 1), min(nh, y + 2)):
                for nx in range(max(0, x - 1), min(nw, x + 2)):
                    j = ny * nw + nx
                    if j in unvisited:
                        unvisited.remove(j)
                        stack.append(j)
        largest_cluster = max(largest_cluster, size)

    passed = (
        different == 0
        and edge_cells <= args.max_edge_cells
        and (args.max_cluster == 0 or largest_cluster <= args.max_cluster)
    )

    args.out_dir.mkdir(parents=True, exist_ok=True)
    ref_out = args.out_dir / f"{args.id}-reference.png"
    act_out = args.out_dir / f"{args.id}-actual.png"
    diff_out = args.out_dir / f"{args.id}-diff.png"
    ref_out.write_bytes(encode_png(nw, nh, nref))
    act_out.write_bytes(encode_png(nw, nh, nact))
    diff_out.write_bytes(encode_png(nw, nh, bytes(diff)))
    metrics = {
        "id": args.id,
        "mode": "normalized",
        "reference_source": str(args.reference),
        "actual_source": str(args.actual),
        "reference_crop": args.reference_crop,
        "actual_crop": args.actual_crop,
        "scale": args.scale,
        "tolerance": args.tolerance,
        "shift": args.shift,
        "edge_tolerance": edge_tolerance,
        "max_edge_cells_allowed": args.max_edge_cells,
        "max_cluster_allowed": args.max_cluster,
        "masks": args.mask,
        "mask_note": args.note,
        "normalized_size": [nw, nh],
        "total_pixels": nw * nh,
        "masked_pixels": masked_pixels,
        "different_pixels": different,
        "edge_cells": edge_cells,
        "max_unmasked_delta": max_delta,
        "largest_cluster": largest_cluster,
        "passed": passed,
        "reference": ref_out.name,
        "actual": act_out.name,
        "diff": diff_out.name,
    }
    (args.out_dir / f"{args.id}-metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")
    print(json.dumps(metrics))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
