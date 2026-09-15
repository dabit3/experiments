import type { LaunchProps } from "./schema";

// Default props = the "Devin on Mac" test launch (brief/launch-mac-vm.md) with the
// brand tokens from brief/brand.md. Swap launches by replacing `content` and `media`.

const WEB_SCREENSHOT_ASPECT = 2990 / 1624;
const RECORDING_ASPECT = 1918 / 1080;

export const defaultProps: LaunchProps = {
  brand: {
    paper: "#F7F6F5",
    surface: "#EFEFEF",
    surfaceAlt: "#FCFCFC",
    line: "#E7E7E7",
    ink: "#191919",
    inkMuted: "#7D7D7D",
    inkSubtle: "#919191",
    accent: "#2200FF",
    black: "#141414",
    white: "#FFFFFF",
    fontFamily:
      '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
    monoFontFamily:
      '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
    logoLight: "logos/devin-lockup-horizontal-black.png",
    logoDark: "logos/devin-lockup-horizontal-white.png",
  },
  content: {
    featureName: "Devin on Mac",
    eyebrow: "New",
    headline: "Devin now runs in a Mac VM",
    accentWord: "Mac VM",
    subhead:
      "Build, run, and test Mac and iOS apps in a cloud Mac — with a live iPhone Simulator in your session.",
    captions: [
      "Pick macOS when you start a session — same price as Linux.",
      "Devin builds the app in Xcode and runs the full test suite.",
      "It taps, types, and scrolls through the app like a person.",
      "Watch it live in the iPhone Simulator tab — and tap in yourself.",
      "Reproduce a bug, fix it, and prove the fix on screen.",
      "Check iPhone and iPad sizes, dark mode, and orientations.",
      "Ship with a PR that shows the app working — not a 20-minute CI wait.",
    ],
    useCases: [
      "Build & test a feature",
      "Reproduce & fix a bug",
      "QA before shipping",
      "Screens, sizes & dark mode",
      "Upgrade Swift & dependencies",
    ],
    stages: ["Request", "Build", "Run & test", "Verify", "PR"],
    cta: { label: "Start a Mac session", url: "app.devin.ai" },
    outroLine: "The only coding agent with a cloud Mac.",
    speedBadge: "3x",
  },
  media: {
    hero: {
      src: "screenshots/devin-web-1.png",
      kind: "image",
      aspect: WEB_SCREENSHOT_ASPECT,
    },
    pick: {
      src: "screenshots/devin-web-4.png",
      kind: "image",
      aspect: 2988 / 1622,
    },
    work: {
      src: "recordings/devin-working-4.mp4",
      kind: "video",
      startFrom: 150,
      aspect: RECORDING_ASPECT,
    },
    simulator: {
      src: "recordings/androidios.mp4",
      kind: "video",
      startFrom: 90,
      aspect: 1920 / 1148,
      // iPhone Simulator only; the Android emulator on the right is cropped out.
      crop: { x: 0.06, y: 0.128, w: 0.295, h: 0.73 },
    },
    live: {
      src: "screenshots/devin-web-11.png",
      kind: "image",
      aspect: 2986 / 1630,
    },
    result: {
      src: "screenshots/devin-web-12.png",
      kind: "image",
      aspect: 2978 / 1622,
    },
  },
  scenes: [
    { id: "title", kind: "title", durationInFrames: 105, media: "hero", exit: "left" },
    { id: "pick", kind: "demo", durationInFrames: 105, media: "hero", caption: 1, stage: 1, reveal: "cut" },
    { id: "pick-menu", kind: "demo", durationInFrames: 120, media: "pick", stage: 1, reveal: "lift" },
    { id: "work", kind: "demo", durationInFrames: 240, media: "work", caption: 2, stage: 2, reveal: "sleeve" },
    { id: "simulator", kind: "demo", durationInFrames: 240, media: "simulator", caption: 3, stage: 3, reveal: "fold" },
    { id: "live", kind: "demo", durationInFrames: 210, media: "live", caption: 4, stage: 4, reveal: "lift" },
    { id: "result", kind: "demo", durationInFrames: 210, media: "result", caption: 7, stage: 5, reveal: "sleeve" },
    { id: "outro", kind: "outro", durationInFrames: 120, media: "result" },
  ],
  layout: {
    margin: 80,
    headerHeight: 56,
    captionStripHeight: 84,
    gap: 24,
    platePadding: 16,
    plateRadius: 16,
    mediaRadius: 10,
    outroPlateWidth: 880,
  },
  motion: {
    titleExit: 22,
    reveal: 36,
    caption: 14,
    layoutMove: 24,
  },
  surface: {
    shadowStrength: 1,
    texture: 0.6,
  },
};

/** Frame used for `npm run still` and the Poster composition. */
export const posterFrame = 690;
