#!/usr/bin/env python3
"""Two actual Simulator clients; combat/ready/rematch use ONLY desktop mouse events.

Prerequisites: macOS/Xcode, Python3 stdlib, ffmpeg, compiled native_events helper,
Accessibility permission, default BlackHole output, server stdout JSONL, two
landscape Simulator windows at the documented geometry. No websocket dependency.
Run with a single desktop recorder already active; this script records live PCM.
"""

import argparse
import hashlib
import json
import pathlib
import signal
import subprocess
import time

HERE = pathlib.Path(__file__).resolve().parent
CONTROLS = {
    "left": (68, 56),
    "right": (182, 56),
    "jump": (125, 87),
    "crouch": (125, 25),
    "guard": (622, 49),
    "light": (710, 74),
    "heavy": (791, 48),
    "fire": (872, 77),
    "audio": (325, 37),
    "ready": (480, 253),
    "rematch": (480, 254),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--audit", type=pathlib.Path, required=True)
    parser.add_argument("--alpha", required=True, help="First simulator UDID")
    parser.add_argument("--beta", required=True, help="Second, distinct simulator UDID")
    parser.add_argument("--server", default="ws://127.0.0.1:8743")
    parser.add_argument("--app-revision", default="unspecified")
    parser.add_argument("--room", default="MTRCG01")
    parser.add_argument("--audio-index", default="0")
    parser.add_argument("--helper", type=pathlib.Path, default=HERE / "native_events")
    parser.add_argument(
        "--config", type=pathlib.Path, default=HERE / "screen-config.json"
    )
    args = parser.parse_args()
    if args.alpha == args.beta:
        parser.error("--alpha and --beta must identify different simulators")
    devices = {"alpha": args.alpha, "beta": args.beta}
    if args.output.exists():
        raise SystemExit("Output exists; use a fresh directory and fresh room.")
    if not args.output.parent.is_dir():
        raise SystemExit("Output parent must already exist.")
    preflight = json.loads(subprocess.check_output([str(args.helper), "--preflight"]))
    cfg = json.loads(args.config.read_text())
    if cfg["desktop"] != [preflight["width"], preflight["height"]]:
        parser.error(
            "Desktop resolution differs from --config; recalibrate the screen geometry"
        )
    args.output.mkdir()
    events = (args.output / "screen-events.jsonl").open("w", buffering=1)
    helper = subprocess.Popen(
        [str(args.helper)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
    )
    audio_log = (args.output / "audio-capture.log").open("w")
    audio_command = [
        "ffmpeg",
        "-hide_banner",
        "-debug_ts",
        "-f",
        "avfoundation",
        "-i",
        ":" + args.audio_index,
        "-af",
        "aresample=async=1:first_pts=0",
        "-c:a",
        "pcm_s16le",
        str(args.output / "live-loopback.wav"),
    ]
    audio = subprocess.Popen(
        audio_command, stdin=subprocess.PIPE, stdout=audio_log, stderr=audio_log
    )
    metadata = {
        "room": args.room,
        "devices": devices,
        "config": cfg,
        "app_revision": args.app_revision,
        "started": time.time(),
        "input": "CoreGraphics physical-screen mouse events",
        "in_app_driver": False,
        "launch_commands": [],
        "audio_command": audio_command,
        "source_hashes": {
            p.name: hashlib.sha256(p.read_bytes()).hexdigest()
            for p in [pathlib.Path(__file__), HERE / "native_events.swift"]
        },
    }

    def log(kind, **fields):
        row = {"at": time.time(), "kind": kind, **fields}
        events.write(json.dumps(row) + "\n")
        print(json.dumps(row), flush=True)

    def native(label, **request):
        row = {"label": label, **request}
        helper.stdin.write(json.dumps(row) + "\n")
        helper.stdin.flush()
        result = json.loads(helper.stdout.readline())
        log("native", request=row, result=result)
        if not result.get("ok"):
            raise RuntimeError(result)

    def pause(label, duration):
        native(label)
        log("observation_start", label=label, duration=duration)
        time.sleep(duration)
        log("observation_end", label=label)

    def control(player, key, duration=0.09):
        x, y = CONTROLS[key]
        sx, sy, sw, sh = cfg[player]["scene"]
        native(
            f"{player.upper()} · {key.upper()} · {duration:.2f}s",
            player=player,
            control=key,
            kind="hold",
            duration=duration,
            focus=cfg[player]["focus"],
            point=[sx + x * sw / 960, sy + (540 - y) * sh / 540],
        )

    def audit():
        rows = []
        for line in args.audit.read_text().splitlines():
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if row.get("code") == args.room:
                rows.append(row)
        return rows

    def phase():
        return next((r for r in reversed(audit()) if r["event"] == "phase"), {})

    def until(predicate, timeout=15):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            value = predicate()
            if value:
                return value
            time.sleep(0.1)
        raise RuntimeError("Timed out waiting for native control's server audit effect")

    try:
        native("Launching native clients\nNo --auto / --driver flags")
        for player, udid in devices.items():
            subprocess.run(
                ["xcrun", "simctl", "terminate", udid, "com.metroimpact.arcade"],
                capture_output=True,
            )
            command = [
                "xcrun",
                "simctl",
                "launch",
                udid,
                "com.metroimpact.arcade",
                "--name",
                player.capitalize() + "-CG",
                "--character",
                "kai" if player == "alpha" else "rhea",
                "--room",
                args.room,
                "--server",
                args.server,
            ]
            metadata["launch_commands"].append(command)
            subprocess.run(command, check=True)
        (args.output / "run-metadata.json").write_text(json.dumps(metadata, indent=2))
        pause("Native lobby · both drivers OFF", 3)
        native(
            "ALPHA · CREATE ROOM",
            player="alpha",
            control="create",
            focus=cfg["alpha"]["focus"],
            point=cfg["alpha"]["create"],
        )
        until(lambda: len([r for r in audit() if r["event"] == "join"]) == 1)
        native(
            "BETA · JOIN",
            player="beta",
            control="join",
            focus=cfg["beta"]["focus"],
            point=cfg["beta"]["join"],
        )
        until(lambda: len([r for r in audit() if r["event"] == "join"]) == 2)
        pause("Two real guests connected\nNo automatic READY", 3)
        assert not any(r["event"] == "ready" for r in audit())
        control("alpha", "ready")
        until(lambda: len([r for r in audit() if r["event"] == "ready"]) == 1)
        pause("Negative check: only Alpha READY\nFight must not start", 3)
        assert not phase()
        control("beta", "ready")
        until(lambda: phase().get("phase") == "fight")
        deadline = time.monotonic() + 300
        round_seen = None
        cycles = 0
        while phase().get("phase") != "matchOver":
            if time.monotonic() > deadline:
                raise RuntimeError("No native match outcome within 300 seconds")
            state = phase()
            if state.get("phase") != "fight":
                time.sleep(0.15)
                continue
            if state["round"] != round_seen:
                round_seen = state["round"]
                native(f"ROUND {round_seen} · actual held movement")
                control("alpha", "right", 1.0)
                control("beta", "left", 1.0)
                if round_seen == 1:
                    control("alpha", "jump", 0.35)
                    time.sleep(0.5)
                    control("beta", "crouch", 0.35)
                    control("alpha", "guard", 0.35)
            sequence = [
                ("alpha", "right", 0.25, 0.05),
                ("beta", "left", 0.25, 0.05),
                ("alpha", "light", 0.09, 0.38),
                ("beta", "heavy", 0.09, 0.55),
                ("alpha", "heavy", 0.09, 0.55),
                ("beta", "light", 0.09, 0.38),
                ("alpha", "fire", 0.09, 0.65),
                ("beta", "fire", 0.09, 0.65),
            ]
            for player, key, duration, delay in sequence:
                if phase().get("phase") != "fight":
                    break
                control(player, key, duration)
                time.sleep(delay)
            cycles += 1
        outcome = phase()
        assert all(p["actions"] > 0 and p["damage"] > 0 for p in outcome["players"])
        log("authoritative_outcome", state=outcome, cycles=cycles)
        pause(
            "SHARED RESULT · observe both displays\nNo automatic rematch (>9 seconds)",
            12,
        )
        assert not any(r["event"] == "rematchVote" for r in audit())
        control("alpha", "audio")
        control("beta", "audio")
        pause("SOUND · both native clients muted", 5)
        control("alpha", "audio")
        pause("SOUND · Alpha only restored", 5)
        control("beta", "audio")
        pause("SOUND · both clients restored", 3)
        control("alpha", "rematch")
        until(lambda: len([r for r in audit() if r["event"] == "rematchVote"]) == 1)
        pause(
            "Negative check: Alpha voted AGAIN\nResult must remain until Beta votes", 3
        )
        assert phase().get("phase") == "matchOver"
        control("beta", "rematch")
        until(lambda: phase().get("match") == 2)
        reset = phase()
        assert all(
            p["hp"] == 100 and p["wins"] == 0 and p["actions"] == 0 and p["damage"] == 0
            for p in reset["players"]
        )
        log("rematch_reset", state=reset)
        pause("REMATCH · same players · HP 100/100\nWins and combat counters reset", 7)
        log("completed")
    except BaseException as error:
        log("failed", error=repr(error))
        raise
    finally:
        (args.output / "run-metadata.json").write_text(json.dumps(metadata, indent=2))
        (args.output / "server-audit.jsonl").write_text(
            "".join(json.dumps(r) + "\n" for r in audit())
        )
        audio.send_signal(signal.SIGINT)
        try:
            audio.wait(timeout=20)
        except subprocess.TimeoutExpired:
            audio.kill()
        log("audio_stopped", returncode=audio.returncode)
        helper.stdin.close()
        helper.wait(timeout=10)
        events.close()
        audio_log.close()


if __name__ == "__main__":
    main()
