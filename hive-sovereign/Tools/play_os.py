#!/usr/bin/env python3
"""Two real OS-pointer captains. No WebSocket writes or application URL hooks."""
import argparse
import ctypes
import hashlib
import json
import math
import pathlib
import re
import subprocess
import threading
import time
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--room", required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    parser.add_argument("--config", type=pathlib.Path, default=HERE / "layout.example.json")
    parser.add_argument("--server", default="http://127.0.0.1:8789")
    parser.add_argument("--timeout", type=float, default=180)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Z0-9]{4,6}", args.room):
        parser.error("room must be 4–6 uppercase alphanumerics")
    if not args.out.parent.is_dir() or args.out.exists():
        parser.error("--out must be a NEW directory under an existing parent")
    config = json.loads(args.config.read_text())
    players = config["players"]
    if len(players) != 2 or config["reference_desktop"] != [1024, 768]:
        parser.error("exactly two players and 1024x768 reference coordinates required")
    args.out.mkdir()
    out = args.out

    def save(name, value):
        (out / name).write_text(json.dumps(value, indent=2) + "\n")

    def state():
        # This is the ONLY network operation in the harness: read-only HTTP GET.
        with urllib.request.urlopen(args.server + "/rooms/" + args.room, timeout=3) as response:
            return json.load(response)

    initial = state()
    if initial["phase"] not in ("lobby", "result"):
        raise RuntimeError("Start with both clients waiting in lobby or at result")
    if len(initial["peers"]) != 2 or not all(p["connected"] for p in initial["peers"]):
        raise RuntimeError("Two connected clients required")
    processes = subprocess.check_output(["ps", "-ww", "-axo", "command"], text=True)
    clients = [line for line in processes.splitlines()
               if "HiveSovereign.app/HiveSovereign" in line]
    if len(clients) != 2 or any("--autopilot" in line for line in clients):
        raise RuntimeError("Exactly two app processes, neither using --autopilot, required")
    if not all(any(p["udid"] in line for line in clients) for p in players):
        raise RuntimeError("Live client UDIDs do not match configuration")
    revision = subprocess.run(
        ["git", "-C", str(HERE), "rev-parse", "HEAD"],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    )
    manifest = {
        "revision": revision.stdout.strip() if revision.returncode == 0 else "unversioned",
        "room": args.room, "launch_processes": clients, "config": config,
        "method": "Native CGEvent pointer holds; single mouse alternates clients",
        "AI": "Unselected teammates use normal server AI; no captain driver",
        "network": "HTTP GET /rooms/<room> only; never input/state writes",
        "source_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in [HERE / "Pointer.swift", pathlib.Path(__file__), args.config]},
    }
    save("manifest.json", manifest)
    subprocess.run(["swiftc", str(HERE / "Pointer.swift"), "-o", str(out / "pointer")], check=True)
    (out / "status.txt").write_text("OS POINTER CAPTAINS\nPreparing synchronized capture")
    pointer = subprocess.Popen([str(out / "pointer"), str(out / "status.txt")],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    probe = json.loads(pointer.stdout.readline())
    if not probe.get("ready"):
        raise RuntimeError(probe)
    save("pointer-probe.json", probe)
    actions = (out / "actions.jsonl").open("w")
    samples = []
    poll_errors = []
    stop = threading.Event()
    step = "Both captains MANUAL; waiting to ready"
    target_match = initial["match"] + 1

    def poll():
        with (out / "telemetry.jsonl").open("w") as log:
            while not stop.is_set():
                try:
                    s = state()
                    record = {"wall_time": time.time(), "state": s}
                    samples.append(record)
                    log.write(json.dumps(record) + "\n")
                    log.flush()
                    text = ("HIVE SOVEREIGN\nOS POINTER CAPTAINS\n" + manifest["revision"][:7]
                            + "\n\nAZURE: TOP / AMBER: BOTTOM\nCaptain driver OFF on both\n"
                            "Unselected teammates: AI\nOne mouse, alternating\n\n"
                            "Actual BlackHole game audio\nAzure ON / Amber MUTED\n\n"
                            + step + "\n\nRoom " + args.room + " | " + s["phase"].upper())
                    if s.get("game"):
                        g = s["game"]
                        text += (f"\nMatch {s['match']} | tick {g['tick']}\n"
                                 f"Berries {g['score']} | Eggs {g['lives']}\n")
                        for team in range(2):
                            u = next(u for u in g["units"] if u["id"] == f"{team}-0")
                            text += f"{players[team]['name']} Q: {u['x']:.0f},{u['y']:.0f}\n"
                        if s["phase"] == "result":
                            text += f"\n{g['victory'].upper()} RESULT\nWinner: {players[g['winner']]['name']}"
                    (out / "status.txt").write_text(text)
                except Exception as error:
                    poll_errors.append({"wall_time": time.time(), "error": str(error)})
                stop.wait(0.05)

    def press(team, sequence):
        nonlocal step
        step = players[team]["name"] + ": " + " → ".join(c for c, _ in sequence)
        events = []
        # Focus via harmless IN-GAME header, never via Simulator titlebar.
        for control, duration in [("focus", 0.18)] + sequence:
            x, y = players[team][control]
            events.append({"target": players[team]["name"], "control": control,
                           "x": x, "y": y, "hold": duration})
        request_time = time.time()
        pointer.stdin.write(json.dumps({"events": events}) + "\n")
        pointer.stdin.flush()
        reply = json.loads(pointer.stdout.readline())
        if "error" in reply:
            raise RuntimeError(reply["error"])
        for event in reply["events"]:
            event["request_wall"] = request_time
            actions.write(json.dumps(event) + "\n")
        actions.flush()

    def wait_for(predicate, seconds):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            s = state()
            if predicate(s):
                return s
            time.sleep(0.05)
        raise RuntimeError("Timed out waiting for expected room state")

    class Timebase(ctypes.Structure):
        _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]
    lib = ctypes.CDLL(None)
    lib.mach_absolute_time.restype = ctypes.c_uint64
    tb = Timebase()
    lib.mach_timebase_info(ctypes.byref(tb))
    meta = {"start_wall": time.time(),
            "wall_minus_host": time.time() - lib.mach_absolute_time() * tb.numer / tb.denom / 1e9,
            "audio": "Concurrent real loopback PCM; timestamp gaps padded, no soundtrack"}
    capture_log = (out / "capture.log").open("w")
    recorder = subprocess.Popen([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "verbose",
        "-thread_queue_size", "512", "-f", "avfoundation", "-framerate", "15",
        "-pixel_format", "uyvy422", "-capture_cursor", "1", "-i", config["avfoundation"],
        "-c:v", "libx264", "-preset", "ultrafast", "-threads", "2", "-crf", "20",
        "-pix_fmt", "yuv420p", "-r", "15",
        "-af", "aresample=async=1:min_hard_comp=0.01:first_pts=0",
        "-c:a", "pcm_s16le", str(out / "live-desktop-audio.mov")],
        stdin=subprocess.PIPE, stdout=capture_log, stderr=capture_log)
    thread = threading.Thread(target=poll, daemon=True)
    thread.start()
    error = None
    try:
        deadline = time.monotonic() + 25
        while "Output #0" not in (out / "capture.log").read_text():
            if recorder.poll() is not None or time.monotonic() > deadline:
                raise RuntimeError("Recorder did not initialize; inspect capture.log")
            time.sleep(0.1)
        time.sleep(2)
        ready = "lobby_ready" if initial["phase"] == "lobby" else "result_ready"
        press(0, [(ready, 0.25)])
        press(1, [(ready, 0.25)])
        wait_for(lambda s: s["match"] == target_match, 8)
        for team in range(2):
            press(team, [("queen", 0.18)])
        wait_for(lambda s: s["phase"] == "playing", 8)
        for team in range(2):
            press(team, [("jump", 0.14), ("action", 0.2),
                         ("left" if team == 0 else "right", 0.45)])
        stages = [0, 0]
        turns = [0, 0]
        deadline = time.monotonic() + args.timeout
        while time.monotonic() < deadline:
            s = state()
            if s["phase"] == "result":
                break
            if recorder.poll() is not None:
                raise RuntimeError("Recorder exited during gameplay")
            for team in range(2):
                s = state()
                if s["phase"] == "result":
                    break
                g = s["game"]
                u = next(u for u in g["units"] if u["id"] == f"{team}-0")
                if u["dead"] > 0:
                    continue
                outside = [230, 730][team]
                gate = g["gates"][team]
                if stages[team] == 0 and abs(u["x"] - outside) < 18 and u["y"] <= 240:
                    stages[team] = 1
                if stages[team] == 1 and gate["team"] == team:
                    stages[team] = 2
                target = outside if stages[team] == 0 else gate["x"]
                if stages[team] == 2:
                    rival = next(v for v in g["units"] if v["id"] == f"{1-team}-0")
                    target = rival["x"]
                delta = target - u["x"]
                sequence = []
                if stages[team] == 2 and turns[team] % 2 == 0:
                    sequence += [("jump", 0.14), ("action", 0.2)]
                if abs(delta) > 8:
                    sequence.append(("right" if delta > 0 else "left",
                                     min(0.45, max(0.12, abs(delta) / 185))))
                if sequence:
                    press(team, sequence)
                turns[team] += 1
                time.sleep(0.05)
        else:
            raise RuntimeError("No genuine result within gameplay timeout")
        step = "VERIFY: shared result on both\nNo forced score or outcome"
        time.sleep(8)
    except Exception as exc:
        error = str(exc)
        step = "INCOMPLETE: " + error
    finally:
        stop.set()
        thread.join(timeout=5)
        if recorder.poll() is None:
            recorder.stdin.write(b"q\n")
            recorder.stdin.flush()
            recorder.wait(timeout=60)
        capture_log.close()
        pointer.stdin.close()
        pointer.wait(timeout=10)
        actions.close()
        meta["stop_wall"] = time.time()
        meta["ffmpeg_exit"] = recorder.returncode
        match = re.search(r"Duration: N/A, start: ([0-9.]+)", (out / "capture.log").read_text())
        if match:
            meta["media_start_wall"] = float(match.group(1)) + meta["wall_minus_host"]
        save("capture-meta.json", meta)

    run = [r for r in samples if r["state"]["match"] == target_match]
    checks = {}
    for team in range(2):
        units = [next(u for u in r["state"]["game"]["units"] if u["id"] == f"{team}-0")
                 for r in run if r["state"].get("game")]
        human = [u for u in units if u["human"]]
        checks[players[team]["name"]] = {
            "human_queen": bool(human),
            "horizontal_motion": any(abs(u["vx"]) > 100 for u in human),
            "jump_upward": any(u["vy"] > 100 for u in human),
            "dive_observed": any(u["diving"] for u in human),
            "gate_owned_at_human_queen": any(
                gate["team"] == team and math.hypot(gate["x"] - u["x"], gate["y"] - u["y"]) < 27
                for r in run if r["state"].get("game")
                for u in r["state"]["game"]["units"] if u["id"] == f"{team}-0" and u["human"]
                for gate in r["state"]["game"]["gates"]),
            "new_inputs": max([p["inputs"] for r in run for p in r["state"]["peers"]
                               if p["team"] == team] or [0])
                          - next(p["inputs"] for p in initial["peers"] if p["team"] == team),
        }
    final = run[-1]["state"] if run else initial
    passed = not error and final["phase"] == "result" and all(
        all(value is True for key, value in check.items() if key != "new_inputs")
        and check["new_inputs"] > 30 for check in checks.values())
    save("assertions.json", {
        "passed": passed, "error": error, "captains": checks,
        "distinct_peers": len({p["id"] for p in final["peers"]}) == 2,
        "terminal_server_state": final, "poll_errors": poll_errors,
        "visual_and_audio_validation": "Separate human/agent inspection required; not auto-passed",
    })
    print(json.dumps({"passed": passed, "captains": checks, "error": error, "out": str(out)}, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
