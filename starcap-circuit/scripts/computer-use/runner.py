#!/usr/bin/env python3
"""External mouse-only two-simulator controller. Gameplay network access: GET only."""

import argparse
import ctypes as C
import json
import math
import signal
import subprocess
import threading
import time
from pathlib import Path
from urllib.request import urlopen


class Point(C.Structure):
    _fields_ = [("x", C.c_double), ("y", C.c_double)]


class Mouse:
    def __init__(self):
        self.cg = C.CDLL(
            "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"
        )
        self.cf = C.CDLL(
            "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
        )
        ax = C.CDLL(
            "/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices"
        )
        ax.AXIsProcessTrusted.restype = C.c_bool
        if not ax.AXIsProcessTrusted():
            raise RuntimeError(
                "Grant Accessibility to the launching terminal/Python process"
            )
        self.cg.CGEventCreateMouseEvent.argtypes = [
            C.c_void_p,
            C.c_uint32,
            Point,
            C.c_uint32,
        ]
        self.cg.CGEventCreateMouseEvent.restype = C.c_void_p
        self.cg.CGEventPost.argtypes = [C.c_uint32, C.c_void_p]
        self.cf.CFRelease.argtypes = [C.c_void_p]
        self.last = (0, 0)

    def event(self, kind, xy):
        self.last = xy
        e = self.cg.CGEventCreateMouseEvent(None, kind, Point(*xy), 0)
        if not e:
            raise RuntimeError("CGEvent allocation failed")
        self.cg.CGEventPost(0, e)
        self.cf.CFRelease(e)

    def hold(self, xy, seconds):
        self.event(5, xy)  # mouse moved
        time.sleep(0.005)
        self.event(1, xy)  # left down
        time.sleep(0.005)
        self.event(
            6, (xy[0] + 1, xy[1])
        )  # held-state drag triggers SwiftUI DragGesture
        try:
            time.sleep(seconds)
        finally:
            self.event(2, xy)  # always release
        time.sleep(0.005)


def angle(a):
    return math.atan2(math.sin(a), math.cos(a))


def track_point(track, index):
    t = index / 240 * math.tau
    r = (61 + 12 * math.sin(3 * t)) if track else (68 + 8 * math.sin(3 * t))
    return math.sin(t) * r * 1.14, math.cos(t) * r


class Runner:
    def __init__(self, args):
        self.args = args
        self.cfg = json.loads(Path(args.config).read_text())
        self.out = Path(args.output).resolve()
        self.out.mkdir(parents=True, exist_ok=True)
        if (self.out / "actions.jsonl").exists():
            raise RuntimeError(
                "Use a new output directory; action evidence must not be overwritten"
            )
        self.mouse = Mouse()
        self.state = None
        self.stop = False
        self.error = None
        self.actions = []
        self.assertions = []
        self.stage = "Waiting to start"
        self.lock = threading.Lock()
        self.players = self.cfg["players"]
        self.scale = self.cfg.get("coordinate_scale", 1)
        self.begin = time.time()

    def log(self, file, obj):
        with (self.out / file).open("a") as f:
            f.write(json.dumps(obj) + "\n")

    def publish(self):
        s = self.state or {}
        content = {
            "stage": self.stage,
            "elapsed": round(time.time() - self.begin, 1),
            "room": self.args.room,
            "phase": s.get("phase"),
            "race": s.get("race"),
            "players": s.get("players", []),
            "actions": self.actions[-8:],
            "assertions": self.assertions,
            "error": self.error,
            "method": "Real Quartz mouse events; AUTO OFF; GET-only telemetry feedback",
        }
        tmp = self.out / "status.tmp"
        tmp.write_text(json.dumps(content))
        tmp.replace(self.out / "status.json")

    def observe(self):
        while not self.stop:
            try:
                with urlopen(
                    self.args.base + "/rooms/" + self.args.room, timeout=1
                ) as r:
                    s = json.load(r)
                self.state = s
                self.log("snapshots.jsonl", {"at": time.time(), "state": s})
            except Exception:
                pass
            self.publish()
            time.sleep(0.05)

    def player(self, label):
        name = self.players[label]["name"]
        return next(
            (
                p.copy()
                for p in (self.state or {}).get("players", [])
                if p["name"] == name
            ),
            None,
        )

    def act(self, label, control, seconds=0.09):
        xy = [v * self.scale for v in self.players[label]["controls"][control]]
        before = self.player(label)
        item = {
            "at": time.time(),
            "device": label,
            "control": control,
            "holdSeconds": seconds,
            "xy": xy,
            "before": before,
        }
        self.actions.append(
            {k: item[k] for k in ("at", "device", "control", "holdSeconds")}
        )
        self.mouse.hold(xy, seconds)
        time.sleep(0.04)
        item["after"] = self.player(label)
        item["endedAt"] = time.time()
        self.log("actions.jsonl", item)
        return item

    def check(self, name, ok, actual):
        a = {
            "at": time.time(),
            "name": name,
            "result": "passed" if ok else "failed",
            "actual": actual,
        }
        self.assertions.append(a)
        (self.out / "assertions.json").write_text(json.dumps(self.assertions, indent=2))
        print(json.dumps(a), flush=True)
        if not ok:
            raise AssertionError(name)

    def await_state(self, predicate, timeout=10):
        end = time.time() + timeout
        while time.time() < end:
            if self.state and predicate(self.state):
                return self.state
            time.sleep(0.1)
        raise TimeoutError("Timed out waiting for state during " + self.stage)

    def screenshot(self, name):
        subprocess.run(
            ["screencapture", "-x", str(self.out / (name + ".png"))], check=True
        )

    def run(self):
        observer = threading.Thread(target=self.observe, daemon=True)
        observer.start()
        try:
            time.sleep(self.args.start_delay)
            self.stage = "JOIN: two independent manual-only guests"
            self.act("A", "join")
            time.sleep(0.5)
            self.act("B", "join")
            s = self.await_state(lambda s: len(s["players"]) == 2)
            self.check(
                "Distinct guest IDs and racers",
                len({p["id"] for p in s["players"]}) == 2
                and {p["racer"] for p in s["players"]} == {0, 1},
                s["players"],
            )
            self.screenshot("joined")
            time.sleep(2)
            self.stage = "READY A only: must wait in lobby"
            self.act("A", "ready")
            time.sleep(2)
            self.check(
                "One ready guest cannot start",
                self.state["phase"] == "lobby"
                and sum(p["ready"] for p in self.state["players"]) == 1,
                self.state,
            )
            self.stage = "READY B: common countdown"
            self.act("B", "ready")
            self.await_state(lambda s: s["phase"] == "countdown")
            self.screenshot("countdown")
            self.check(
                "Both ready countdown",
                all(p["ready"] for p in self.state["players"]),
                self.state,
            )
            self.await_state(lambda s: s["phase"] == "racing")
            self.stage = "Both drivers: GAS then BRAKE response probes"
            for label in ("A", "B"):
                gas = self.act(label, "gas", 1.0)
                self.check(
                    label + " gas accelerates",
                    gas["after"]["speed"] - gas["before"]["speed"] > 5,
                    gas,
                )
                brake = self.act(label, "brake", 0.48)
                self.check(
                    label + " brake decelerates",
                    brake["before"]["speed"] - brake["after"]["speed"] > 5,
                    brake,
                )
            self.stage = "RACING: interleaved GAS / STEER / ITEM mouse input"
            self.screenshot("controls-manual")
            end = time.time() + self.args.timeout
            steer_proof = set()
            while self.state["phase"] == "racing" and time.time() < end:
                for label in ("A", "B"):
                    me = self.player(label)
                    if not me or me["finish"]:
                        continue
                    tx, tz = track_point(self.state["track"], me["index"] + 7)
                    err = angle(math.atan2(tx - me["x"], tz - me["z"]) - me["heading"])
                    if abs(err) > 0.07:
                        a = self.act(
                            label,
                            "right" if err > 0 else "left",
                            min(0.32, max(0.055, abs(err) * 0.8 / 1.55)),
                        )
                        if (
                            a["before"]
                            and a["after"]
                            and abs(
                                angle(a["after"]["heading"] - a["before"]["heading"])
                            )
                            > 0.04
                        ):
                            if label not in steer_proof:
                                self.check(label + " steering changes heading", True, a)
                                steer_proof.add(label)
                    me = self.player(label)
                    if me["item"] and me["roulette"] <= 0:
                        self.act(label, "item")
                    me = self.player(label)
                    self.act(label, "gas", 0.42 if me["speed"] < 23 else 0.1)
            self.check(
                "Both racers responded to steering",
                steer_proof == {"A", "B"},
                sorted(steer_proof),
            )
            s = self.state
            self.check(
                "Shared completed outcome without DNF",
                s["phase"] == "results"
                and all(
                    p["finish"] > 0 and p["gate"] == 17 and p["lap"] == 2
                    for p in s["players"]
                )
                and {p["rank"] for p in s["players"]} == {1, 2},
                s,
            )
            (self.out / "results.json").write_text(json.dumps(s, indent=2))
            self.check(
                "Both racers used acquired items",
                all(p["pickups"] > 0 and p["shots"] > 0 for p in s["players"]),
                [
                    {k: p[k] for k in ("name", "pickups", "shots", "hits")}
                    for p in s["players"]
                ],
            )
            self.stage = "RESULTS: shared authoritative finish order"
            self.screenshot("results")
            time.sleep(6)
            self.stage = "UI REMATCH: switch course and reset readiness"
            old_track = s["track"]
            self.act("A", "rematch")
            self.await_state(lambda s: s["phase"] == "lobby")
            self.check(
                "Rematch switches course and clears readiness",
                self.state["track"] != old_track
                and not any(p["ready"] for p in self.state["players"]),
                self.state,
            )
            self.screenshot("rematch")
            self.stage = "DONE: mouse-only two-player race completed"
            time.sleep(4)
        except BaseException as e:
            self.error = repr(e)
            self.stage = "FAILED / STOPPED"
            self.assertions.append(
                {
                    "at": time.time(),
                    "name": "Runner completed",
                    "result": "failed",
                    "actual": repr(e),
                }
            )
            (self.out / "assertions.json").write_text(
                json.dumps(self.assertions, indent=2)
            )
            self.screenshot("failure")
            raise
        finally:
            self.mouse.event(2, self.mouse.last)
            self.stop = True
            observer.join(timeout=2)
            self.publish()


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--config", default=str(Path(__file__).with_name("geometry.json")))
    ap.add_argument("--output", required=True)
    ap.add_argument("--room", default="TOUCH")
    ap.add_argument("--base", default="http://127.0.0.1:8791")
    ap.add_argument("--start-delay", type=float, default=8)
    ap.add_argument("--timeout", type=float, default=170)
    args = ap.parse_args()
    signal.signal(signal.SIGTERM, lambda *a: (_ for _ in ()).throw(KeyboardInterrupt()))
    Runner(args).run()
