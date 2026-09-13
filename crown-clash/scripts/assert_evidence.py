"""Verify two native clients' JSONL evidence from the same live match."""

import json
import sys
from pathlib import Path


def read(path):
    return [
        json.loads(line) for line in Path(path).read_text().splitlines() if line.strip()
    ]


def verify(first, second):
    streams = [read(first), read(second)]
    assertions = []

    def check(name, condition):
        assertions.append({"check": name, "passed": bool(condition)})

    identities = [
        next(row["player"] for row in rows if row.get("kind") == "launch")
        for rows in streams
    ]
    check("distinct native player identities", identities[0] != identities[1])
    rooms = [
        {row["room"] for row in rows if row.get("kind") == "welcome"}
        for rows in streams
    ]
    check(
        "both guests joined the same single room",
        len(rooms[0]) == 1 and rooms[0] == rooms[1],
    )
    snapshots = [
        [row for row in rows if "peers" in row and "phase" in row] for rows in streams
    ]
    results = [
        [row for row in rows if row["phase"] == "result" and row["match"] == 1]
        for rows in snapshots
    ]
    check("both clients observed first match result", all(results))
    if all(results):
        left, right = results[0][0], results[1][0]
        check("same authoritative winner", left["winner"] == right["winner"])
        check(
            "same final roster health and active indices",
            [(peer["id"], peer["roster"], peer["active"]) for peer in left["peers"]]
            == [
                (peer["id"], peer["roster"], peer["active"]) for peer in right["peers"]
            ],
        )
        check(
            "whole losing team eliminated",
            any(
                peer["active"] == 3
                and all(member["hp"] == 0 for member in peer["roster"])
                for peer in left["peers"]
            ),
        )
        check(
            "both real peers inflicted damage",
            all(peer["damage"] > 0 for peer in left["peers"]),
        )
    for identity, rows, states in zip(identities, streams, snapshots):
        check(
            f"{identity}: both peers ready",
            any(
                len(state["peers"]) == 2
                and all(peer["ready"] for peer in state["peers"])
                for state in states
            ),
        )
        check(
            f"{identity}: active replacement observed",
            any(
                any(peer["active"] in (1, 2) for peer in state["peers"])
                for state in states
            ),
        )
        check(
            f"{identity}: rematch reset observed",
            any(
                state["match"] == 2
                and state["phase"] == "countdown"
                and all(
                    peer["active"] == 0
                    and all(member["hp"] == 100 for member in peer["roster"])
                    for peer in state["peers"]
                )
                for state in states
            ),
        )
        check(
            f"{identity}: reconnect event observed",
            any(row.get("kind") == "reconnected" for row in rows),
        )
        check(
            f"{identity}: actions use labeled network input",
            any(
                row.get("kind") == "input" and row.get("source") == "automated-driver"
                for row in rows
            ),
        )
    events = [
        {
            row["id"]: row
            for row in rows
            if isinstance(row.get("id"), int) and "kind" in row
        }
        for rows in streams
    ]
    common = set(events[0]) & set(events[1])
    check(
        "shared combat events agree",
        len(common) >= 10 and all(events[0][key] == events[1][key] for key in common),
    )
    print(
        json.dumps(
            {
                "passed": all(row["passed"] for row in assertions),
                "assertions": assertions,
            },
            indent=2,
        )
    )
    return 0 if all(row["passed"] for row in assertions) else 1


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(
            "Usage: python3 scripts/assert_evidence.py alpha.jsonl bravo.jsonl"
        )
    raise SystemExit(verify(sys.argv[1], sys.argv[2]))
