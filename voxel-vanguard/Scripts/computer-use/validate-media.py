#!/usr/bin/env python3
"""Validate real capture frames/samples and compose cursor-visible evidence.

Requires ffmpeg/ffprobe and NumPy. --reference-host is the measured host clock at
desktop PTS zero, inferred from the visible clock at multiple known PTS values.
No soundtrack is generated: original PCM is trimmed, gain-adjusted and encoded.
"""

import argparse
import json
import math
import subprocess
from pathlib import Path
import numpy as np

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--out", type=Path, required=True)
p.add_argument("--reference-host", type=float, required=True)
p.add_argument("--start", type=float, required=True)
p.add_argument("--duration", type=float, required=True)
p.add_argument("--compose", action="store_true")
p.add_argument(
    "--gain", type=float, default=4, help="Constant gain, not a replacement soundtrack"
)
a = p.parse_args()
r = a.out


def probe(path):
    return json.loads(
        subprocess.check_output(
            [
                "ffprobe",
                "-v",
                "error",
                "-show_streams",
                "-show_format",
                "-of",
                "json",
                str(path),
            ]
        )
    )


def decode(path):
    with (r / (path.name + ".decode.log")).open("w") as log:
        result = subprocess.run(
            [
                "ffmpeg",
                "-v",
                "error",
                "-threads",
                "2",
                "-i",
                str(path),
                "-f",
                "null",
                "-",
            ],
            stdout=subprocess.DEVNULL,
            stderr=log,
        )
    return {
        "exitCode": result.returncode,
        "errorLogBytes": (r / (path.name + ".decode.log")).stat().st_size,
    }


def pcm_stats(path):
    proc = subprocess.Popen(
        ["ffmpeg", "-v", "error", "-i", str(path), "-map", "0:a:0", "-f", "f32le", "-"],
        stdout=subprocess.PIPE,
    )
    count = clipped = nonzero = 0
    square_sum = peak = 0.0
    while True:
        raw = proc.stdout.read(262144)
        if not raw:
            break
        samples = np.frombuffer(raw, dtype="<f4").astype(np.float64)
        count += len(samples)
        square_sum += float(np.dot(samples, samples))
        peak = max(peak, float(np.max(np.abs(samples))))
        clipped += int(np.sum(np.abs(samples) >= 1))
        nonzero += int(np.count_nonzero(samples))
    if proc.wait():
        raise RuntimeError("PCM decoding failed")
    rms = math.sqrt(square_sum / count) if count else 0
    return {
        "samples": count,
        "decodedStereoFrames": count // 2,
        "peak": peak,
        "rms": rms,
        "rmsDBFS": 20 * math.log10(rms) if rms else None,
        "clippedSamples": clipped,
        "nonzeroSamples": nonzero,
    }


buffers = [
    json.loads(line) for line in (r / "audio-buffers.jsonl").read_text().splitlines()
]
raw = pcm_stats(r / "loopback.caf")
expected = sum(b["frames"] for b in buffers)
discontinuities = [
    i
    for i in range(1, len(buffers))
    if buffers[i]["offsetFrames"]
    != buffers[i - 1]["offsetFrames"] + buffers[i - 1]["frames"]
    or buffers[i]["sampleTime"]
    != buffers[i - 1]["sampleTime"] + buffers[i - 1]["frames"]
]
clock_errors = [
    (b["hostSeconds"] - buffers[0]["hostSeconds"]) - b["offsetFrames"] / b["sampleRate"]
    for b in buffers
]
raw.update(
    bufferFrames=expected,
    bufferCount=len(buffers),
    discontinuities=discontinuities,
    persistedFramesEqualBufferTotal=raw["decodedStereoFrames"] == expected,
    hostClockErrorRangeSeconds=[min(clock_errors), max(clock_errors)],
)
audio_start = a.reference_host + a.start - buffers[0]["hostSeconds"]
final = r / "voxel-vanguard-devin-computer-use-live-audio.mp4"
composition = {
    "videoSource": "reference.mkv, actual cursor-visible desktop capture",
    "audioSource": "loopback.caf, actual concurrent BlackHole input",
    "referenceFirstHost": a.reference_host,
    "referenceTrimStart": a.start,
    "audioTrimStart": audio_start,
    "duration": a.duration,
    "audioGain": a.gain,
    "timeCompression": False,
    "completeDisplaysRetained": True,
    "avAlignmentConservativeUncertaintySeconds": 0.2,
    "note": "Host-clock alignment avoids dependence on wall-clock adjustments; inspect multiple clock anchors",
}
if a.compose:
    if final.exists():
        raise SystemExit("Refusing to replace final video")
    cmd = [
        "ffmpeg",
        "-hide_banner",
        "-ss",
        str(a.start),
        "-i",
        str(r / "reference.mkv"),
        "-ss",
        str(audio_start),
        "-i",
        str(r / "loopback.caf"),
        "-t",
        str(a.duration),
        "-map",
        "0:v:0",
        "-map",
        "1:a:0",
        "-c:v",
        "libx264",
        "-threads",
        "4",
        "-preset",
        "veryfast",
        "-crf",
        "20",
        "-pix_fmt",
        "yuv420p",
        "-af",
        f"volume={a.gain}",
        "-c:a",
        "aac",
        "-b:a",
        "192k",
        "-movflags",
        "+faststart",
        str(final),
    ]
    composition["command"] = cmd
    with (r / "composition.log").open("w") as log:
        subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, check=True)
    (r / "composition.json").write_text(json.dumps(composition, indent=2))
result = {
    "rawAudio": raw,
    "captures": {},
    "composition": composition,
    "subjectiveListening": "untested",
    "limitations": [
        "Audio mixes both simulators, not separate stems",
        "Digital signal/decode verification is not human listening",
        "Capture cadence is not a physical-device performance measurement",
    ],
}
for name in ["aster.mov", "bramble.mov", "reference.mkv"]:
    path = r / name
    if not path.exists() and name.endswith(".mov"):
        continue
    info = probe(path)
    (r / (name + ".ffprobe.json")).write_text(json.dumps(info, indent=2))
    checks = decode(path)
    stream = info["streams"][0]
    checks.update(
        width=stream["width"],
        height=stream["height"],
        duration=info["format"]["duration"],
    )
    if name.endswith(".mov"):
        frame_data = json.loads(
            subprocess.check_output(
                [
                    "ffprobe",
                    "-v",
                    "error",
                    "-select_streams",
                    "v:0",
                    "-show_frames",
                    "-show_entries",
                    "frame=best_effort_timestamp_time",
                    "-of",
                    "json",
                    str(path),
                ]
            )
        )
        times = [float(f["best_effort_timestamp_time"]) for f in frame_data["frames"]]
        gaps = [y - x for x, y in zip(times, times[1:])]
        checks.update(
            frames=len(times),
            averageFPS=len(times) / float(info["format"]["duration"]),
            maxFrameGapSeconds=max(gaps),
            gapsOver250ms=sum(g > 0.25 for g in gaps),
        )
    result["captures"][name] = checks
if final.exists():
    info = probe(final)
    (r / "final-ffprobe.json").write_text(json.dumps(info, indent=2))
    result["final"] = {
        "decode": decode(final),
        "audio": pcm_stats(final),
        "streams": info["streams"],
        "format": info["format"],
    }
result["passed"] = (
    raw["persistedFramesEqualBufferTotal"]
    and not discontinuities
    and raw["nonzeroSamples"] > 0
    and raw["clippedSamples"] == 0
    and all(
        c["exitCode"] == 0 and c["errorLogBytes"] == 0
        for c in result["captures"].values()
    )
    and "final" in result
    and result["final"]["decode"]["exitCode"] == 0
    and result["final"]["decode"]["errorLogBytes"] == 0
    and result["final"]["audio"]["nonzeroSamples"] > 0
    and result["final"]["audio"]["clippedSamples"] == 0
)
(r / "video-audio-validation.json").write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
raise SystemExit(0 if result["passed"] else 1)
