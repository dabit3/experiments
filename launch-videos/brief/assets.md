# Asset index

All paths are relative to `launch-videos/assets/`. Everything here is real Devin UI.
Screenshots are 16:9-ish PNGs at roughly 2880x1600-3024x1964 (retina); recordings are
H.264 MP4, no audio, max 1920px wide.

## Recordings (`recordings/`)

| File                        | Size      | Length | What it shows                                                                                   |
|-----------------------------|-----------|--------|--------------------------------------------------------------------------------------------------|
| `agent-selector-cloud.mp4`  | 1918x1080 | 9.2s   | Devin web home; user opens the agent/OS selector under the prompt box and picks a cloud agent.   |
| `devin-working-4.mp4`       | 1918x1080 | 14.7s  | Devin web session: Devin working through a task, sidebar with sessions, timeline of steps.       |
| `devin-testing-2.mp4`       | 1918x1080 | 59.1s  | Devin's testing-recording player: video of Devin driving an app on the left, "It should ..." checklist with pass counts on the right. |
| `pdf.mp4`                   | 1798x1080 | 42.3s  | Same testing-recording player layout with a document/PDF-style app under test.                   |
| `androidios.mp4`            | 1920x1148 | 22.4s  | macOS desktop: iPhone Simulator (left) and an Android emulator (right) running the same app side by side. Crop to the iPhone for iOS-only beats. |

## Screenshots (`screenshots/`)

Web app (`devin-web-*.png`):

| File               | What it shows                                                                                  |
|--------------------|-------------------------------------------------------------------------------------------------|
| `devin-web-1.png`  | Home: "Ask Devin to build features, fix bugs..." prompt with **macOS** pill selected below it.   |
| `devin-web-2.png`  | Home with `/` slash-command menu open (skills list).                                            |
| `devin-web-3.png`  | Home with "+" attachment menu → Actions submenu (Jira, Linear, Figma, Notion).                  |
| `devin-web-4.png`  | Home with OS picker open: Ubuntu / macOS / Windows.                                              |
| `devin-web-5.png`  | Home with Virtual environment → macOS nested menu.                                               |
| `devin-web-6.png`  | Home with model / effort pickers open.                                                           |
| `devin-web-7.png`  | Sessions sidebar expanded (Automations, Security, Review, Customize, session list incl. "Build Native Abliteration iOS App"). |
| `devin-web-8.png`  | Session: merged PR "Add tweets to @ValsAI..." with diff view.                                    |
| `devin-web-9.png`  | Session "Build Native Abliteration iOS App": Wisp iOS app in Simulator embedded in chat, environment-change suggestion banner. |
| `devin-web-10.png` | Session: PR "Add Wisp: native iOS chat client", Ready to merge, changes list.                    |
| `devin-web-11.png` | Testing recording: Wisp iPhone Simulator (chat app) + "It should reject invalid keys..." checklist, 6 passed. |
| `devin-web-12.png` | Testing recording: Wisp iPhone, another step highlighted.                                        |
| `devin-web-13.png` | Session: "Add Starcup Circuit native iPhone multiplayer kart racer" PR, Ready to merge, embedded demo videos. |
| `devin-web-14.png` | Session: Devin's summary message with "Reel Horizon: build, test, screenshot on iOS Simulator" bullets. |
| `devin-web-15.png` | Testing recording: Afterhours Maze iPhone game, checklist.                                       |
| `devin-web-16.png` | Settings: organization preferences.                                                              |
| `devin-web-17.png` | Settings: Usage & limits with spend chart.                                                       |
| `devin-web-18.png` | Dark session: "Simulator testing (iPhone 17 Pro, iOS 26.5, real Abliteration API)" with 6 iPhone screenshots grid. |
| `devin-web-19.png` | Testing recording: dark iPhone app (Terra Table) with checklist.                                 |

Desktop app (`devin-desktop-*.png`): Devin Desktop with file tree, prompt box, recent
sessions; `-4` model picker, `-5` code editor, `-6` sessions list, `-7` session detail
with "Clone Fishing Planet iOS" run, `-8` session with embedded video, `-9` "Transit
Atelier" iPhone Simulator recording.

CLI (`devin-cli-*.png`): Devin CLI in a terminal — `-1` session resume list,
`-2` `/model` picker, `-3` empty prompt "Ask Devin to build features, fix bugs...".

## Logos (`logos/`)

`devin-lockup-horizontal-black.png`, `devin-lockup-horizontal-white.png`,
`devin-avatar-black.png`, `devin-avatar-white.png`. See `brand.md`.

## Fonts (`fonts/`)

Empty by design. Drop licensed `NBInternationalPro-Regular.woff2` / `-Medium.woff2`
here to replace the Inter fallback.
