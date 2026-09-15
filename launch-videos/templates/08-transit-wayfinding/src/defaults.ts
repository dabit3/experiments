import type { LaunchProps } from "./schema";

const captions = [
  "Pick macOS when you start a session — same price as Linux.",
  "Devin builds the app in Xcode and runs the full test suite.",
  "It taps, types, and scrolls through the app like a person.",
  "Watch it live in the iPhone Simulator tab — and tap in yourself.",
  "Reproduce a bug, fix it, and prove the fix on screen.",
  "Check iPhone and iPad sizes, dark mode, and orientations.",
  "Ship with a PR that shows the app working — not a 20-minute CI wait.",
];

// Test launch: "Devin on Mac" (brief/launch-mac-vm.md). Copy is verbatim.
export const defaultProps: LaunchProps = {
  brand: {
    paper: "#F7F6F5",
    surface: "#EFEFEF",
    line: "#E7E7E7",
    ink: "#191919",
    inkMuted: "#7D7D7D",
    inkSubtle: "#919191",
    accent: "#2200FF",
    white: "#FFFFFF",
    fontFamily: '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
    monoFontFamily: '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
    logoLight: "logos/devin-lockup-horizontal-black.png",
    logoDark: "logos/devin-lockup-horizontal-white.png",
  },
  content: {
    featureName: "Devin on Mac",
    eyebrow: "New",
    headline: "Devin now runs in a Mac VM",
    headlineAccentWord: "Mac",
    subhead:
      "Build, run, and test Mac and iOS apps in a cloud Mac — with a live iPhone Simulator in your session.",
    captions,
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
    // Home with the OS picker open (Ubuntu / macOS / Windows), cropped to the prompt box.
    pick: {
      src: "screenshots/devin-web-4.png",
      kind: "image",
      sourceWidth: 2988,
      sourceHeight: 1622,
      crop: { x: 0.17, y: 0.24, w: 0.66, h: 0.62 },
    },
    // Devin working through a task: timeline of steps, embedded recording.
    work: {
      src: "recordings/devin-working-4.mp4",
      kind: "video",
      sourceWidth: 1918,
      sourceHeight: 1080,
      startFrom: 30,
    },
    // iPhone Simulator on a Mac desktop, cropped to the iPhone (Android window cropped out).
    simulator: {
      src: "recordings/androidios.mp4",
      kind: "video",
      sourceWidth: 1920,
      sourceHeight: 1148,
      startFrom: 60,
      crop: { x: 0.15, y: 0.155, w: 0.21, h: 0.7 },
    },
    // Testing-recording player: app on the left, "It should ..." checklist with pass counts.
    verify: {
      src: "recordings/devin-testing-2.mp4",
      kind: "video",
      sourceWidth: 1918,
      sourceHeight: 1080,
      startFrom: 1080,
    },
    // Session with the PR "Ready to merge" and embedded Simulator demo videos.
    result: {
      src: "screenshots/devin-web-12.png",
      kind: "image",
      sourceWidth: 2978,
      sourceHeight: 1622,
    },
  },
  route: {
    originLabel: "Devin on Mac",
    stations: [
      {
        id: "request",
        name: "Request",
        branches: [
          { label: "Ubuntu", chosen: false },
          { label: "macOS", chosen: true },
          { label: "Windows", chosen: false },
        ],
      },
      { id: "build", name: "Build" },
      { id: "run", name: "Run & test" },
      { id: "verify", name: "Verify" },
      { id: "pr", name: "PR" },
    ],
    y: 660,
    lineWidth: 6,
    markerRadius: 14,
  },
  timing: { arrive: 15, expand: 16, collapse: 16, captionWipe: 14 },
  scenes: [
    { id: "open", type: "open", durationInFrames: 105 },
    {
      id: "s1-request",
      type: "station",
      station: "request",
      media: "pick",
      durationInFrames: 180,
      captions: [{ text: captions[0], atFrame: 34 }],
    },
    { id: "l1", type: "link", from: "request", to: "build", durationInFrames: 36 },
    {
      id: "s2-build",
      type: "station",
      station: "build",
      media: "work",
      durationInFrames: 180,
      captions: [{ text: captions[1], atFrame: 34 }],
    },
    { id: "l2", type: "link", from: "build", to: "run", durationInFrames: 36 },
    {
      id: "s3-run",
      type: "station",
      station: "run",
      media: "simulator",
      durationInFrames: 240,
      captions: [
        { text: captions[2], atFrame: 34 },
        { text: captions[3], atFrame: 134 },
      ],
    },
    { id: "l3", type: "link", from: "run", to: "verify", durationInFrames: 36 },
    {
      id: "s4-verify",
      type: "station",
      station: "verify",
      media: "verify",
      durationInFrames: 195,
      captions: [{ text: captions[4], atFrame: 34 }],
    },
    { id: "l4", type: "link", from: "verify", to: "pr", durationInFrames: 36 },
    {
      id: "s5-pr",
      type: "station",
      station: "pr",
      media: "result",
      durationInFrames: 171,
      captions: [{ text: captions[6], atFrame: 34 }],
    },
    { id: "outro", type: "outro", durationInFrames: 135 },
  ],
};
