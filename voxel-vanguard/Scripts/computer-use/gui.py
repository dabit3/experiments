#!/usr/bin/env python3
"""Emit native GUI tool batches. A Devin runtime must dispatch the JSON.

This helper sends NO game/network/OS input. Commit is a post-dispatch operator
attestation, not proof by itself; retain actual screenshots and independent logs.
"""

import argparse
import json
import subprocess
import time
from pathlib import Path


def windows():
    script = """tell application "System Events" to tell process "Simulator"
set outputText to ""
repeat with w in windows
set p to position of w
set s to size of w
set outputText to outputText & (name of w as text) & tab & (item 1 of p as text) & tab & (item 2 of p as text) & tab & (item 1 of s as text) & tab & (item 2 of s as text) & linefeed
end repeat
return outputText
end tell"""
    text = subprocess.check_output(["osascript", "-e", script], text=True)
    return {
        row.split("\t")[0]: list(map(float, row.split("\t")[1:]))
        for row in text.strip().splitlines()
        if "\t" in row
    }


def devices():
    data = json.loads(
        subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "booted", "--json"]
        )
    )
    return [
        d for group in data["devices"].values() for d in group if d["state"] == "Booted"
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("inspect")
    cfg = sub.add_parser("configure")
    cfg.add_argument("--aster", required=True)
    cfg.add_argument("--bramble", required=True)
    cfg.add_argument("--desktop", type=float, nargs=2, required=True)
    cfg.add_argument("--aster-screen", type=float, nargs=4, required=True)
    cfg.add_argument("--bramble-screen", type=float, nargs=4, required=True)
    emit = sub.add_parser("emit")
    emit.add_argument("label")
    emit.add_argument("--player", choices=["aster", "bramble"], required=True)
    emit.add_argument("--steps", required=True)
    commit = sub.add_parser("commit")
    commit.add_argument("label")
    commit.add_argument("--screenshot", type=Path, required=True)
    args = parser.parse_args()
    if not args.out.is_dir():
        raise SystemExit("Create a fresh output directory first")
    if args.command == "inspect":
        print(json.dumps({"windows": windows(), "bootedDevices": devices()}, indent=2))
        return
    if args.command == "configure":
        path = args.out / "gui-config.json"
        if path.exists():
            raise SystemExit("Refusing to overwrite calibration")
        names = {"aster": args.aster, "bramble": args.bramble}
        rects = {"aster": args.aster_screen, "bramble": args.bramble_screen}
        live_devices, live_windows = devices(), windows()
        selected = {}
        for name, identity in names.items():
            choices = [d for d in live_devices if identity in [d["name"], d["udid"]]]
            if len(choices) != 1:
                raise SystemExit("Missing or ambiguous device: " + identity)
            device = choices[0]
            titles = [
                title
                for title in live_windows
                if title.startswith(device["name"] + " –")
            ]
            if len(titles) != 1:
                raise SystemExit("Missing or ambiguous Simulator window")
            title = titles[0]
            x, y, width, height = live_windows[title]
            sx, sy, sw, sh = rects[name]
            dx, dy = args.desktop[0] / 1024, args.desktop[1] / 768
            relative = [
                (sx * dx - x) / width,
                (sy * dy - y) / height,
                sw * dx / width,
                sh * dy / height,
            ]
            if (
                not all(0 <= value <= 1 for value in relative)
                or relative[0] + relative[2] > 1
                or relative[1] + relative[3] > 1
            ):
                raise SystemExit(
                    "Display rectangle is outside window; wait for rotation and recalibrate"
                )
            selected[name] = {
                "udid": device["udid"],
                "window": title,
                "calibratedWindow": live_windows[title],
                "relativeDisplay": relative,
            }
        if selected["aster"]["udid"] == selected["bramble"]["udid"]:
            raise SystemExit("Two distinct devices required")
        data = {
            "desktop": args.desktop,
            "toolSpace": [1024, 768],
            "players": selected,
            "created": time.time(),
        }
        path.write_text(json.dumps(data, indent=2))
        print(json.dumps(data, indent=2))
        return
    if args.command == "commit":
        path = args.out / "batches" / (args.label + ".json")
        data = json.loads(path.read_text())
        if "completedWall" in data:
            raise SystemExit("Already committed")
        if not args.screenshot.is_file():
            raise SystemExit("Actual screenshot file required")
        data.update(
            completedWall=time.time(),
            source="devin_computer",
            screenshot=str(args.screenshot.resolve()),
            provenance="Exact payload dispatched through functions.computer; bracket timestamps only",
        )
        path.write_text(json.dumps(data, indent=2))
        with (args.out / "computer-actions.jsonl").open("a") as output:
            output.write(json.dumps(data) + "\n")
        print(json.dumps({"committed": args.label, "source": data["source"]}))
        return
    config = json.loads((args.out / "gui-config.json").read_text())
    live_windows = windows()
    actions = []
    steps = json.loads(args.steps)
    for step in steps:
        player = config["players"][step.get("player", args.player)]
        x, y, width, height = live_windows[player["window"]]
        if any(
            abs(a - b) > 1
            for a, b in zip([width, height], player["calibratedWindow"][2:])
        ):
            raise SystemExit("Window resized or rotated; use a fresh calibration")
        rx, ry, rw, rh = player["relativeDisplay"]

        def point(at):
            if not all(0 <= number <= 1 for number in at):
                raise ValueError("Normalized coordinates must be within display")
            return [
                round((x + (rx + at[0] * rw) * width) * 1024 / config["desktop"][0]),
                round((y + (ry + at[1] * rh) * height) * 768 / config["desktop"][1]),
            ]

        kind = step["kind"]
        if kind == "tap":
            actions.append({"action": "left_click", "coordinate": point(step["at"])})
        elif kind in ["hold", "drag"]:
            actions += [
                {
                    "action": "mouse_move",
                    "coordinate": point(step.get("from", step.get("at"))),
                },
                {"action": "left_mouse_down"},
            ]
            if kind == "drag":
                actions.append(
                    {"action": "mouse_move", "coordinate": point(step["to"])}
                )
            actions.append({"action": "wait", "duration": step["seconds"]})
            if kind == "drag":
                actions.append({"action": "screenshot"})
            actions.append({"action": "left_mouse_up"})
        elif kind in ["type", "key"]:
            actions.append({"action": kind, "text": step["text"]})
        elif kind == "wait":
            actions.append({"action": "wait", "duration": step["seconds"]})
        else:
            raise ValueError("Unsupported step: " + kind)
    actions.append({"action": "screenshot"})
    directory = args.out / "batches"
    directory.mkdir(exist_ok=True)
    path = directory / (args.label + ".json")
    if path.exists():
        raise SystemExit("Unique label required")
    data = {
        "label": args.label,
        "player": args.player,
        "steps": steps,
        "payload": {"actions": actions},
        "requestedWall": time.time(),
        "windowBounds": live_windows,
        "source": "pending_devin_computer",
    }
    path.write_text(json.dumps(data, indent=2))
    print(json.dumps(data["payload"]))


if __name__ == "__main__":
    main()
