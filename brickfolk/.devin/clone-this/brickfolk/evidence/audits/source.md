# Source audit — reference access boundary

**Source:** Roblox (commercial online game platform). **Clone:** Brickfolk.

## What was used as the reference
The original was **not run or purchased**. The reference is the publicly documented
design captured in `evidence/reference/`:
- `public-docs-roblox-wikipedia-obby-tycoon-avatar-home.txt` — platform overview,
  avatar/economy model, the obby and tycoon genres, home/discovery surface.
- `public-docs-experience-badge-chat-party-friends.txt` — experiences, badges,
  chat filtering, parties/joining friends, friends system.

From these the run inventoried: an avatar-based hub, an experience browser with
thumbnails, three archetypal experiences (obby, tycoon, tag), avatar editor with
purchasable items and a soft currency, friends, parties with join codes, filtered
chat, profiles with badges, daily rewards, server-authoritative rooms and
persistent player data.

## What is inferred / inaccessible
Anything requiring the running original — exact layouts, timings, physics
constants, item catalogues, sounds, moderation word lists — is **inferred** and
was designed independently. No item in the manifest claims parity with the
original's pixels, assets or numeric tuning; every `visual` item compares
Brickfolk's own web build (reference) against its native macOS build (actual).

## Entry points enumerated
- Sign-in -> Hub (Play / Avatar / Social / Chat / Profile tabs, daily reward sheet)
- Hub -> Room (lobby -> countdown -> gameplay -> results -> play again / leave)
- Server: `/ws` protocol v1, `/health`, `/test/state`, `/test/control` (test mode only)

Status: verified against the reference notes; frontier empty.
