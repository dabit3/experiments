#!/usr/bin/env python3
"""Assemble the clone-this manifest (state.json) for the Brickfolk run.

The manifest is a declaration of *what was verified and where the evidence
lives*; every evidence path is checked to be a nonempty file inside the run
directory before it is written, so the manifest cannot reference artifacts
that do not exist. Nothing here fabricates results: the pixel counts come from
the metrics files written by test/e2e/visual_compare.py during the e2e run,
and the sweep records come from the JSON produced by the two sweep scripts.

Usage:
  build_manifest.py --run-dir <clone-root>/.devin/clone-this/brickfolk \
      --e2e evidence/tests/multiplayer-<stamp> \
      --e2e-tycoon evidence/tests/<dir> --e2e-tag evidence/tests/<dir> \
      --revision sha256:... [--status complete]
"""
import argparse
import json
from pathlib import Path
import sys

AUDIT_IDS = (
    "source", "navigation", "roles", "states", "responsive",
    "data", "assets", "accessibility", "reliability", "rebrand",
)
CHECK_IDS = ("functional", "visual", "build", "quality", "security")
VISUAL_SCREENS = ("hub", "avatar", "social", "chat", "profile", "daily")


class Evidence:
    def __init__(self, run_dir):
        self.run_dir = run_dir
        self.problems = []

    def __call__(self, *paths):
        out = []
        for rel in paths:
            full = self.run_dir / rel
            if not full.is_file() or full.stat().st_size == 0:
                self.problems.append(f"missing or empty evidence: {rel}")
            out.append(rel)
        return out


def item(id_, kind, label, evidence, **extra):
    record = {
        "id": id_,
        "kind": kind,
        "label": label,
        "status": "verified",
        "verified_revision": None,
        "evidence": evidence,
    }
    record.update(extra)
    return record


def build_items(ev, e2e, tycoon, tag):
    vis = f"{e2e}/visual"
    shots = lambda phase: [f"{e2e}/{p}-{phase}.png" for p in ("web", "ios", "android", "macos")]
    q = "evidence/quality"
    a = "evidence/audits"
    r = "evidence/reference"
    items = [
        # ---- routes (screens of the clone) ---------------------------------
        item("route-sign-in", "route",
             "Sign-in screen: name entry, theme toggle, brand wordmark",
             ev(f"{vis}/web-signin.png", f"{a}/navigation.md")),
        item("route-hub-play", "route",
             "Hub / Play tab: experience browser with thumbnails, live player counts, party banner",
             ev(f"{vis}/web-hub.png", f"{vis}/macos-hub.png", f"{vis}/web-hub-dark.png")),
        item("route-hub-avatar", "route",
             "Hub / Avatar tab: avatar editor and shop",
             ev(f"{vis}/web-avatar.png", f"{vis}/macos-avatar.png", f"{vis}/web-avatar-dark.png")),
        item("route-hub-social", "route",
             "Hub / Social tab: friends list, requests, party controls and join code",
             ev(f"{vis}/web-social.png", f"{vis}/macos-social.png")),
        item("route-hub-chat", "route",
             "Hub / Chat tab: global chat with filtered text",
             ev(f"{vis}/web-chat.png", f"{vis}/macos-chat.png")),
        item("route-hub-profile", "route",
             "Hub / Profile tab: player card, stats, badges, settings",
             ev(f"{vis}/web-profile.png", f"{vis}/macos-profile.png")),
        item("route-daily-reward", "route",
             "Daily reward sheet: 7-day streak calendar and claim action",
             ev(f"{vis}/web-daily.png", f"{vis}/macos-daily.png")),
        item("route-room-lobby", "route",
             "Room lobby: seats, ready state, join code, countdown",
             ev(*shots("lobby"))),
        item("route-room-gameplay", "route",
             "Room gameplay: Flame canvas, HUD pills, timer, mini leaderboard, controls",
             ev(*shots("gameplay"))),
        item("route-room-results", "route",
             "Room results: podium, ranked rows, rewards, play-again / leave",
             ev(*shots("results"))),
        # ---- features (public reference requirements) ---------------------
        item("feature-experience-browser", "feature",
             "Browse experiences (places) with thumbnails, descriptions and live player counts",
             ev(f"{vis}/web-hub.png", f"{e2e}/server-state.json",
                f"{r}/public-docs-experience-badge-chat-party-friends.txt")),
        item("feature-obby", "feature",
             "Obstacle course with 12 checkpoints, respawn at last checkpoint, finish pad, timed leaderboard",
             ev(f"{e2e}/report.json", f"{e2e}/summary.md", f"{q}/shared-test.log",
                f"{r}/public-docs-roblox-wikipedia-obby-tycoon-avatar-home.txt")),
        item("feature-tycoon", "feature",
             "Tycoon: place bricks on a personal plot, buy upgrades, income per second, richest builder wins",
             ev(f"{tycoon}/report.json", f"{tycoon}/summary.md", f"{q}/shared-test.log",
                f"{q}/server-test.log")),
        item("feature-tag", "feature",
             "Round-based freeze tag: tagger freezes runners, teammates thaw, three rounds per match",
             ev(f"{tag}/report.json", f"{tag}/summary.md", f"{q}/shared-test.log",
                f"{q}/server-test.log")),
        item("feature-avatar-editor", "feature",
             "Avatar editor: body colours, hats, faces and accessories (original art), live preview",
             ev(f"{vis}/web-avatar.png", f"{vis}/macos-avatar.png", f"{q}/server-test.log")),
        item("feature-shop-currency", "feature",
             "Shared currency (pips) and inventory: buy items once, owned items equip anywhere",
             ev(f"{vis}/web-avatar.png", f"{q}/server-test.log", f"{a}/data.md")),
        item("feature-daily-reward", "feature",
             "Daily reward loop: streak calendar, once-per-day claim, cooldown error",
             ev(f"{vis}/web-daily.png", f"{q}/server-test.log")),
        item("feature-friends", "feature",
             "Friends: request, accept, decline, remove; social badge on first friend",
             ev(f"{vis}/web-social.png", f"{q}/server-test.log")),
        item("feature-party-join-codes", "feature",
             "Parties with 4-letter join codes; leader launches the whole party into one room across platforms",
             ev(f"{e2e}/report.json", f"{e2e}/server-state.json", *shots("lobby"))),
        item("feature-chat-filtered", "feature",
             "Text chat (global, party, room) with profanity masking, URL/number stripping and rate limits",
             ev(f"{vis}/web-chat.png", f"{q}/server-test.log")),
        item("feature-profile-badges", "feature",
             "Player profiles with stats and earned badges (original badge set)",
             ev(f"{vis}/web-profile.png", f"{q}/server-test.log")),
        item("feature-server-authoritative-rooms", "feature",
             "Server-authoritative rooms per experience, up to 8 seats, seeded simulation at 30 ticks/s",
             ev(f"{e2e}/server-state.json", f"{e2e}/server.log", f"{a}/data.md")),
        item("feature-bots", "feature",
             "Deterministic server-side bots fill empty seats and appear on the leaderboard",
             ev(f"{e2e}/report.json", f"{tycoon}/report.json", f"{tag}/report.json")),
        item("feature-reconnect", "feature",
             "Token resume and reconnect within the grace period keep the seat and re-send room state",
             ev(f"{q}/server-test.log", f"{a}/reliability.md")),
        item("feature-persistence", "feature",
             "SQLite persistence of players, avatars, inventory, badges, friends, plots and results",
             ev(f"{e2e}/brickfolk-test.db", f"{q}/server-test.log", f"{a}/data.md")),
        item("feature-match-lifecycle", "feature",
             "Lobby -> countdown -> gameplay -> results lifecycle with play-again",
             ev(f"{e2e}/report.json", *shots("lobby"), *shots("gameplay"), *shots("results"))),
        item("feature-deterministic-test-mode", "feature",
             "Test mode: fixed seed and clock, deterministic autopilots, /test/state and /test/control",
             ev(f"{e2e}/report.json", f"{vis}/summary.json", f"{q}/app-test.log")),
        item("feature-themes", "feature",
             "Light and dark themes with shared Inter type scale",
             ev(f"{vis}/web-hub.png", f"{vis}/web-hub-dark.png", f"{q}/app-test.log")),
        item("feature-input-modes", "feature",
             "Keyboard (web/macOS) and touch joystick/jump (iOS/Android) controls for the same simulation",
             ev(f"{e2e}/web-gameplay.png", f"{e2e}/ios-gameplay.png",
                f"{e2e}/android-gameplay.png", f"{e2e}/macos-gameplay.png", f"{a}/accessibility.md")),
        # ---- journeys ------------------------------------------------------
        item("journey-cross-platform-obby-match", "journey",
             "Web, iOS, Android and macOS join party BRIK, enter one obby room, finish, identical results and checksum",
             ev(f"{e2e}/report.json", f"{e2e}/summary.md", f"{e2e}/recording-four-way.mp4",
                *shots("results"))),
        item("journey-tycoon-match", "journey",
             "Web and macOS play a full tycoon match with bots to identical results",
             ev(f"{tycoon}/report.json", f"{tycoon}/summary.md")),
        item("journey-tag-match", "journey",
             "Web and macOS play a full three-round tag match with bots to identical results",
             ev(f"{tag}/report.json", f"{tag}/summary.md")),
        item("journey-first-run", "journey",
             "First run: sign-in screen, choose a name, land in the hub, open every tab and the daily reward",
             ev(f"{vis}/web-signin.png", f"{vis}/web-hub.png", f"{vis}/web-daily.png",
                f"{e2e}/harness.log")),
        # ---- assets --------------------------------------------------------
        item("asset-inter-font", "asset",
             "Inter type family bundled under its OFL licence (weights 400-800)",
             ev(f"{a}/assets.md", f"{vis}/web-hub.png")),
        item("asset-original-avatars", "asset",
             "Procedurally painted blocky avatars, hats, faces and accessories (no third-party art)",
             ev(f"{a}/assets.md", f"{vis}/web-avatar.png")),
        item("asset-place-thumbnails", "asset",
             "Procedural place thumbnails per experience",
             ev(f"{a}/assets.md", f"{vis}/web-hub.png")),
        item("asset-brand", "asset",
             "Brickfolk wordmark and brick logo painted in code",
             ev(f"{a}/rebrand.md", f"{vis}/web-signin.png")),
        # ---- integrations --------------------------------------------------
        item("integration-websocket-protocol", "integration",
             "JSON-over-WebSocket protocol v1 (/ws) shared by all four clients",
             ev(f"{e2e}/server.log", f"{e2e}/report.json", f"{a}/data.md")),
        item("integration-sqlite", "integration",
             "sqlite3 store on the server (file per deployment)",
             ev(f"{e2e}/brickfolk-test.db", f"{a}/data.md")),
        item("integration-test-endpoints", "integration",
             "/health, /test/state and /test/control HTTP endpoints used by the harness",
             ev(f"{e2e}/harness.log", f"{e2e}/server-state.json")),
    ]
    # ---- visual matrix (web reference vs macOS actual) ---------------------
    for screen in VISUAL_SCREENS:
        base = f"{vis}/{screen}"
        metrics_rel = f"{base}/hub-{screen}-metrics.json"
        metrics_path = ev.run_dir / metrics_rel
        if not metrics_path.is_file():
            ev.problems.append(f"missing visual metrics: {metrics_rel}")
            continue
        metrics = json.loads(metrics_path.read_text())
        comparison = {
            "mode": "normalized",
            "reference": f"{base}/{metrics['reference']}",
            "actual": f"{base}/{metrics['actual']}",
            "diff": f"{base}/{metrics['diff']}",
            "different_pixels": metrics["different_pixels"],
            "total_pixels": metrics["total_pixels"],
            "normalization_evidence": metrics_rel,
        }
        ev(comparison["reference"], comparison["actual"], comparison["diff"], metrics_rel)
        items.append(item(
            f"visual-hub-{screen}", "visual",
            f"Hub '{screen}' screen: web (reference) vs native macOS, normalised comparison",
            ev(metrics_rel, f"{vis}/summary.json", f"{vis}/web-{screen}.png", f"{vis}/macos-{screen}.png"),
            comparison=comparison,
            raw_captures={"web": f"{vis}/web-{screen}.png", "macos": f"{vis}/macos-{screen}.png"},
        ))
    return items


def build_audits(ev, e2e, tycoon, tag):
    vis = f"{e2e}/visual"
    q = "evidence/quality"
    a = "evidence/audits"
    r = "evidence/reference"
    extra = {
        "source": [f"{r}/public-docs-roblox-wikipedia-obby-tycoon-avatar-home.txt",
                   f"{r}/public-docs-experience-badge-chat-party-friends.txt"],
        "navigation": [f"{vis}/web-signin.png", f"{vis}/web-hub.png", f"{e2e}/web-lobby.png",
                       f"{e2e}/web-results.png"],
        "roles": [f"{e2e}/server-state.json", f"{e2e}/report.json"],
        "states": [f"{e2e}/harness.log", f"{q}/server-test.log"],
        "responsive": [f"{e2e}/ios-lobby.png", f"{e2e}/android-lobby.png", f"{e2e}/macos-lobby.png",
                       f"{e2e}/web-lobby.png"],
        "data": [f"{e2e}/brickfolk-test.db", f"{q}/server-test.log"],
        "assets": [f"{q}/asset-inventory.txt"],
        "accessibility": [f"{q}/app-test.log"],
        "reliability": [f"{q}/fingerprint-list.txt", f"{q}/server-test.log", f"{e2e}/report.json",
                        f"{tycoon}/report.json", f"{tag}/report.json"],
        "rebrand": [f"{q}/rebrand-scan.txt"],
    }
    return [
        {"id": aid, "status": "verified", "verified_revision": None,
         "evidence": ev(f"{a}/{aid}.md", *extra[aid])}
        for aid in AUDIT_IDS
    ]


def build_checks(ev, e2e, tycoon, tag):
    vis = f"{e2e}/visual"
    q = "evidence/quality"
    a = "evidence/audits"
    evidence = {
        "functional": [f"{e2e}/report.json", f"{tycoon}/report.json", f"{tag}/report.json",
                       f"{q}/app-test.log", f"{q}/server-test.log", f"{q}/shared-test.log"],
        "visual": [f"{vis}/summary.json", f"{e2e}/summary.md"]
        + [f"{vis}/{s}/hub-{s}-metrics.json" for s in VISUAL_SCREENS]
        + [f"{vis}/{s}/hub-{s}-diff.png" for s in VISUAL_SCREENS],
        "build": [f"{q}/clean-checkout.log", f"{q}/build-web.log", f"{q}/build-ios.log",
                  f"{q}/build-apk.log", f"{q}/build-macos.log"],
        "quality": [f"{q}/format.log", f"{q}/analyze.log", f"{q}/node-check.log",
                    f"{q}/python-check.log"],
        "security": [f"{a}/security.md", f"{q}/secret-scan.txt", f"{q}/pub-outdated.log"],
    }
    return [
        {"id": cid, "status": "passed", "verified_revision": None, "evidence": ev(*evidence[cid])}
        for cid in CHECK_IDS
    ]


def load_sweeps(ev, run_dir, required=True):
    sweeps = []
    for rel in ("evidence/discovery/sweep-001.json", "evidence/discovery/sweep-002.json"):
        path = run_dir / rel
        if not path.is_file():
            if required:
                ev.problems.append(f"missing sweep evidence: {rel}")
            continue
        data = json.loads(path.read_text())
        sweeps.append({
            "revision": data["revision"],
            "new_items": data["new_items"],
            "frontier_empty": data["frontier_empty"],
            "audit_ids": list(AUDIT_IDS),
            "evidence": ev(rel),
            "method": data.get("method"),
        })
    return sweeps


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--run-dir", required=True, type=Path)
    ap.add_argument("--e2e", required=True, help="four-platform obby run, relative to the run dir")
    ap.add_argument("--e2e-tycoon", required=True)
    ap.add_argument("--e2e-tag", required=True)
    ap.add_argument("--revision", required=True)
    ap.add_argument("--status", default="active", choices=("active", "complete"))
    ap.add_argument("--next-action", default="Deliver: open the pull request and attach the evidence.")
    ap.add_argument("--without-sweeps", action="store_true",
                    help="intermediate pass that writes the inventory so the sweeps can read it; "
                         "the sweeps must be added by a final pass")
    args = ap.parse_args()
    if args.without_sweeps and args.status == "complete":
        ap.error("--without-sweeps cannot mark the run complete")

    run_dir = args.run_dir.resolve()
    state_path = run_dir / "state.json"
    state = json.loads(state_path.read_text())
    ev = Evidence(run_dir)

    items = build_items(ev, args.e2e, args.e2e_tycoon, args.e2e_tag)
    audits = build_audits(ev, args.e2e, args.e2e_tycoon, args.e2e_tag)
    checks = build_checks(ev, args.e2e, args.e2e_tycoon, args.e2e_tag)
    sweeps = load_sweeps(ev, run_dir, required=not args.without_sweeps)
    for record in items + audits + checks:
        record["verified_revision"] = args.revision
    for sweep in sweeps:
        if sweep["revision"] != args.revision:
            ev.problems.append(f"sweep revision {sweep['revision']} != {args.revision}")
    if ev.problems:
        print("Manifest not written:", file=sys.stderr)
        for p in sorted(set(ev.problems)):
            print(f"- {p}", file=sys.stderr)
        return 1

    state.update({
        "status": args.status,
        "iteration": int(state.get("iteration", 0)) + 1,
        "revision": args.revision,
        "frontier": [],
        "blockers": [],
        "unverified_assumptions": [],
        "items": items,
        "audits": audits,
        "checks": checks,
        "sweeps": sweeps,
        "next_action": args.next_action,
        "reference_access": {
            "mode": "public-documentation",
            "note": "The source is a commercial platform that was not run or purchased. The reference "
                    "is its publicly documented design (rules, modes, social systems, visual language) "
                    "captured under evidence/reference/. Visual parity is measured between Brickfolk's "
                    "own clients (web is the reference for native macOS), never against the original.",
        },
        "evidence_runs": {"obby": args.e2e, "tycoon": args.e2e_tycoon, "tag": args.e2e_tag},
    })
    state_path.write_text(json.dumps(state, indent=2) + "\n")
    print(f"wrote {state_path}: {len(items)} items, {len(audits)} audits, {len(checks)} checks, {len(sweeps)} sweeps")
    return 0


if __name__ == "__main__":
    sys.exit(main())
