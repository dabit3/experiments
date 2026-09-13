"""Check two independent native clients' network logs from the same recorded run."""
import argparse
import json
from pathlib import Path

def is_lobby_join(left, right):
    before, after = sorted((left, right), key=lambda state: len(state["players"]))
    return (
        before["phase"] == after["phase"] == "lobby"
        and len(before["players"]) == 1
        and len(after["players"]) == 2
        and len({player["id"] for player in after["players"]}) == 2
        and before["players"][0] in after["players"]
        and {key: value for key, value in before.items() if key != "players"}
        == {key: value for key, value in after.items() if key != "players"}
    )


def validate(left, right):
    assert left and right, "Both native clients must produce evidence"
    rooms = {state["code"] for state in left + right}
    assert len(rooms) == 1, "Clients are in different rooms"
    left_ticks = {state["tick"]: state for state in left}
    right_ticks = {state["tick"]: state for state in right}
    common = sorted(left_ticks.keys() & right_ticks.keys())
    matching = []
    joins = []
    for tick in common:
        if left_ticks[tick] == right_ticks[tick]:
            matching.append(tick)
        elif is_lobby_join(left_ticks[tick], right_ticks[tick]):
            joins.append({
                "tick": tick,
                "left_ids": [player["id"] for player in left_ticks[tick]["players"]],
                "right_ids": [player["id"] for player in right_ticks[tick]["players"]]
            })
        else:
            raise AssertionError(f"Peer divergence at tick {tick}")
    assert len(matching) > 100, "Insufficient concurrent state observations"
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
    return {
        "status": "passed", "room": next(iter(rooms)), "player_ids": sorted(ids),
        "matching_snapshots": len(matching), "winner": winner,
        "lobby_join_transitions": joins,
        "checks": [
            "Two native peers with distinct IDs join the same room",
            "Over 100 same-tick snapshots agree byte-for-value",
            "Each player deals real network-authoritative damage",
            "Jump, air dash, guard, projectile and cancel events observed",
            "Both peers receive the same best-of-three winner",
            "Both peers enter a new fight after rematch votes"
        ],
        "events": sorted(actions),
        "note": (
            "Network assertions complement simultaneous footage and manual UI testing. "
            "An immediate lobby join snapshot can share the preceding broadcast tick; "
            "only an otherwise identical one-to-two-player transition is reported "
            "separately and excluded from the matching snapshot count."
        )
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("left", type=Path)
    parser.add_argument("right", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    left = [json.loads(line) for line in args.left.read_text().splitlines() if line.strip()]
    right = [json.loads(line) for line in args.right.read_text().splitlines() if line.strip()]
    report = validate(left, right)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
