"""Validate captured native runtime evidence, not synthetic test peers."""
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
events = [json.loads(line) for line in (root / "server.jsonl").read_text().splitlines()]
telemetry = {
    name: (root / f"{name}-telemetry.jsonl").read_text().splitlines()
    for name in ("pro", "air")
}
checks = []


def check(name, condition, actual):
    checks.append({"assertion": name, "result": "passed" if condition else "failed", "actual": actual})


results = [e for e in events if e["event"] == "results"]
check("Three completed native matches", len(results) == 3, len(results))
for result in results:
    key = f'{result["room"]}/{result["match"]}'
    players = result["players"]
    check(f"{key}: exactly two distinct peers", len(players) == 2 and len({p["id"] for p in players}) == 2, [p["id"] for p in players])
    for p in players:
        check(f'{key}/{p["name"]}: 184 unique notes judged', len(set(p["judged"])) == 184 and sum(p["counts"].values()) == 184,
              {"score": p["score"], "counts": p["counts"], "judged": len(set(p["judged"]))})
        hits = [e for e in events if e["event"] == "hit" and e["room"] == result["room"] and e["match"] == result["match"] and e["id"] == p["id"]]
        check(f'{key}/{p["name"]}: all nine lanes score', {e["lane"] for e in hits} == set(range(9)), sorted({e["lane"] for e in hits}))
    if players[0]["automated"]:
        check(f"{key}: meaningful unequal automated scores", players[0]["score"] > players[1]["score"] > 500000, [p["score"] for p in players])
    duration = 52000 if result["songID"] == "sugar" else 45478
    elapsed = result["serverTime"] - result["startAt"]
    check(f"{key}: authored song duration completed", duration <= elapsed <= duration + 100, elapsed)
    for name, self_index in (("pro", 0), ("air", 1)):
        expected = f'match={result["match"]} self={players[self_index]["score"]} rival={players[1-self_index]["score"]} judged=184'
        check(f"{key}/{name}: native result agrees with server", any(expected in line and "\tresult\t" in line for line in telemetry[name]), expected)
        starts = [line for line in telemetry[name] if "\taudio_scheduled\t" in line and f'start={result["startAt"]}.0' in line]
        timing = [dict(re.findall(r"(\w+)=([-\d.]+)", line)) for line in starts]
        check(f"{key}/{name}: same epoch scheduled ahead with RTT <100ms",
              bool(timing) and all(float(t["delta"]) > 0 and float(t["rtt"]) < 100 for t in timing), timing)

joins = [e for e in events if e["event"] == "joined" and e.get("automated")]
check("Reconnect retains guest UUID without adding seat", len(joins) == 3 and joins[1]["id"] == joins[2]["id"], [j["id"] for j in joins])
check("Rematch advances match with fresh start", results[0]["room"] == results[1]["room"] and results[1]["match"] == results[0]["match"] + 1 and results[1]["startAt"] > results[0]["startAt"], [r["startAt"] for r in results[:2]])
for name in telemetry:
    touches = [line for line in telemetry[name] if "source=touch" in line]
    check(f"{name}: native touch origin on all nine lanes", {int(re.search(r"lane=(\d+)", line)[1]) for line in touches} == set(range(9)), touches)
    manual_start = next(i for i, line in enumerate(telemetry[name]) if "room=" + results[-1]["room"] in line and "\twelcome\t" in line)
    check(f"{name}: no built-in automation in manual room", not any("source=automated" in line for line in telemetry[name][manual_start:]), "manual welcome automated=false; source=touch only")
output = {"revision": "a0e7d6865b9bbc446d5a62e750bb91589410653d", "build": "Debug iOS Simulator", "checks": checks,
          "limitations": ["Silent host: audible playback and acoustic synchronization unverified", "OS pointer simulator touch, not physical-device multitouch",
                          "Host manual match used +15ms calibration after slider release; restored to 0ms afterward"],
          "failed": sum(c["result"] == "failed" for c in checks)}
print(json.dumps(output, indent=2))
sys.exit(bool(output["failed"]))
