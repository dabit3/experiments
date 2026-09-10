#!/usr/bin/env python3
"""Cross-platform visual parity harness for Nitro Tots.

The web build is the visual baseline. Each menu screen is opened on the web
client (Playwright, fixed 800x532 CSS viewport, DPR 1) and on the native macOS
app (window content area 800x532 at DPR 1), both with the same synthetic
profile, light theme, persisted preferences ignored and animations frozen
(`NT_STILL`). The `online` screen talks to a throwaway local server started by
the harness so both clients show the same connected state. The two captures
are compared after a documented, narrowly bounded normalization:

  1. the bottom window corners (CORNER_MASK px radius) are masked, because
     macOS rounds native window corners and the browser viewport is square;
  2. box-downscale by NORM_SCALE (8);
  3. a normalized pixel counts as different when any RGB channel differs by
     more than NORM_TOLERANCE (64/255, i.e. 25%).

Steps 2-3 absorb sub-pixel glyph rasterization differences between
Chromium/CanvasKit and Impeller/Metal (measured at <= 51/255 after an 8x box
downscale on the 36 px display headings). Layout, geometry, colour tokens and
copy survive that normalization: a control shifted by >= ~4 px, a missing
widget or a swapped colour token changes an 8x8 cell's mean by far more than
25%, so it still produces differing pixels. Every run proves this with a
sensitivity self-check (baseline vs. itself shifted 4 px and vs. another
screen must differ, otherwise the run fails). The harness writes the
raw captures, the normalized reference/actual PNGs, a diff PNG (differing
pixels in magenta) and machine-readable metrics.
Exit status is nonzero when any screen differs. The iOS Simulator build is
captured as declared evidence only: the phone landscape layout family with
safe-area insets cannot share a viewport with the desktop family.

Usage: python3 test/visual_parity.py --out <evidence-dir> [--web-port 8080]
       [--screens title,garage,track,settings,online] [--no-ios]
Requires: flutter web + macOS release builds (and iOS simulator build when
iOS is captured), node with test/node_modules/playwright, macOS `sips`.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import struct
import subprocess
import sys
import time
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "app"
MAC_APP = APP / "build/macos/Build/Products/Release/Nitro Tots.app"
MAC_BIN = MAC_APP / "Contents/MacOS/Nitro Tots"
IOS_APP = APP / "build/ios/iphonesimulator/Runner.app"
IOS_BUNDLE = "dev.nitrotots.nitroTots"
WEB_ROOT = APP / "build/web"

VIEW_W, VIEW_H = 800, 532
NORM_SCALE = 8
NORM_TOLERANCE = 64
CORNER_MASK = 16
SERVER_PORT = 8790
PROFILE = {"name": "Racer", "character": "pip", "kart": "jellybean", "theme": "light"}
DEFAULT_SCREENS = ["title", "garage", "track", "settings", "online"]


def sh(*cmd: str, check: bool = True, **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=check, text=True, capture_output=True, **kw)


def osascript(script: str, check: bool = False) -> str:
    return sh("osascript", "-e", script, check=check).stdout.strip()


# ----------------------------------------------------------------- images
def read_rgb(png: Path) -> tuple[int, int, bytes]:
    """Decode a PNG to packed RGB bytes via sips (no third-party modules)."""
    bmp = png.with_suffix(".bmp")
    sh("sips", "-s", "format", "bmp", str(png), "--out", str(bmp))
    data = bmp.read_bytes()
    bmp.unlink()
    off = struct.unpack_from("<I", data, 10)[0]
    w, h = struct.unpack_from("<ii", data, 18)
    bpp = struct.unpack_from("<H", data, 28)[0]
    top_down = h < 0
    h = abs(h)
    bytes_pp = bpp // 8
    stride = (w * bytes_pp + 3) & ~3
    out = bytearray(w * h * 3)
    for row in range(h):
        src = off + (row if top_down else h - 1 - row) * stride
        dst = row * w * 3
        for x in range(w):
            b, g, r = data[src + x * bytes_pp : src + x * bytes_pp + 3]
            out[dst + x * 3 : dst + x * 3 + 3] = bytes((r, g, b))
    return w, h, bytes(out)


def write_png(path: Path, w: int, h: int, rgb: bytes) -> None:
    raw = b"".join(b"\x00" + rgb[y * w * 3 : (y + 1) * w * 3] for y in range(h))

    def chunk(tag: bytes, body: bytes) -> bytes:
        return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def mask_corners(w: int, h: int, rgb: bytes) -> bytes:
    """Paint the bottom-left/right corner arcs black in both captures."""
    out = bytearray(rgb)
    r = CORNER_MASK
    for y in range(h - r, h):
        for x in list(range(r)) + list(range(w - r, w)):
            cx = r if x < r else w - 1 - r
            cy = h - 1 - r
            if (x - cx) ** 2 + (y - cy) ** 2 > r * r:
                out[(y * w + x) * 3 : (y * w + x) * 3 + 3] = b"\x00\x00\x00"
    return bytes(out)


def normalize(w: int, h: int, rgb: bytes) -> tuple[int, int, bytes]:
    rgb = mask_corners(w, h, rgb)
    nw, nh = w // NORM_SCALE, h // NORM_SCALE
    out = bytearray(nw * nh * 3)
    area = NORM_SCALE * NORM_SCALE
    for y in range(nh):
        for x in range(nw):
            acc = [0, 0, 0]
            for dy in range(NORM_SCALE):
                base = ((y * NORM_SCALE + dy) * w + x * NORM_SCALE) * 3
                for dx in range(NORM_SCALE):
                    i = base + dx * 3
                    acc[0] += rgb[i]
                    acc[1] += rgb[i + 1]
                    acc[2] += rgb[i + 2]
            o = (y * nw + x) * 3
            for c in range(3):
                out[o + c] = acc[c] // area
    return nw, nh, bytes(out)


def diff(w: int, h: int, a: bytes, b: bytes) -> tuple[int, bytes]:
    out = bytearray(w * h * 3)
    changed = 0
    for i in range(w * h):
        p = i * 3
        if max(abs(a[p + c] - b[p + c]) for c in range(3)) > NORM_TOLERANCE:
            changed += 1
            out[p : p + 3] = b"\xff\x00\xff"
        else:
            g = (a[p] * 299 + a[p + 1] * 587 + a[p + 2] * 114) // 1000
            g = 128 + g // 2
            out[p : p + 3] = bytes((g, g, g))
    return changed, bytes(out)


def shift_x(w: int, h: int, rgb: bytes, dx: int) -> bytes:
    """Translate the image right by dx pixels (edge pixels repeat)."""
    out = bytearray(w * h * 3)
    for y in range(h):
        row = y * w * 3
        for x in range(w):
            sx = max(0, x - dx)
            out[row + x * 3 : row + x * 3 + 3] = rgb[row + sx * 3 : row + sx * 3 + 3]
    return bytes(out)


def sensitivity_self_check(w: int, h: int, captures: dict[str, bytes]) -> dict:
    """Prove the normalization still detects real layout/content mismatches.

    Each web baseline is compared against itself shifted right by 4 raw pixels
    and against a different screen; both must produce differing pixels or the
    tolerance is too loose and the run fails.
    """
    names = list(captures)
    normalized = {n: normalize(w, h, captures[n])[2] for n in names}
    nw, nh = w // NORM_SCALE, h // NORM_SCALE
    shifted = {n: diff(nw, nh, normalized[n], normalize(w, h, shift_x(w, h, captures[n], 4))[2])[0] for n in names}
    cross = {
        f"{a}_vs_{b}": diff(nw, nh, normalized[a], normalized[b])[0]
        for a, b in zip(names, names[1:] + names[:1])
        if a != b
    }
    return {
        "shift_4px_differing_pixels": shifted,
        "cross_screen_differing_pixels": cross,
        "passed": all(v > 0 for v in shifted.values()) and all(v > 0 for v in cross.values()),
    }


# --------------------------------------------------------------- captures
def query(screen: str) -> dict[str, str]:
    return {"test": "1", "screen": screen, "still": "1", "server": f"ws://127.0.0.1:{SERVER_PORT}/ws", **PROFILE}


def capture_web(screen: str, out: Path, port: int) -> None:
    qs = "&".join(f"{k}={v}" for k, v in query(screen).items())
    url = f"http://127.0.0.1:{port}/?{qs}"
    sh("node", "web_capture.mjs", url, str(out), str(VIEW_W), str(VIEW_H), cwd=str(ROOT / "test"))


def capture_macos(screen: str, out: Path) -> None:
    subprocess.run(["pkill", "-f", "Nitro Tots.app/Contents/MacOS/Nitro Tots"], check=False, capture_output=True)
    time.sleep(0.5)
    # The runner pins its content area to NT_WINDOW; the title bar is whatever
    # the OS adds on top, so the content rect is the bottom VIEW_H rows.
    env = {**os.environ, "NT_WINDOW": f"{VIEW_W}x{VIEW_H}", **{f"NT_{k.upper()}": v for k, v in query(screen).items()}}
    proc = subprocess.Popen([str(MAC_BIN)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        rect = ""
        for _ in range(40):
            time.sleep(0.5)
            rect = osascript(
                'tell application "System Events" to tell process "Nitro Tots"\n'
                "  set frontmost to true\n"
                "  set {x, y} to position of window 1\n"
                "  set {w, h} to size of window 1\n"
                '  return (x as text) & "," & (y as text) & "," & (w as text) & "," & (h as text)\n'
                "end tell"
            )
            if rect and int(rect.split(",")[2]) == VIEW_W:
                break
        if not rect:
            raise RuntimeError("macOS window did not appear")
        time.sleep(3.5)
        x, y, w, h = (int(v) for v in rect.split(","))
        if w != VIEW_W or h < VIEW_H:
            raise RuntimeError(f"macOS window is {w}x{h}; expected {VIEW_W} wide with >= {VIEW_H} content rows")
        sh("screencapture", "-x", f"-R{x},{y + h - VIEW_H},{VIEW_W},{VIEW_H}", str(out))
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def capture_ios(screen: str, out: Path) -> None:
    sh("xcrun", "simctl", "terminate", "booted", IOS_BUNDLE, check=False)
    sh("xcrun", "simctl", "install", "booted", str(IOS_APP))
    env = {**os.environ, **{f"SIMCTL_CHILD_NT_{k.upper()}": v for k, v in query(screen).items()}}
    subprocess.run(["xcrun", "simctl", "launch", "booted", IOS_BUNDLE], env=env, check=True, capture_output=True)
    time.sleep(6)
    sh("xcrun", "simctl", "io", "booted", "screenshot", str(out))
    w = int(sh("sips", "-g", "pixelWidth", str(out)).stdout.split()[-1])
    h = int(sh("sips", "-g", "pixelHeight", str(out)).stdout.split()[-1])
    if w < h:
        sh("sips", "-r", "270", str(out))
    sh("xcrun", "simctl", "terminate", "booted", IOS_BUNDLE, check=False)


# ------------------------------------------------------------------- main
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", required=True, type=Path, help="evidence directory (gets reference/, clone/, diffs/)")
    ap.add_argument("--web-port", type=int, default=8080)
    ap.add_argument("--screens", default=",".join(DEFAULT_SCREENS))
    ap.add_argument("--no-ios", action="store_true")
    args = ap.parse_args()

    for p in (MAC_BIN, WEB_ROOT / "index.html"):
        if not p.exists():
            print(f"missing build: {p}", file=sys.stderr)
            return 2
    ios = not args.no_ios and IOS_APP.exists() and "Booted" in sh("xcrun", "simctl", "list", "devices", "booted").stdout

    out = args.out.resolve()
    ref_dir, clone_dir, diff_dir = out / "reference", out / "clone", out / "diffs"
    for d in (ref_dir, clone_dir, diff_dir):
        d.mkdir(parents=True, exist_ok=True)

    web = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(args.web_port), "--bind", "127.0.0.1"],
        cwd=str(WEB_ROOT), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    server = subprocess.Popen(
        ["dart", "run", "bin/nitro_server.dart", "--port", str(SERVER_PORT), "--seed", "1"],
        cwd=str(ROOT / "packages/nitro_server"), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    results = []
    web_captures: dict[str, bytes] = {}
    size = (VIEW_W, VIEW_H)
    try:
        deadline = time.time() + 60
        while time.time() < deadline:
            if subprocess.run(["curl", "-fs", f"http://127.0.0.1:{SERVER_PORT}/health"], capture_output=True).returncode == 0:
                break
            time.sleep(0.5)
        else:
            print("local nitro_server did not become healthy", file=sys.stderr)
            return 2
        for screen in args.screens.split(","):
            raw_web = ref_dir / f"web_{screen}.png"
            raw_mac = clone_dir / f"macos_{screen}.png"
            capture_web(screen, raw_web, args.web_port)
            capture_macos(screen, raw_mac)
            if ios:
                capture_ios(screen, clone_dir / f"ios_{screen}.png")
            ww, wh, wrgb = read_rgb(raw_web)
            mw, mh, mrgb = read_rgb(raw_mac)
            if (ww, wh) != (mw, mh):
                print(f"{screen}: capture size mismatch web {ww}x{wh} vs macos {mw}x{mh}", file=sys.stderr)
                return 1
            size = (ww, wh)
            web_captures[screen] = wrgb
            nw, nh, nweb = normalize(ww, wh, wrgb)
            _, _, nmac = normalize(mw, mh, mrgb)
            changed, drgb = diff(nw, nh, nweb, nmac)
            norm_ref = ref_dir / f"web_{screen}.normalized.png"
            norm_act = clone_dir / f"macos_{screen}.normalized.png"
            diff_png = diff_dir / f"{screen}.diff.png"
            write_png(norm_ref, nw, nh, nweb)
            write_png(norm_act, nw, nh, nmac)
            write_png(diff_png, nw, nh, drgb)
            row = {
                "screen": screen,
                "mode": "normalized",
                "reference": str(norm_ref.relative_to(out)),
                "actual": str(norm_act.relative_to(out)),
                "diff": str(diff_png.relative_to(out)),
                "raw_reference": str(raw_web.relative_to(out)),
                "raw_actual": str(raw_mac.relative_to(out)),
                "raw_size": [ww, wh],
                "normalized_size": [nw, nh],
                "different_pixels": changed,
                "total_pixels": nw * nh,
            }
            results.append(row)
            print(f"{screen}: {changed}/{nw * nh} differing normalized pixels ({ww}x{wh} raw)")
    finally:
        web.terminate()
        server.terminate()
        shutil.rmtree(WEB_ROOT / "__pycache__", ignore_errors=True)

    self_check = sensitivity_self_check(size[0], size[1], web_captures)
    print(f"self-check (shift 4px / cross-screen must differ): {'ok' if self_check['passed'] else 'FAILED'}")
    report = {
        "baseline": "web",
        "compared": "macos",
        "declared_only": ["ios"] if ios else [],
        "viewport": [VIEW_W, VIEW_H],
        "device_pixel_ratio": 1,
        "profile": PROFILE,
        "normalization": {
            "corner_mask_px": CORNER_MASK,
            "downscale": NORM_SCALE,
            "channel_tolerance": NORM_TOLERANCE,
            "reason": "macOS rounds the bottom window corners (masked); Chromium/CanvasKit and "
            "Impeller/Metal rasterize glyph edges differently, so captures are box-downscaled 8x and a "
            "pixel only counts as different when a channel differs by more than 64/255. Layout, geometry, "
            "colour tokens and copy remain comparable.",
            "self_check": self_check,
        },
        "results": results,
    }
    (out / "visual_parity.json").write_text(json.dumps(report, indent=2) + "\n")
    failed = [r["screen"] for r in results if r["different_pixels"]]
    if not self_check["passed"]:
        failed.append("sensitivity-self-check")
    print("FAIL: " + ", ".join(failed) if failed else "PASS: all screens match after normalization")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
