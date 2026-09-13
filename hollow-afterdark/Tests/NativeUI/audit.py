"""Read-only runtime/media audit; trim only actual excess PCM by native timestamps."""

import array
import json
import math
import os
import pathlib
import re
import subprocess
import wave

P = pathlib.Path(os.environ["EVIDENCE"]).resolve()


def save(n, v):
    (P / n).write_text(json.dumps(v, indent=2))


def lines(n):
    return [json.loads(x) for x in (P / n).read_text().splitlines()]


checks = []


def check(test, ok, actual):
    checks.append(dict(test=test, result="passed" if ok else "failed", actual=actual))


def probe(name):
    result = json.loads(
        subprocess.check_output(
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
    )
    save(name + ".ffprobe.json", result)
    return result


buffers = lines("raw-audio.jsonl")
b = [x for x in buffers if x["frames"]]
ao = b[0]["host_seconds"]
vo = float(
    re.search(
        r"demuxer -> .*?pkt_pts_time:([0-9.]+)", (P / "avfoundation.log").read_text()
    ).group(1)
)
frames = sum(x["frames"] for x in b)
gaps = [y["sample_time"] - x["sample_time"] - x["frames"] for x, y in zip(b, b[1:])]
offsets = [
    y["frame_offset"] - x["frame_offset"] - x["frames"] for x, y in zip(b, b[1:])
]
drift = [x["host_seconds"] - ao - x["frame_offset"] / 48000 for x in b]
aa = dict(
    nonempty_buffers=len(b),
    empty_shutdown_callbacks=len(buffers) - len(b),
    frames=frames,
    bytes=(P / "raw-audio.s16le").stat().st_size,
    duration=frames / 48000,
    sample_discontinuities=sum(abs(x) > 0.001 for x in gaps),
    storage_discontinuities=sum(x != 0 for x in offsets),
    max_host_sample_drift_seconds=max(map(abs, drift)),
    all_valid_timestamps=all(x["flags"] & 3 == 3 for x in b),
    all_bytes_written=all(
        x["bytes"] == x["written"] == x["frames"] * 4 for x in buffers
    ),
)
save("audio-buffer-audit.json", aa)
check(
    "Native received PCM is fully stored and contiguous",
    aa["all_valid_timestamps"]
    and aa["all_bytes_written"]
    and frames * 4 == aa["bytes"]
    and not aa["sample_discontinuities"]
    and not aa["storage_discontinuities"]
    and max(map(abs, drift)) < 0.02,
    aa,
)
duration = float(probe("raw-video.mkv")["format"]["duration"])
packets = json.loads(
    subprocess.check_output(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_packets",
            "-of",
            "json",
            str(P / "raw-video.mkv"),
        ]
    )
)["packets"]
save("raw-video-packets.json", packets)
vd = [float(y["pts_time"]) - float(x["pts_time"]) for x, y in zip(packets, packets[1:])]
trim = round((vo - ao) * 48000)
kept = min(round(duration * 48000), frames - trim)
assert trim >= 0 and kept > 0, "Cannot manufacture missing audio"
with (
    (P / "raw-audio.s16le").open("rb") as source,
    wave.open(str(P / "live-audio-aligned.wav"), "wb") as dest,
):
    source.seek(trim * 4)
    dest.setparams((2, 2, 48000, 0, "NONE", "not compressed"))
    dest.writeframes(source.read(kept * 4))
timing = dict(
    video_first_host_seconds=vo,
    audio_first_host_seconds=ao,
    trimmed_head_frames=trim,
    trimmed_tail_frames=frames - trim - kept,
    video_duration_seconds=duration,
    aligned_audio_duration_seconds=kept / 48000,
    alignment_rounding_error_seconds=ao + trim / 48000 - vo,
    inserted_frames=0,
    resampling=False,
    video_packets=len(packets),
    max_video_interval_seconds=max(vd),
    video_intervals_over_50ms=sum(x > 0.05 for x in vd),
)
save("timing.json", timing)
check(
    "Original host timestamps align captured PCM without padding",
    abs(timing["alignment_rounding_error_seconds"]) < 1 / 48000
    and abs(kept / 48000 - duration) < 0.002,
    timing,
)
events = lines("capture-events.jsonl")
rows = lines("snapshots.jsonl")
states = [x["state"] for x in rows]
first = next(s for s in states if s["phase"] == "countdown" and s["matchNumber"] == 1)
check(
    "Two distinct native peers start full health and zero score",
    len(first["players"]) == 2
    and len({p["id"] for p in first["players"]}) == 2
    and all(
        p["connected"] and p["hp"] == 1000 and p["wins"] == 0 for p in first["players"]
    ),
    first,
)
results = {}
for m in (1, 2):
    result = next(s for s in states if s["phase"] == "result" and s["matchNumber"] == m)
    results[m] = result
    check(
        f"Match {m} genuine shared result",
        bool(result["winner"])
        and max(p["wins"] for p in result["players"]) == 2
        and any(p["hp"] == 0 for p in result["players"]),
        result,
    )
    for p in result["players"]:
        xs = [
            q["x"]
            for s in states
            if s["matchNumber"] == m
            for q in s["players"]
            if q["id"] == p["id"]
        ]
        st = p["stats"]
        check(
            f"Match {m}: {p['name']} moves, jumps, hits, specials and defends",
            max(xs) - min(xs) > 50
            and min(st["hits"], st["specials"], st["jumps"]) > 0
            and st["blocks"] + st["shields"] > 0,
            dict(x_range=max(xs) - min(xs), stats=st),
        )
save("results.json", results)
rematch = next(s for s in states if s["phase"] == "countdown" and s["matchNumber"] == 2)
actions = [e for e in events if e["event"] == "ui_action_completed"]
consent = {e["player"] for e in actions if e["control"] == "rematch"}
check(
    "Scripted native REMATCH consent resets both HP and scores",
    consent == {"Ren", "Aya"}
    and all(p["hp"] == 1000 and p["wins"] == 0 for p in rematch["players"]),
    rematch,
)
check(
    "One pointer alternates non-overlapping native touch intervals",
    all(a["end_host"] <= b["start_host"] for a, b in zip(actions, actions[1:])),
    dict(actions=len(actions), players=sorted({e["player"] for e in actions})),
)
check(
    "No AUTO control activated by external harness",
    all(e["control"] != "driver" for e in actions),
    sorted({e["control"] for e in actions}),
)
pause = next((e for e in events if e["event"] == "paused"), None)
check(
    "Input harness resumes checkpoint while original capture continues",
    pause is not None
    and any(e["host"] > pause["host"] for e in actions)
    and len([e for e in events if e["event"] == "video_process_started"]) == 1,
    pause,
)
audio = array.array("h")
audio.frombytes((P / "raw-audio.s16le").read_bytes())


def measure(h, d=6):
    x = audio[round((h - ao) * 48000) * 2 : round((h - ao + d) * 48000) * 2]
    return dict(
        host_start=h,
        media_start=h - vo,
        duration=len(x) / 96000,
        samples=len(x),
        nonzero_samples=sum(v != 0 for v in x),
        rms=math.sqrt(sum(v * v for v in x) / len(x)) / 32768,
        peak=max(map(abs, x)) / 32768,
    )


measurements = {
    e["event"]: measure(e["host"] + 1)
    for e in events
    if e["event"].startswith("audio_") and "top" in e
}
fight = next(
    e for e in events if e["event"] == "phase" and e["phase"] == [1, 1, "fight"]
)
measurements["combat"] = measure(fight["host"] + 14)
save("audio-measurements.json", measurements)
for name in ("audio_music_only_on", "audio_restored_on", "combat"):
    check(
        f"Nonzero original captured audio: {name}",
        measurements[name]["rms"] > 1e-5,
        measurements[name],
    )
check(
    "Both-muted raw received PCM is digital silence",
    measurements["audio_both_off"]["nonzero_samples"] == 0,
    measurements["audio_both_off"],
)
silent = []
start = None
for i in range(0, len(audio), 960):
    zero = not any(audio[i : i + 960])
    if zero and start is None:
        start = ao + i / 96000
    if not zero and start is not None:
        end = ao + i / 96000
        if end - start > 0.5:
            silent.append(
                dict(
                    host_start=start,
                    host_end=end,
                    media_start=start - vo,
                    media_end=end - vo,
                )
            )
        start = None
save("raw-silence-intervals.json", silent)
off = next(e for e in events if e["event"] == "audio_both_off")
on = next(e for e in events if e["event"] == "audio_restored_on")
interval = min(silent, key=lambda s: abs(s["host_start"] - off["host"]))
latency = dict(
    off_seconds=interval["host_start"] - off["host"],
    on_seconds=interval["host_end"] - on["host"],
)
save("audio-toggle-timing.json", latency)
check(
    "Live audio transitions follow native toggle completion within 250ms",
    abs(latency["off_seconds"]) < 0.25 and abs(latency["on_seconds"]) < 0.25,
    latency,
)
save("assertions.json", checks)
print(
    json.dumps(
        dict(
            checks=[(x["test"], x["result"]) for x in checks],
            timing=timing,
            audio=aa,
            measurements=measurements,
        ),
        indent=2,
    )
)
raise SystemExit(1 if any(c["result"] == "failed" for c in checks) else 0)
