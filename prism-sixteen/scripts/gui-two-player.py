#!/usr/bin/env python3
"""External native-GUI test. No WebSocket client or app-internal automation.

AX locates targets; mouse CGEvents and System Events keyboard input drive the UI.
Read-only public chart/server logs schedule the single pointer. See GUI-TESTING.md.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def command(args, **kwargs):
    return subprocess.run([str(x) for x in args], check=True, text=True, **kwargs)


def rows(path):
    if not path.exists():
        return []
    # A final incomplete line is an in-progress writer, not a protocol message.
    return [json.loads(x) for x in path.read_text().splitlines(keepends=True)
            if x.endswith("\n")]


def wait_for(predicate, description, timeout=15):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        value = predicate()
        if value:
            return value
        time.sleep(0.12)
    raise AssertionError("Timed out: " + description)


class Run:
    def __init__(self, args):
        self.args = args
        self.out = args.output.resolve()
        self.out.mkdir(parents=True, exist_ok=False)
        self.events = (self.out / "gui-events.jsonl").open("w", buffering=1)
        self.assertions = []
        self.gui = None
        self.server = None
        self.windows = []
        self.rounds = []
        self.report = {"command": sys.argv, "autoplay": False, "directProtocolInput": False}

    def log(self, event, **detail):
        row = {"event": event, "epoch": time.time(), **detail}
        self.events.write(json.dumps(row) + "\n")
        if event == "step":
            print(json.dumps(row), flush=True)

    def check(self, name, passed, detail=None):
        self.assertions.append({"assertion": name, "result": "passed" if passed else "failed",
                                "detail": detail})
        (self.out / "assertions.json").write_text(json.dumps(self.assertions, indent=2))
        if not passed:
            raise AssertionError(name + ": " + str(detail))

    def bridge(self, **request):
        self.gui.stdin.write(json.dumps(request) + "\n")
        self.gui.stdin.flush()
        result = json.loads(self.gui.stdout.readline())
        self.log("gui", request=request, response=result)
        if not result.get("ok"):
            raise RuntimeError(result)
        return result

    def elements(self, player):
        return self.bridge(command="inspect", window=self.windows[player])["elements"]

    @staticmethod
    def find(elements, identifier=None, label=None):
        matches = [e for e in elements if (
            e["id"] == identifier if identifier else
            e["role"] == "AXButton" and label in e["description"])]
        return matches[0] if len(matches) == 1 else None

    def target(self, player, identifier=None, label=None):
        return wait_for(lambda: self.find(self.elements(player), identifier, label),
                        f"player {player} {identifier or label}")

    def click(self, player, target, **extra):
        self.check_target(player, target)
        x, y, w, h = target["bounds"]
        return self.bridge(command="click", window=self.windows[player],
                           point=[x + w / 2, y + h / 2], **extra)

    def check_target(self, player, target):
        if not target["enabled"]:
            raise AssertionError("Disabled target: " + str(target))
        x, y, w, h = target["bounds"]
        wx, wy, ww, wh = self.window_bounds[player]
        if not (w > 0 and h > 0 and wx <= x and wy <= y
                and x + w <= wx + ww + 1 and y + h <= wy + wh + 1):
            raise AssertionError("Target outside visible window: " + str(target))

    def field(self, player, identifier, value):
        self.click(player, self.target(player, identifier))
        self.bridge(command="text", text=value)
        wait_for(lambda: self.target(player, identifier)["value"] == value,
                 f"{identifier} contains typed text")

    def screenshot(self, name):
        command(["screencapture", "-x", self.out / (name + ".png")])
        self.log("screenshot", path=name + ".png")

    def states(self):
        return [r for r in rows(self.out / "wire.jsonl") if r["message"]["type"] == "state"]

    def room(self):
        states = self.states()
        return states[-1]["message"]["room"] if states else {}

    def prepare(self):
        if self.args.device_a == self.args.device_b:
            raise ValueError("Two DIFFERENT simulator UDIDs are required")
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", self.args.port))  # Never kill an existing server.
        devices = json.loads(command(["xcrun", "simctl", "list", "devices", "--json"],
                                     capture_output=True).stdout)
        devices = [d for group in devices["devices"].values() for d in group]
        selected = []
        for udid in [self.args.device_a, self.args.device_b]:
            device = next(d for d in devices if d["udid"] == udid and d["isAvailable"])
            selected.append(device)
            if device["state"] != "Booted":
                command(["xcrun", "simctl", "boot", udid])
            command(["xcrun", "simctl", "bootstatus", udid, "-b"])
        if selected[0]["name"] == selected[1]["name"]:
            raise ValueError("Use uniquely named simulators (simctl rename while shutdown)")
        command(["open", "-a", "Simulator"])
        command(["xcrun", "swiftc", ROOT / "scripts/GUIInput.swift", "-o",
                 self.out / "gui-input"])
        self.gui = subprocess.Popen([str(self.out / "gui-input")], stdin=subprocess.PIPE,
                                    stdout=subprocess.PIPE, text=True, bufsize=1)
        discovery = wait_for(lambda: self.bridge(command="windows"), "Simulator AX")
        self.check("macOS Accessibility permission is available", discovery["trusted"])
        display_w, display_h = discovery["display"]
        for device in selected:
            matches = [w for w in discovery["windows"]
                       if w["title"].startswith(device["name"] + " – ")]
            if len(matches) != 1:
                raise ValueError(f"Open one unique Simulator window for {device['name']}")
            self.windows.append(matches[0]["title"])
        bounds = [next(w["bounds"] for w in discovery["windows"] if w["title"] == title)
                  for title in self.windows]
        width = sum(b[2] for b in bounds)
        self.check("Both complete windows fit the main display",
                   width + 40 < display_w and max(b[3] for b in bounds) + 120 < display_h,
                   {"display": discovery["display"], "bounds": bounds})
        gap = (display_w - width) / 3
        self.window_bounds = []
        x = gap
        for title, rect in zip(self.windows, bounds):
            positioned = self.bridge(command="moveWindow", window=title,
                                     point=[x, max(35, (display_h - rect[3]) / 4)])
            self.window_bounds.append(positioned["bounds"])
            x += rect[2] + gap
        server_log = (self.out / "server-console.log").open("w")
        self.server = subprocess.Popen(["node", str(ROOT / "scripts/gui-trace.mjs"),
                                        str(self.out), str(self.args.port)],
                                       stdout=server_log, stderr=subprocess.STDOUT)
        wait_for(lambda: any(r["event"] == "listening" for r in rows(self.out / "server.jsonl")),
                 "test-owned WebSocket server")
        self.report.update({"devices": selected, "windows": self.window_bounds})
        self.report["launchCommands"] = []
        for i, device in enumerate(selected):
            udid = device["udid"]
            subprocess.run(["xcrun", "simctl", "terminate", udid, "ai.prismsixteen.game"],
                           capture_output=True, check=False)
            command(["xcrun", "simctl", "install", udid, self.args.app])
            launch = ["xcrun", "simctl", "launch", "--stdout=" + str(self.out / f"player-{i}.log"),
                      "--stderr=" + str(self.out / f"player-{i}-errors.log"), udid,
                      "ai.prismsixteen.game", "--name", "NEW PLAYER",
                      "--server", f"ws://127.0.0.1:{self.args.port}"]
            command(launch, env={**os.environ, "SIMCTL_CHILD_NSUnbufferedIO": "YES"})
            self.report["launchCommands"].append(launch)
            self.target(i, "guestName")
        self.check("Both launch commands omit autoplay/create/join drivers",
                   all("--autoplay" not in c and "--create" not in c and "--join" not in c
                       for c in self.report["launchCommands"]))
        (self.out / "provenance.json").write_text(json.dumps(self.report, indent=2))
        self.log("step", text="READY: two native apps; waiting for external GUI play")
        self.screenshot("01-selection")
        if self.args.wait_for_start:
            wait_for(lambda: (self.out / "START").exists(), "START file / recording ready", 300)

    def lobby(self):
        self.log("step", text="GUI names, BASIC selection, CREATE and JOIN")
        for i, name in enumerate(["NOVA", "ECHO"]):
            self.field(i, "guestName", name)
            self.click(i, self.target(i, label="BASIC"))
        self.click(0, self.target(0, "createRoom"))
        code = wait_for(lambda: self.room().get("code"), "GUI-created room")
        self.field(1, "roomCode", code)
        self.click(1, self.target(1, "joinRoom"))
        room = wait_for(lambda: self.room() if len(self.room().get("players", [])) == 2 else None,
                        "two joined players")
        players = room["players"]
        self.check("GUI create/join yields distinct NOVA/ECHO identities",
                   {p["name"] for p in players} == {"NOVA", "ECHO"}
                   and len({p["id"] for p in players}) == 2, players)
        self.check("GUI BASIC selection reaches real server", room["difficulty"] == "BASIC", room)
        self.screenshot("02-lobby")

    def play(self, round_number):
        self.log("step", text=f"Round {round_number}: GUI ready; single-pointer native touches")
        for i in [0, 1]:
            wait_for(lambda: self.target(i, "readyButton")["enabled"], "synchronized ready control")
            self.click(i, self.target(i, "readyButton"))
            if i == 0:
                time.sleep(1.2)  # Verify the ready gate while only player A is ready.
                room = self.room()
                self.check(f"Round {round_number}: one ready player cannot start",
                           room["phase"] != "playing", room)
        room = wait_for(lambda: self.room() if self.room().get("phase") == "playing" else None,
                        "both-ready countdown")
        self.check(f"Round {round_number}: frozen results reset", room["results"] == [])
        self.check(f"Round {round_number}: scores reset", all(p["score"] == 0 for p in room["players"]))
        self.check(f"Round {round_number}: new shared epoch",
                   room["round"] == round_number and
                   (not self.rounds or room["startAt"] > self.rounds[-1]["startAt"]), room["startAt"])
        panels = []
        for i in [0, 1]:
            elements = self.elements(i)
            targets = [self.find(elements, f"panel{cell + 1}") for cell in range(16)]
            self.check(f"Round {round_number}: player {i} exposes 16 native panel bounds",
                       all(targets))
            panels.append(targets)
        self.screenshot(f"round-{round_number}-countdown")
        catalog = json.loads((ROOT / "Resources/catalog.json").read_text())
        song = next(s for s in catalog if s["id"] == room["songID"])
        # Only the first cell at each authored instant: no simulated simultaneous chords.
        singles = {note["time"]: note for note in reversed(song["charts"][room["difficulty"]])}
        schedule = []
        for index, note in enumerate(sorted(singles.values(), key=lambda n: n["time"])):
            for player, delay in [(0, -0.02), (1, 0.075)]:
                if player == 1 and index % 5 == 0:
                    continue  # Deliberately different performance, never forced scores.
                due = room["startAt"] + note["time"] + delay
                if due > time.time() + 0.25:
                    schedule.append({"player": player, "epoch": due, "cell": note["cell"],
                                     "noteTime": note["time"], "delay": delay})
        schedule.sort(key=lambda n: n["epoch"])
        (self.out / f"round-{round_number}-schedule.json").write_text(json.dumps(schedule, indent=2))
        photographed = False
        for event in schedule:
            # The persistent native helper waits until due; no app clock is modified.
            response = self.click(event["player"], panels[event["player"]][event["cell"]],
                                  epoch=event["epoch"], hold=0.035)
            self.log("panel-input", round=round_number, **event,
                     actualDownEpoch=response["downEpoch"])
            if not photographed and event["noteTime"] > 16:
                self.screenshot(f"round-{round_number}-gameplay")
                photographed = True
        final = wait_for(lambda: self.room() if self.room().get("phase") == "results" else None,
                         "complete authoritative result", song["duration"] + 15)
        time.sleep(1)
        self.screenshot(f"round-{round_number}-results")
        self.rounds.append(final)
        self.check(f"Round {round_number}: both final scores are meaningful",
                   all(p["score"] > 0 for p in final["results"]), final["results"])
        self.check(f"Round {round_number}: performances differ",
                   len({p["score"] for p in final["results"]}) == 2)
        # Capture native accessibility text, not just server state.
        for i in [0, 1]:
            ui = self.elements(i)
            (self.out / f"round-{round_number}-player-{i}-results-ui.json").write_text(
                json.dumps(ui, indent=2))
        self.log("step", text=f"Round {round_number}: both complete results visible",
                 results=final["results"])
        if round_number < self.args.rounds:
            time.sleep(3)

    def validate(self):
        wire = rows(self.out / "wire.jsonl")
        inputs = [r for r in wire if r["direction"] == "client-to-server"
                  and r["message"]["type"] == "tap"]
        self.check("All native input messages are source=touch",
                   bool(inputs) and all(r["message"].get("source") == "touch" for r in inputs))
        sockets = {r["socket"] for r in inputs}
        self.check("Both distinct native WebSocket clients send touch inputs", len(sockets) == 2)
        for i in [0, 1]:
            text = (self.out / f"player-{i}.log").read_text()
            self.check(f"Player {i}: no internal driver ran", "PRISM driver" not in text)
        states = self.states()
        for final in self.rounds:
            n = final["round"]
            result_rows = [r for r in states if r["message"]["room"]["round"] == n
                           and r["message"]["room"]["phase"] == "results"]
            self.check(f"Round {n}: identical frozen results delivered to both sockets",
                       {r["socket"] for r in result_rows
                        if r["message"]["room"]["results"] == final["results"]} == sockets)
            for player in final["results"]:
                judgments = {key: player[key] for key in ["perfect", "great", "good", "miss"]}
                good = sum(player[key] for key in ["perfect", "great", "good"])
                self.check(f"Round {n}: {player['name']} at least 15 scored native touches",
                           good >= 15, judgments)
            for sock in sockets:
                playing = [r["message"]["room"] for r in states if r["socket"] == sock
                           and r["message"]["room"]["round"] == n
                           and r["message"]["room"]["phase"] == "playing"]
                self.check(f"Round {n}: socket {sock} receives both live nonzero scores",
                           any(all(p["score"] > 0 for p in r["players"]) for r in playing))
                self.check(f"Round {n}: socket {sock} uses the shared epoch",
                           bool(playing) and all(r["startAt"] == final["startAt"] for r in playing))
        errors = [r for r in wire if r["message"]["type"] == "error"]
        self.check("No protocol errors occurred", not errors, errors)
        self.log("step", text="PASS: GUI-only input assertions; both live results left visible")

    def finish(self):
        self.report["rounds"] = self.rounds
        self.report["assertions"] = self.assertions
        (self.out / "provenance.json").write_text(json.dumps(self.report, indent=2))
        # Leave the apps and test server alive for inspection. Record its PID.
        if self.server:
            (self.out / "server.pid").write_text(str(self.server.pid) + "\n")
        if self.gui:
            self.gui.stdin.close()
            self.gui.wait(timeout=5)
        self.events.close()
        manifest = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in self.out.iterdir() if p.is_file()
                    and p.suffix not in [".jsonl", ".log"] and p.name != "sha256.json"}
        (self.out / "sha256.json").write_text(json.dumps(manifest, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device-a", required=True, help="First bootable iPhone Simulator UDID")
    parser.add_argument("--device-b", required=True, help="Second, different Simulator UDID")
    parser.add_argument("--output", required=True, type=Path, help="New evidence directory")
    parser.add_argument("--app", type=Path,
                        default=ROOT / "build/Build/Products/Debug-iphonesimulator/PrismSixteen.app")
    parser.add_argument("--port", type=int, default=43116)
    parser.add_argument("--rounds", type=int, choices=[1, 2], default=2)
    parser.add_argument("--wait-for-start", action="store_true",
                        help="After setup wait up to 300s for OUTPUT/START, allowing capture setup")
    args = parser.parse_args()
    run = Run(args)
    try:
        run.prepare()
        run.lobby()
        for n in range(1, args.rounds + 1):
            run.play(n)
        run.validate()
    except Exception as error:
        run.assertions.append({"assertion": "Procedure completes", "result": "failed",
                               "detail": str(error)})
        (run.out / "assertions.json").write_text(json.dumps(run.assertions, indent=2))
        run.log("step", text="FAIL", error=str(error))
        raise
    finally:
        run.finish()


if __name__ == "__main__":
    main()
