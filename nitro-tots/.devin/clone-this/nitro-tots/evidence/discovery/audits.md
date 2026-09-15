# Parity audits — Nitro Tots

All ten mandatory audits were run against the final revision recorded in
`state.json`. "Reference" always means the public design documentation
(`evidence/reference/`), never the running commercial game (see
`source-access-boundary.md`).

## source
- Reference enumerated: two public documents (series overview; latest mainline
  entry with controls, items, modes, HUD notes, battle, GP, time trials).
- Every requirement in `requirements-inventory.md` cites its class
  (observed / inferred / inaccessible). No requirement depends on running the
  original. Result: **verified** (boundary recorded, nothing inaccessible is
  claimed).

## navigation
- Screen graph: title → {garage, track, settings, online}; online → lobby →
  race → podium → (next race | lobby | title); garage/track/settings → back to
  title; race → pause → {resume, quit to title}.
- Every `Screen` enum value is reachable and has a back/exit path
  (`app/lib/main.dart`, `_go`). Deep-link/test entry via `?screen=` verified by
  `test/visual_parity.py`. Result: **verified**.

## roles
- Roles: host (creates room, may change settings and start), guest (join by
  code, ready-up), bot (server-side), spectator-of-results (any client after
  finishing). Host-only actions are enforced server side
  (`packages/nitro_server/lib/src/room.dart`, `settings`/`start_match` require
  `isHost`) and tested by `server_test.dart`. Result: **verified**.

## states
- Connection: offline, connecting, online, reconnecting, failed
  (`ConnState`); each has distinct copy/colour in `_ConnPill` and is rendered by
  the `online (<state>)` smoke tests.
- Room: lobby → racing → results → match-over, plus empty lobby, waiting for
  players, all-ready, and error toasts (`room_full`, `no_such_room`, `not_host`,
  `unknown_type`).
- Race: countdown, racing, wrong-way, hit/stunned, shielded, boosting, jumping,
  finished, spectating. Result: **verified**.

## responsive
- Smoke tests pump every menu screen at phone (360×780 @3x), tablet
  (834×1194 @2x) and desktop (1440×900 @1x) in light and dark themes with
  semantics enabled and assert no layout exceptions (`app/test`).
- `NtScreen` scales padding/typography at 480/900 px breakpoints; safe areas
  applied on iOS; HUD anchors to `MediaQuery.padding`. Result: **verified**.

## data
- All match data originates on the server (authoritative sim); clients
  reconcile against snapshots. Points table, standings, race results and the
  final result hash are computed server side and mirrored by clients; equality
  is asserted by `test/verify_room.py` across clients. Persistence: profile,
  settings, ghosts via `shared_preferences`. Result: **verified**.

## assets
- Fonts: Fredoka, Nunito (OFL licences bundled). Audio: 21 generated WAVs (19 cues + 2 music loops) from
  `tools/gen_audio.py`. Art: code-drawn. Icons: Material rounded set.
  No third-party or source-game asset present (`audit-rebrand.txt`).
  Result: **verified**.

## accessibility
- Semantics labels on icon buttons (`NtIconButton.tooltip` → `Tooltip` +
  semantics), 44 px minimum hit targets, focus traversal and keyboard
  activation for menus, reduce-motion setting honoured by all animated
  widgets, colour tokens pass 4.5:1 for body text in both themes
  (`tokens.dart` `ink`/`inkSoft` on `surface`). Smoke tests run with the
  semantics tree enabled. Result: **verified** (screen-reader testing on real
  devices not performed — recorded as a caveat in the README).

## reliability
- Reconnect/resume with token (`server_test.dart`), duplicate-message
  cooldowns, server rejects malformed types, audio failures degrade to silent
  play, countdown and list indices clamped, room GC after empty. Live 3-client
  GP runs completed twice with identical hashes across all clients
  (`evidence/multiplayer/`). Result: **verified**.

## rebrand
- `audit-rebrand.txt`: zero matches for source vocabulary in shipped code,
  assets, docs, tests, tools. Bundle IDs `dev.nitrotots.*`, product name
  "Nitro Tots", original copyright string. Result: **verified**.
