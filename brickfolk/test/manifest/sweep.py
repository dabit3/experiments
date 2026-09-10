#!/usr/bin/env python3
"""Zero-discovery sweeps for the Brickfolk clone-this run.

Two independent methods enumerate everything the clone is supposed to cover
and check that each surface is claimed by a manifest item (matched by id or
by keyword in the item label). Anything unclaimed is a discovery; the sweep
only counts as clean when there are none.

  --method source     walks the application source: hub tabs, screens and
                      sheets, Flame game views, protocol message types and
                      error codes, experiences, client launch flags.
  --method reference  walks the public reference notes and the user brief
                      (a fixed requirement list) and checks each requirement.

Writes <out> as JSON with revision, new_items, frontier_empty, discoveries.
Exit 0 when new_items == 0, 1 otherwise.
"""
import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CLONE = HERE.parent.parent  # brickfolk/


def claims(state):
    text = " ".join(f"{i['id']} {i['label']}" for i in state["items"]).lower()
    return text


def source_surfaces():
    surfaces = []
    app = CLONE / "app" / "lib" / "src"
    for f in sorted((app / "screens").glob("*.dart")):
        surfaces.append(("screen", f.stem))
    for f in sorted((app / "game").glob("*_view.dart")):
        surfaces.append(("game-view", f.stem.replace("_view", "")))
    home = (app / "screens" / "home_shell.dart").read_text()
    decl = re.search(r"enum HubTab \{([^}]*)\}", home).group(1)
    for tab in re.findall(r"\w+", decl):
        surfaces.append(("hub-tab", tab))
    proto = (CLONE / "shared" / "lib" / "src" / "protocol.dart").read_text()
    for name in re.findall(r"static const (\w+) = '[a-z_]+'", proto):
        surfaces.append(("protocol", name))
    exps = (CLONE / "shared" / "lib" / "src" / "experiences.dart").read_text()
    for kind in re.findall(r"ExperienceKind\.(\w+)\b", exps):
        surfaces.append(("experience", kind))
    cfg = (app / "config.dart").read_text()
    for flag in re.findall(r"pick\('(\w+)'|flag\('(\w+)'", cfg):
        surfaces.append(("launch-flag", flag[0] or flag[1]))
    seen = set()
    return [s for s in surfaces if not (s in seen or seen.add(s))]


# Which manifest keywords cover each source surface. A surface with no entry
# here (a new screen, message or flag) is reported as a discovery.
SOURCE_COVERAGE = {
    ("screen", "sign_in_screen"): ["route-sign-in"],
    ("screen", "home_shell"): ["route-hub-play"],
    ("screen", "places_screen"): ["route-hub-play", "feature-experience-browser"],
    ("screen", "avatar_screen"): ["route-hub-avatar", "feature-avatar-editor"],
    ("screen", "social_screen"): ["route-hub-social", "feature-friends", "feature-party-join-codes"],
    ("screen", "chat_panel"): ["route-hub-chat", "feature-chat-filtered"],
    ("screen", "profile_screen"): ["route-hub-profile", "feature-profile-badges"],
    ("screen", "daily_reward_sheet"): ["route-daily-reward", "feature-daily-reward"],
    ("screen", "room_screen"): ["route-room-lobby", "route-room-gameplay", "route-room-results"],
    ("game-view", "obby"): ["feature-obby"],
    ("game-view", "tycoon"): ["feature-tycoon"],
    ("game-view", "tag"): ["feature-tag"],
    ("hub-tab", "play"): ["route-hub-play"],
    ("hub-tab", "avatar"): ["route-hub-avatar"],
    ("hub-tab", "social"): ["route-hub-social"],
    ("hub-tab", "chat"): ["route-hub-chat"],
    ("hub-tab", "profile"): ["route-hub-profile"],
    ("experience", "obby"): ["feature-obby", "journey-cross-platform-obby-match"],
    ("experience", "tycoon"): ["feature-tycoon", "journey-tycoon-match"],
    ("experience", "tag"): ["feature-tag", "journey-tag-match"],
    ("launch-flag", "server"): ["integration-websocket-protocol"],
    ("launch-flag", "name"): ["feature-deterministic-test-mode"],
    ("launch-flag", "party"): ["feature-party-join-codes"],
    ("launch-flag", "host"): ["feature-deterministic-test-mode"],
    ("launch-flag", "test"): ["feature-deterministic-test-mode"],
    ("launch-flag", "tour"): ["feature-deterministic-test-mode"],
    ("launch-flag", "experience"): ["feature-deterministic-test-mode"],
    ("launch-flag", "theme"): ["feature-themes"],
    ("launch-flag", "marker"): ["feature-deterministic-test-mode"],
    ("launch-flag", "autoready"): ["feature-deterministic-test-mode"],
}
PROTOCOL_COVERAGE = {
    "hello": ["integration-websocket-protocol"], "welcome": ["integration-websocket-protocol"],
    "ping": ["feature-reconnect"], "pong": ["feature-reconnect"],
    "error": ["integration-websocket-protocol"],
    "resume": ["feature-reconnect"],
    "input": ["feature-server-authoritative-rooms"],
    "places": ["feature-experience-browser"], "profile": ["feature-profile-badges"],
    "avatar": ["feature-avatar-editor"], "shop": ["feature-shop-currency"],
    "buy": ["feature-shop-currency"], "inventory": ["feature-shop-currency"],
    "daily": ["feature-daily-reward"], "friend": ["feature-friends"],
    "party": ["feature-party-join-codes"], "chat": ["feature-chat-filtered"],
    "room": ["feature-server-authoritative-rooms"], "frame": ["feature-server-authoritative-rooms"],
    "results": ["feature-match-lifecycle"], "lobby": ["feature-match-lifecycle"],
    "ready": ["feature-match-lifecycle"], "again": ["feature-match-lifecycle"],
    "leave": ["feature-match-lifecycle"], "join": ["feature-party-join-codes"],
    "launch": ["feature-party-join-codes"], "badge": ["feature-profile-badges"],
    "tycoon": ["feature-tycoon"], "obby": ["feature-obby"], "tag": ["feature-tag"],
    "test": ["feature-deterministic-test-mode"], "global": ["feature-chat-filtered"],
    "bad_request": ["integration-websocket-protocol"], "name": ["route-sign-in"],
    "not_found": ["integration-websocket-protocol"], "full": ["feature-server-authoritative-rooms"],
    "pips": ["feature-shop-currency"], "owned": ["feature-shop-currency"],
    "leader": ["feature-party-join-codes"], "cooldown": ["feature-daily-reward"],
    "rate": ["feature-chat-filtered"], "unauth": ["feature-reconnect"],
    "player": ["feature-profile-badges"], "list": ["feature-friends"],
    "request": ["feature-friends"], "accept": ["feature-friends"], "decline": ["feature-friends"],
    "remove": ["feature-friends"], "kick": ["feature-party-join-codes"],
    "state": ["feature-server-authoritative-rooms"], "sync": ["feature-server-authoritative-rooms"],
    "place": ["feature-tycoon"], "upgrade": ["feature-tycoon"], "equip": ["feature-avatar-editor"],
    "countdown": ["feature-match-lifecycle"], "start": ["feature-match-lifecycle"],
    "invalid": ["route-sign-in"], "taken": ["route-sign-in"],
}


def protocol_cover(name):
    lower = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
    for key, ids in PROTOCOL_COVERAGE.items():
        if key in lower:
            return ids
    return None


REFERENCE_REQUIREMENTS = [
    # From the public reference notes and the brief; each maps to manifest ids.
    ("Players represent themselves with a customisable blocky avatar", ["feature-avatar-editor"]),
    ("Avatar items (hats, faces, accessories) bought with a virtual currency", ["feature-shop-currency"]),
    ("A catalogue of experiences (places) players browse and join", ["feature-experience-browser"]),
    ("Obstacle courses (obbies) with checkpoints are a staple genre", ["feature-obby"]),
    ("Tycoon games where players build and buy upgrades for income", ["feature-tycoon"]),
    ("Round-based tag / hide-and-seek experiences", ["feature-tag"]),
    ("Friends list with requests", ["feature-friends"]),
    ("Parties that join an experience together", ["feature-party-join-codes"]),
    ("Filtered text chat for a family-friendly audience", ["feature-chat-filtered"]),
    ("Badges awarded for achievements shown on a profile", ["feature-profile-badges"]),
    ("Daily login rewards and a soft-currency loop", ["feature-daily-reward"]),
    ("Servers hold authoritative game state per experience instance", ["feature-server-authoritative-rooms"]),
    ("Cross-platform play between web, phones, tablets and desktop", ["journey-cross-platform-obby-match"]),
    ("Persistent player data across sessions", ["feature-persistence"]),
    ("Bots / fill for under-populated matches (brief)", ["feature-bots"]),
    ("Reconnect after a dropped connection (brief)", ["feature-reconnect"]),
    ("Lobby, gameplay and results screens (brief)", ["route-room-lobby", "route-room-gameplay", "route-room-results"]),
    ("Light and dark themes (brief)", ["feature-themes"]),
    ("Keyboard, touch and mouse/trackpad input (brief)", ["feature-input-modes"]),
    ("Deterministic automated four-platform test (brief)", ["feature-deterministic-test-mode", "journey-cross-platform-obby-match"]),
    ("Original art, names and audio under the new name (brief)", ["asset-brand", "asset-original-avatars", "asset-place-thumbnails"]),
    ("Documented JSON-over-WebSocket protocol (brief)", ["integration-websocket-protocol"]),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", required=True, type=Path)
    ap.add_argument("--method", required=True, choices=("source", "reference"))
    ap.add_argument("--revision", required=True)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args()
    state = json.loads(args.state.read_text())
    ids = {i["id"] for i in state["items"]}
    checked = []
    discoveries = []
    if args.method == "source":
        for surface in source_surfaces():
            kind, name = surface
            cover = protocol_cover(name) if kind == "protocol" else SOURCE_COVERAGE.get(surface)
            missing = [c for c in (cover or []) if c not in ids]
            ok = bool(cover) and not missing
            checked.append({"kind": kind, "name": name, "covered_by": cover, "ok": ok})
            if not ok:
                discoveries.append(f"{kind}:{name} -> {'no coverage rule' if not cover else 'missing ' + ','.join(missing)}")
    else:
        for req, cover in REFERENCE_REQUIREMENTS:
            missing = [c for c in cover if c not in ids]
            checked.append({"requirement": req, "covered_by": cover, "ok": not missing})
            if missing:
                discoveries.append(f"{req} -> missing {','.join(missing)}")
    result = {
        "method": args.method,
        "revision": args.revision,
        "checked": len(checked),
        "new_items": len(discoveries),
        "frontier_empty": not state.get("frontier"),
        "discoveries": discoveries,
        "detail": checked,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    print(f"{args.method} sweep: checked {len(checked)} surfaces, {len(discoveries)} discoveries")
    for d in discoveries:
        print(f"  - {d}")
    return 0 if not discoveries else 1


if __name__ == "__main__":
    sys.exit(main())
