# Reference-access boundary — Nitro Tots (source: "Mario Kart")

## What the reference is

The source is a commercial console/handheld game series. It cannot be run,
purchased, downloaded or inspected in this environment, and its code, art,
audio, names, logos and characters are proprietary. The accessible reference is
therefore the **publicly documented game design**:

- `evidence/reference/public-docs-wikipedia-mariowiki.txt` — sanitized text
  captures of the Wikipedia series article and the Super Mario Wiki article
  for the most recent mainline entry (controls table, item rules, modes,
  HUD/interface notes, battle mode, Grand Prix/points, Time Trials with
  staff ghosts, mini-turbo tiers, slipstream, position-based item odds).

Everything inventoried below is derived from that public description. Nothing
was copied from the original game.

## Classification of requirements

| Class | Meaning | How it is handled |
| --- | --- | --- |
| **observed** | Described unambiguously in the public documentation (e.g. "3 laps", "item odds depend on race position", "Grand Prix cups of 4 races award points", "battle mode with balloons/points", "time trial with ghost", "drift → mini-turbo", "slipstream") | Implemented and verified in Nitro Tots. Inventory items carry the doc line they came from. |
| **inferred** | Present in the genre but only implied by the docs (exact stat curves, item probability tables, boost durations, track lengths, camera behaviour, menu flow details) | Designed independently for Nitro Tots and recorded as *original design decisions*, not as parity claims. They are verified against the Nitro Tots spec (`README.md`, `PROTOCOL.md`, `packages/nitro_core`). |
| **inaccessible** | Requires the running original (exact layouts, pixel colours, fonts, audio, timing, private online behaviour) | Not claimed. Visual parity is defined as *normalized parity between the four Nitro Tots clients with the web build as the baseline*, never against the original. |

## Rebrand / originality

- Name: **Nitro Tots**. Characters: Pip, Bea, Juno, Ozzie, Mabel, Kiki, Rocco,
  Tank. Karts: Jellybean, Tin Can, Bubble Buggy, Pinewood Racer, Rocket Scoot,
  Big Wheel. Tracks: Sprinkle Speedway, Mossy Hollow, Tin City Loop, Frostbite
  Pass. Arena: Bumper Bowl. Cups: Sugar Cup, Nitro Cup. Items: Turbo Can,
  Triple Turbo, Homing Rocket, Bouncy Orb, Syrup Slick, Bubble Shield,
  Thunder Zap, Comet Ride.
- Art: vector karts/characters/tracks drawn in code (`app/lib/game/*_art.dart`),
  original design tokens (`app/lib/theme/tokens.dart`), open-licensed fonts
  Fredoka (display) and Nunito (body).
- Audio: generated WAV assets from `tools/gen_audio.py` (no sampled audio).
- The only reference to the source title in the shipped tree is the
  clone-this manifest field `source`. `rg -i "mario|nintendo|luigi|bowser|koopa|shell"`
  over `app/lib packages README.md PROTOCOL.md` finds no product copy (see
  `evidence/discovery/audit-rebrand.txt`).

## Consequence for the completion claim

Completion is an evidence claim about the **accessible reference** (public
design documentation) plus the **Nitro Tots cross-platform parity contract**.
It is not, and must not be reported as, parity with the commercial game.
