import type { Brand, Content, LaunchProps, Media, Scene } from "./schema";

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

export const defaultBrand: Brand = {
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
  blackRaisedAlt: "#252525",
  white: "#FFFFFF",
  fontFamily:
    '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
  monoFontFamily:
    '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
  fontFaceCss: "",
  logoLight: "logos/devin-lockup-horizontal-black.png",
  logoDark: "logos/devin-lockup-horizontal-white.png",
  safeMargin: 96,
  radius: 16,
};

export const defaultContent: Content = {
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

export const defaultMedia: Media = {
  hero: {
    src: "screenshots/devin-web-1.png",
    kind: "image",
    width: 2990,
    height: 1624,
  },
  pick: {
    src: "screenshots/devin-web-5.png",
    kind: "image",
    width: 2988,
    height: 1624,
  },
  work: {
    src: "recordings/devin-working-4.mp4",
    kind: "video",
    width: 1918,
    height: 1080,
    startFrom: 0,
  },
  simulator: {
    src: "recordings/androidios.mp4",
    kind: "video",
    width: 1920,
    height: 1148,
    startFrom: 60,
    // The macOS desktop inside the recording player: iPhone Simulator front and centre.
    crop: { x: 0.07, y: 0.127, w: 0.582, h: 0.732 },
  },
  verify: {
    src: "recordings/devin-testing-2.mp4",
    kind: "video",
    width: 1918,
    height: 1080,
    startFrom: 120,
  },
  result: {
    src: "screenshots/devin-web-12.png",
    kind: "image",
    width: 2978,
    height: 1622,
  },
  merged: {
    src: "screenshots/devin-web-8.png",
    kind: "image",
    width: 2990,
    height: 1618,
  },
};

export const defaultScenes: Scene[] = [
  { id: "title", type: "title", durationInFrames: 105 },
  {
    id: "hero",
    type: "hero",
    durationInFrames: 105,
    media: "hero",
    label: "Devin web — new session with macOS selected",
  },
  {
    id: "chapter-1",
    type: "chapter",
    durationInFrames: 45,
    index: 1,
    title: "Build & test a feature",
  },
  {
    id: "pick",
    type: "demo",
    durationInFrames: 90,
    chapter: 1,
    chapterTitle: "Build & test a feature",
    media: "pick",
    lowerThirds: [{ caption: 0, from: 10, durationInFrames: 80 }],
  },
  {
    id: "build",
    type: "demo",
    durationInFrames: 150,
    chapter: 1,
    chapterTitle: "Build & test a feature",
    media: "work",
    lowerThirds: [{ caption: 1, from: 12, durationInFrames: 138 }],
  },
  {
    id: "chapter-2",
    type: "chapter",
    durationInFrames: 45,
    index: 2,
    title: "QA before shipping",
  },
  {
    id: "simulator",
    type: "demo",
    durationInFrames: 210,
    chapter: 2,
    chapterTitle: "QA before shipping",
    media: "simulator",
    lowerThirds: [
      { caption: 2, from: 12, durationInFrames: 96 },
      { caption: 3, from: 112, durationInFrames: 98 },
    ],
  },
  {
    id: "chapter-3",
    type: "chapter",
    durationInFrames: 45,
    index: 3,
    title: "Reproduce & fix a bug",
  },
  {
    id: "verify",
    type: "demo",
    durationInFrames: 180,
    chapter: 3,
    chapterTitle: "Reproduce & fix a bug",
    media: "verify",
    lowerThirds: [{ caption: 4, from: 12, durationInFrames: 168 }],
  },
  {
    id: "chapter-4",
    type: "chapter",
    durationInFrames: 45,
    index: 4,
    title: "PR",
  },
  {
    id: "ship",
    type: "evidence",
    durationInFrames: 180,
    chapter: 4,
    chapterTitle: "PR",
    media: "result",
    evidence: "merged",
    evidenceLabel: "Merged",
    lowerThirds: [{ caption: 6, from: 12, durationInFrames: 168 }],
  },
  { id: "closing", type: "closing", durationInFrames: 150 },
];

export const defaultProps: LaunchProps = {
  brand: defaultBrand,
  content: defaultContent,
  media: defaultMedia,
  scenes: defaultScenes,
  motion: { wipeFrames: 14, enterFrames: 14, lowerThirdFrames: 12 },
};
