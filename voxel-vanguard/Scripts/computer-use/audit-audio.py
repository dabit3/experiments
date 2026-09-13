#!/usr/bin/env python3
"""Read-only cue correlation in original PCM. Never synthesizes an output track.

Requests JSON: [{label, wall, pitch, expectCue, before?, duration?, threshold?}].
An absence check is meaningful only with independently verified quiet context.
"""

import argparse
import json
import subprocess
from pathlib import Path
import numpy as np

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--out", type=Path, required=True)
parser.add_argument("--requests", type=Path, required=True)
args = parser.parse_args()
buffers = [
    json.loads(line)
    for line in (args.out / "audio-buffers.jsonl").read_text().splitlines()
]
results = []
for request in json.loads(args.requests.read_text()):
    wall = request["wall"]
    anchor = min(buffers, key=lambda row: abs(row["callbackWall"] - wall))
    at = (
        anchor["offsetFrames"] / anchor["sampleRate"]
        + wall
        - anchor["callbackWall"]
        + anchor["frames"] / anchor["sampleRate"]
    )
    start = max(0, at - request.get("before", 0.15))
    duration = request.get("duration", 0.85)
    raw = subprocess.check_output(
        [
            "ffmpeg",
            "-v",
            "error",
            "-ss",
            str(start),
            "-i",
            str(args.out / "loopback.caf"),
            "-t",
            str(duration),
            "-ac",
            "1",
            "-ar",
            "48000",
            "-f",
            "f32le",
            "-",
        ]
    )
    window = np.frombuffer(raw, dtype="<f4").astype(np.float64)
    t = np.arange(5760) / 48000
    pitch = request["pitch"]
    template = np.sin(2 * np.pi * (pitch * t + pitch * t * t)) * (
        np.exp(-t / 0.12 * 5) * np.minimum(1, t * 800)
    )
    if len(window) < len(template):
        raise SystemExit("Requested cue window extends outside captured PCM")
    corr = np.abs(np.correlate(window, template, mode="valid"))
    cumulative = np.concatenate(([0.0], np.cumsum(window * window)))
    energy = cumulative[len(template) :] - cumulative[: -len(template)]
    score = corr / np.maximum(1e-20, np.sqrt(energy * np.dot(template, template)))
    index = int(np.argmax(score))
    peak = float(score[index])
    threshold = request.get("threshold", 0.7)
    found = peak >= threshold
    results.append(
        dict(
            request,
            correlation=peak,
            found=found,
            passed=found == request["expectCue"],
            sampleOffsetSeconds=start + index / 48000,
            estimatedDelaySeconds=start + index / 48000 - at,
        )
    )
result = {
    "method": "Normalized Soundscape chirp correlation in original captured PCM",
    "note": "Analysis template only; no generated audio is mixed into any capture",
    "limitations": "Mixed simulators; approximate callback-end wall alignment ±150 ms; no human listening",
    "passed": all(check["passed"] for check in results),
    "checks": results,
}
(args.out / "audio-cues.json").write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
raise SystemExit(0 if result["passed"] else 1)
