"""Native AudioQueue PCM plus screen-only video, independently timestamped."""

import ctypes
import hashlib
import json
import os
import pathlib
import signal
import subprocess
import time
import urllib.request

P = pathlib.Path(os.environ["EVIDENCE"]).resolve()
ROOM = os.environ["ROOM"]
lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
lib.mach_absolute_time.restype = ctypes.c_uint64


class Timebase(ctypes.Structure):
    _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]


tb = Timebase()
lib.mach_timebase_info(ctypes.byref(tb))


def host():
    return lib.mach_absolute_time() * tb.numer / tb.denom / 1e9


def stamp():
    return {"unix": time.time(), "host": host()}


def event(kind, **kw):
    row = {**stamp(), "event": kind, **kw}
    with (P / "capture-events.jsonl").open("a") as f:
        f.write(json.dumps(row) + "\n")
    print(json.dumps(row), flush=True)


stop = False


def finish(*_):
    global stop
    stop = True


if __name__ == "__main__":
    signal.signal(signal.SIGINT, finish)
    signal.signal(signal.SIGTERM, finish)
    assert not any(
        (P / name).exists()
        for name in (
            "raw-video.mkv",
            "raw-audio.s16le",
            "raw-audio.jsonl",
            "metadata.json",
        )
    ), "Never overwrite an earlier capture"
    cmd = [
        "ffmpeg",
        "-hide_banner",
        "-y",
        "-debug_ts",
        "-f",
        "avfoundation",
        "-probesize",
        "10000000",
        "-analyzeduration",
        "1000000",
        "-framerate",
        "30",
        "-i",
        os.environ["SCREEN_DEVICE"] + ":none",
        "-c:v",
        "h264_videotoolbox",
        "-b:v",
        "6M",
        "-fps_mode",
        "passthrough",
        "-progress",
        str(P / "progress.log"),
        str(P / "raw-video.mkv"),
    ]
    acmd = [str(P / "queue"), str(P / "raw-audio"), "600"]
    (P / "metadata.json").write_text(
        json.dumps(
            {
                "revision": subprocess.check_output(
                    ["git", "rev-parse", "HEAD"],
                    cwd=pathlib.Path(__file__).resolve().parents[2],
                    text=True,
                ).strip(),
                "harness_sha256": {
                    path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                    for path in pathlib.Path(__file__).parent.iterdir()
                    if path.suffix in {".py", ".swift", ".c"}
                },
                "room": ROOM,
                "server": "ws://127.0.0.1:8788",
                "devices": [os.environ["DEVICE_A"], os.environ["DEVICE_B"]],
                "capture_command": cmd,
                "audio_command": acmd,
                "clock_pair": stamp(),
                "window_bounds": [[300, 40, 910, 518], [300, 590, 910, 518]],
                "audio": "Native AudioQueue real BlackHole2ch PCM; no generated soundtrack",
                "input": "External native mouse/touch controls, alternating devices; no in-app drivers",
            },
            indent=2,
        )
    )
    alog = (P / "audioqueue.log").open("w")
    audio = subprocess.Popen(acmd, stdout=alog, stderr=alog)
    event("audio_process_started", pid=audio.pid)
    log = (P / "avfoundation.log").open("w")
    capture = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=log, stderr=log)
    event("video_process_started", pid=capture.pid)
    began = host()
    seen = set()
    with (P / "snapshots.jsonl").open("w", buffering=1) as out:
        while not stop and host() - began < 595 and not (P / "STOP").exists():
            try:
                rooms = json.load(
                    urllib.request.urlopen("http://127.0.0.1:8788/rooms", timeout=2)
                )
                s = next((x for x in rooms if x["code"] == ROOM), None)
                if s:
                    row = {**stamp(), "state": s}
                    out.write(json.dumps(row) + "\n")
                    phase = (s["matchNumber"], s["round"], s["phase"])
                    if phase not in seen:
                        seen.add(phase)
                        event(
                            "phase",
                            phase=phase,
                            hp=[p["hp"] for p in s["players"]],
                            wins=[p["wins"] for p in s["players"]],
                        )
                        if phase[0] == 2 and phase[2] == "result":
                            (P / "SECOND_RESULT").write_text(json.dumps(row))
            except Exception as ex:
                event("observer_error", error=str(ex))
            if capture.poll() is not None or audio.poll() is not None:
                event("capture_exited_early", video=capture.poll(), audio=audio.poll())
                break
            time.sleep(0.1)
    capture.communicate(b"q", timeout=30)
    audio.send_signal(signal.SIGINT)
    audio.wait(timeout=10)
    log.close()
    alog.close()
    event(
        "capture_finished", video_code=capture.returncode, audio_code=audio.returncode
    )
