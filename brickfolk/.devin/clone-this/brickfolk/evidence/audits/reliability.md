# Reliability audit

Arcade redesign: see `arcade-ui.md` for the macOS Debug virtual-Metal assertion
and successful native Release retest. Do not count that Debug manual run as
passing. The final clean-copy log verifies all four targets from source without
existing build or dependency directories.

The former visual blocker is preserved in `arcade-visual-blocker.md`.
The user approved scoped font-edge normalization; its bounds, calibration and
independent controls are in `font-edge-normalization.md`. Current pass/fail
results are in the manifest's evidence runs. The focused Release UI retest is
recorded in `font-ui-retest.md`.

- Reconnect: token resume within the grace period keeps the seat and re-sends
  room state (`server-test.log`). Client retries with backoff and shows a banner.
- Determinism: the fresh web/macOS reports verify client/server agreement.
  The required four-client rerun remains blocked by Android's software-emulator
  stall; see `normalization-rerun.md`. Earlier four-client passes are historical
  evidence and are not promoted to the current revision.
- Slow devices: the harness scales match timers on software-emulated Android
  (`--match-length-scale`) without changing simulation ticks per second.
- Rooms close when the last human leaves; parties survive a member going offline.
- Rate limits on chat; name collisions rejected; stale test names reclaimable
  only in test mode.
- Builds are reproducible from a clean checkout (`quality/clean-checkout.log`).
- Fingerprint: `quality/fingerprint-list.txt` lists the hashed files.

Evidence: `report.json` (obby), tycoon and tag `report.json`, `server-test.log`.
