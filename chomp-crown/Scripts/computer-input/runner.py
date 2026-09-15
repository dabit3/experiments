#!/usr/bin/env python3
"""Real two-player OS-touch test. Python stdlib; native Swift CGEvent + Vision.

No WebSocket client, direction deep link, built-in driver, or game-state mutation.
prepare-only + resume are the same setup/execution functions as the default run.
"""
import argparse
import collections
import ctypes
import hashlib
import heapq
import json
import math
import os
import plistlib
from pathlib import Path
import re
import signal
import shutil
import socket
import subprocess
import sys
import time

from result_ocr import modal_lines, result_matches

HERE = Path(__file__).resolve().parent
BUNDLE = "games.chompcrown.neon"
VERSION = "2.1"
SUPPORTED_TYPES = {
    "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro": 402,
    "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max": 440,
}
DIRS = {"up": (0, -1), "right": (1, 0), "down": (0, 1), "left": (-1, 0)}


class Timebase(ctypes.Structure):
    _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]


LIB = ctypes.CDLL(None)
LIB.mach_absolute_time.restype = ctypes.c_uint64
TB = Timebase()
LIB.mach_timebase_info(ctypes.byref(TB))


def clock():
    return {"wallUnix": time.time(),
            "hostSeconds": LIB.mach_absolute_time() * TB.numer / TB.denom / 1e9}


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def run(*argv, **kwargs):
    return subprocess.run([str(a) for a in argv], check=True, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, **kwargs).stdout


def source_hashes():
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(HERE.iterdir()) if p.suffix in (".py", ".swift", ".mjs", ".md", ".json")}


def resolve_devices(config):
    if not isinstance(config, list) or len(config) != 2:
        raise ValueError("--devices must contain exactly two objects")
    allowed = {"udid", "pointWidth"}
    for item in config:
        if not isinstance(item, dict) or set(item) - allowed or not isinstance(item.get("udid"), str):
            raise ValueError("Device objects support only required udid and optional pointWidth")
    if config[0]["udid"].upper() == config[1]["udid"].upper():
        raise ValueError("Two distinct simulator UDIDs are required")
    inventory = json.loads(run("xcrun", "simctl", "list", "devices", "available", "-j"))["devices"]
    types = {t["identifier"]: t for t in json.loads(run("xcrun", "simctl", "list", "devicetypes", "-j"))["devicetypes"]}
    result = []
    for index, entry in enumerate(config):
        matches = [(runtime, d) for runtime, devices in inventory.items() for d in devices
                   if d["udid"].upper() == entry["udid"].upper() and d.get("isAvailable")]
        if len(matches) != 1:
            raise ValueError(f"UDID unavailable or ambiguous: {entry['udid']}")
        runtime, device = matches[0]
        type_id = device["deviceTypeIdentifier"]
        if type_id not in SUPPORTED_TYPES:
            raise ValueError("Geometry currently supports iPhone 17 Pro / Pro Max portrait only")
        profile = Path(types[type_id]["bundlePath"]) / "Contents/Resources/profile.plist"
        derived = None
        if profile.exists():
            with profile.open("rb") as f:
                data = plistlib.load(f)
            pixels, scale = data.get("mainScreenWidth"), data.get("mainScreenScale")
            if isinstance(pixels, (int, float)) and isinstance(scale, (int, float)) and scale > 0:
                derived = pixels / scale
        supplied = entry.get("pointWidth")
        if supplied is not None and (type(supplied) not in (int, float) or not math.isfinite(supplied)):
            raise ValueError("pointWidth must be a finite number")
        if derived is not None and supplied is not None and derived != supplied:
            raise ValueError("Configured pointWidth conflicts with simulator profile")
        width = derived if derived is not None else supplied
        if width != SUPPORTED_TYPES[type_id]:
            raise ValueError("Missing/unsupported pointWidth; configure 402 for Pro or 440 for Pro Max")
        result.append({"name": ("Gold", "Rose")[index], "udid": device["udid"],
                       "deviceName": device["name"], "typeIdentifier": type_id,
                       "runtimeIdentifier": runtime, "pointWidth": width,
                       "widthSource": str(profile) if derived is not None else "caller-config"})
    if result[0]["deviceName"] == result[1]["deviceName"]:
        raise ValueError("Simulator device names must be unique for unambiguous visible-window targeting")
    return result


def cleanup(output):
    session = json.loads((Path(output) / "session.json").read_text())
    pid = session["serverPID"]
    cmd = run("ps", "-p", pid, "-o", "command=").strip()
    expected = session.get("observerScript", str(HERE / "observe-server.mjs"))
    if expected not in cmd or str(Path(output).resolve() / "observations.jsonl") not in cmd:
        raise RuntimeError("PID no longer matches this run's exact observer command; refusing cleanup")
    os.kill(pid, signal.SIGTERM)
    print(f"Sent SIGTERM to this run's verified observer PID {pid}; simulators remain open.")


class Mouse:
    def __init__(self):
        self.p = subprocess.Popen([str(HERE / "mouse")], stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, text=True, bufsize=1)

    def call(self, op, **kw):
        self.p.stdin.write(json.dumps(dict(op=op, **kw)) + "\n")
        self.p.stdin.flush()
        answer = json.loads(self.p.stdout.readline())
        if "error" in answer:
            raise RuntimeError(answer["error"])
        return answer

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=5)


class Test:
    def __init__(self, args):
        self.a, self.out = args, Path(args.out).resolve()
        self.repo = Path(args.repo).resolve()
        self.devices = []
        self.results = {"method": "external OS CGEvent touch; read-only snapshot planning",
                        "started": clock(), "assertions": [], "metrics": {}}
        self.mouse = None
        self.audio = self.video = None
        self.latest = None
        self.pending = ""
        self.positions = collections.defaultdict(set)
        self.sequences = collections.defaultdict(set)
        self.scores = collections.defaultdict(int)
        self.clicks = collections.Counter()
        self.visits = collections.defaultdict(collections.Counter)
        self.obs = None
        self.owns_output = False

    def event(self, event, **kw):
        record = dict(clock(), event=event, **kw)
        with (self.out / "actions.jsonl").open("a") as f:
            f.write(json.dumps(record) + "\n")
        print(json.dumps(record), flush=True)

    def check(self, name, ok, detail=None):
        item = {"name": name, "result": "passed" if ok else "failed", "detail": detail}
        self.results["assertions"].append(item)
        self.event("assertion", **item)
        save(self.out / "results.json", self.results)
        if not ok:
            raise AssertionError(name + ": " + str(detail))

    def start_mouse(self):
        executable = HERE / "mouse"
        if not executable.exists() or executable.stat().st_mtime < (HERE / "mouse.swift").stat().st_mtime:
            run("swiftc", HERE / "mouse.swift", "-o", executable)
        self.mouse = Mouse()
        info = self.mouse.call("info")
        self.check("Accessibility, event posting and screen capture permitted",
                   all(info.get(k) for k in ("trusted", "postEvents", "screenCapture")), info)
        self.screen = info

    def read(self):
        if self.obs is None:
            self.obs = (self.out / "observations.jsonl").open()
        self.pending += self.obs.read()
        lines = self.pending.split("\n")
        self.pending = lines.pop()
        for line in lines:
            if not line:
                continue
            s = json.loads(line)["state"]
            self.latest = s
            for p in s["players"]:
                self.positions[p["id"]].add((round(p["x"], 1), round(p["y"], 1)))
                self.sequences[p["id"]].add(p["lastSeq"])
                self.scores[p["id"]] = max(self.scores[p["id"]], p["score"])
        return self.latest

    def until(self, predicate, seconds=15):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            s = self.read()
            if s and predicate(s):
                return s
            time.sleep(.08)
        raise TimeoutError(f"State condition timed out after {seconds}s: {self.latest}")

    def native_image(self, d, label):
        path = self.out / f"{d['name'].lower()}-{label}.png"
        run("xcrun", "simctl", "io", d["udid"], "screenshot", path)
        return path

    def screenshot(self, label):
        path = self.out / f"dual-{label}.png"
        run("/usr/sbin/screencapture", "-x", path)
        self.event("screenshot", path=str(path))
        return path

    def texts(self, d, label):
        path = self.native_image(d, label)
        texts = self.mouse.call("ocr", path=str(path))["texts"]
        save(self.out / f"{d['name'].lower()}-{label}-ocr.json", texts)
        return texts

    def target(self, d, text, label):
        texts = self.texts(d, label)
        matches = [t for t in texts if t["text"].upper() == text.upper()]
        if len(matches) != 1:
            raise RuntimeError(f"Expected one visible {text!r}: {texts}")
        t, v = matches[0], d["viewport"]
        return (v["x"] + (t["x"] + t["width"]/2) * v["width"],
                v["y"] + (1 - t["y"] - t["height"]/2) * v["height"])

    def click(self, d, x, y, purpose, **extra):
        response = self.mouse.call("click", title=d["title"], x=float(x), y=float(y))
        self.event("os-click", player=d["name"], purpose=purpose, x=x, y=y,
                   response=response, **extra)

    def button(self, d, text, label):
        self.click(d, *self.target(d, text, label), purpose=text)

    def frames(self):
        windows = self.mouse.call("windows")["windows"]
        frames = []
        for d in self.devices:
            w = next(w for w in windows if w["title"] == d["title"])
            f = w["frame"]
            if not (f["x"] >= 0 and f["y"] >= 25 and
                    f["x"] + f["width"] <= self.screen["screenWidth"] and
                    f["y"] + f["height"] <= self.screen["screenHeight"] - 50):
                raise RuntimeError(f"Complete simulator window not visible: {w}")
            new_view = self.mouse.call("viewport", title=d["title"])["frame"]
            if "viewport" in d and d["viewport"] != new_view:
                raise RuntimeError("Simulator viewport moved during test; refusing stale coordinates")
            d["viewport"] = new_view
            frames.append(f)
        a, b = frames
        self.check("Both complete named devices are side-by-side",
                   a["x"] + a["width"] <= b["x"] or b["x"] + b["width"] <= a["x"],
                   {"devices": self.devices})

    def prepare(self):
        if not self.a.devices:
            raise ValueError("--devices JSON is required for a new run")
        self.devices = resolve_devices(json.loads(Path(self.a.devices).read_text()))
        self.a.port = 8873 if self.a.port is None else self.a.port
        self.out.mkdir(parents=False, exist_ok=False)
        self.owns_output = True
        snapshot = self.out / "tested-source"
        snapshot.mkdir()
        hashes = source_hashes()
        for name in hashes:
            shutil.copy2(HERE / name, snapshot / name)
        versions = {"harness": VERSION, "python": sys.version, "node": run("node", "--version").strip(),
                    "swift": run("swiftc", "--version").strip(), "xcode": run("xcodebuild", "-version").strip(),
                    "ffmpeg": run("ffmpeg", "-version").splitlines()[0], "macOS": run("sw_vers").strip()}
        save(self.out / "source-manifest.json", {"sha256": hashes, "versions": versions})
        self.event("harness-identity", versions=versions, sha256=hashes)
        self.start_mouse()
        app = self.repo / "build/Build/Products/Release-iphonesimulator/ChompCrown.app"
        if not app.is_dir():
            raise RuntimeError("Build the unchanged Release iOS simulator app first")
        if not (self.repo / "Server/node_modules/ws/package.json").exists():
            raise RuntimeError("Run npm ci --prefix Server first")
        with socket.socket() as s:
            if s.connect_ex(("127.0.0.1", self.a.port)) == 0:
                raise RuntimeError("Server port occupied; stop only your own previous test server")
        log = (self.out / "server.log").open("w")
        server = subprocess.Popen(["node", str(HERE / "observe-server.mjs"), str(self.repo),
                                   str(self.out / "observations.jsonl"), str(self.a.port)],
                                  stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        log.close()
        self.session = {"serverPID": server.pid, "port": self.a.port,
                        "repo": str(self.repo), "devices": self.devices,
                        "observerScript": str(HERE / "observe-server.mjs"),
                        "sourceHashes": hashes, "setupCommands": [], "created": clock()}
        save(self.out / "session.json", self.session)
        for d in self.devices:
            booted = run("xcrun", "simctl", "list", "devices", "booted", "-j")
            if d["udid"] not in booted:
                run("xcrun", "simctl", "boot", d["udid"])
            run("xcrun", "simctl", "bootstatus", d["udid"], "-b")
            run("xcrun", "simctl", "install", d["udid"], app)
            subprocess.run(["xcrun", "simctl", "terminate", d["udid"], BUNDLE],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            command = ["xcrun", "simctl", "launch",
                       f"--stdout={self.out / (d['name'].lower() + '.log')}",
                       f"--stderr={self.out / (d['name'].lower() + '-stderr.log')}",
                       d["udid"], BUNDLE, "--server", f"ws://127.0.0.1:{self.a.port}",
                       "--name", d["name"]]
            if d["name"] == "Gold":
                command += ["--create"]
            else:
                command += ["--room", self.room, "--join"]
            env = dict(os.environ, SIMCTL_CHILD_NSUnbufferedIO="YES")
            run(*command, env=env)
            self.session["setupCommands"].append(command)
            state = self.until(lambda s: any(p["name"] == d["name"] for p in s["players"]))
            self.room = state["code"]
        run("open", "-a", "Simulator")
        windows = self.mouse.call("windows")["windows"]
        x = 60
        for d in self.devices:
            matches = [w for w in windows if w["title"].startswith(d["deviceName"] + " –")]
            if len(matches) != 1:
                raise RuntimeError(f"Expected one visible Simulator window for {d['deviceName']}")
            w = matches[0]
            d["title"] = w["title"]
            self.mouse.call("place", title=d["title"], x=float(x), y=45.0)
            x += w["frame"]["width"] + 60
        time.sleep(.5)
        self.frames()
        self.session.update(room=self.room, devices=self.devices)
        save(self.out / "session.json", self.session)
        self.screenshot("lobby")
        self.check("Two distinct native peers share one real lobby",
                   self.latest["phase"] == "lobby" and len(self.latest["players"]) == 2 and
                   len({p["id"] for p in self.latest["players"]}) == 2, self.latest["players"])
        for d in self.devices:
            texts = self.texts(d, "lobby")
            self.check(f"{d['name']} has no built-in driver label",
                       not any("AUTOMATED INPUT" in t["text"] for t in texts), texts)

    def resume(self):
        self.session = json.loads((self.out / "session.json").read_text())
        if str(self.repo) != self.session["repo"]:
            raise ValueError("--repo conflicts with prepared session")
        if self.a.port is not None and self.a.port != self.session["port"]:
            raise ValueError("--port conflicts with prepared session")
        self.a.port = self.session["port"]
        if source_hashes() != self.session["sourceHashes"]:
            raise ValueError("Harness source changed after prepare; refusing to mix versions")
        stored_config = [{"udid": d["udid"], "pointWidth": d["pointWidth"]} for d in self.session["devices"]]
        resolved = resolve_devices(json.loads(Path(self.a.devices).read_text()) if self.a.devices else stored_config)
        keys = ("udid", "pointWidth", "deviceName", "typeIdentifier", "runtimeIdentifier")
        if any(any(a[k] != b[k] for k in keys) for a, b in zip(resolved, self.session["devices"])):
            raise ValueError("--devices or current simulator metadata conflicts with prepared session")
        self.results = json.loads((self.out / "results.json").read_text())
        self.owns_output = True
        self.devices = self.session["devices"]
        self.room = self.session["room"]
        self.start_mouse()
        self.frames()
        self.until(lambda s: s["code"] == self.room and s["phase"] == "lobby")

    def capture_start(self):
        if not self.a.record:
            return
        audio_exe = HERE / "capture-audio"
        if not audio_exe.exists() or audio_exe.stat().st_mtime < (HERE / "capture-audio.swift").stat().st_mtime:
            run("swiftc", HERE / "capture-audio.swift", "-o", audio_exe)
        audio_command = [str(audio_exe), str(self.out / "live-audio"),
                         str(2 * self.a.match_timeout + 100)]
        video_command = ["ffmpeg", "-y", "-nostdin", "-hide_banner", "-debug_ts",
                         "-f", "avfoundation", "-framerate", "30",
                         "-i", f"{self.a.screen_index}:none", "-c:v", "h264_videotoolbox",
                         "-b:v", "6000k", "-fps_mode", "passthrough",
                         str(self.out / "screen-raw.mkv")]
        self.audio = subprocess.Popen(audio_command, stdout=(self.out / "live-audio.log").open("w"),
                                      stderr=subprocess.STDOUT)
        self.video = subprocess.Popen(video_command, stdout=(self.out / "screen-capture.log").open("w"),
                                      stderr=subprocess.STDOUT)
        save(self.out / "capture.json", {"started": clock(), "audioCommand": audio_command,
             "videoCommand": video_command, "audioPID": self.audio.pid, "videoPID": self.video.pid,
             "timebase": {"numer": TB.numer, "denom": TB.denom},
             "alignment": "Use actual audio-buffer hostSeconds and video demuxer PTS only"})
        end = time.monotonic() + 25
        while time.monotonic() < end:
            video_log = (self.out / "screen-capture.log").read_text(errors="replace")
            if ("demuxer ->" in video_log and "type:video" in video_log and
                (self.out / "screen-raw.mkv").exists() and
                (self.out / "screen-raw.mkv").stat().st_size > 10000 and
                "CAPTURE READY" in (self.out / "live-audio.log").read_text()):
                self.event("capture-ready")
                return
            if self.video.poll() is not None or self.audio.poll() is not None:
                break
            time.sleep(.25)
        raise RuntimeError("Capture not ready; no match started. Preserve logs, do not silently retry.")

    def calibrate(self, d):
        # Visible STEER center is ~24pt above the middle D-pad row in this app.
        _, sy = self.target(d, "STEER", "controls")
        v = d["viewport"]
        scale = v["width"] / d["pointWidth"]
        cx, cy = v["x"] + v["width"]/2, sy + 24*scale
        d["controls"] = {name: [cx + dx*49*scale, cy + dy*45*scale]
                         for name, (dx, dy) in DIRS.items()}
        self.event("calibration", player=d["name"], controls=d["controls"])

    def direction(self, d, direction, state, reason):
        p = next(p for p in state["players"] if p["name"] == d["name"])
        self.click(d, *d["controls"][direction], purpose="D-pad " + direction,
                   tick=state["tick"], round=state["round"], id=p["id"],
                   observedPosition=[p["x"], p["y"]], planned=reason)
        self.clicks[p["id"]] += 1

    def choose(self, state, p):
        """Replan from current telemetry. Dijkstra reward targets, hazard cost.

        Each player runs the same competitive policy; neither is designated to lose.
        Upcoming tile respects continuous motion so queued turns occur at intersections.
        """
        maze = state["maze"]
        def walk(x, y):
            return 0 <= y < len(maze) and 0 <= x < len(maze[0]) and maze[y][x] != "#"
        x, y = p["x"], p["y"]
        dx, dy = DIRS[p["dir"]]
        cx, cy = math.floor(x + .5), math.floor(y + .5)
        if abs(x-cx) > .03 or abs(y-cy) > .03:
            cx = math.ceil(x-.001) if dx > 0 else math.floor(x+.001) if dx < 0 else cx
            cy = math.ceil(y-.001) if dy > 0 else math.floor(y+.001) if dy < 0 else cy
        start = (cx, cy)
        self.visits[p["id"]][start] += 1
        dangers = [(g["x"], g["y"]) for g in state["ghosts"] if g["respawn"] <= 0]
        foes = [q for q in state["players"] if q["id"] != p["id"] and q["alive"]]
        if p["power"] <= 0:
            dangers += [(q["x"], q["y"]) for q in foes if q["power"] > 0]
        pellets = set(state["pellets"])
        powers = {(q["x"], q["y"]) for q in state["powers"] if q["active"]}
        queue = [(0, cx, cy, "")]
        seen, candidates = set(), []
        while queue:
            cost, ax, ay, first = heapq.heappop(queue)
            if (ax, ay) in seen:
                continue
            seen.add((ax, ay))
            reward = 0
            if f"{ax},{ay}" in pellets:
                reward = 12
            if (ax, ay) in powers:
                reward = 95 if p["power"] < 2 else 35
            if p["power"] > 1.8:
                if any(abs(ax-q["x"])+abs(ay-q["y"]) < 1.2 and q["power"] <= 0 for q in foes):
                    reward = 200
                if any(abs(ax-gx)+abs(ay-gy) < .9 for gx, gy in dangers):
                    reward = max(reward, 65)
            if first and reward:
                merit = reward / (cost + 2) - self.visits[p["id"]][(ax, ay)] * .08
                candidates.append((merit, first, [ax, ay], reward))
            for direction, (vx, vy) in DIRS.items():
                nx, ny = ax+vx, ay+vy
                if not walk(nx, ny) or (nx, ny) in seen:
                    continue
                danger = 0
                if p["power"] <= 0 and p["shield"] < .4:
                    distance = min((math.hypot(nx-gx, ny-gy) for gx, gy in dangers), default=100)
                    danger = max(0, 3.5-distance) * 8
                heapq.heappush(queue, (cost + 1 + danger, nx, ny, first or direction))
        if candidates:
            _, direction, goal, reward = max(candidates)
            return direction, {"goal": goal, "reward": reward, "fromUpcomingTile": start}
        options = [d for d, (vx, vy) in DIRS.items() if walk(cx+vx, cy+vy)]
        return (options[0] if options else p["dir"]), {"fallback": "walkable"}

    def compete(self, match_number):
        end = time.monotonic() + self.a.match_timeout
        captured, last_frames, last_phase = set(), 0, None
        while time.monotonic() < end:
            state = self.read()
            if state["phase"] != last_phase:
                self.event("phase", match=match_number, phase=state["phase"], round=state["round"])
                last_phase = state["phase"]
            if state["phase"] == "matchOver":
                return state
            if self.a.record and (self.audio.poll() is not None or self.video.poll() is not None):
                raise RuntimeError("A capture process stopped during gameplay")
            if time.monotonic() - last_frames > 10:
                self.frames()
                last_frames = time.monotonic()
            if state["phase"] in ("playing", "countdown"):
                order = self.devices if state["tick"] % 2 else self.devices[::-1]
                for d in order:
                    state = self.read()
                    p = next(p for p in state["players"] if p["name"] == d["name"])
                    if p["alive"]:
                        direction, reason = self.choose(state, p)
                        self.direction(d, direction, state, reason)
                if state["phase"] == "playing" and state["round"] not in captured and state["remaining"] < 36:
                    self.screenshot(f"gameplay-match-{match_number}-round-{state['round']}")
                    captured.add(state["round"])
            time.sleep(.025)
        raise TimeoutError(f"Natural match {match_number} exceeded {self.a.match_timeout}s")

    def play(self):
        self.capture_start()
        self.event("test-start", test="Two real native peers compete through external OS touch")
        # Both apps initially sound=true. Mute Rose only using visible toolbar geometry.
        rose = self.devices[1]
        v = rose["viewport"]
        self.click(rose, v["x"] + v["width"] - 88 * v["width"]/rose["pointWidth"],
                   v["y"] + 78 * v["width"]/rose["pointWidth"], purpose="Visible Rose sound toggle")
        self.screenshot("ready")
        for d in self.devices:
            self.button(d, "READY TO CHOMP", "ready")
        self.until(lambda s: s["phase"] in ("countdown", "playing"))
        for d in self.devices:
            self.calibrate(d)
        save(self.out / "calibration.json", self.devices)
        baseline = {p["id"]: p["lastSeq"] for p in self.read()["players"]}
        for d in self.devices:
            s = self.read()
            p = next(p for p in s["players"] if p["name"] == d["name"])
            direction, reason = self.choose(s, p)
            self.direction(d, direction, s, reason)
        self.until(lambda s: all(p["lastSeq"] > baseline[p["id"]] for p in s["players"]), 5)
        self.check("Visible D-pad coordinates reach both native clients", True)
        for d in self.devices:
            v = d["viewport"]
            response = self.mouse.call("drag", title=d["title"],
                x=float(v["x"] + v["width"]*.40), y=float(v["y"] + v["height"]*.40),
                toX=float(v["x"] + v["width"]*.58), toY=float(v["y"] + v["height"]*.40),
                heldScreenshot=str(self.out / f"dual-held-{d['name'].lower()}.png"))
            self.event("held-maze-swipe", player=d["name"], response=response)
        state = self.compete(1)
        self.check("Natural shared first-to-two match outcome",
                   state["phase"] == "matchOver" and state["winner"] is not None and
                   any(p["id"] == state["winnerId"] and p["crowns"] == 2 for p in state["players"]), state)
        save(self.out / "match-outcome.json", state)
        winner = state["winner"]["name"].upper()
        for d in self.devices:
            texts = self.texts(d, "winner")
            self.check(f"{d['name']} visibly displays shared {winner} outcome",
                       result_matches(texts, winner), {"modalLines": modal_lines(texts), "ocr": texts})
        self.screenshot("winner")
        for p in state["players"]:
            metric = {"id": p["id"], "osDpadClicks": self.clicks[p["id"]],
                      "distinctPositions": len(self.positions[p["id"]]),
                      "acceptedSeqValues": len(self.sequences[p["id"]]),
                      "maxAcceptedSeq": max(self.sequences[p["id"]]),
                      "maxScore": self.scores[p["id"]], "crowns": p["crowns"]}
            native = (self.out / f"{p['name'].lower()}.log").read_text()
            sources = re.findall(r"source=(\S+)", native)
            metric["nativeTouchInputs"] = sources.count("touch")
            metric["nativeSources"] = sorted(set(sources))
            self.results["metrics"][p["name"]] = metric
            self.check(f"{p['name']} competed with sustained native touch control",
                       metric["osDpadClicks"] >= 20 and metric["nativeTouchInputs"] >= 20 and
                       metric["distinctPositions"] >= 10 and metric["acceptedSeqValues"] >= 20 and
                       metric["maxScore"] > 0 and set(sources) == {"touch"}, metric)
        self.button(self.devices[0], "REMATCH", "rematch-vote")
        waiting = self.until(lambda s: s["phase"] == "matchOver" and s["players"][0]["ready"])
        time.sleep(2)
        self.check("One rematch vote waits without resetting",
                   self.read()["phase"] == "matchOver" and self.latest["winnerId"] == waiting["winnerId"])
        self.screenshot("waiting")
        self.button(self.devices[1], "REMATCH", "rematch-vote")
        reset = self.until(lambda s: s["phase"] == "countdown" and s["round"] == 1, 5)
        self.check("Both visible rematch votes reset round, scores, crowns and winner",
                   reset["winnerId"] is None and reset["winner"] is None and
                   all(p["score"] == 0 and p["crowns"] == 0 for p in reset["players"]), reset)
        save(self.out / "rematch-reset.json", reset)
        self.screenshot("reset")
        rematch = self.compete(2)
        self.check("Rematch completes with natural first-to-two outcome",
                   rematch["winner"] is not None and any(
                       p["id"] == rematch["winnerId"] and p["crowns"] == 2 for p in rematch["players"]),
                   rematch)
        save(self.out / "rematch-outcome.json", rematch)
        for d in self.devices:
            texts = self.texts(d, "rematch-winner")
            name = rematch["winner"]["name"].upper()
            self.check(f"{d['name']} visibly displays shared rematch {name} outcome",
                       result_matches(texts, name), {"modalLines": modal_lines(texts), "ocr": texts})
        self.screenshot("rematch-winner")
        self.event("test-end", test="Two real native peers compete through external OS touch")

    def finish(self):
        if self.video and self.video.poll() is None:
            self.video.send_signal(signal.SIGINT)
            try:
                self.video.wait(timeout=15)
            except subprocess.TimeoutExpired:
                self.video.kill()
                self.results["captureStopError"] = "Video required kill; preserve raw failure"
        # Do not terminate the supplied tap early: permit its normal file flush.
        if self.audio and self.audio.poll() is None:
            self.event("waiting-for-audio-flush")
            self.audio.wait(timeout=2 * self.a.match_timeout + 110)
        self.results["finished"] = clock()
        self.results["exitCode"] = int(any(a["result"] == "failed" for a in self.results["assertions"]))
        save(self.out / "results.json", self.results)
        if self.mouse:
            self.mouse.close()
        if self.obs:
            self.obs.close()
        # Apps/server remain open for live inspection. Cleanup PID is in session.json.


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--repo")
    p.add_argument("--out", required=True, help="New output directory, or prepared output with --resume")
    p.add_argument("--prepare-only", action="store_true")
    p.add_argument("--resume", action="store_true")
    p.add_argument("--devices", help="JSON array of two {udid, optional pointWidth} objects; required for prepare")
    p.add_argument("--cleanup", action="store_true", help="Stop only this output's verified observer PID")
    p.add_argument("--record", action="store_true", help="Concurrent real input-tap audio and screen capture")
    p.add_argument("--screen-index", default="0", help="Verify with ffmpeg -f avfoundation -list_devices true -i ''")
    p.add_argument("--port", type=int)
    p.add_argument("--match-timeout", type=int, default=200)
    args = p.parse_args()
    if args.cleanup:
        cleanup(args.out)
        return
    if not args.repo:
        p.error("--repo is required except for --cleanup")
    if args.prepare_only and args.resume:
        p.error("--prepare-only and --resume cannot be combined")
    t = Test(args)
    try:
        t.resume() if args.resume else t.prepare()
        if not args.prepare_only:
            t.play()
    except Exception as error:
        if t.owns_output:
            t.results["assertions"].append({"name": "Runner completed required flow", "result": "failed",
                                           "detail": repr(error)})
            t.event("failure", error=repr(error))
        raise
    finally:
        if t.owns_output:
            t.finish()


if __name__ == "__main__":
    main()
