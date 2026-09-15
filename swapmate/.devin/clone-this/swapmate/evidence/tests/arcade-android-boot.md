# Android cold boot investigation

The macOS host reports `kern.hv_support=0`. The Android 15 ATD emulator uses
software TCG and SwiftShader. The fresh run started its emulator at 02:03 UTC.
Before Swapmate was installed or joined, Android's `system_server` aborted:
`Caused HeapTaskDaemon failure: SuspendAll timeout`, with a 2.257 s final wait.
The dependent permission-controller and network-stack processes then exited
with `DeadSystemException`. The crash buffer is retained as
`e2e-20260911T015803Z/android-boot-crash.log`.

The existing framework watchdog multiplier was confirmed as `10`. ART's
separate thread-suspension limit was still at its default. The Android 15 source
maps `dalvik.vm.thread-suspend-timeout-ms` to `-XX:ThreadSuspendTimeout=`:

- https://android.googlesource.com/platform/frameworks/base/+/android-15.0.0_r1/core/jni/AndroidRuntime.cpp
- https://android.googlesource.com/platform/art/+/android-15.0.0_r1/runtime/parsed_options.cc
- https://android.googlesource.com/platform/art/+/android-15.0.0_r1/runtime/thread_list.cc

In the disposable rooted emulator, the limit was set to 60000 ms and zygote
restarted so the runtime reads it:

```sh
adb shell setprop dalvik.vm.thread-suspend-timeout-ms 60000
adb shell setprop ctl.restart zygote
```

Both `dalvik.vm.thread-suspend-timeout-ms=60000` and
`ro.hw_timeout_multiplier=10` were read back. This adjusts emulator startup,
not chess clocks, protocol deadlines or application assertions. The four-client
match had not begun; its gameplay, screenshots and assertions run after boot.
Final recovery and match outcome are recorded separately in the E2E log.
