# Blocker: Android emulator cannot boot on this host

Affected IDs: `journey-e2e-android`, `visual-android-lobby`, `visual-android-results`.

## Missing capability

Hardware virtualization inside the build VM. The host is an `Apple M4 (Virtual)`
macOS 26.5.2 guest with `kern.hv_support: 0`; nested Hypervisor.framework is not
exposed, so the Android emulator's `qemu-system-aarch64` cannot start with HVF and
the software fallback never reaches `sys.boot_completed`.

```
emulator -accel-check          -> "accel: 0 Hypervisor.Framework OS X Version 26.5"
sysctl kern.hv_support         -> 0
qemu log                       -> HVF error: HV_UNSUPPORTED
                                  qemu-system-aarch64-headless: failed to initialize HVF: Invalid argument
adb devices                    -> emulator-5554 offline (never becomes `device`)
```

## Attempted safe alternatives (all failed)

| Attempt | Result |
| --- | --- |
| `emulator -avd voxelhearth -no-snapshot -gpu swiftshader_indirect` | HVF init failure, process exits |
| `-accel off` / `-feature -HVF` (TCG software CPU) | boots to `offline`, `sys.boot_completed` never set after 15+ min |
| `-no-window -no-audio -memory 1536 -skin 720x1280`, `-wipe-data` | same as above |
| direct `qemu-system-aarch64-headless` with the AVD images | same HVF error |
| kill/restart `adb` + emulator, fresh AVD (API 36 `google_apis`, arm64) | same |
| x86_64 system image | not runnable on arm64 host without HVF either |

## What *is* verified for Android

* `flutter build apk --debug` succeeds (`../checks/build-android.txt`) and the
  APK installs with `adb install` when a device is present.
* The Android client shares 100% of the Dart code exercised on web/iOS/macOS;
  `MainActivity.kt` only forwards `--es VH_*` intent extras to the launch
  channel, mirroring the iOS/macOS Swift shims that *are* exercised.
* The harness supports it end to end: `VH_PLATFORMS=web,ios,android,macos ./test/multiplayer-e2e.sh`.

## Resume condition

Run the harness on a machine with working hardware virtualization (bare-metal
Apple silicon Mac, or Linux/Windows with KVM/WHPX): the emulator must reach
`adb shell getprop sys.boot_completed` = `1`. Then re-run the full four-platform
E2E and update `journey-e2e-android` and the Android visual items.
