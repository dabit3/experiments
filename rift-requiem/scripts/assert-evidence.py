"""Check two independent native clients' network logs from the same recorded run."""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("left", type=Path)
parser.add_argument("right", type=Path)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
left = [json.loads(line) for line in args.left.read_text().splitlines() if line.strip()]
right = [json.loads(line) for line in args.right.read_text().splitlines() if line.strip()]
assert left and right, "Both native clients must produce evidence"
rooms = {state["code"] for state in left + right}
assert len(rooms) == 1, "Clients are in different rooms"
left_ticks = {state["tick"]: state for state in left}
right_ticks = {state["tick"]: state for state in right}
common = sorted(left_ticks.keys() & right_ticks.keys())
assert len(common) > 100, "Insufficient concurrent state observations"
for tick in common:
    assert left_ticks[tick] == right_ticks[tick], f"Peer divergence at tick {tick}"
dual = [state for state in left if len(state["players"]) == 2]
assert dual, "No shared duel"
ids = {player["id"] for player in dual[0]["players"]}
assert len(ids) == 2, "Peers must have distinct player IDs"
events = {event["id"]: event for state in left + right for event in state["events"]}
attackers = {event.get("attacker") for event in events.values() if event["type"] == "hit"}
assert ids <= attackers, "Both peers must cause real damage"
actions = {event["type"] for event in events.values()}
assert {"jump", "airdash", "block", "projectile", "cancel"} <= actions, "Combat mechanics not demonstrated"
results_left = [state for state in left if state["phase"] == "result"]
results_right = [state for state in right if state["phase"] == "result"]
assert results_left and results_right, "Both clients must observe a match result"
winner = results_left[0]["winner"]
assert winner and winner == results_right[0]["winner"], "Match winners disagree"
assert max(player["wins"] for player in results_left[0]["players"]) == 2
assert any(state["matches"] >= 1 and state["phase"] == "fight" for state in left)
assert any(state["matches"] >= 1 and state["phase"] == "fight" for state in right)
report = {
    "status": "passed", "room": next(iter(rooms)), "player_ids": sorted(ids),
    "matching_snapshots": len(common), "winner": winner,
    "checks": [
        "Two native peers with distinct IDs join the same room",
        "Over 100 same-tick snapshots agree byte-for-value",
        "Each player deals real network-authoritative damage",
        "Jump, air dash, guard, projectile and cancel events observed",
        "Both peers receive the same best-of-three winner",
        "Both peers enter a new fight after rematch votes"
    ],
    "events": sorted(actions),
    "note": "Network assertions complement simultaneous footage and manual UI testing."
}
args.output.write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
