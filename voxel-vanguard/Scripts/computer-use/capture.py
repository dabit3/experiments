#!/usr/bin/env python3
"""Simultaneous native device videos, cursor-visible desktop, and actual PCM.
Requires compiled audio-capture beside this file. Never generates game inputs.
Stop by creating OUT/STOP; apps intentionally remain alive for inspection.
"""

import argparse
import ctypes
import json
import signal
import subprocess
import time
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("--out", type=Path, required=True)
p.add_argument("--screen-device", default="0", help="FFmpeg avfoundation display index")
p.add_argument(
    "--native", action="store_true", help="Also retain separate native framebuffers"
)
a = p.parse_args()
r = a.out
cfg = json.loads((r / "gui-config.json").read_text())
if any(
    (r / f).exists() for f in ["capture.json", "STOP", "AUDIO_STOP", "loopback.caf"]
):
    raise SystemExit("Capture output already exists: use a fresh directory")
lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib")


class Timebase(ctypes.Structure):
    _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]


tb = Timebase()
lib.mach_timebase_info(ctypes.byref(tb))
lib.mach_absolute_time.restype = ctypes.c_uint64


def clock():
    return {
        "wall": time.time(),
        "host": lib.mach_absolute_time() * tb.numer / tb.denom / 1e9,
    }


m = {
    "starts": {},
    "devices": {k: v["udid"] for k, v in cfg["players"].items()},
    "initialClock": clock(),
}
procs = {}
streams = {}


def start(name, cmd):
    m["starts"][name] = clock()
    streams[name] = open(r / (name + "-capture.log"), "w")
    procs[name] = subprocess.Popen(
        cmd, stdin=subprocess.PIPE, stdout=streams[name], stderr=subprocess.STDOUT
    )
    m.setdefault("commands", {})[name] = cmd


start("audio", [str(Path(__file__).with_name("audio-capture")), str(r), "900"])
start(
    "reference",
    [
        "ffmpeg",
        "-hide_banner",
        "-f",
        "avfoundation",
        "-capture_cursor",
        "1",
        "-framerate",
        "30",
        "-pixel_format",
        "uyvy422",
        "-i",
        a.screen_device + ":none",
        "-c:v",
        "libx264",
        "-preset",
        "ultrafast",
        "-crf",
        "20",
        "-r",
        "30",
        "-pix_fmt",
        "yuv420p",
        str(r / "reference.mkv"),
    ],
)
try:
    deadline = time.monotonic() + 20
    while not (
        (r / "reference.mkv").exists() and (r / "reference.mkv").stat().st_size > 0
    ):
        if procs["reference"].poll() is not None:
            raise RuntimeError("Reference exited")
        if time.monotonic() > deadline:
            raise RuntimeError("Reference initialization timeout")
        time.sleep(0.1)
    if a.native:
        for name, d in m["devices"].items():
            start(
                name,
                [
                    "xcrun",
                    "simctl",
                    "io",
                    d,
                    "recordVideo",
                    "--codec=h264",
                    "--mask=black",
                    str(r / (name + ".mov")),
                ],
            )
    m["pids"] = {n: q.pid for n, q in procs.items()}
    (r / "capture.json").write_text(json.dumps(m, indent=2))
    print(json.dumps(m), flush=True)
    while not (r / "STOP").exists():
        if any(q.poll() is not None for q in procs.values()):
            raise RuntimeError("Capture process exited early")
        time.sleep(0.1)
finally:
    m["stopRequested"] = clock()
    for n in ["aster", "bramble"]:
        if n in procs and procs[n].poll() is None:
            procs[n].send_signal(signal.SIGINT)
    for n in ["aster", "bramble"]:
        if n in procs:
            procs[n].wait(timeout=30)
    (r / "AUDIO_STOP").touch()
    if "audio" in procs:
        procs["audio"].wait(timeout=15)
    ref = procs.get("reference")
    if ref and ref.poll() is None:
        ref.stdin.write(b"q\n")
        ref.stdin.flush()
        ref.wait(timeout=30)
    m["exitCodes"] = {n: q.returncode for n, q in procs.items()}
    m["finished"] = clock()
    (r / "capture.json").write_text(json.dumps(m, indent=2))
    print(json.dumps(m), flush=True)
