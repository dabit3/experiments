import type { LaunchProps } from "./schema";

// Brand tokens from launch-videos/brief/brand.md
export const defaultBrand: LaunchProps["brand"] = {
  paper: "#F7F6F5",
  surface: "#EFEFEF",
  line: "#E7E7E7",
  ink: "#191919",
  inkMuted: "#7D7D7D",
  inkSubtle: "#919191",
  accent: "#2200FF",
  black: "#141414",
  blackRaised: "#1F1F1F",
  blackRaisedAlt: "#252525",
  white: "#FFFFFF",
  fontFamily: '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
  monoFontFamily: '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
  logoLight: "logos/devin-lockup-horizontal-black.png",
  logoDark: "logos/devin-lockup-horizontal-white.png",
};

// Copy from launch-videos/brief/launch-mac-vm.md (verbatim)
export const defaultContent: LaunchProps["content"] = {
  featureName: "Devin on Mac",
  eyebrow: "New",
  headline: "Devin now runs in a Mac VM",
  headlineAccentWord: "Mac VM",
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

export const defaultMedia: LaunchProps["media"] = {
  pick: { src: "screenshots/devin-web-4.png", kind: "image", aspect: 2988 / 1622 },
  work: { src: "recordings/devin-working-4.mp4", kind: "video", startFrom: 0 },
  simulator: {
    src: "recordings/androidios.mp4",
    kind: "video",
    startFrom: 90,
    aspect: 1920 / 1148,
    // iPhone Simulator only; the Android emulator on the right is cropped out.
    crop: { x: 0.105, y: 0.125, w: 0.275, h: 0.66 },
  },
  verify: { src: "recordings/devin-testing-2.mp4", kind: "video", startFrom: 1110 },
  result: { src: "screenshots/devin-web-9.png", kind: "image", aspect: 2988 / 1628 },
};

export const defaultScenes: LaunchProps["scenes"] = [
  { id: "open", type: "statement", durationInFrames: 120, showLogo: true },
  {
    id: "pick",
    type: "product",
    durationInFrames: 180,
    media: "pick",
    caption: defaultContent.captions[0],
    captionIndex: "01",
    layout: "full",
    holdOutFrames: 0,
    speedBadge: false,
  },
  { id: "title-build", type: "title", durationInFrames: 60, index: "02", text: defaultContent.useCases[0] },
  {
    id: "work",
    type: "product",
    durationInFrames: 255,
    media: "work",
    caption: defaultContent.captions[1],
    captionIndex: "02",
    layout: "full",
    holdOutFrames: 0,
    speedBadge: false,
  },
  { id: "title-qa", type: "title", durationInFrames: 60, index: "03", text: defaultContent.useCases[2] },
  {
    id: "simulator",
    type: "product",
    durationInFrames: 225,
    media: "simulator",
    caption: defaultContent.captions[2],
    captionIndex: "03",
    layout: "split",
    mask: { kind: "shutter-vertical", durationInFrames: 30, delayInFrames: 6, slit: true },
    holdOutFrames: 0,
    speedBadge: false,
  },
  {
    id: "verify",
    type: "product",
    durationInFrames: 210,
    media: "verify",
    caption: defaultContent.captions[4],
    captionIndex: "04",
    layout: "full",
    holdOutFrames: 0,
    speedBadge: false,
  },
  {
    id: "result",
    type: "product",
    durationInFrames: 150,
    media: "result",
    caption: defaultContent.captions[6],
    captionIndex: "05",
    layout: "full",
    mask: { kind: "iris", durationInFrames: 30, delayInFrames: 6, slit: false },
    holdOutFrames: 0,
    speedBadge: false,
  },
  { id: "outro", type: "outro", durationInFrames: 90 },
];

export const defaultProps: LaunchProps = {
  brand: defaultBrand,
  content: defaultContent,
  media: defaultMedia,
  scenes: defaultScenes,
  mask: { kind: "shutter-horizontal", durationInFrames: 30, delayInFrames: 6, slit: true },
  lighting: { edgeGlow: 0.5, keyLine: true, vignette: 0.5 },
  layout: {
    safeMargin: 96,
    mediaWidth: 1536,
    mediaTop: 72,
    radius: 12,
    captionSize: 30,
  },
};
