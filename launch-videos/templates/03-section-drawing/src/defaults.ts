import type { LaunchProps } from "./schema";

/**
 * Default props = the "Devin on Mac" test launch (brief/launch-mac-vm.md) rendered with the
 * Devin brand tokens (brief/brand.md). Swap launches by replacing `content` and `media`.
 */
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
    gridOpacity: 0.55,
    gridSize: 48,
  },
  content: {
    featureName: "Devin on Mac",
    eyebrow: "New",
    headline: "Devin now runs in a Mac VM",
    headlineAccent: "Mac VM",
    subhead:
      "Build, run, and test Mac and iOS apps in a cloud Mac — with a live iPhone Simulator in your session.",
    overviewTitle: "How a request moves through a Mac session",
    outroAccent: "cloud Mac",
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
      { id: "request", label: "Request", media: "pick" },
      { id: "build", label: "Build", media: "build" },
      { id: "run", label: "Run & test", media: "simulator" },
      { id: "verify", label: "Verify", media: "verifyPhone" },
      { id: "pr", label: "PR", media: "result" },
    ],
    connections: [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
    ],
    cta: { label: "Start a Mac session", url: "app.devin.ai" },
    outroLine: "The only coding agent with a cloud Mac.",
    speedBadge: "3x",
    sheet: { number: "A-03", title: "Section through a Mac session", scale: "1:1" },
  },
  media: {
    // Home: prompt box with the macOS pill selected underneath.
    pick: {
      src: "screenshots/devin-web-1.png",
      kind: "image",
      width: 2990,
      height: 1624,
      crop: { x: 0.18, y: 0.27, w: 0.64, h: 0.56 },
    },
    // Home with the OS picker open: Ubuntu / macOS / Windows.
    pickMenu: {
      src: "screenshots/devin-web-4.png",
      kind: "image",
      width: 2988,
      height: 1622,
      crop: { x: 0.18, y: 0.27, w: 0.64, h: 0.56 },
    },
    // Session "Build Native Abliteration iOS App": Wisp in the Simulator + its PR.
    build: {
      src: "screenshots/devin-web-9.png",
      kind: "image",
      width: 2988,
      height: 1628,
    },
    // Devin working through a task: worklog of steps on the left, Desktop tab on the right.
    work: {
      src: "recordings/devin-working-4.mp4",
      kind: "video",
      width: 1918,
      height: 1080,
      startFrom: 0,
    },
    // iPhone Simulator on a Mac desktop (Android emulator on the right cropped out).
    simulator: {
      src: "recordings/androidios.mp4",
      kind: "video",
      width: 1920,
      height: 1148,
      startFrom: 45,
      crop: { x: 0.055, y: 0.105, w: 0.315, h: 0.77 },
    },
    // Testing recording: dark iPhone app, 5 passed / 0 failed.
    verifyPhone: {
      src: "screenshots/devin-web-18.png",
      kind: "image",
      width: 2978,
      height: 1626,
      crop: { x: 0.215, y: 0.12, w: 0.235, h: 0.77 },
    },
    // Testing recording: iPad app, 6 passed / 0 failed.
    verifyPad: {
      src: "screenshots/devin-web-19.png",
      kind: "image",
      width: 2982,
      height: 1626,
      crop: { x: 0.06, y: 0.14, w: 0.54, h: 0.74 },
    },
    // Testing recording pass list (right column of the iPad recording).
    verifyList: {
      src: "screenshots/devin-web-19.png",
      kind: "image",
      width: 2982,
      height: 1626,
      crop: { x: 0.655, y: 0.09, w: 0.345, h: 0.6 },
    },
    // Session with the PR "Ready to merge" and embedded Simulator demo videos.
    result: {
      src: "screenshots/devin-web-12.png",
      kind: "image",
      width: 2978,
      height: 1622,
    },
  },
  scenes: [
    { kind: "title", id: "title", durationInFrames: 120 },
    { kind: "overview", id: "overview", durationInFrames: 165, separateAt: 40 },
    {
      kind: "stage",
      id: "request",
      durationInFrames: 195,
      stage: 0,
      layout: "wide",
      media: ["pick", "pickMenu"],
      swapAt: 95,
      enter: "forward",
      annotations: [
        {
          media: "pick",
          anchor: { x: 0.285, y: 0.6 },
          caption: 0,
          side: "right",
          y: 0.62,
          startFrame: 40,
        },
      ],
    },
    {
      kind: "stage",
      id: "build",
      durationInFrames: 180,
      stage: 1,
      layout: "wide",
      media: ["work"],
      enter: "slide",
      annotations: [
        {
          media: "work",
          anchor: { x: 0.135, y: 0.3 },
          caption: 1,
          side: "left",
          y: 0.4,
          startFrame: 30,
        },
      ],
    },
    {
      kind: "stage",
      id: "run",
      durationInFrames: 195,
      stage: 2,
      layout: "wide",
      media: ["simulator"],
      enter: "slide",
      annotations: [
        {
          media: "simulator",
          anchor: { x: 0.255, y: 0.5 },
          caption: 2,
          side: "right",
          y: 0.42,
          startFrame: 30,
        },
      ],
    },
    {
      kind: "stage",
      id: "verify",
      durationInFrames: 180,
      stage: 3,
      layout: "split",
      media: ["verifyPhone", "verifyPad"],
      enter: "slide",
      annotations: [
        {
          media: "verifyPad",
          anchor: { x: 0.33, y: 0.48 },
          caption: 5,
          side: "right",
          y: 0.42,
          startFrame: 30,
        },
      ],
    },
    {
      kind: "stage",
      id: "pr",
      durationInFrames: 150,
      stage: 4,
      layout: "wide",
      media: ["result"],
      enter: "slide",
      annotations: [
        {
          media: "result",
          anchor: { x: 0.185, y: 0.26 },
          caption: 6,
          side: "left",
          y: 0.3,
          startFrame: 26,
        },
      ],
    },
    { kind: "close", id: "close", durationInFrames: 165, result: "result" },
  ],
  timing: { enter: 14, move: 20, leader: 16 },
};
