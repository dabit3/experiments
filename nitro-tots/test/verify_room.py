#!/usr/bin/env python3
"""Asserts that every client in a finished Nitro Tots room saw the same result.

    verify_room.py <server-http-url> <room-code> <out-dir> <expected-platforms...>

Reads the room inspection endpoint, compares the final result hash and the
Grand Prix standings reported by each client (via `test_report` messages)
against the server's authoritative copy, and writes `result.json` plus a
Markdown summary to <out-dir>. Exit code 0 means all clients agree.
"""
import json
import sys
import urllib.request
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 5:
        print(__doc__)
        return 2
    server, code, out_dir, *expected = sys.argv[1:]
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    with urllib.request.urlopen(f"{server}/rooms/{code}", timeout=10) as r:
        room = json.load(r)
    (out / "room_final.json").write_text(json.dumps(room, indent=2))

    problems = []
    if room.get("status") != "matchOver":
        problems.append(f"room status is {room.get('status')!r}, expected 'matchOver'")

    server_hash = room.get("hash")
    server_standings = room.get("standings") or []
    if not server_hash:
        problems.append("server has no final hash")

    def order(standings):
        return [(s["slot"], s["name"], s["points"], s.get("places")) for s in standings]

    humans = [p for p in room.get("players", []) if not p.get("bot")]
    by_platform = {p["platform"]: p for p in humans}
    for plat in expected:
        p = by_platform.get(plat)
        if p is None:
            problems.append(f"no player from platform {plat!r} in the room")
            continue
        rep = p.get("testReport") or {}
        if rep.get("phase") != "matchOver":
            problems.append(f"{plat}: last reported phase is {rep.get('phase')!r}")
        if rep.get("hash") != server_hash:
            problems.append(f"{plat}: hash {rep.get('hash')!r} != server {server_hash!r}")
        if order(rep.get("standings") or []) != order(server_standings):
            problems.append(f"{plat}: standings differ from the server's")

    hashes = {plat: (by_platform.get(plat) or {}).get("testReport", {}).get("hash") for plat in expected}
    result = {
        "room": code,
        "status": room.get("status"),
        "seed": room.get("seed"),
        "races": room.get("totalRaces"),
        "serverHash": server_hash,
        "clientHashes": hashes,
        "platformsVerified": [p for p in expected if hashes.get(p) == server_hash and server_hash],
        "standings": server_standings,
        "raceResults": room.get("races"),
        "problems": problems,
        "passed": not problems,
    }
    (out / "result.json").write_text(json.dumps(result, indent=2))

    lines = [f"# Multiplayer result for room {code}", ""]
    lines.append(f"- Status: `{room.get('status')}`  ·  seed `{room.get('seed')}`  ·  races `{room.get('totalRaces')}`")
    lines.append(f"- Server result hash: `{server_hash}`")
    for plat in expected:
        mark = "OK " if hashes.get(plat) == server_hash and server_hash else "FAIL"
        lines.append(f"- {mark} {plat}: `{hashes.get(plat)}`")
    lines += ["", "| # | Racer | Platform | Points | Places |", "|---|---|---|---|---|"]
    for i, s in enumerate(server_standings, 1):
        who = "bot" if s.get("bot") else s.get("platform")
        lines.append(f"| {i} | {s['name']} | {who} | {s['points']} | {' '.join(str(p) for p in s.get('places', []))} |")
    if problems:
        lines += ["", "## Problems", *[f"- {p}" for p in problems]]
    (out / "result.md").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
