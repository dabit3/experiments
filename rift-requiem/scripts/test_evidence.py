"""Regression coverage for shared-tick evidence and an asynchronous guest join."""
from copy import deepcopy
from pathlib import Path
import runpy
import unittest

validate = runpy.run_path(str(Path(__file__).with_name("assert-evidence.py")))["validate"]


def match_log():
    events = [
        {"id": 1, "type": "hit", "attacker": "a"},
        {"id": 2, "type": "hit", "attacker": "b"}
    ] + [
        {"id": index, "type": action}
        for index, action in enumerate(("jump", "airdash", "block", "projectile", "cancel"), 3)
    ]
    states = [
        {
            "code": "ROOM", "tick": tick, "phase": "fight", "matches": 0,
            "winner": "", "events": events,
            "players": [
                {"id": "a", "hp": 100, "wins": 0},
                {"id": "b", "hp": 100, "wins": 0}
            ]
        }
        for tick in range(104)
    ]
    states[0].update(phase="lobby", events=[])
    states[-2].update(phase="result", winner="a")
    states[-2]["players"][0]["wins"] = 2
    states[-1]["matches"] = 1
    return states


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.left = match_log()
        self.right = deepcopy(self.left)

    def test_identical_snapshots(self):
        report = validate(self.left, self.right)
        self.assertEqual(report["matching_snapshots"], 104)
        self.assertEqual(report["lobby_join_transitions"], [])

    def test_join_is_reported_without_counting_it_as_agreement(self):
        self.left[0]["players"].pop()
        for left, right in ((self.left, self.right), (self.right, self.left)):
            with self.subTest(left_count=len(left[0]["players"])):
                report = validate(left, right)
                self.assertEqual(report["matching_snapshots"], 103)
                self.assertEqual(report["lobby_join_transitions"][0]["tick"], 0)

    def test_existing_guest_change_is_not_a_join(self):
        self.left[0]["players"].pop()
        self.right[0]["players"][0]["hp"] -= 1
        with self.assertRaisesRegex(AssertionError, "Peer divergence at tick 0"):
            validate(self.left, self.right)

    def test_same_roster_lobby_difference_is_rejected(self):
        self.right[0]["players"][0]["hp"] -= 1
        with self.assertRaisesRegex(AssertionError, "Peer divergence at tick 0"):
            validate(self.left, self.right)

    def test_combat_difference_is_rejected(self):
        self.right[20]["players"][1]["hp"] -= 1
        with self.assertRaisesRegex(AssertionError, "Peer divergence at tick 20"):
            validate(self.left, self.right)

    def test_combat_roster_change_is_rejected(self):
        self.left[20]["players"].pop()
        with self.assertRaisesRegex(AssertionError, "Peer divergence at tick 20"):
            validate(self.left, self.right)

    def test_join_does_not_satisfy_minimum_observation_count(self):
        self.left[0]["players"].pop()
        with self.assertRaisesRegex(AssertionError, "Insufficient concurrent"):
            validate(self.left[:101], self.right[:101])

    def test_changed_room_field_is_not_a_join(self):
        self.left[0]["players"].pop()
        self.right[0]["winner"] = "b"
        with self.assertRaisesRegex(AssertionError, "Peer divergence at tick 0"):
            validate(self.left, self.right)


if __name__ == "__main__":
    unittest.main()
