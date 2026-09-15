# Media attribution and factual boundaries

All visual assets and original font binaries come from the user-supplied
`shared-assets.zip` for the Devin Mac launch. Their exact filenames, SHA-256
hashes, sizes, image dimensions and video metadata are recorded in
`src/shared/asset-manifest.json`. The binary originals stay ignored. This project
does not assert a license to redistribute them.

## Brand reference

The parent workflow verified the corrected Figma file:
https://www.figma.com/design/evS5ExlrnLrUCMPm395OHw/Devin?node-id=0-1

Its inspected raw styles supply the neutral canvas `#f7f6f5`, ink `#191919`,
white `#ffffff`, secondary ink `rgba(25,25,25,0.56)`, and subtle media mat
approximately `#edeceb`. No named Figma variable library was returned.
`src/shared/tokens.ts` scales these styles to 1080p motion compositions.

The bundled fonts came from the public Devin website, according to the verified
brand reference included in the bundle:

| Local file | Original website filename | Use |
| --- | --- | --- |
| NBInternationalPro-Regular.woff2 | NBInternationalPro_Regular-s.p.1zobv4yb0l45-.woff2 | Primary family `nbInternationalPro`, regular 400 |
| NBInternationalPro-Light.woff2 | NBInternationalPro_Light-s.p.2ha41b_ddzi59.woff2 | Optional family `nbInternationalPro Light`, weight 300 |
| GeistMono-Regular.woff2 | GeistMono_Regular-s.p.2tw7uc71e2v7r.woff2 | Sparse editorial indices, `Geist Mono`, regular 400 |

All four logo PNGs are supplied transparent original artwork. Their aspect ratios
are preserved by the media component. Black lockup:
`BLACK_NO_BG_DEVIN_LOCKUP_HORIZONTAL_WHITE.png`; white lockup:
`DEVIN_LOCKUP_HORIZONTAL_WHITE_TRANSPARENT.png`; avatars:
`DEVIN_AVATAR_SQUARE_BLACK_NO_BG.png` and `DEVIN_AVATAR_SQUARE_WHITE_NO_BG.png`.
Use appropriate artwork for the background; do not redraw or recolor it.

## Default edit map

| Output | Original asset | Trim / provenance / required context |
| --- | --- | --- |
| 0–4 seconds | Supplied Devin logo | Opening and main benefit, fonts above |
| 4–9 seconds | devin-web-4.png | Actual hosted environment menu with macOS selected |
| 9–13 seconds | agent-selector-cloud.mp4 | Source 0–4 seconds, 1×, agent mode/capability menu |
| 13–17.5 seconds | devin-web-14.png | Afterhours Maze iPhone still, **8 passed, 0 failed, 1 untested** |
| 17.5–22 seconds | devin-web-18.png | Large Dispatch iPhone still and final-review report |
| 22–29 seconds | devin-testing-2.mp4 | Source 0–7 seconds, 1×; **Web QA example** label throughout |
| 29–35 seconds | devin-web-19.png | Terra Table iPad still and acceptance report |
| 35–40 seconds | Supplied Devin logo / stable result | Pricing, CTA, URL |

The video recordings are **1918 × 1080 / 30 fps**, lasting **9.166667 seconds**
and **59.133333 seconds**, respectively. Neither is iOS Simulator footage.
The agent menu does not demonstrate macOS environment selection.

The native examples are separate stills from separate sessions. No part of the
foundation animates their internal UI state. Copy describes Simulator workflows;
there is no claim about App Store publishing, TestFlight, signing, real devices,
camera, Bluetooth, or Apple ID features.

Other supplied web/desktop/CLI screenshots are reference only in the common edit.
The Wisp screenshots contain failures: `devin-web-9.png` shows **12 passed,
3 failed, 2 untested**, and `devin-web-10.png` / `devin-web-11.png` also show
failures. Never describe these as all passing or crop away their counts.

`figma-cloud.png` and `figma-cloud-hero.png` are brand reference only. Do not
include their unrelated customer logos, statistics or marketing claims. No Notion
customer list is used. No customer endorsement, name or logo is invented.

## Template-specific map

Each producer adds `attribution.json` in its own template directory, using the
schema in `TEMPLATE-CONTRACT.md`. It identifies every used source and its
destination/source time range, crops and labels. Reuse the same shared default
source selections for comparability. Record any approved deviation explicitly.
