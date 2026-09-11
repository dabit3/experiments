# Audit: rebrand

Searched `app/`, `server/`, `packages/`, docs and native project files for
template or third-party branding.

| Location | Value |
| --- | --- |
| Dart packages | `swapmate` (app), `swapmate_core`, `swapmate_server` with Swapmate descriptions |
| Android | `applicationId`/namespace `dev.swapmate.swapmate`, label "Swapmate", generated launcher icons |
| iOS | `CFBundleDisplayName` "Swapmate", bundle id `dev.swapmate.swapmate`, AppIcon set from the Swapmate mark |
| macOS | `PRODUCT_NAME = Swapmate`, `PRODUCT_BUNDLE_IDENTIFIER = dev.swapmate.swapmate`, AppIcon set |
| Web | `<title>Swapmate</title>`, description meta, `manifest.json` name/short_name "Swapmate", theme colour `#171B21`, favicon + icons from the mark |
| In-app copy | "Swapmate" wordmark and `SwapmateMark`; the variant is described generically ("team-up chess on two boards") |
| Docs | README / PROTOCOL use "Swapmate"; "Bughouse" appears only as the public rules name |

Removed during this audit: Flutter's `A new Flutter project.` description,
`flutter` template theme colours and lowercase app name in `web/manifest.json`
and `web/index.html`. No `com.example`, `flutter_app` or source-title strings
remain (grep for `example|A new Flutter|com\.example` across the native
projects returns nothing). No third-party logos, piece sets, sounds or
trademarked names are present (see assets audit).
