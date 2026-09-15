# 04 / Luxury Editorial Magazine

A contemporary launch edition built around **scale contrast and asymmetric
spreads**. An oversized cover title faces a genuine tight crop of the Mac menu.
A wider environment image sits beside a narrow caption, followed by a clean cut
to a generous recording. The two iPhone examples replace one another at exactly
the same coordinates. The web recording is another large demonstration spread;
the iPad image then faces a narrow text column beneath the oversized “Layouts”
margin word. The closing spread keeps that same real iPad result beside the CTA.

Motion is editorial: short horizontal reveals for screenshots and extending
masthead rules, clean cuts into recordings, and an aligned image replacement.
No page flips, simulated application state, typography movement during
demonstrations, stock imagery, or decorative animation.

## Render

From `product-launch-videos/` using the foundation's Node >=22.12 / npm / FFmpeg
environment:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run lint
npm run typecheck
npm test
npm run templates:list
npm run render -- --template 04-luxury-editorial-magazine
npm run still -- --template 04-luxury-editorial-magazine --frame 60
npm run still -- --template 04-luxury-editorial-magazine \
  --frames 0,60,126,180,330,450,600,750,960,1140
npm run contact-sheet -- out/04-luxury-editorial-magazine
```

The independent entry is `entry.tsx`; composition ID is
`LuxuryEditorialMagazine`. `index.ts` only exports the descriptor; no shared
registry changes are required. Outputs, screenshots, fonts, and recordings
remain in the project's ignored directories. No public deployment is needed.

## Editing

Edit the typed complete `config.ts`, or copy the render's
`out/04-luxury-editorial-magazine/resolved-props.json`, edit it, and pass the
complete object using `--props path/to/props.json`. Partial configs are not merged.

- `copy`: feature name, opening, benefit, all action captions, pricing, CTA, URL.
  Headings wrap naturally and reduce in size for longer text. Keep demo captions
  around 80 characters or fewer and inspect renders after substantial copy edits.
- `durations`: seconds for all seven scenes. Metadata and all sequence offsets
  derive from these; the default is 4/5/4/9/7/6/5 = **40 seconds**. Both videos
  stay at 1×, and the shared component rejects trims beyond the original clip.
- `media`: typed original asset names, contain/cover mode, normalized crop
  anchors, source-pixel crop windows, and source offsets for videos. Preserve
  all report counts. Defaults contain every evidence report without cropping.
- `editorial.coverFraming`: independent opening crop on `media.environment.asset`.
  The default is x600/y895/w880/h495 in the 2988×1622 original screenshot. If
  replacing the environment source, update both crop windows to fit its pixels.
- `brand`: neutral presentation colors, approved font family, heading/body
  sizing, line height, tracking, and title gap. Heading size scales the editorial
  type sizes proportionally; typography is regular NB International throughout.
  The shared font gate blocks rendering until original fonts load.
- `layout`: common outer margin, image padding, gutter, and reserved demo caption
  height. `layout.grid` gives cover image/text geometry, environment and iPad
  caption rail widths, image top/height, and closing image/text positions.
- `editorial`: all supplementary labels, explicit still captions, edition and
  separate-session note, margin words, cover/caption/side/margin/closing type
  sizes, and proportional logo width.
- `motion.revealFrames`: still-window horizontal reveals (default 14 frames).
  Capped at one fifth of the scene duration so shorter edits retain a hold.
  Set to 0 for cuts.
- `motion.revealDirection`: `left` or `right`. Does not move the source pixels.
- `motion.coverRevealDelay`: opening-window delay in frames (default 3).
- `motion.ruleFrames`: masthead-rule extension (default 12).
- `motion.iphoneSplit`: first iPhone still's share of the scene (default 0.5).
  Must be strictly between 0 and 1; preserve readable holds for both reports.

All motion is deterministic and driven by Remotion frames. Changing layout
dimensions is an art-direction edit: keep source boxes positive and inside
1920×1080, leave room for text, then render and inspect the result.

## Media and claims

`attribution.json` maps every default use to source/output times, crop coordinates,
and required labels. Original hashes and provenance are in the shared asset
manifest and `MEDIA-ATTRIBUTION.md`. The original direction is section 4 of the
ignored `public/assets/pasted-1789430547875.txt`.

The two videos are web recordings, not Simulator recordings. The shared
`SourceVideo` preserves playback rate and adds **Web QA example** outside the
test recording. iPhone/iPad scenes are composed stills from separate sessions.
Afterhours Maze's **8 passed / 0 failed / 1 untested** counts are not changed,
cropped, or concealed. No unrelated app is presented as a before/after result.
No customer names, endorsements, App Store, signing, or real-device claims are
added. Source screenshots remain unmodified, including text in their real reports.

## Validation

The final default render must report 1920×1080, 30/1 fps, 1200 frames, 40 seconds:

```sh
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/04-luxury-editorial-magazine/04-luxury-editorial-magazine.mp4
```

The default sample passed asset verification, lint, TypeScript, all eight
TypeScript and three Python tests, template discovery, and the Vite build.
Its full H.264 export reports 1920×1080, 30/1 fps, 1200 frames, 40.000 seconds.
Ten decoded video frames cover the intro, reveal, product spreads, and closing;
the poster is frame 60. The contact sheet uses those genuine decoded frames.

Reproduce the non-default configuration check:

```sh
npx tsx src/templates/04-luxury-editorial-magazine/write-variant.ts
npm run render -- --template 04-luxury-editorial-magazine \
  --props out/04-luxury-editorial-magazine/variant/props.json \
  --output out/04-luxury-editorial-magazine/variant/variant.mp4
```

The helper writes a complete ignored props file with 3/4/3/6/4/4/4-second
scenes, longer two-line agent and CTA captions, rightward reveals, and a 40/60
iPhone split. The full variant is 28 seconds / 840 frames; inspect its agent
caption at frame 240 and closing caption at frame 780. The render CLI updates
the default output folder's metadata and resolved props even with a custom
video output path, so preserve those files before rendering a variant.

The sample is silent. Both supplied videos are web recordings and the
Simulator scenes use still images. Large arbitrary copy or layout changes
need another render inspection; source-video durations cannot exceed their
remaining source footage.
