#!/usr/bin/env bash
# Panic Pantry — build the edited review video from the newest four-way E2E run
# and the browser smoke run (see test/review-video/build.mjs for the cut).
#
# Usage:
#   test/review-video.sh                          # newest evidence/e2e/<stamp> run
#   test/review-video.sh --e2e <dir> [--smoke <dir>] [--out <dir>] [--no-gif]
#
# Output (next to the e2e run unless --out is given): review-video.mp4,
# review-video.gif, review-video.json (edit decision list), review-video.log.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
export PATH="/opt/homebrew/bin:$PATH"

command -v ffmpeg >/dev/null || { echo "review-video: ffmpeg is required (brew install ffmpeg)" >&2; exit 2; }
(cd "$here" && npm install --no-audit --no-fund >/dev/null)

cd "$root"
exec node "$here/review-video/build.mjs" "$@"
