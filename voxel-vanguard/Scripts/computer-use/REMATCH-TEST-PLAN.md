# Focused late-enable / new-room automatic-rematch recipe

This supplements `TEST-PLAN.md`; it does not repeat the full manual-control flow.
Use the setup, dynamic simulator discovery/calibration, concurrent capture and
actual Devin-runtime dispatch instructions in `README.md`. The emitter does not
dispatch controls itself. Preserve each exact payload, returned screenshot and
commit; label ordinary in-app driver actions separately.

## Preconditions

- Both real simulator apps are launched with `-automation -autoRematch`, their
  evidence files enabled, and a clean logged server. Record process IDs/start
  times once; do not relaunch either app during the following room transition.
- Two complete landscape displays are visible. Inspect the tiny footer target
  after focusing the intended window; never infer a successful toggle from a tap.
- Choose distinct, unused old/fresh room codes. Do not embed device IDs or local
  paths in a reusable action plan. Text-field input may need a settled/blurred
  state before Create/Join; preserve any rejected attempt rather than hiding it.

## One adversarial flow

1. **Old result accumulation:** Create/Join through the UIs. Let ordinary drivers
   reach round-two results and remain ON there for at least 12 seconds. Record
   the authoritative result timestamp and the later Aster driver-disable event.
   This must exceed the nine-second / 90-pulse first-round readiness delay.
2. **New identity without new process:** Turn Aster OFF visibly, Leave Expedition
   on both peers, type the fresh room code, then Create/Join. Require two new
   identities and unchanged process IDs/start times. Aster must not auto-ready.
3. **Entire playing phase OFF:** Let Bramble's ordinary driver ready itself and
   click Aster's *lobby* Ready. Keep Aster OFF throughout fresh round one. Bramble
   may complete the cooperative encounter alone; GUI assistance is allowed if
   necessary but must be logged. Require a first result with Aster still OFF.
4. **Late enable only:** At first-round results, enable Aster with its footer
   control. Do not click Rematch or send additional game input. Require exactly
   one Aster `ready` after approximately nine seconds (8–12 seconds allows
   scheduling variation), not immediately or never. Require both clients to
   observe round-two playing with the same fresh identities.
5. **Second shared outcome:** Let both visible drivers finish. Require matching
   shared result/score snapshots, at least ten common client ticks with zero
   mismatches, and no Rematch click in the dispatched trace after lobby Ready.
   Leave both apps at usable results. Stop capture and collect read-only logs.

## Interpretation and media

`App/GameClient.swift` resets `resultFrames` for each new welcomed identity and
readies round-one players only when `resultFrames >= 90 && !me.ready`. The counter
is private and not directly logged: the delayed Ready is behavioral evidence,
not a claimed measurement of every pulse. The old expedition must first
accumulate result time; otherwise this test does not distinguish stale counters.

Validate raw PCM buffer/frame conservation, nonzero signal, no clipping, video/
audio decode and multiple visible host-clock anchors with existing helpers.
Keep original captures and all failed probe outputs. Soundscape serializes
effects, so dense combat can delay the 587-Hz clear cue beyond a subsecond
analysis window; an explicitly labeled extended diagnostic window can establish
eventual output, but must not turn an initial timing miss into a low-latency pass.
The 120-ms correlation template is not a full 1.5-second victory-tone template.
Report mixed simulator audio, constant gain, capture cadence and untested
subjective listening. Do not imply physical-device, PvP or autonomous-Devin
runtime coverage.
