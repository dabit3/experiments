#!/usr/bin/env python3
"""Read-only runtime assertions. Screenshots and dispatch provenance remain required.

Input: server.jsonl, aster-client.jsonl, bramble-client.jsonl,
computer-actions.jsonl, and gui-end-state.json ({wall,state}).
"""

import argparse
import json
import math
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--out", type=Path, required=True)
parser.add_argument("--room", required=True)
args = parser.parse_args()
root = args.out


def read(name):
    return [json.loads(line) for line in (root / name).read_text().splitlines()]


def write(name, rows):
    (root / name).write_text("".join(json.dumps(row) + "\n" for row in rows))


server = [s for s in read("server.jsonl") if s["code"] == args.room]
write("server-room.jsonl", server)
end = json.loads((root / "gui-end-state.json").read_text())
ids = {p["id"] for p in end["state"]["players"]}
clients = {name: read(name + "-client.jsonl") for name in ["aster", "bramble"]}
filtered = {
    name: [e for e in rows if e.get("peer", e.get("client")) in ids]
    for name, rows in clients.items()
}
for name, rows in filtered.items():
    write(name + "-client-room.jsonl", rows)
driver_start = min(
    e["time"]
    for rows in filtered.values()
    for e in rows
    if e.get("event") == "driver_enabled"
)
gui = [s for s in server if s["at"] / 1000 < driver_start]
checks = []


def check(label, passed, actual):
    checks.append(dict(label=label, passed=bool(passed), actual=actual))


lobby = [s for s in gui if s["phase"] == "lobby" and len(s["players"]) == 2]
unready = [s for s in lobby if not any(p["ready"] for p in s["players"])]
duration = (unready[-1]["at"] - unready[0]["at"]) / 1000 if unready else 0
check("both not ready for at least two seconds", duration >= 2, duration)
check(
    "one-ready lobby does not start",
    any(sum(p["ready"] for p in s["players"]) == 1 for s in lobby),
    len(lobby),
)
check(
    "GUI boundary precedes all driver enables",
    end["wall"] < driver_start,
    end["wall"] - driver_start,
)
details = {}
for alias, rows in filtered.items():
    peer = next(e["peer"] for e in rows if e.get("event") == "welcome")
    events = [e for e in rows if "event" in e and e["time"] < driver_start]
    player = next(p for p in end["state"]["players"] if p["id"] == peer)
    states = [p for s in gui for p in s["players"] if p["id"] == peer]
    displacement = max(
        math.hypot(p["x"] - states[0]["x"], p["z"] - states[0]["z"]) for p in states
    )
    required = [
        "manual_joystick",
        "manual_melee",
        "manual_ranged",
        "manual_dodge",
        "manual_heal",
    ]
    check(
        alias + " manual controls logged",
        all(any(e["event"] == action for e in events) for action in required),
        sorted({e["event"] for e in events}),
    )
    check(alias + " displacement >1", displacement > 1, displacement)
    check(
        alias + " combat counters and equipment",
        all(
            player["stats"][k] >= 1
            for k in ["melee", "ranged", "dodge", "heal", "hits", "equipment"]
        ),
        player["stats"],
    )
    heal = next(e for e in events if e["event"] == "manual_heal")
    before = next(
        p
        for p in [s for s in gui if s["at"] / 1000 < heal["time"]][-1]["players"]
        if p["id"] == peer
    )
    after = next(
        p
        for p in [s for s in gui if s["at"] / 1000 > heal["time"]][0]["players"]
        if p["id"] == peer
    )
    check(
        alias + " natural damage then healing",
        before["hp"] < before["maxHP"] and after["hp"] > before["hp"],
        [before["hp"], after["hp"]],
    )
    details[alias] = dict(
        peer=peer,
        displacement=displacement,
        stats=player["stats"],
        gear=[player["weapon"], player["bow"], player["armor"]],
    )
claimed = [loot for loot in end["state"]["loot"] if loot["kind"] == "chest"]
check(
    "independent claims at same cache",
    any(set(c["claimed"]) == ids for c in claimed),
    claimed,
)
victories = {s["round"] for s in server if s["phase"] == "victory"}
check("two shared victories", len(victories) >= 2, sorted(victories))
second = [s for s in server if s["round"] == 2]
check(
    "rematch preserves identities",
    bool(second) and all({p["id"] for p in s["players"]} == ids for s in second),
    sorted(ids),
)
for peer in ids:
    states = [p for s in second for p in s["players"] if p["id"] == peer]
    check(
        peer + " both bridges in round 2",
        all(
            any(abs(p["x"] - x) < 2 and abs(p["z"]) < 2 for p in states)
            for x in [12, 36]
        ),
        max(p["x"] for p in states),
    )
    check(
        peer + " two cache upgrades in round 2",
        max(p["stats"]["equipment"] for p in states) >= 2,
        max(p["stats"]["equipment"] for p in states),
    )
snapshots = {
    name: {
        (e["state"]["round"], e["state"]["tick"]): e["state"]
        for e in rows
        if "state" in e and e["state"]["code"] == args.room
    }
    for name, rows in filtered.items()
}
common = snapshots["aster"].keys() & snapshots["bramble"].keys()
mismatches = [
    key for key in common if snapshots["aster"][key] != snapshots["bramble"][key]
]
check(
    "shared client snapshots agree",
    len(common) >= 10 and not mismatches,
    dict(common=len(common), mismatches=mismatches),
)
trace = read("computer-actions.jsonl")
check(
    "committed real-tool action trace",
    bool(trace)
    and all(e["source"] == "devin_computer" and "completedWall" in e for e in trace),
    len(trace),
)
result = dict(
    room=args.room,
    driverStartWall=driver_start,
    gui=details,
    passed=all(c["passed"] for c in checks),
    checks=checks,
    limitations="Provenance commits are operator attestations; inspect screenshots/video. Automatic rematch and delayed superseded messages are not inferred.",
)
(root / "runtime-assertions.json").write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
raise SystemExit(0 if result["passed"] else 1)
