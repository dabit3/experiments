#!/usr/bin/env python3
"""Emit one recorded normalized batch, with fresh live window coordinates.

Requires a Devin operator/runtime to dispatch the returned functions.computer
payload. Does not send inputs itself. Inspect the live UI between batches:
combat timing, cooldowns and cache positions are not deterministic.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--out", type=Path, required=True)
p.add_argument(
    "--plan", type=Path, default=Path(__file__).with_name("action-plan.json")
)
p.add_argument("--set", action="append", default=[], metavar="NAME=VALUE")
p.add_argument("command", choices=["list", "emit"])
p.add_argument("label", nargs="?")
a = p.parse_args()
plan = json.loads(a.plan.read_text())
variables = dict(value.split("=", 1) for value in a.set)
if a.command == "list":
    print("\n".join(f"{b['label']}: {len(b['steps'])} steps" for b in plan))
else:
    b = next((b for b in plan if b["label"] == a.label), None)
    if not b:
        raise SystemExit("Choose an existing label with list")
    steps = json.dumps(b["steps"])
    for name, value in variables.items():
        steps = steps.replace("{{" + name + "}}", value)
    if "{{" in steps:
        raise SystemExit("Supply unresolved variables with --set NAME=VALUE")
    subprocess.run(
        [
            sys.executable,
            str(Path(__file__).with_name("gui.py")),
            "--out",
            str(a.out),
            "emit",
            b["label"],
            "--player",
            b["player"],
            "--steps",
            steps,
        ],
        check=True,
    )
