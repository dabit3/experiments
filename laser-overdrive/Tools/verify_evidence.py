"""Validate exported logs from an actual two-device run; never mutates game state."""

import json
from pathlib import Path
import sys


def read(path):
    return [json.loads(line) for line in Path(path).read_text().splitlines() if line.strip()]


def verify(first, second, server):
    assertions = []

    def check(name, condition, actual):
        assertions.append({"check": name, "passed": bool(condition), "actual": actual})

    ids = [next(entry["id"] for entry in logs if entry["event"] == "joined") for logs in [first, second]]
    check("two distinct native guest IDs", ids[0] != ids[1], ids)
    results = []
    for logs in [first, second]:
        matches = [entry for entry in logs if entry["event"] == "phase" and entry["detail"].startswith("results")]
        check("client received completed match", bool(matches), len(matches))
        if not matches:
            continue
        results.append(matches[-1])
    if len(results) == 2:
        a, b = results
        check("same room and round", a["room"] == b["room"] and a["epoch"] == b["epoch"],
              [a["room"], a["epoch"], b["room"], b["epoch"]])
        score_a = {p["id"]: p["score"] for p in a["peers"]}
        score_b = {p["id"]: p["score"] for p in b["peers"]}
        check("identical authoritative scores", score_a == score_b and len(score_a) == 2, [score_a, score_b])
        for peer in a["peers"]:
            counts = {key: peer[key] for key in ["tapHits", "fxHits", "holdHits", "laserHits", "slamHits"]}
            check(f"all gameplay mechanics scored by {peer['name']}", all(v > 0 for v in counts.values()), counts)
        for logs, identity in zip([first, second], ids):
            samples = [entry for entry in logs if entry["event"] == "snapshot"
                       and entry["epoch"] == a["epoch"] and 4 < entry["songTime"] < 40
                       and entry.get("audioTime") is not None]
            drift = [abs(entry["songTime"] - entry["audioTime"]) for entry in samples]
            check(f"local music follows song clock for {identity}", len(drift) > 15 and max(drift) < 0.18,
                  {"samples": len(drift), "maximumSeconds": max(drift) if drift else None})
        starts = [entry for entry in server if entry["event"] == "start"
                  and entry["room"] == a["room"] and entry["epoch"] == a["epoch"]]
        check("server started both peers together", len(starts) == 1 and set(starts[0]["ids"]) == set(ids), starts)
    touch = [entry for entry in server if entry["event"] == "input" and entry.get("source") == "touch"]
    kinds = {entry["kind"] for entry in touch}
    check("actual touch button and swipe inputs accepted", {"button", "laser"} <= kinds,
          {"packets": len(touch), "kinds": sorted(kinds)})
    print(json.dumps({"passed": all(item["passed"] for item in assertions), "assertions": assertions}, indent=2))
    return all(item["passed"] for item in assertions)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: verify_evidence.py phone-a.jsonl phone-b.jsonl server.jsonl")
    raise SystemExit(0 if verify(*(read(path) for path in sys.argv[1:])) else 1)
