# Native two-peer computer-use acceptance plan

Preconditions: current Release installed once on two distinct landscape peers;
both complete displays calibrated; ordinary logged server reachable; BlackHole
48-kHz stereo verified; real Devin runtime available. No credentials required.

Source paths: `App/GameClient.swift` welcome identity reset/receive generation,
driver toggle and movement; `App/VoxelVanguardApp.swift` entry, ready, footer,
action gestures, Reliquary and joystick; `Server/game.mjs` combat/gear/retention;
`Server/server.mjs` same-identity resume; `App/Soundscape.swift` supported cues.
Reconfirm source line locations when using this plan on a later revision.

## Regression: room identity and sound cursor

1. Create/join an old room and naturally accumulate supported event IDs >=100.
   Turn drivers OFF and click Leave on both. Record PIDs before/after.
2. Without relaunch, Create/Join a fresh room and Ready both. Require new distinct
   player identities and unchanged app PIDs. Confirm both driver labels OFF.
3. Press RANGE. Require a new supported event ID below the old maximum and its
   chirp in captured PCM (correlation >=0.7).
4. Legitimately clear stage one; require no living enemies and drivers OFF.
   Wait >=3 seconds. Fire one RANGE cue, release, then Reconnect quickly enough
   that welcome still retains the event (<1.5 seconds). Do this separately for
   each peer. Require identical identity, exactly two connected peers, original
   cue correlation >=0.7, and no matching replay in the quiet post-welcome window.
   Retention timing misses or ambiguous mixed cues require an inconclusive result,
   not inference from an empty event list. Direct delayed old-generation message
   injection is outside this UI-only plan and must remain explicitly untested.

## Primary flow: actual Devin input, then separately labeled assistance

1. Leave/Create/Join a new room with drivers OFF. Observe both NOT READY for >=2s,
   then Aster-only Ready without starting; Ready Bramble to start.
2. On BOTH heroes use real computer holds/drags for movement, melee, range and
   dodge. Capture during the held drag. Require displacement >1 world unit,
   each action counter >=1 and actual hits >=1 before any driver enable.
   After natural HP loss, click HEAL: require positive HP gain and heal count >=1.
3. Reach a real cleared cache, open the five-card Reliquary, select gear on each
   peer. Require visible choices, changed item, equipment count >=1 and separate
   chest claims. Save `gui-end-state.json` while both drivers remain OFF.
4. Explicitly label driver assistance, enable BOTH drivers, confirm labels/logs.
   Require both bridge crossings and two equipment claims per peer, three-stage
   shared victory, same-identity rematch, and second shared victory. A manual
   rematch recovery must be labeled separately from automatic-rematch acceptance.
5. Require >=10 common client snapshot ticks and zero differences. Preserve
   actual dispatched action trace with screenshots and room-filtered server logs.
6. Validate exact PCM frame conservation, nonzero/no-clipping samples, supported
   cue timing, several visible clock anchors, and error-free final MP4 decode.
   Inspect final lobby, held-control, gear and result frames. Keep both apps live
   at a usable result or lobby. Report mixed audio, capture cadence/alignment,
   below-threshold cue checks and subjective-listening limitations honestly.
