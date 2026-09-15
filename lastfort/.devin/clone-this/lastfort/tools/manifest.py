#!/usr/bin/env python3
"""Small helper for maintaining the clone-this manifest of the Lastfort run.

Usage (from the clone root):
  python3 .devin/clone-this/lastfort/tools/manifest.py fingerprint
  python3 .devin/clone-this/lastfort/tools/manifest.py item ID KIND "LABEL" [--status S] [--evidence P ...] [--verified]
  python3 .devin/clone-this/lastfort/tools/manifest.py audit ID STATUS [--evidence P ...]
  python3 .devin/clone-this/lastfort/tools/manifest.py check ID STATUS [--evidence P ...]
  python3 .devin/clone-this/lastfort/tools/manifest.py event "OUTCOME" "NEXT" [--changed ID ...] [--commands C ...]
  python3 .devin/clone-this/lastfort/tools/manifest.py frontier add|remove "TEXT"
  python3 .devin/clone-this/lastfort/tools/manifest.py sweep EVIDENCE_PATH [--new-items N]
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

RUN_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(RUN_DIR, "state.json")
EVENTS = os.path.join(RUN_DIR, "events.jsonl")
SKILL = os.environ.get(
    "CLONE_THIS_SKILL", "/Users/devin/clone-this-skill/.devin/skills/clone-this"
)
AUDIT_IDS = [
    "source", "navigation", "roles", "states", "responsive",
    "data", "assets", "accessibility", "reliability", "rebrand",
]


def load() -> dict:
    with open(STATE, encoding="utf-8") as f:
        return json.load(f)


def save(state: dict) -> None:
    tmp = STATE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp, STATE)


def fingerprint(clone_root: str) -> str:
    out = subprocess.run(
        [sys.executable, "-B", os.path.join(SKILL, "scripts", "fingerprint.py"), clone_root],
        check=True, capture_output=True, text=True,
    )
    return out.stdout.strip().splitlines()[-1]


def upsert(records: list, record: dict) -> None:
    for i, r in enumerate(records):
        if r["id"] == record["id"]:
            records[i] = {**r, **record}
            return
    records.append(record)


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("fingerprint")
    p = sub.add_parser("item")
    p.add_argument("id"); p.add_argument("kind"); p.add_argument("label")
    p.add_argument("--status", default=None)
    p.add_argument("--evidence", nargs="*", default=None)
    p.add_argument("--verified", action="store_true")
    p.add_argument("--comparison", default=None, help="JSON object for visual items")
    for name in ("audit", "check"):
        q = sub.add_parser(name)
        q.add_argument("id"); q.add_argument("status")
        q.add_argument("--evidence", nargs="*", default=None)
    e = sub.add_parser("event")
    e.add_argument("outcome"); e.add_argument("next")
    e.add_argument("--changed", nargs="*", default=[])
    e.add_argument("--commands", nargs="*", default=[])
    fr = sub.add_parser("frontier")
    fr.add_argument("op", choices=["add", "remove"]); fr.add_argument("text")
    sw = sub.add_parser("sweep")
    sw.add_argument("evidence"); sw.add_argument("--new-items", type=int, default=0)
    args = ap.parse_args()

    state = load()
    rev = fingerprint(state["clone_root"])

    if args.cmd == "fingerprint":
        print(rev)
        return 0
    if args.cmd == "item":
        existing = next((r for r in state["items"] if r["id"] == args.id), None)
        rec = {
            "id": args.id, "kind": args.kind, "label": args.label,
            "status": args.status or (existing or {}).get("status", "pending"),
            "verified_revision": (existing or {}).get("verified_revision"),
            "evidence": args.evidence if args.evidence is not None else (existing or {}).get("evidence", []),
        }
        if args.verified:
            rec["status"] = "verified"
            rec["verified_revision"] = rev
        if args.comparison:
            rec["comparison"] = json.loads(args.comparison)
        elif existing and "comparison" in existing:
            rec["comparison"] = existing["comparison"]
        upsert(state["items"], rec)
    elif args.cmd in ("audit", "check"):
        key = "audits" if args.cmd == "audit" else "checks"
        existing = next((r for r in state[key] if r["id"] == args.id), None)
        rec = {
            "id": args.id, "status": args.status,
            "verified_revision": rev if args.status in ("verified", "passed") else None,
            "evidence": args.evidence if args.evidence is not None else (existing or {}).get("evidence", []),
        }
        upsert(state[key], rec)
    elif args.cmd == "event":
        state["iteration"] += 1
        state["next_action"] = args.next
        record = {
            "iteration": state["iteration"], "revision": rev, "changed": args.changed,
            "commands": args.commands, "outcome": args.outcome,
            "blockers": state["blockers"], "next_action": args.next,
        }
        with open(EVENTS, "a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")
    elif args.cmd == "frontier":
        if args.op == "add" and args.text not in state["frontier"]:
            state["frontier"].append(args.text)
        if args.op == "remove" and args.text in state["frontier"]:
            state["frontier"].remove(args.text)
    elif args.cmd == "sweep":
        state["sweeps"].append({
            "revision": rev, "new_items": args.new_items,
            "frontier_empty": len(state["frontier"]) == 0,
            "audit_ids": AUDIT_IDS, "evidence": [args.evidence],
        })
    state["revision"] = rev
    save(state)
    print(rev)
    return 0


if __name__ == "__main__":
    sys.exit(main())
