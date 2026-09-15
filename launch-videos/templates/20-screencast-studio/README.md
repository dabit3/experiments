# 20 — Screencast Studio

Devin launch video (macOS / native iOS) in the style of a polished screen
recording (Screen Studio / Loom): a centred, drop-shadowed app window on a soft
wallpaper, a smoothed cursor, auto zoom-ins on click regions, subtle window
scale on interaction, and clean captions beneath the window.

1920x1080 · 30fps · 47.6s · composition id `Main`.

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # H.264
npx remotion studio                       # live preview
npx tsc --noEmit                          # typecheck
```

Assets are read from the shared `launch-videos/assets/` folder via
`Config.setPublicDir("../../assets")` — nothing is copied into this template.

## Scenes (`src/scenes.ts`)

| # | id | length | what happens |
|---|----|--------|--------------|
| 1 | `hook` | 3.4s | Window fades/scales in on the empty prompt (`web-1`, macOS chip). Caption: "Devin now runs on Mac." |
| 2 | `context` | 5.2s | Slow push-in on `web-1`. "Before, iOS teams QA'd by hand or waited 20+ minutes for CI." → "No coding agent could build, run and tap through an iPhone app." |
| 3 | `choosePlatform` | 7.2s | Cursor glides to the platform chip, clicks; zoom into the picker as `web-1` cross-fades to `web-4` (macOS selected); click, zoom back out. |
| 4 | `prompt` | 7.0s | Click the prompt box, zoom in, type the iOS request, click send; cross-fade to the session (`web-13`) and push in on Devin's reply. |
| 5 | `simulator` | 8.0s | `web-13` → Simulator loading (`web-11`) → running feature checks (`web-10`); pan across the phone, then push in on the test list. The overlay cursor fades because these captures already contain a pointer. |
| 6 | `pullRequest` | 6.6s | Cross-fade to `web-9` (PR panel), cursor to the PR title, then to "Ready to merge" with a zoom-in. |
| 7 | `outcome` | 6.4s | Window recedes; three statements under a Geist Mono label: minutes not CI round-trips · only Mac cloud agent · same security, no price increase. |
| 8 | `endCard` | 3.8s | Devin lockup, "Build, run and test iOS apps in the cloud.", `devin.ai`. |

Retime by editing the `seconds` values in `src/scenes.ts`; every scene reads
its own frame count from `scenes[id].duration`.

## Structure

- `src/components/Window.tsx` — macOS-style window, screenshot clipping, click-centred zoom transform.
- `src/components/Cursor.tsx` — eased cursor keyframes, press + ripple.
- `src/components/Caption.tsx` — caption pill under the window.
- `src/components/Typewriter.tsx` — typed prompt over the placeholder.
- `src/zoom.ts`, `src/handoff.ts` — zoom timelines and the cursor/zoom states shared across scene boundaries.
- `src/tokens.ts` — typed access to `assets/tokens.json` (colours, type, easings).
