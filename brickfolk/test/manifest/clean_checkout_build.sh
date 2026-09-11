#!/usr/bin/env bash
# Builds every Brickfolk target from a clean checkout: the set of files git
# would commit (tracked + untracked, honouring .gitignore) is copied to a fresh
# directory with no build/, .dart_tool/ or node_modules/, dependencies are
# fetched and all four clients, the server and the test suites are built and
# run there. The log lands in the clone-this run directory as
# evidence/quality/clean-checkout.log; a failing step fails the script.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
repo="$(git -C "$root" rev-parse --show-toplevel)"
rel="${root#"$repo"/}"
q="$root/.devin/clone-this/brickfolk/evidence/quality"
mkdir -p "$q"
log="$q/clean-checkout.log"
work="${BRICKFOLK_CLEAN_DIR:-$HOME/brickfolk-clean-checkout}"

exec > >(tee "$log") 2>&1
echo "# clean checkout build $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# source: $repo/$rel  ->  $work"
rm -rf "$work"
mkdir -p "$work/$rel"
git -C "$repo" ls-files --cached --others --exclude-standard -z -- "$rel" \
  | grep -zv "^$rel/.devin/" \
  | rsync -a --files-from=- --from0 "$repo/" "$work/"
cd "$work/$rel"
echo "# files copied: $(find . -type f | wc -l | tr -d ' ')"
for d in build .dart_tool node_modules app/build app/.dart_tool app/ios/Pods; do
  [ -e "$d" ] && { echo "unexpected $d in clean copy" >&2; exit 1; }
done

step() {
  echo; echo "==> $*"
  local t0=$SECONDS
  "$@"
  echo "<== ok in $((SECONDS - t0))s"
}

step bash -c 'cd shared && dart pub get'
step bash -c 'cd server && dart pub get'
step bash -c 'cd app && flutter pub get'
step bash -c 'cd test/e2e && npm ci --no-audit --no-fund'
step bash -c 'cd shared && dart test'
step bash -c 'cd server && dart test'
step bash -c 'cd server && dart build cli -o build/cli && ls -la build/cli/bundle/bin/server && build/cli/bundle/bin/server --help >/dev/null'
step bash -c 'cd app && flutter test'
step bash -c 'cd app && flutter build web --release'
step bash -c 'cd app && flutter build ios --simulator --debug'
step bash -c 'cd app && flutter build apk --release'
step bash -c 'cd app && flutter build macos --release'
echo
echo "# artefacts"
ls -la app/build/web/main.dart.js app/build/app/outputs/flutter-apk/app-release.apk
ls -d app/build/ios/iphonesimulator/Runner.app app/build/macos/Build/Products/Release/*.app
echo "clean checkout build passed"
