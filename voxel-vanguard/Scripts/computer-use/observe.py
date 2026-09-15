#!/usr/bin/env python3
"""Read-only room snapshots and simulator log collection; never sends gameplay input."""

import argparse
import json
import shutil
import subprocess
import time
import urllib.parse
import urllib.request
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--out", type=Path, required=True)
p.add_argument("--room", required=True)
p.add_argument("--server", default="http://127.0.0.1:8791")
p.add_argument("--snapshot", help="Output basename, e.g. gui-end-state.json")
p.add_argument("--collect", action="store_true")
p.add_argument("--server-log", type=Path)
a = p.parse_args()
if a.snapshot:
    if Path(a.snapshot).name != a.snapshot:
        raise SystemExit("Snapshot must be a basename")
    with urllib.request.urlopen(
        a.server.rstrip("/") + "/rooms/" + urllib.parse.quote(a.room, safe="")
    ) as response:
        state = json.load(response)
    (a.out / a.snapshot).write_text(
        json.dumps({"wall": time.time(), "state": state}, indent=2)
    )
if a.collect:
    config = json.loads((a.out / "gui-config.json").read_text())
    for name, player in config["players"].items():
        container = subprocess.check_output(
            [
                "xcrun",
                "simctl",
                "get_app_container",
                player["udid"],
                "games.vanguard.voxel.ios",
                "data",
            ],
            text=True,
        ).strip()
        shutil.copy(
            Path(container) / "Documents/vanguard-evidence.jsonl",
            a.out / (name + "-client.jsonl"),
        )
    if a.server_log:
        shutil.copy(a.server_log, a.out / "server.jsonl")
