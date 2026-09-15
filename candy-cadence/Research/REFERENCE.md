# Reference audit — 13 September 2026

## Access and observations

Reference: **pop'n music 14 FEVER! (2006)**, within the requested 2006-onward era.
Read the official product page and inspected its actual published JPEGs before implementation.

- https://www.konami.com/arcadegames/products/am_popn_14/
- https://www.konami.com/products_master_kam/jp_publish/am_popn_14/jp/ja/images/g01.jpg
  Observed: narrow black nine-lane chart in the center; illustrated dancers on both sides;
  tiny rounded colored descending notes; circular receptors; vivid pink, lime, yellow
  and purple framing; large outlined title; score/combo bottom-left; segmented
  multicolor groove gauge beneath the chart; “FEVER!” feedback.
- https://www.konami.com/products_master_kam/jp_publish/am_popn_14/jp/ja/images/g02.jpg
  Observed: chunky slanted mode banners, halftone backgrounds, rainbow checkerboard,
  flat cartoon figures with heavy outlines, instructional speech bubbles.
- https://www.konami.com/products_master_kam/jp_publish/am_popn_14/jp/ja/images/am_popn14.jpg
  Observed: pink cabinet; nine wide candy-like physical buttons in staggered rows.
- https://www.highwaygames.com/arcade-machines/pop-music-fever-9726/
  Documents nine buttons in two rows, colored falling pop notes, timing bar, upbeat songs.
- https://remywiki.com/AC_pnm_14
  Documents 5/9-button modes, Challenge, Super Challenge, Battle and NET competition.

Official text describes a dance-music theme, over 540 tracks and online competition.
Screenshots are small archival promotional images; original arcade software, original
timing behavior, cabinets and playable NET service are inaccessible. No ROMs, game
assets or original songs are extracted or redistributed.

## Application decisions (authored/inferred, not observed parity)

Candy Cadence uses **native landscape iPad**: nine simultaneously usable large touch
targets and two side dancers need more surface than an iPhone. SwiftUI menus and
SpriteKit gameplay use original vector art: Mallow the headphone rabbit and Fizzy
the roller-skating cat. A pink/cream candy carnival shell surrounds the dark chart.
White/yellow/green/blue/red/blue/green/yellow/white buttons alternate lower/upper rows.
Original score windows, charts and music are authored here; they are not claims
about Konami's implementation. Each player has a full nine-lane chart on their own
iPad. WebSocket competition is original LAN room functionality.

Two original structured instrumental songs have melody, chords, bass, percussion,
intro, verse, chorus and ending. Charts use intentional repeating/answering phrases,
alternating hands, center accents, sweeps and two-note chords; no random falling notes.

## Evidence matrix

| ID | Requirement | Verification |
|---|---|---|
| R1 | Nine lanes, staggered candy buttons, pop faces | Native screenshot and touch test |
| R2 | Side dancers, patterned framing, expressive feedback | Recorded moving native scene |
| R3 | Timing windows, combo, groove and chart exhaustion | Server unit/integration tests |
| R4 | Song selection and audible authored chart/music | Generated asset validation + native recording |
| R5 | Guest room, two ready peers, common start, live rival score | Two actual simulator clients + server log |
| R6 | Results, rematch, disconnect/rejoin | Protocol tests + native recorded journey |
| R7 | Manual controls and labeled automated driver | Touch evidence + same-path driver |

The installed clone-this skill's research, inventory, provenance and evidence
workflow is used. Its zero-pixel/no-approximation gate is inapplicable under the
user's express visual-approximation allowance; that strict gate is not passed.
No literal pixel parity is claimed.
