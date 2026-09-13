#!/usr/bin/env python3
"""Read-only runtime verification. Reads audit/events/media; never contacts game server."""

import argparse
import audioop
import hashlib
import json
import math
import pathlib
import re
import subprocess
import wave

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--run", required=True, type=pathlib.Path)
p.add_argument(
    "--sources", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parent
)
a = p.parse_args()
root = a.run


def load(name):
    return json.loads((root / name).read_text())


def rows(name):
    return [json.loads(x) for x in (root / name).read_text().splitlines()]


audit = rows("server-audit.jsonl")
events = rows("screen-events.jsonl")
metadata = load("run-metadata.json")
checks = []


def check(name, passed, actual):
    checks.append({"assertion": name, "passed": bool(passed), "actual": actual})


joins = [r for r in audit if r["event"] == "join"]
ids = {r["player"] for r in joins}
check(
    "Two distinct simulator and server player identities",
    len(set(metadata["devices"].values())) == len(ids) == len(joins) == 2,
    {"devices": metadata["devices"], "joins": joins},
)
check(
    "Exact source files used remain preserved",
    all(
        hashlib.sha256((a.sources / name).read_bytes()).hexdigest() == digest
        for name, digest in metadata["source_hashes"].items()
    ),
    metadata["source_hashes"],
)
check(
    "No built-in driver/auto launch arguments",
    not metadata["in_app_driver"]
    and all(
        "--auto" not in cmd and "--driver" not in cmd
        for cmd in metadata["launch_commands"]
    ),
    metadata["launch_commands"],
)
native = [r for r in events if r["kind"] == "native"]
check(
    "All posted native-event requests completed",
    all(r["result"]["ok"] for r in native)
    and any(r["kind"] == "completed" for r in events),
    {
        "native_requests": len(native),
        "completed": any(r["kind"] == "completed" for r in events),
    },
)
for player in ["alpha", "beta"]:
    controls = {
        r["request"].get("control")
        for r in native
        if r["request"].get("player") == player
    }
    check(
        f"{player} used visible movement and LIGHT/HEAVY/WAVE",
        {"light", "heavy", "fire", "right" if player == "alpha" else "left"}
        <= controls,
        sorted(controls),
    )
ready = [r for r in audit if r["event"] == "ready"]
phases = [r for r in audit if r["event"] == "phase"]
check(
    "One READY cannot start; second READY begins countdown",
    len(ready) == 2
    and ready[1]["at"] - ready[0]["at"] >= 3000
    and phases[0]["at"] >= ready[1]["at"]
    and phases[0]["phase"] == "countdown",
    {"ready": ready, "first_phase": phases[0]},
)
outcome = next(r for r in phases if r["phase"] == "matchOver" and r["match"] == 1)
check(
    "Both native players deal positive damage and actions",
    all(r["actions"] > 0 and r["damage"] > 0 for r in outcome["players"]),
    outcome["players"],
)
winner = next(r for r in joins if r["player"] == outcome["winner"])
check(
    "Authoritative first-to-two result",
    next(r for r in outcome["players"] if r["id"] == outcome["winner"])["wins"] == 2,
    outcome,
)
ocr = load("result-ocr.json")
score = [r["wins"] for r in outcome["players"]]
ocr_text = {
    role: "\n".join(r["text"] for r in ocr[role]).upper() for role in ("alpha", "beta")
}


def numeric_score(text):
    # Vision reads this font's numeric zero as letter O. Normalize ONLY the
    # two numeric score fields; preserve raw text and initial mismatch evidence.
    match = re.search(r"MATCH COMPLETE\s*[·•]?\s*([0-9O]+)\s*[-—–−]\s*([0-9O]+)", text)
    return [int(x.replace("O", "0")) for x in match.groups()] if match else None


check(
    "Actual screenshot OCR agrees on winner and score on BOTH displays",
    all(
        winner["character"].upper() + " WINS" in text and numeric_score(text) == score
        for text in ocr_text.values()
    ),
    {
        "image": "shared-outcome.png",
        "raw_text": ocr_text,
        "normalized_numeric_scores": {
            role: numeric_score(text) for role, text in ocr_text.items()
        },
        "normalization": "O to 0 only in numeric score fields; visually cross-checked",
    },
)
votes = [r for r in audit if r["event"] == "rematchVote"]
check(
    "No automatic rematch after result",
    len(votes) == 2 and votes[0]["at"] - outcome["at"] > 9000,
    {"seconds_to_first_screen_vote": (votes[0]["at"] - outcome["at"]) / 1000},
)
reset = next(r for r in phases if r["match"] == 2)
check(
    "One AGAIN vote cannot rematch; second does",
    votes[1]["at"] - votes[0]["at"] >= 3000 and reset["at"] >= votes[1]["at"],
    {"votes": votes, "reset_at": reset["at"]},
)
check(
    "Rematch retains UUIDs and resets HP, wins, actions, damage",
    {r["id"] for r in reset["players"]} == ids
    and reset["round"] == 1
    and all(
        r["hp"] == 100 and r["wins"] == r["actions"] == r["damage"] == 0
        for r in reset["players"]
    ),
    reset,
)
correlations = []
for audited, control in [(r, "ready") for r in ready] + [(r, "rematch") for r in votes]:
    role = next(
        r["name"].split("-")[0].lower()
        for r in joins
        if r["player"] == audited["player"]
    )
    event = next(
        r
        for r in native
        if r["request"].get("player") == role and r["request"].get("control") == control
    )
    t = audited["at"] / 1000
    correlations.append(
        event["result"]["started"] <= t <= event["result"]["ended"] + 0.75
    )
check(
    "Every READY/AGAIN audit event correlates with that player's screen click",
    all(correlations),
    correlations,
)

alignment = load("av-alignment.json")
audio_start = alignment["audio_source_start"]
clock_offset = native[0]["result"]["ended"] - native[0]["result"]["uptime"]


def metrics(path, start=0, end=None):
    with wave.open(str(path)) as w:
        rate = w.getframerate()
        duration = w.getnframes() / rate
        stop = duration if end is None else min(duration, end)
        w.setpos(max(0, int(start * rate)))
        data = w.readframes(max(0, int((stop - start) * rate)))
        rms = audioop.rms(data, 2)
        return {
            "start": start,
            "end": stop,
            "frames": len(data) // (2 * w.getnchannels()),
            "rate": rate,
            "channels": w.getnchannels(),
            "rms": rms,
            "rms_dbfs": 20 * math.log10(rms / 32768) if rms else None,
            "peak": audioop.max(data, 2),
        }


whole = metrics(root / "live-loopback.wav")
fight = next(r for r in phases if r["phase"] == "fight")
start = fight["at"] / 1000 - clock_offset - audio_start + 1
end = outcome["at"] / 1000 - clock_offset - audio_start - 1
gameplay = metrics(root / "live-loopback.wav", start, end)
check(
    "Simultaneous live native gameplay audio is nonzero (> -50 dBFS)",
    gameplay["frames"] > 0 and gameplay["rms_dbfs"] > -50,
    gameplay,
)
check(
    "Raw 48 kHz stereo loopback has no clipping",
    whole["rate"] == 48000 and whole["channels"] == 2 and whole["peak"] < 32767,
    whole,
)
windows = {}
for label, key in [
    ("SOUND · both native clients muted", "both_muted"),
    ("SOUND · Alpha only restored", "alpha_only"),
]:
    event = next(r for r in native if r["request"]["label"] == label)
    t = event["result"]["uptime"] - audio_start
    windows[key] = [t + 1, t + 4]
    measured = metrics(root / "live-loopback.wav", *windows[key])
    check(
        "Native SOUND " + key,
        measured["peak"] == 0 if key == "both_muted" else measured["rms_dbfs"] > -50,
        measured,
    )

video = root / "two-player-computer-use.mp4"
probe = json.loads(
    subprocess.check_output(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_streams",
            "-show_format",
            "-of",
            "json",
            str(video),
        ]
    )
)
(root / "ffprobe.json").write_text(json.dumps(probe, indent=2))
types = {s["codec_type"] for s in probe["streams"]}
check(
    "Final media contains native full-desktop video plus live audio",
    types == {"video", "audio"}
    and any(
        [s.get("width"), s.get("height")] == metadata["config"]["desktop"]
        for s in probe["streams"]
    ),
    probe["format"],
)
decoded = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", str(video), "-f", "null", "-"],
    capture_output=True,
    text=True,
)
(root / "full-decode.log").write_text(decoded.stderr)
check(
    "Full final video/audio decode",
    decoded.returncode == 0 and not decoded.stderr,
    {"returncode": decoded.returncode, "errors": decoded.stderr},
)
subprocess.run(
    [
        "ffmpeg",
        "-y",
        "-v",
        "error",
        "-i",
        str(video),
        "-map",
        "0:a:0",
        "-c:a",
        "pcm_s16le",
        str(root / "decoded-audio.wav"),
    ],
    check=True,
)
decoded_mute = metrics(root / "decoded-audio.wav", *windows["both_muted"])
decoded_sound = metrics(root / "decoded-audio.wav", *windows["alpha_only"])
check(
    "Final decoded AAC preserves native SOUND contrast",
    decoded_mute["peak"] == 0 and decoded_sound["rms_dbfs"] > -50,
    {"muted": decoded_mute, "alpha_only": decoded_sound},
)
result = {
    "app_revision": metadata.get("app_revision", "not recorded"),
    "room": metadata["room"],
    "checks": checks,
    "passed": sum(c["passed"] for c in checks),
    "failed": sum(not c["passed"] for c in checks),
    "limitations": [
        "Single mouse serializes touch input; not simultaneous multitouch.",
        "Physical-speaker fidelity and WAN behavior not assessed.",
        "Movement and moving playback additionally require visual inspection.",
    ],
}
(root / "assertions.json").write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
raise SystemExit(bool(result["failed"]))
