"""Assert two independent native telemetry streams describe the same real match."""
import argparse
import json
import pathlib


def load(path):
    return [json.loads(line) for line in pathlib.Path(path).read_text().splitlines() if line.strip()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("alpha")
    parser.add_argument("beta")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    streams = [load(args.alpha), load(args.beta)]
    assertions = []

    def check(name, passed, actual):
        assertions.append({"check": name, "passed": bool(passed), "actual": actual})

    welcomes = [[row for row in stream if row.get("type") == "welcome"] for stream in streams]
    ids = [rows[0]["detail"].split(" room=")[0] if rows else "" for rows in welcomes]
    check("Distinct native peer IDs", all(ids) and ids[0] != ids[1], ids)
    states = [[row for row in stream if row.get("type") == "state"] for stream in streams]
    rooms = [sorted({row["code"] for row in rows}) for rows in states]
    check("Same room", rooms[0] == rooms[1] and len(rooms[0]) == 1, rooms)
    for index, rows in enumerate(states):
        rounds = sorted({row["round"] for row in rows})
        check(f"Peer {index + 1}: countdown, gameplay, result", all(
            phase in {row["phase"] for row in rows} for phase in ["countdown", "playing", "result"]),
            sorted({row["phase"] for row in rows}))
        check(f"Peer {index + 1}: rematch", 2 in rounds, rounds)
        units = [unit for row in rows for unit in row["units"] if unit["id"] == ids[index]]
        for key in ["damage", "shots", "swings", "steps", "flight"]:
            maximum = max((unit[key] for unit in units), default=0)
            check(f"Peer {index + 1}: {key}", maximum > 0, maximum)
    results = [[row for row in rows if row["phase"] == "result" and row["round"] == 1] for rows in states]
    if all(results):
        outcomes = [{key: rows[0][key] for key in ["winner", "reason", "costs", "round"]} for rows in results]
        check("Shared finite outcome", outcomes[0] == outcomes[1], outcomes)
    else:
        check("Shared finite outcome", False, "Missing one or both result states")
    common_ticks = {row["tick"]: row for row in states[0]}
    comparisons = [(common_ticks[row["tick"]], row) for row in states[1] if row["tick"] in common_ticks]
    check("Identical authoritative state at shared ticks", bool(comparisons) and all(
        a["units"] == b["units"] and a["costs"] == b["costs"] for a, b in comparisons), len(comparisons))
    report = {"passed": all(item["passed"] for item in assertions), "assertions": assertions}
    pathlib.Path(args.output).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report["passed"] else 1)


if __name__ == "__main__":
    main()
