# Devin brand tokens

Extracted from the Devin design file in Figma (`Devin` file, Page 1: website frames
"Devin | The AI Software Engineer", "Devin Cloud | Devin", "Devin Desktop | Devin").
Use these as the default values of every template's `brand` prop. Keep them editable.

## Color

| Token            | Hex       | Usage                                                        |
|------------------|-----------|--------------------------------------------------------------|
| `paper`          | `#F7F6F5` | Primary light background (page / nav surface)                |
| `surface`        | `#EFEFEF` | Cards, tiles, secondary light surfaces                       |
| `surfaceAlt`     | `#FCFCFC` | Elevated light surface                                       |
| `line`           | `#E7E7E7` | Hairlines, dividers, card borders                            |
| `ink`            | `#191919` | Primary text and primary button fill on light                |
| `inkMuted`       | `#7D7D7D` | Secondary text / eyebrow labels                              |
| `inkSubtle`      | `#919191` | Tertiary text, metadata                                      |
| `accent`         | `#2200FF` | Devin blue. One accent only: highlighted word, route line, progress, cursor |
| `black`          | `#141414` | Dark section background                                      |
| `blackRaised`    | `#1F1F1F` | Dark cards / panels                                          |
| `blackRaisedAlt` | `#252525` | Dark hover / secondary panel                                 |
| `white`          | `#FFFFFF` | Text on dark, button text on ink                             |

Rules: black-and-white first, `accent` sparingly (a single word in a headline, a
progress indicator, one line). No gradients other than a subtle grain/paper texture
if the direction calls for it. Shadows on light: `0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)`
(product screenshots on paper) or `0 0 8px #DDD` (soft card).

## Type

Brand typeface: **NB International Pro** (Regular 400, Medium 500). It is licensed and
is NOT in this repo. Templates must expose `brand.fontFamily` and default to a metric-
compatible fallback stack: `"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif`.
Load Inter via `@remotion/google-fonts/Inter` so renders are deterministic. If a
licensed `NBInternationalPro-*.woff2` is dropped into `launch-videos/assets/fonts/`,
templates should pick it up via `@font-face` (document the hook in the template README).

Mono (code, captions that quote commands, timecodes): **Geist Mono** (Regular/Medium),
via `@remotion/google-fonts/GeistMono` or fallback `ui-monospace, SFMono-Regular, Menlo, monospace`.

Scale (from the site, 1512px artboard; scale x1.27 for 1920 video):

| Role          | Size / line-height / tracking            | Weight  |
|---------------|-------------------------------------------|---------|
| Display       | 70.4px / 70.4px / -2.67px                 | Medium  |
| Heading 2     | 64px / 74.4px / -2.34px                   | Medium  |
| Heading 3     | 26.8px / 33.5px / -0.42px                 | Medium  |
| Heading 5     | 21.5px / 32.2px / -0.31px                 | Regular |
| Body          | 16px / 22.4px / -0.31px                   | Regular |
| Body small    | 14.9px / 20.2px / -0.23px                 | Regular |
| Label / nav   | 14px / 19.6px / -0.15px                   | Regular |
| Eyebrow       | 11.3px / 17px / +0.28px, uppercase        | Medium  |

Headlines are sentence case, tight tracking, left- or center-aligned; never all caps
except eyebrows. Accent word in a headline is set in `accent` (e.g. "Build with **Devin**").

## Spacing, radius, layout

- 8px base grid. Common paddings: 12 / 16 / 24 / 32 / 45 / 74 / 84 / 146px.
- Section gutter on the site: 45px outer, 120px inner. For 1920x1080 video use a 96px
  safe margin and a 12-column grid with 24px gutters.
- Radius: 16px for cards and screenshot frames, 2px for primary buttons, pill (9999px)
  for nav chips, 8px for small chips/badges.
- Buttons: `ink` fill, `white` 16px text, 2px radius, 12px horizontal padding, 33px tall.
- Product screenshots sit flat, front-facing, with a 1px `line` border or the soft
  shadow above. Never skew or bend the UI.

## Logo

`assets/logos/`:

- `devin-lockup-horizontal-black.png` (use on light)
- `devin-lockup-horizontal-white.png` (use on dark)
- `devin-avatar-black.png`, `devin-avatar-white.png` (square mark)

Minimum clear space = the height of the mark. Do not recolor, outline, or animate the
mark's geometry; fade/slide the whole lockup only.

## Motion

Deliberate and mechanical: ease-out cubic for entrances (300-500ms), ease-in-out for
layout moves (500-800ms), no overshoot/elastic/bounce unless the template direction
explicitly asks. Captions hold at least 2.5s. Product footage plays at 1x unless a speed
badge is shown.
