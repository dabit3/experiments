"""Manifest refresh after a re-verification run: refresh_state.py OLD_RUN NEW_RUN

Re-points every evidence path at the final harness run, re-stamps verified
items/audits/checks at the current fingerprint, updates the visual comparison
counts from evidence/visual/web-vs-macos.jsonl and drops the sweeps recorded at
the previous revision (new sweeps are recorded separately with manifest.py).
"""

import json
import os
import subprocess
import sys

RUN_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(RUN_DIR, "state.json")
OLD_RUN, NEW_RUN = sys.argv[1:3] if len(sys.argv) == 3 else ("e2e-20260909-175052", "e2e-20260909-184420")


def main() -> int:
    rev = subprocess.run(
        [sys.executable, os.path.join(RUN_DIR, "tools", "manifest.py"), "fingerprint"],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    with open(STATE, encoding="utf-8") as f:
        raw = f.read().replace(OLD_RUN, NEW_RUN)
    state = json.loads(raw)

    counts = {}
    with open(os.path.join(RUN_DIR, "evidence", "visual", "web-vs-macos.jsonl"), encoding="utf-8") as f:
        for line in f:
            j = json.loads(line)
            if j["tolerance"] == 0:
                screen = os.path.basename(j["reference"]).replace("web-", "").replace(".png", "")
                counts[screen] = (j["different_pixels"], j["total_pixels"])

    for item in state["items"]:
        if item["status"] == "verified":
            item["verified_revision"] = rev
        cmp_ = item.get("comparison")
        if cmp_:
            screen = os.path.basename(cmp_["reference"]).replace("web-", "").replace("-ref.png", "")
            screen = {"hud": "matchover"}.get(screen, screen)
            cmp_["different_pixels"], cmp_["total_pixels"] = counts[screen]
    for a in state["audits"]:
        if a["status"] == "verified":
            a["verified_revision"] = rev
    for c in state["checks"]:
        if c["status"] == "passed":
            c["verified_revision"] = rev
    state["sweeps"] = []
    state["revision"] = rev
    with open(STATE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(rev)
    for item in state["items"]:
        if item.get("comparison"):
            print(item["id"], item["comparison"]["different_pixels"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
