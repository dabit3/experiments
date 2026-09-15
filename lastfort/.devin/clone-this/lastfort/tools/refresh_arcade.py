"""Refresh evidence pointers after the capture-gated arcade verification."""

import json
import os
import sys

import manifest


def main():
    run = "evidence/tests/" + sys.argv[1]
    state = manifest.load()
    revision = manifest.fingerprint(state["clone_root"])
    manual = "evidence/tests/manual-arcade/report.md"
    builds = "evidence/checks/arcade-clean-builds.txt"
    audit = "evidence/audits/arcade-review.md"
    with open(os.path.join(manifest.RUN_DIR, run, "result.json")) as stream:
        result = json.load(stream)
    if not result["passed"]:
        raise SystemExit("The multiplayer result did not pass")

    for item in state["items"]:
        if item["status"] != "verified":
            continue
        item["verified_revision"] = revision
        item["evidence"] = [manual, audit, builds, run + "/report.md"]
        item["verification_scope"] = (
            "Current shared code, core/server regression suites, and web/iOS "
            "UI observations. Android runtime remains blocked; macOS current "
            "revision is build-verified, with historical runtime evidence. "
            "The manual report records unexercised branches."
        )
    items = {item["id"]: item for item in state["items"]}
    items["journey-web-ios-parallel"]["evidence"] = [
        run + "/" + name for name in (
            "report.md", "result.json", "harness.log", "run.json",
            "review.mp4", "review.mp4.chapters.json", "timeline.jsonl",
            "phase-lobby.json", "phase-bus.json", "all-lobby.png",
            "all-bus.png", "all-gameplay.png", "all-results.png",
        )
    ]
    items["journey-ui-polish"]["status"] = "blocked"
    items["journey-ui-polish"]["verified_revision"] = None
    items["journey-ui-polish"]["note"] = (
        "The requested arcade pass is verified on web and iOS. Every-platform "
        "screenshot review remains incomplete: Android cannot run and current "
        "macOS UI was not manually re-exercised."
    )
    items["journey-four-platform-match"]["evidence"] = [
        run + "/report.md", builds,
        "evidence/blockers/android-emulator-boot-attempt.log",
    ]
    for item in state["items"]:
        if item["id"].startswith("visual-"):
            item["note"] = (
                "Stored comparison counts are historical, predating the arcade "
                "redesign. Current web/iOS captures have different viewports and "
                "player data; they do not establish zero-difference parity."
            )
            item["evidence"] = [audit, "evidence/visual/README.md"]

    checks = {check["id"]: check for check in state["checks"]}
    checks["functional"].update(
        status="failed", verified_revision=None,
        evidence=[run + "/result.json", manual, builds],
        note="Web+iOS and all unit suites pass; four-platform runtime remains blocked.",
    )
    checks["visual"].update(
        status="failed", verified_revision=None,
        evidence=[audit, manual, "evidence/visual/README.md"],
        note="Arcade web/iOS review passed; strict cross-renderer pixel equality is unverified.",
    )
    for key, evidence in {
        "build": [builds],
        "quality": [builds, "evidence/checks/arcade-final-client.txt",
                    "evidence/checks/arcade-final-scripts.txt",
                    "evidence/checks/arcade-determinism-sweep.txt"],
        "security": ["evidence/checks/arcade-security.txt", audit],
    }.items():
        checks[key].update(status="passed", verified_revision=revision, evidence=evidence)
    for entry in state["audits"]:
        entry.update(status="verified", verified_revision=revision, evidence=[audit, manual])
    for blocker in state["blockers"]:
        if blocker["id"] == "android-runtime":
            blocker["affected"] = ["journey-four-platform-match", "journey-ui-polish"]
    state["revision"] = revision
    state["status"] = "blocked"
    state["sweeps"] = []
    state["next_action"] = (
        "Resume four-platform runtime and visual parity on a host with Android "
        "virtualization; review current macOS UI and normalized equivalent captures."
    )
    manifest.save(state)
    print(revision)


if __name__ == "__main__":
    main()
