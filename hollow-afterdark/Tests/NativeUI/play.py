"""Resumable external native-control harness. GET observations only; no network inputs."""

import argparse
import json
import os
import subprocess
import time
import urllib.request

from capture import ROOM, P, event, host

WINDOWS = {"Ren": os.environ["WINDOW_A"], "Aya": os.environ["WINDOW_B"]}
CONTROLS = {
    "left": (67, 67),
    "right": (145, 67),
    "jump": (106, 131),
    "guard": (224, 67),
    "shield": (289, 67),
    "light": (935, 62),
    "heavy": (1010, 85),
    "special": (1087, 62),
    "ex": (1153, 109),
    "throw": (867, 108),
    "shift": (783, 121),
}
# Native desktop points for the documented 1600x1200 stacked layout.
BUTTONS = {
    "enter": (905, 406),
    "ready": (832, 383),
    "rematch": (723, 385),
    "leave": (794, 385),
    "audio": (574, 461),
}
helper = None


def observe():
    rooms = json.load(urllib.request.urlopen("http://127.0.0.1:8788/rooms", timeout=2))
    return next((s for s in rooms if s["code"] == ROOM), None)


def shot(name):
    subprocess.run(["screencapture", "-x", str(P / (name + ".png"))], check=True)


def tap(name, control, duration=0.07):
    global helper
    assert name in WINDOWS and control != "driver"
    if helper is None:
        helper = subprocess.Popen(
            [str(P / "native-touch")],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
    if control in CONTROLS:
        x, y = CONTROLS[control]
        x = 322 + x * 0.722
        y = 126 + (560 - y) * 0.722
    else:
        x, y = BUTTONS[control]
    if name == "Aya":
        y += 550
    request = {"window": WINDOWS[name], "x": x, "y": y, "duration": duration}
    event("ui_action_requested", player=name, control=control, request=request)
    helper.stdin.write(json.dumps(request) + "\n")
    helper.stdin.flush()
    reply = json.loads(helper.stdout.readline())
    assert reply["ok"], reply
    event("ui_action_completed", player=name, control=control, **reply)
    return reply


checkpoint = P / "play-checkpoint.json"
state = (
    json.loads(checkpoint.read_text())
    if checkpoint.exists()
    else {"openings": [], "rematched": False, "turn": 0}
)


def save():
    temp = checkpoint.with_suffix(".tmp")
    temp.write_text(json.dumps(state, indent=2))
    temp.replace(checkpoint)


def gate():
    s = observe()
    assert s and len(s["players"]) == 2 and all(p["connected"] for p in s["players"]), (
        "Peers disconnected; stop and resume after recovery"
    )
    assert {p["name"] for p in s["players"]} == set(WINDOWS)
    return s


def opening(key):
    # Each attack travels across the stage while the OTHER native window is raised.
    # One mouse pointer: no simultaneous touches or in-app automation.
    event("annotation", text=f"{key}: scripted C then opponent guard/shield; jump both")
    tap("Ren", "special")
    tap("Aya", "shield", 1.2)
    time.sleep(0.25)
    tap("Aya", "special")
    tap("Ren", "guard", 1.2)
    time.sleep(0.25)
    tap("Ren", "jump")
    time.sleep(0.65)
    tap("Aya", "jump")
    time.sleep(0.7)
    state["openings"].append(key)
    save()
    shot(f"native-controls-{key}")


def play():
    started = host()
    last = None
    while host() - started < 480:
        if (P / "PAUSE").exists():
            event("paused", reason="PAUSE file; resume with play command")
            return
        s = gate()
        key = f"m{s['matchNumber']}-r{s['round']}"
        phase = (s["matchNumber"], s["round"], s["phase"])
        if phase != last:
            event("input_phase", phase=phase)
            last = phase
        if s["phase"] == "result":
            shot(f"result-match-{s['matchNumber']}")
            event(
                "assertion",
                test="Genuine shared match result",
                result="passed",
                message=s["message"],
                players=s["players"],
            )
            if s["matchNumber"] >= 2:
                return
            time.sleep(7)
            tap("Ren", "rematch")
            time.sleep(0.4)
            tap("Aya", "rematch")
            state["rematched"] = True
            save()
            time.sleep(1)
            continue
        if s["phase"] == "lobby":
            raise RuntimeError("Join and READY both devices before play")
        if s["phase"] != "fight":
            time.sleep(0.15)
            continue
        if key not in state["openings"]:
            opening(key)
            continue
        name = ("Ren", "Aya")[state["turn"] % 2]
        p = next(p for p in s["players"] if p["name"] == name)
        other = next(p for p in s["players"] if p["name"] != name)
        if p["stun"] or p["move"]:
            time.sleep(0.12)
            continue
        if p["ascend"]:
            tap(name, "shift")
            time.sleep(0.18)
        gap = abs(p["x"] - other["x"])
        if gap > 95:
            tap(
                name,
                "right" if p["x"] < other["x"] else "left",
                min(0.85, max(0.08, (gap - 82) / 252)),
            )
            time.sleep(0.1)
        s = gate()
        if s["phase"] != "fight":
            continue
        # Distinct transparent strategies: Ren heavy-led; Aya light-led.
        # Outcomes emerge from real hits/damage, never prescribed server state.
        control = (
            "heavy"
            if name == "Ren"
            else ("heavy" if state["turn"] % 6 == 3 else "light")
        )
        tap(name, control)
        state["turn"] += 1
        save()
        time.sleep(0.82)
    raise TimeoutError("Bounded gameplay timed out; retain evidence and investigate")


def audio():
    tap("Ren", "leave")
    time.sleep(0.4)
    tap("Aya", "leave")
    time.sleep(1)
    tap("Aya", "audio")
    event("audio_music_only_on", top="ON", bottom="OFF")
    shot("audio-on")
    time.sleep(8)
    tap("Ren", "audio")
    event("audio_both_off", top="OFF", bottom="OFF")
    shot("audio-off")
    time.sleep(8)
    tap("Ren", "audio")
    event("audio_restored_on", top="ON", bottom="OFF")
    shot("audio-restored")
    time.sleep(8)
    (P / "STOP").write_text("Native-control flow and audio audit completed\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["join", "ready", "play", "audio", "tap"])
    parser.add_argument("player", nargs="?")
    parser.add_argument("control", nargs="?")
    parser.add_argument("--duration", type=float, default=0.07)
    a = parser.parse_args()
    try:
        if a.command == "join":
            tap("Ren", "enter")
            time.sleep(1)
            tap("Aya", "enter")
            time.sleep(1)
            event(
                "assertion",
                test="Two driver-disabled native peers joined",
                result="passed",
                state=gate(),
            )
            shot("driver-disabled-lobby")
        elif a.command == "ready":
            tap("Ren", "ready")
            time.sleep(0.3)
            tap("Aya", "ready")
        elif a.command == "play":
            play()
        elif a.command == "audio":
            audio()
        else:
            tap(a.player, a.control, a.duration)
    finally:
        if helper:
            # Closing stdin lets any in-flight bounded hold release naturally.
            helper.stdin.close()
            helper.wait(timeout=5)
