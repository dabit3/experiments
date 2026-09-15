import type { LaunchProps } from "./schema";

export const WIDTH = 1920;
export const HEIGHT = 1080;
export const FPS = 30;

// Brand tokens from brief/brand.md. NB International Pro is licensed and not in the
// repo; Inter (loaded via @remotion/google-fonts) is the deterministic fallback.
export const defaultBrand: LaunchProps["brand"] = {
  paper: "#F7F6F5",
  surface: "#EFEFEF",
  surfaceAlt: "#FCFCFC",
  line: "#E7E7E7",
  ink: "#191919",
  inkMuted: "#7D7D7D",
  inkSubtle: "#919191",
  accent: "#2200FF",
  black: "#141414",
  blackRaised: "#1F1F1F",
  white: "#FFFFFF",
  fontFamily: '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
  monoFontFamily: '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
  logoLight: "logos/devin-lockup-horizontal-black.png",
  logoDark: "logos/devin-lockup-horizontal-white.png",
};

// Canonical copy from brief/launch-mac-vm.md (verbatim).
export const defaultContent: LaunchProps["content"] = {
  featureName: "Devin on Mac",
  eyebrow: "New",
  headline: "Devin now runs in a Mac VM",
  headlineAccentWord: "Mac",
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

// Footage from brief/assets.md, mapped per brief/launch-mac-vm.md.
export const defaultMedia: LaunchProps["media"] = {
  pickStill: {
    src: "screenshots/devin-web-4.png",
    kind: "image",
    width: 2990,
    height: 1624,
  },
  pick: {
    src: "recordings/agent-selector-cloud.mp4",
    kind: "video",
    width: 1918,
    height: 1080,
    startFrom: 0,
  },
  simulatorStill: {
    src: "screenshots/devin-web-9.png",
    kind: "image",
    width: 2988,
    height: 1628,
  },
  simulator: {
    src: "recordings/androidios.mp4",
    kind: "video",
    width: 1920,
    height: 1148,
    startFrom: 60,
    // The recording-player window on the Mac desktop (drops the desktop wallpaper).
    crop: { x: 0.04, y: 0.072, w: 0.918, h: 0.868 },
  },
  verifyStill: {
    src: "screenshots/devin-web-11.png",
    kind: "image",
    width: 2986,
    height: 1630,
  },
  verify: {
    src: "recordings/devin-testing-2.mp4",
    kind: "video",
    width: 1918,
    height: 1080,
    startFrom: 600,
  },
  result: {
    src: "screenshots/devin-web-12.png",
    kind: "image",
    width: 2978,
    height: 1622,
  },
};

export const defaultGallery: LaunchProps["gallery"] = {
  safeMargin: 96,
  floorHeight: 132,
  displayWidthStill: 1160,
  displayWidthDolly: 1240,
  displayWidthMotion: 1380,
  displayCenterY: 490,
  displayRadius: 16,
  displayShadow: "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)",
  labelWidth: 300,
  labelGap: 48,
  panFrames: 24,
  expandFrames: 24,
  crossfadeFrames: 15,
  cutFrames: 12,
};

// 120 + 300 + 315 + 315 + 180 + 120 = 1350 frames = 45s at 30fps.
export const defaultScenes: LaunchProps["scenes"] = [
  { id: "title", kind: "title", durationInFrames: 120 },
  {
    id: "exhibit-1",
    kind: "exhibit",
    durationInFrames: 300,
    numeral: "I",
    stageIndex: 0,
    useCaseIndex: 0,
    captionIndex: 0,
    still: "pickStill",
    motion: "pick",
    revealAt: 100,
  },
  {
    id: "exhibit-2",
    kind: "exhibit",
    durationInFrames: 315,
    numeral: "II",
    stageIndex: 2,
    useCaseIndex: 2,
    captionIndex: 2,
    still: "simulatorStill",
    motion: "simulator",
    revealAt: 105,
  },
  {
    id: "exhibit-3",
    kind: "exhibit",
    durationInFrames: 315,
    numeral: "III",
    stageIndex: 3,
    useCaseIndex: 1,
    captionIndex: 4,
    still: "verifyStill",
    motion: "verify",
    revealAt: 105,
  },
  {
    id: "result",
    kind: "exhibit",
    durationInFrames: 180,
    numeral: "IV",
    stageIndex: 4,
    useCaseIndex: 0,
    captionIndex: 6,
    still: "result",
    isResult: true,
  },
  { id: "cta", kind: "cta", durationInFrames: 120 },
];

export const defaultProps: LaunchProps = {
  brand: defaultBrand,
  content: defaultContent,
  media: defaultMedia,
  gallery: defaultGallery,
  scenes: defaultScenes,
};

// Hero frame for the poster still: mid-demo on exhibit II with the recording live.
export const POSTER_FRAME = 670;
