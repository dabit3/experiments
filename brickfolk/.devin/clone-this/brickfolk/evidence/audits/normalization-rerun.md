# Android retry outcome

The retries at `evidence/tests/multiplayer-2026-09-15T21-26-24` and
`evidence/tests/multiplayer-2026-09-15T21-37-12` did not complete the required
four-client Obby journey. The second retry started a fresh software emulator
and waited for its package manager, network and load to settle.

In the last retry, all four clients joined the room. Web, iOS and macOS finished.
Android remained at checkpoint 0, with stale inputs, until the round ended.
Its display showed countdown at 1502 seconds and gameplay at 1538 seconds;
the server had already entered results at 1457 seconds. Its results report
arrived at 1596 seconds. There is no valid Android gameplay capture from this
attempt. The harness subsequently exited with
`Timed out waiting for server idle before visual tour` at 1848 seconds.

The raw harness log, Android marker probes, per-client recordings, aligned
four-way recording and available screenshots remain in the last retry
directory. It has no completed `report.json`; no successful report was
fabricated. Agreement reports alone do not establish that Android completed
the course. This attempt is failed evidence.

The host reports `kern.hv_support=0`. Its legacy Android emulator uses
`-accel off` under software emulation. System ANRs and multi-minute frame lag
are recorded in the attempts. The emulator was stopped after the last retry.
Safe independent verification continues with web and native macOS. Those
two-client tests must not replace the four-client completion requirement.

Resume condition: provide an Android emulator with hardware acceleration
available to the harness, then repeat the four-platform Obby test with fresh
captures and results. Refresh the manifest, edited review, discovery sweeps and
final verifier afterward. The durable run remains blocked until then.

## Fresh native Release verification

The production-equivalent macOS Release build completed successfully after the
Debug product was moved out of the harness search path. The running executable
was confirmed inside `Build/Products/Release/Brickfolk.app`.

These fresh web/macOS runs passed with server/client state and leaderboard
agreement:

| Experience | Evidence run | Checksum |
| --- | --- | --- |
| Skyline Obby | `multiplayer-2026-09-15T22-19-16` | `0604703a` |
| Brick Tycoon | `multiplayer-2026-09-15T22-22-14` | `2f1d181c` |
| Freeze Tag Arena | `multiplayer-2026-09-15T22-25-33` | `389f937d` |

Each run's seven normalized web/macOS visual comparisons passed with zero
differing cells. Hub/social retain the failing unfiltered comparisons (one
differing cell each). The 8px sensitivity control detects 2,001 differing
cells, and the repeated-capture noise baseline has zero differences.
These runs verify the approved normalization; they do not satisfy the blocked
four-platform journey.

The final edited review is `evidence/clone/normalization-review/review.mp4`
with `review-edl.json`: 114.4 seconds, eleven chapters, captions, platform
labels, a failed four-client excerpt, and an explicit overall BLOCKED verdict.
The successful web/macOS section is labelled as a subset throughout.
Original reports and recordings were not modified.

The focused computer-use Release retest and its edited recording are indexed
in `font-ui-retest.md`. It independently checks text readability and navigation.
The quality suite, clean builds and ten comparator controls are under
`evidence/quality/`. All evidence in this final checkpoint describes revision
`sha256:07b6054c364f3d4ed5ff59136e2473ca8c1f216c1218208d359d684030bc8226`.
Historical Debug runs remain preserved but are not used for this Release gate.

# Normalization rerun environment interruption

`tests/multiplayer-2026-09-15T20-56-29` built all four clients successfully
and started the shared Obby room. At about 1,577 seconds the Node harness
exited on an unhandled recording/log write error:

```
Error: ENOSPC: no space left on device, write
errno: -28
code: ENOSPC
syscall: write
```

The host reported only 132 MiB available on its 123 GiB data volume. This
attempt has no passing multiplayer report and is not used as completion
evidence. Its raw captures, logs and recordings are retained.

Stopped the orphaned test recorders and client. Removed only generated
`app/build` outputs from three earlier disposable Brickfolk clean-copy
directories, recovering about 7.3 GiB. No source files, captures or logs were
deleted. The successful current clean-copy build is retained.

The next attempt reuses the unchanged four freshly built clients
(`--no-build`) with fresh server fixtures. The interrupted run's successful
build logs remain independently valid; gameplay and visual completion must
come from a subsequent passing run.
