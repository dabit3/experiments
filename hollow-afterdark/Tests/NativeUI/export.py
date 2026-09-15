"""Compose full displays and factual timestamped native-action captions."""

import json
import os
import pathlib
import subprocess

P = pathlib.Path(os.environ["EVIDENCE"]).resolve()
HERE = pathlib.Path(__file__).parent


def save(n, x):
    (P / n).write_text(json.dumps(x, indent=2))


timing = json.loads((P / "timing.json").read_text())
origin = timing["video_first_host_seconds"]
duration = timing["video_duration_seconds"]
events = sorted(
    [json.loads(x) for x in (P / "capture-events.jsonl").read_text().splitlines()],
    key=lambda x: x["host"],
)
changes = [
    (0, "Fresh native lobbies | real WebSocket room | both autonomous drivers OFF")
]
phase = "LOBBY"
for e in events:
    t = max(0, e["host"] - origin)
    if t >= duration:
        continue
    kind = e["event"]
    caption = None
    if kind == "phase":
        m, r, p = e["phase"]
        phase = f"MATCH {m} / ROUND {r} / {p.upper()}"
        caption = phase + (" - genuine shared result" if p == "result" else "")
    elif kind == "ui_action_completed":
        label = {
            "heavy": "B / HEAVY",
            "light": "A / LIGHT",
            "special": "C / RIFT",
            "shield": "D / SHIELD",
            "guard": "G / GUARD",
            "shift": "S / SHIFT",
            "rematch": "native REMATCH consent",
        }.get(e["control"], e["control"].upper())
        caption = f"{phase} | Scripted native touch: {e['player']} - {label}"
    elif kind == "paused":
        caption = "Harness checkpoint pause/resume | original live recording continues"
    elif kind == "audio_music_only_on":
        caption = "AUDIO AUDIT | Ren ON / Aya OFF - isolated original soundtrack"
    elif kind == "audio_both_off":
        caption = "AUDIO AUDIT | Both native apps OFF - checking raw received silence"
    elif kind == "audio_restored_on":
        caption = "AUDIO AUDIT | Ren ON restored / Aya OFF - original music returns"
    if caption:
        changes.append((t, caption))
captions = [
    [a, changes[i + 1][0] if i + 1 < len(changes) else duration, text]
    for i, (a, text) in enumerate(changes)
]
captions = [c for c in captions if c[1] > c[0]]
save("captions.json", captions)
subprocess.run(["swift", str(HERE / "banners.swift"), str(P)], check=True)
with (P / "banners.concat").open("w") as out:
    for i, (a, b, _) in enumerate(captions):
        out.write(f"file 'banner-{i:02d}.png'\nduration {b - a:.6f}\n")
    out.write(f"file 'banner-{len(captions) - 1:02d}.png'\n")
master = [
    "ffmpeg",
    "-v",
    "warning",
    "-y",
    "-i",
    str(P / "raw-video.mkv"),
    "-i",
    str(P / "live-audio-aligned.wav"),
    "-map",
    "0:v",
    "-map",
    "1:a",
    "-c",
    "copy",
    str(P / "synchronized-master.mkv"),
]
with (P / "mux.log").open("w") as log:
    subprocess.run(master, stdout=log, stderr=log, check=True)
layout = "[0:v]split=2[t][b];[t]crop=910:518:300:40[t1];[b]crop=910:518:300:590[b1];[t1][b1]hstack=inputs=2[d];[1:v]fps=30,scale=1840:660[bg];[bg][d]overlay=10:70:shortest=1[v]"
cmd = [
    "ffmpeg",
    "-hide_banner",
    "-y",
    "-i",
    str(P / "synchronized-master.mkv"),
    "-f",
    "concat",
    "-safe",
    "0",
    "-i",
    str(P / "banners.concat"),
    "-filter_complex",
    layout,
    "-map",
    "[v]",
    "-map",
    "0:a",
    "-c:v",
    "libx264",
    "-preset",
    "veryfast",
    "-crf",
    "22",
    "-pix_fmt",
    "yuv420p",
    "-fps_mode",
    "vfr",
    "-c:a",
    "aac",
    "-b:a",
    "192k",
    "-movflags",
    "+faststart",
    str(P / "PRIMARY-full-game-native-controls.mp4"),
]
save("export-command.json", dict(master=master, delivery=cmd))
with (P / "export.log").open("w") as log:
    subprocess.run(cmd, stdout=log, stderr=log, check=True)
checks = json.loads((P / "assertions.json").read_text())
for name in (
    "raw-video.mkv",
    "synchronized-master.mkv",
    "PRIMARY-full-game-native-controls.mp4",
):
    probed = subprocess.check_output(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_format",
            "-show_streams",
            "-of",
            "json",
            str(P / name),
        ]
    )
    (P / (name + ".ffprobe.json")).write_bytes(probed)
    with (P / (name + ".decode.log")).open("w") as log:
        result = subprocess.run(
            ["ffmpeg", "-v", "error", "-i", str(P / name), "-f", "null", "-"],
            stdout=log,
            stderr=log,
        )
    checks.append(
        dict(
            test=f"Complete decode: {name}",
            result="passed" if result.returncode == 0 else "failed",
            actual=result.returncode,
        )
    )
save("assertions.json", checks)
raise SystemExit(1 if any(c["result"] == "failed" for c in checks) else 0)
