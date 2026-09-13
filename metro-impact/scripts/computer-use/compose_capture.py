#!/usr/bin/env python3
"""Compose only the contemporaneous raw desktop and BlackHole recording."""

import argparse
import json
import pathlib
import re
import subprocess
import wave

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--run", type=pathlib.Path, required=True)
p.add_argument("--screen-dir", type=pathlib.Path, required=True)
a = p.parse_args()
video_start = float(
    re.search(r"start: ([\d.]+)", (a.screen_dir / "ffmpeg.log").read_text())[1]
)
audio_start = float(
    re.search(r"start: ([\d.]+)", (a.run / "audio-capture.log").read_text())[1]
)
offset = audio_start - video_start
assert offset >= 0, (
    "This capture started video first; investigate reversed source ordering"
)
sources = sorted(a.screen_dir.glob("*-raw-*.mkv"))
assert sources, "Missing actual raw desktop capture"
segments = []
for source in sources:
    data = json.loads(
        subprocess.check_output(
            [
                "ffprobe",
                "-v",
                "error",
                "-show_packets",
                "-show_entries",
                "packet=pts_time",
                "-of",
                "json",
                str(source),
            ]
        )
    )
    pts = [float(x["pts_time"]) for x in data["packets"]]
    cadence = sorted(b - a for a, b in zip(pts, pts[1:]))[len(pts) // 2]
    segments.append({"file": str(source.resolve()), "duration": pts[-1] + cadence})
concat = a.run / "screen.ffconcat"
concat.write_text(
    "ffconcat version 1.0\n"
    + "".join(f"file '{x['file']}'\nduration {x['duration']:.9f}\n" for x in segments)
)
with wave.open(str(a.run / "live-loopback.wav")) as w:
    duration = w.getnframes() / w.getframerate()
command = [
    "ffmpeg",
    "-y",
    "-hide_banner",
    "-f",
    "concat",
    "-safe",
    "0",
    "-i",
    str(concat),
    "-i",
    str(a.run / "live-loopback.wav"),
    "-map",
    "0:v:0",
    "-map",
    "1:a:0",
    "-vf",
    f"trim=start={offset},setpts=PTS-{offset}/TB",
    "-r",
    "30",
    "-fps_mode",
    "cfr",
    "-c:v",
    "libx264",
    "-crf",
    "20",
    "-preset",
    "veryfast",
    "-pix_fmt",
    "yuv420p",
    "-c:a",
    "aac",
    "-b:a",
    "192k",
    "-t",
    str(duration),
    "-shortest",
    "-movflags",
    "+faststart",
    str(a.run / "two-player-computer-use.mp4"),
]
(a.run / "av-alignment.json").write_text(
    json.dumps(
        {
            "video_source_start": video_start,
            "audio_source_start": audio_start,
            "video_prefix_trim": offset,
            "duration": duration,
            "segments": segments,
            "method": "AVFoundation common host-clock PTS. Decode all source frames, then trim/setpts to audio start; no demuxer seeking.",
            "no_midmatch_cuts": True,
            "no_replacement_audio": True,
            "command": command,
        },
        indent=2,
    )
)
with (a.run / "mux.log").open("w") as log:
    subprocess.run(command, stdout=log, stderr=log, check=True)
events = [
    json.loads(s) for s in (a.run / "screen-events.jsonl").read_text().splitlines()
]
captures = {}
for player, direction in [("alpha", "right"), ("beta", "left")]:
    row = next(
        r
        for r in events
        if r["kind"] == "native"
        and r["request"].get("player") == player
        and r["request"].get("control") == direction
        and r["request"].get("duration") == 1.0
    )
    captures[player + "-held-video"] = row["result"]["uptime"] - 0.5 - audio_start
for text, filename in [
    ("SOUND · both native clients muted", "sound-both-muted"),
    ("SOUND · Alpha only restored", "sound-alpha-only"),
]:
    row = next(
        r for r in events if r["kind"] == "native" and r["request"]["label"] == text
    )
    captures[filename] = row["result"]["uptime"] + 2 - audio_start
for filename, t in captures.items():
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-v",
            "error",
            "-ss",
            str(t),
            "-i",
            str(a.run / "two-player-computer-use.mp4"),
            "-frames:v",
            "1",
            str(a.run / (filename + ".png")),
        ],
        check=True,
    )
(a.run / "extracted-frame-times.json").write_text(json.dumps(captures, indent=2))
print(
    json.dumps(
        {
            "video": str(a.run / "two-player-computer-use.mp4"),
            "duration": duration,
            "offset": offset,
        },
        indent=2,
    )
)
