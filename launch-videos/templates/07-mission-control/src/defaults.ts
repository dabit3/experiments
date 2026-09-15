import type { LaunchProps } from "./schema";

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

/** Frame used for `npm run still` / the Poster composition (inside the closing hero). */
export const POSTER_FRAME = 1245;

export const defaultProps: LaunchProps = {
  brand: {
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
    consoleLine: "#2E2E2E",
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
    stages: [
      { id: "request", label: "Request" },
      { id: "build", label: "Build" },
      { id: "run", label: "Run & test" },
      { id: "verify", label: "Verify" },
      { id: "pr", label: "PR" },
    ],
    cta: { label: "Start a Mac session", url: "app.devin.ai" },
    outroLine: "The only coding agent with a cloud Mac.",
    speedBadge: "3x",
  },
  media: {
    // Bay thumbnails (stills, cropped to the meaningful region).
    request: {
      src: "screenshots/devin-web-1.png",
      kind: "image",
      aspectRatio: 2990 / 1624,
      crop: { x: 0.19, y: 0.28, w: 0.62, h: 0.36 },
    },
    work: {
      src: "screenshots/devin-web-9.png",
      kind: "image",
      aspectRatio: 2988 / 1628,
      crop: { x: 0.02, y: 0.24, w: 0.3, h: 0.16 },
    },
    artifact: {
      src: "screenshots/devin-web-12.png",
      kind: "image",
      aspectRatio: 2978 / 1622,
      crop: { x: 0.555, y: 0.145, w: 0.37, h: 0.223 },
    },
    // Primary-display sources, one per inspected stage.
    pick: {
      src: "screenshots/devin-web-4.png",
      kind: "image",
      aspectRatio: 2988 / 1622,
      crop: { x: 0.14, y: 0.28, w: 0.72, h: 0.56 },
    },
    build: {
      src: "recordings/devin-working-4.mp4",
      kind: "video",
      aspectRatio: 1918 / 1080,
      startFrom: 0,
    },
    simulator: {
      src: "recordings/androidios.mp4",
      kind: "video",
      aspectRatio: 1920 / 1148,
      startFrom: 60,
      crop: { x: 0.07, y: 0.13, w: 0.29, h: 0.727 },
    },
    verify: {
      src: "recordings/devin-testing-2.mp4",
      kind: "video",
      aspectRatio: 1918 / 1080,
      startFrom: 1080,
    },
    result: {
      src: "screenshots/devin-web-12.png",
      kind: "image",
      aspectRatio: 2978 / 1622,
      crop: { x: 0.55, y: 0.0, w: 0.45, h: 0.41 },
    },
  },
  bays: [
    { id: "request", label: "Request", media: "request" },
    { id: "work", label: "Active work", media: "work" },
    { id: "artifact", label: "Artifact", media: "artifact" },
  ],
  statusLabels: {
    standby: "Standby",
    live: "On primary",
    held: "Held",
  },
  layout: {
    safeMargin: 96,
    gutter: 24,
    headerHeight: 48,
    captionHeight: 120,
    primaryFraction: 0.69,
    baysSide: "right",
    panelRadius: 16,
    transitionFrames: 14,
    consolidateFrames: 22,
  },
  scenes: [
    {
      id: "open",
      durationInFrames: 150,
      primary: "title",
      captions: [],
      speedBadge: false,
    },
    {
      id: "request",
      durationInFrames: 180,
      primary: "pick",
      activeBay: "request",
      stage: "request",
      useCase: 0,
      captions: [{ at: 0, caption: 0 }],
      speedBadge: false,
    },
    {
      id: "build",
      durationInFrames: 210,
      primary: "build",
      activeBay: "work",
      stage: "build",
      useCase: 0,
      captions: [{ at: 0, caption: 1 }],
      speedBadge: false,
    },
    {
      id: "simulate",
      durationInFrames: 270,
      primary: "simulator",
      activeBay: "work",
      stage: "run",
      useCase: 2,
      captions: [
        { at: 0, caption: 2 },
        { at: 135, caption: 3 },
      ],
      speedBadge: false,
    },
    {
      id: "verify",
      durationInFrames: 240,
      primary: "verify",
      activeBay: "work",
      stage: "verify",
      useCase: 1,
      captions: [{ at: 0, caption: 4 }],
      speedBadge: false,
    },
    {
      id: "pr",
      durationInFrames: 150,
      primary: "result",
      activeBay: "artifact",
      stage: "pr",
      useCase: 2,
      captions: [{ at: 0, caption: 6 }],
      speedBadge: false,
    },
    {
      id: "hero",
      durationInFrames: 150,
      primary: "hero",
      stage: "pr",
      captions: [],
      speedBadge: false,
    },
  ],
};
