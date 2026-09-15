# Focused UI retest for PR #228

The persistent testing agent used fresh local accounts and an isolated database,
actual mouse input, and persisted web/native macOS Release builds at 1180×760.
Application, server and artwork sources are unchanged by this follow-up.
This pass verifies displayed source pixels and navigation, independently of
the screenshot comparator.

Both clients passed headline completeness/sharpness, readable Friends heading
and subtitle, Home → Friends → Home, Let’s play → Skyline lobby → Back to Home.
The web lobby was JH39 and the native lobby BX68. Each unclaimed daily-reward
sheet reappeared after returning; dismissing it revealed the functioning hub.

Native was dark theme and web light theme. This manual pass makes no claim of
cross-theme pixel equality. Fresh equivalent-theme captures are produced by
the separate deterministic harness.

Current evidence is copied unchanged under `evidence/clone/font-ui-pr228/`:
`retest-edited.mp4`, `{web,native}-{hub,social,lobby,returned-hub}.png`.
The testing agent stopped all its clients/services and confirmed no listeners
on 8080, 8090 or 9222 before the lead started the four-platform harness.

This focused pass did not cover gameplay, mobile layouts, synchronization or
comparator mathematics. Those are covered separately by the quality and
multiplayer scripts. The historical Debug virtual-Metal limitation remains
recorded in `arcade-ui.md`; it is not a failure of this Release retest.
