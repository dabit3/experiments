# panic_pantry_server

Authoritative Panic Pantry game server: rooms, join codes, reconnection, deterministic
bots, a fixed 20 Hz tick loop, and a test harness API. See `../PROTOCOL.md`.

```sh
dart pub get
dart run bin/server.dart --port 8787            # optional: --seed 1234 --host 127.0.0.1
dart test
```
