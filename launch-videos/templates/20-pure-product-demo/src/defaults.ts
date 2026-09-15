import type { LaunchProps } from "./schema";

// Default props = the "Devin on Mac" test launch (brief/launch-mac-vm.md) rendered with
// the Devin brand tokens (brief/brand.md). Swap launches by editing this file or by
// passing --props=./my-launch.json to `remotion render`.

export const defaultBrand: LaunchProps["brand"] = {
  paper: "#F7F6F5",
  surface: "#EFEFEF",
  line: "#E7E7E7",
  ink: "#191919",
  inkMuted: "#7D7D7D",
  inkSubtle: "#919191",
  accent: "#2200FF",
  black: "#141414",
  white: "#FFFFFF",
  fontFamily: '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
  monoFontFamily: '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
  logoLight: "logos/devin-lockup-horizontal-black.png",
  logoDark: "logos/devin-lockup-horizontal-white.png",
  fontFaces: [],
};

export const defaultContent: LaunchProps["content"] = {
  featureName: "Devin on Mac",
  eyebrow: "New",
  headline: "Devin now runs in a Mac VM",
  headlineAccent: "Mac VM",
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
};

// Crops are fractions of the source frame. Screenshots are retina (~2990x1624); the
// crops below keep the surrounding chrome so the viewer always knows where they are.
export const defaultMedia: LaunchProps["media"] = {
  homeMac: {
    src: "screenshots/devin-web-1.png",
    kind: "image",
    width: 2990,
    height: 1624,
    crop: { x: 0.15, y: 0.2, w: 0.7, h: 0.7 },
  },
  osPicker: {
    src: "screenshots/devin-web-4.png",
    kind: "image",
    width: 2988,
    height: 1622,
    crop: { x: 0.15, y: 0.2, w: 0.7, h: 0.7 },
  },
  work: {
    src: "recordings/devin-working-4.mp4",
    kind: "video",
    width: 1918,
    height: 1080,
    startFrom: 0,
    playbackRate: 3,
  },
  simulator: {
    src: "recordings/androidios.mp4",
    kind: "video",
    width: 1920,
    height: 1148,
    startFrom: 90,
    playbackRate: 1,
    // The recording shows a Mac desktop with an iPhone Simulator (left) and an Android
    // emulator (right); crop to the iPhone half of the desktop for the iOS beat.
    crop: { x: 0.07, y: 0.127, w: 0.29, h: 0.66 },
  },
  live: {
    src: "screenshots/devin-web-14.png",
    kind: "image",
    width: 2986,
    height: 1626,
  },
  ipad: {
    src: "screenshots/devin-web-19.png",
    kind: "image",
    width: 2982,
    height: 1626,
  },
  darkPhone: {
    src: "screenshots/devin-web-18.png",
    kind: "image",
    width: 2978,
    height: 1626,
  },
  result: {
    src: "screenshots/devin-web-12.png",
    kind: "image",
    width: 2978,
    height: 1622,
  },
};

export const defaultScenes: LaunchProps["scenes"] = [
  { id: "statement", kind: "statement", durationInFrames: 75 },
  {
    id: "request",
    kind: "demo",
    durationInFrames: 150,
    shots: [
      { media: "homeMac", at: 0, zoom: { from: 1, to: 1.03, originX: 0.5, originY: 0.7 } },
      { media: "osPicker", at: 66, zoom: { from: 1.03, to: 1.05, originX: 0.5, originY: 0.7 } },
    ],
    caption: 0,
    stage: 0,
    captionSide: "bottom",
    speedLabel: null,
  },
  {
    id: "build",
    kind: "demo",
    durationInFrames: 144,
    shots: [{ media: "work", at: 0 }],
    caption: 1,
    stage: 1,
    captionSide: "bottom",
    speedLabel: "3x",
  },
  {
    id: "simulator",
    kind: "demo",
    durationInFrames: 210,
    shots: [{ media: "simulator", at: 0 }],
    caption: 2,
    stage: 2,
    captionSide: "right",
    speedLabel: null,
  },
  {
    id: "live",
    kind: "demo",
    durationInFrames: 165,
    shots: [{ media: "live", at: 0 }],
    caption: 3,
    stage: 2,
    captionSide: "bottom",
    speedLabel: null,
  },
  {
    id: "sizes",
    kind: "demo",
    durationInFrames: 180,
    shots: [
      { media: "ipad", at: 0 },
      { media: "darkPhone", at: 90 },
    ],
    caption: 5,
    stage: 3,
    captionSide: "bottom",
    speedLabel: null,
  },
  {
    id: "result",
    kind: "demo",
    durationInFrames: 246,
    shots: [{ media: "result", at: 0, zoom: { from: 1, to: 1.02, originX: 0.45, originY: 0.35 } }],
    caption: 6,
    stage: 4,
    captionSide: "bottom",
    speedLabel: null,
  },
  { id: "outro", kind: "outro", durationInFrames: 180 },
];

export const defaultLayout: LaunchProps["layout"] = {
  marginX: 64,
  marginTop: 56,
  marginBottom: 56,
  captionBand: 104,
  captionColumn: 480,
  gap: 32,
  frameRadius: 12,
  captionSize: 30,
};

export const defaultProps: LaunchProps = {
  brand: defaultBrand,
  content: defaultContent,
  media: defaultMedia,
  scenes: defaultScenes,
  layout: defaultLayout,
  posterFrame: 470,
};
