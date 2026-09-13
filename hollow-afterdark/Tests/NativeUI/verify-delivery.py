"""Additional read-only delivery/visible-toggle checks after export."""

import array
import json
import math
import os
import pathlib
import subprocess

P = pathlib.Path(os.environ["EVIDENCE"]).resolve()


def save(n, x):
    (P / n).write_text(json.dumps(x, indent=2))


checks = json.loads((P / "assertions.json").read_text())


def check(name, ok, actual):
    checks.append(dict(test=name, result="passed" if ok else "failed", actual=actual))


events = [json.loads(x) for x in (P / "capture-events.jsonl").read_text().splitlines()]
timing = json.loads((P / "timing.json").read_text())
origin = timing["video_first_host_seconds"]
frames = json.loads(
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
            str(P / "raw-video.mkv"),
        ]
    )
)["frames"]
pts = [float(f["best_effort_timestamp_time"]) for f in frames]
silence = json.loads((P / "raw-silence-intervals.json").read_text())
ui = []
for kind in ("audio_both_off", "audio_restored_on"):
    e = next(e for e in events if e["event"] == kind)
    t = e["host"] - origin
    start = t - 0.5
    end = t + 0.5
    times = [p for p in pts if start <= p <= end]
    raw = subprocess.check_output(
        [
            "ffmpeg",
            "-v",
            "error",
            "-i",
            str(P / "raw-video.mkv"),
            "-vf",
            f"select='between(t,{start},{end})',crop=90:32:532:442,format=gray",
            "-fps_mode",
            "passthrough",
            "-f",
            "rawvideo",
            "pipe:1",
        ]
    )
    size = 90 * 32
    assert len(raw) == len(times) * size, (len(raw), len(times))
    masks = [
        bytes(1 if v >= 180 else 0 for v in raw[i : i + size])
        for i in range(0, len(raw), size)
    ]
    before = masks[0]
    after = masks[-1]
    assert before != after, "Expected native AUDIO text change in this crop"
    distances = [
        (sum(a != b for a, b in zip(m, before)), sum(a != b for a, b in zip(m, after)))
        for m in masks
    ]
    candidates = [
        i
        for i in range(len(masks) - 2)
        if all(distances[j][1] < distances[j][0] for j in range(i, i + 3))
    ]
    assert candidates, "No stable visible AUDIO-label transition"
    index = candidates[0]
    visible = times[index]
    interval = min(
        silence,
        key=lambda s: abs(s["media_start"] - t)
        if kind == "audio_both_off"
        else abs(s["media_end"] - t),
    )
    signal = (
        interval["media_start"] if kind == "audio_both_off" else interval["media_end"]
    )
    row = dict(
        event=kind,
        native_completion_media=t,
        visible_label_media=visible,
        preceding_frame_media=times[index - 1] if index else None,
        pcm_transition_media=signal,
        pcm_minus_visible_seconds=signal - visible,
        method="Recorded native AUDIO label white-pixel masks; stable >=3 captured frames",
        frame_distances=list(zip(times, distances)),
    )
    ui.append(row)
    check(
        f"Visible native {kind} label aligns with received PCM within250ms",
        abs(signal - visible) < 0.25,
        row,
    )
save("visible-audio-toggle-audit.json", ui)
measure = json.loads((P / "audio-measurements.json").read_text())
delivery = {}
for name, m in measure.items():
    data = subprocess.check_output(
        [
            "ffmpeg",
            "-v",
            "error",
            "-ss",
            str(m["media_start"]),
            "-t",
            "6",
            "-i",
            str(P / "PRIMARY-full-game-native-controls.mp4"),
            "-vn",
            "-f",
            "f32le",
            "pipe:1",
        ]
    )
    values = array.array("f")
    values.frombytes(data)
    rms = math.sqrt(sum(v * v for v in values) / len(values))
    delivery[name] = dict(rms=rms, samples=len(values))
check(
    "Delivery AAC preserves ON/OFF/ON",
    delivery["audio_music_only_on"]["rms"] > 1e-5
    and delivery["audio_restored_on"]["rms"] > 1e-5
    and delivery["audio_both_off"]["rms"] < 1e-6,
    delivery,
)
save("delivery-audio-measurements.json", delivery)
audio_packets = json.loads(
    subprocess.check_output(
        [
            "ffprobe",
            "-v",
            "error",
            "-select_streams",
            "a:0",
            "-show_packets",
            "-of",
            "json",
            str(P / "PRIMARY-full-game-native-controls.mp4"),
        ]
    )
)["packets"]
save("delivery-audio-packets.json", audio_packets)
gaps = [
    float(y["pts_time"]) - float(x["pts_time"]) - float(x["duration_time"])
    for x, y in zip(audio_packets, audio_packets[1:])
]
check(
    "Delivery audio packets are continuous",
    max(map(abs, gaps)) < 0.00001,
    dict(max_gap_seconds=max(map(abs, gaps)), packets=len(audio_packets)),
)
args = (P / "app-process-arguments.txt").read_text().splitlines()
check(
    "Both native launches omit driver/autojoin flags",
    len(args) == 2 and all("--driver" not in a and "--autojoin" not in a for a in args),
    args,
)
save("assertions.json", checks)
print(
    json.dumps(
        dict(
            ui=ui, delivery=delivery, checks=[(c["test"], c["result"]) for c in checks]
        ),
        indent=2,
    )
)
raise SystemExit(1 if any(c["result"] == "failed" for c in checks) else 0)
