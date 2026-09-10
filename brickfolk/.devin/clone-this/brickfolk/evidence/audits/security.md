# Security notes (check: security)

- No secrets in the tree (`quality/secret-scan.txt`); no `.env` files tracked.
- Server binds `0.0.0.0:8080` by default (a LAN play server); `--host 127.0.0.1`
  restricts it. There is no TLS termination in the server itself; put it behind
  a reverse proxy for public deployment (documented in README).
- Test endpoints (`/test/*`) exist only with `--test-mode`; otherwise they return 404.
- Inputs validated: names, chat length/rate, party codes, purchase ids; SQL uses
  bound parameters via `sqlite3` prepared statements.
- Resume tokens are 32-character codes drawn from `Random.secure()` (a seeded
  RNG only in `--seed` mode) and stored as-is in `players.token`; they are
  bearer credentials for a game profile, not for any real-world account.
- Dependencies use caret ranges in `pubspec.yaml`; `quality/pub-outdated.log`
  records the audit-time state.
- Chat filter masks blocked words, strips URLs and phone-number-like digit runs.
