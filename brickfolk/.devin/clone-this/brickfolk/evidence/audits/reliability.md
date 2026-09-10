# Reliability audit

- Reconnect: token resume within the grace period keeps the seat and re-sends
  room state (`server-test.log`). Client retries with backoff and shows a banner.
- Determinism: same seed + same inputs -> same checksum on web, iOS, Android and
  macOS (`report.json`: identical=true for all four; server checksum equal).
- Slow devices: the harness scales match timers on software-emulated Android
  (`--match-length-scale`) without changing simulation ticks per second.
- Rooms close when the last human leaves; parties survive a member going offline.
- Rate limits on chat; name collisions rejected; stale test names reclaimable
  only in test mode.
- Builds are reproducible from a clean checkout (`quality/clean-checkout.log`).
- Fingerprint: `quality/fingerprint-list.txt` lists the hashed files.

Evidence: `report.json` (obby), tycoon and tag `report.json`, `server-test.log`.
