import type { Brand, CameraView, Content, LaunchProps, Lighting, MediaSlot, Scene } from "./schema";

export const FRAME_WIDTH = 1920;
export const FRAME_HEIGHT = 1080;
export const FPS = 30;

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
  white: "#FFFFFF",
  fontFamily: '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
  monoFontFamily: '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
  useLicensedFont: false,
  logoLight: "logos/devin-lockup-horizontal-black.png",
  logoDark: "logos/devin-lockup-horizontal-white.png",
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

export const defaultMedia: Record<string, MediaSlot> = {
  hero: { src: "screenshots/devin-web-1.png", kind: "image", width: 2990, height: 1624 },
  pick: { src: "screenshots/devin-web-4.png", kind: "image", width: 2988, height: 1622 },
  work: { src: "recordings/devin-working-4.mp4", kind: "video", width: 1918, height: 1080, startFrom: 0 },
  simulator: { src: "recordings/androidios.mp4", kind: "video", width: 1920, height: 1148, startFrom: 90 },
  live: { src: "screenshots/devin-web-10.png", kind: "image", width: 2990, height: 1624 },
  verify: { src: "recordings/devin-testing-2.mp4", kind: "video", width: 1918, height: 1080, startFrom: 570 },
  result: { src: "screenshots/devin-web-12.png", kind: "image", width: 2978, height: 1622 },
};

export const defaultLighting: Lighting = {
  keyX: 0.3,
  keyY: 0.1,
  keyRadius: 0.9,
  keyIntensity: 0.6,
  vignette: 0.35,
  shadowStrength: 1,
  planeBorder: true,
};

const clamp01 = (v: number, size: number) => Math.min(Math.max(v, 0), 1 - size);

/**
 * A camera view that shows a window of the source at `zoom` source-pixels per
 * frame-pixel (1 = the asset's native resolution, never upscaled beyond that).
 * `cx`/`cy` is the centre of the window in source fractions; `aspect` is the
 * plane's width/height.
 */
export const detail = (
  slot: MediaSlot,
  opts: { cx: number; cy: number; planeWidth: number; aspect: number; zoom?: number; x: number; y: number },
): CameraView => {
  const zoom = opts.zoom ?? 1;
  const planePx = opts.planeWidth * FRAME_WIDTH;
  const planePy = planePx / opts.aspect;
  const w = planePx / (zoom * slot.width);
  const h = planePy / (zoom * slot.height);
  return {
    crop: { x: clamp01(opts.cx - w / 2, w), y: clamp01(opts.cy - h / 2, h), w, h },
    planeWidth: opts.planeWidth,
    x: opts.x,
    y: opts.y,
  };
};

export const full = (planeWidth: number, x: number, y = 0.5): CameraView => ({
  crop: { x: 0, y: 0, w: 1, h: 1 },
  planeWidth,
  x,
  y,
});

const m = defaultMedia as Record<string, MediaSlot> & {
  hero: MediaSlot;
  pick: MediaSlot;
  work: MediaSlot;
  simulator: MediaSlot;
  live: MediaSlot;
  verify: MediaSlot;
  result: MediaSlot;
};

const openStart = detail(m.hero, { cx: 0.5, cy: 0.57, planeWidth: 1, aspect: 16 / 9, x: 0.5, y: 0.5 });
const openEnd = detail(m.hero, { cx: 0.5, cy: 0.53, planeWidth: 1, aspect: 16 / 9, x: 0.5, y: 0.5 });
const revealEnd = full(0.6, 0.66);
const resultView = full(0.6, 0.65);

export const defaultScenes: Scene[] = [
  {
    id: "open",
    kind: "film",
    durationInFrames: 120,
    media: "hero",
    camera: { from: openStart, to: openEnd, easing: "linear", settleFrames: 0 },
    caption: null,
    stage: null,
    captionPlacement: "left",
    captionWidth: 0.3,
    showTitle: false,
    titleDelay: 0,
    showLogo: false,
    transitionIn: "none",
    transitionOut: "none",
  },
  {
    id: "reveal",
    kind: "film",
    durationInFrames: 210,
    media: "hero",
    camera: { from: openEnd, to: revealEnd, easing: "inOut", settleFrames: 60 },
    caption: null,
    stage: null,
    captionPlacement: "left",
    captionWidth: 0.3,
    showTitle: true,
    titleDelay: 140,
    showLogo: true,
    transitionIn: "none",
    transitionOut: "tilt",
  },
  {
    id: "pick",
    kind: "film",
    durationInFrames: 150,
    media: "pick",
    camera: {
      from: detail(m.pick, { cx: 0.33, cy: 0.7, planeWidth: 0.56, aspect: 4 / 3, zoom: 0.92, x: 0.66, y: 0.5 }),
      to: detail(m.pick, { cx: 0.33, cy: 0.7, planeWidth: 0.56, aspect: 4 / 3, zoom: 1, x: 0.66, y: 0.5 }),
      easing: "inOut",
      settleFrames: 0,
    },
    caption: 0,
    stage: 0,
    captionPlacement: "left",
    captionWidth: 0.28,
    showTitle: false,
    titleDelay: 12,
    showLogo: false,
    transitionIn: "tilt",
    transitionOut: "tilt",
  },
  {
    id: "work",
    kind: "film",
    durationInFrames: 150,
    media: "work",
    camera: { from: full(0.64, 0.63), to: full(0.66, 0.62), easing: "linear", settleFrames: 0 },
    caption: 1,
    stage: 1,
    captionPlacement: "left",
    captionWidth: 0.24,
    showTitle: false,
    titleDelay: 12,
    showLogo: false,
    transitionIn: "tilt",
    transitionOut: "tilt",
  },
  {
    id: "simulator",
    kind: "film",
    durationInFrames: 180,
    media: "simulator",
    camera: {
      from: detail(m.simulator, { cx: 0.25, cy: 0.485, planeWidth: 0.22, aspect: 9 / 16, x: 0.62, y: 0.5 }),
      to: detail(m.simulator, { cx: 0.25, cy: 0.465, planeWidth: 0.22, aspect: 9 / 16, x: 0.62, y: 0.5 }),
      easing: "linear",
      settleFrames: 0,
    },
    caption: 2,
    stage: 2,
    captionPlacement: "left",
    captionWidth: 0.3,
    showTitle: false,
    titleDelay: 12,
    showLogo: false,
    transitionIn: "tilt",
    transitionOut: "tilt",
  },
  {
    id: "live",
    kind: "film",
    durationInFrames: 150,
    media: "live",
    camera: { from: full(0.6, 0.65), to: full(0.62, 0.64), easing: "linear", settleFrames: 0 },
    caption: 3,
    stage: null,
    captionPlacement: "left",
    captionWidth: 0.26,
    showTitle: false,
    titleDelay: 12,
    showLogo: false,
    transitionIn: "tilt",
    transitionOut: "tilt",
  },
  {
    id: "verify",
    kind: "film",
    durationInFrames: 150,
    media: "verify",
    camera: {
      from: full(0.64, 0.63),
      to: detail(m.verify, { cx: 0.75, cy: 0.5, planeWidth: 0.52, aspect: 16 / 9, x: 0.65, y: 0.5 }),
      easing: "inOut",
      settleFrames: 0,
    },
    caption: 4,
    stage: 3,
    captionPlacement: "left",
    captionWidth: 0.26,
    showTitle: false,
    titleDelay: 12,
    showLogo: false,
    transitionIn: "tilt",
    transitionOut: "tilt",
  },
  {
    id: "result",
    kind: "film",
    durationInFrames: 120,
    media: "result",
    camera: { from: resultView, to: resultView, easing: "linear", settleFrames: 0 },
    caption: 6,
    stage: 4,
    captionPlacement: "left",
    captionWidth: 0.26,
    showTitle: false,
    titleDelay: 12,
    showLogo: false,
    transitionIn: "tilt",
    transitionOut: "none",
  },
  {
    id: "cta",
    kind: "cta",
    durationInFrames: 120,
    media: "result",
    camera: { from: resultView, to: resultView, easing: "linear", settleFrames: 0 },
    caption: null,
    stage: null,
    captionPlacement: "left",
    captionWidth: 0.28,
    showTitle: false,
    titleDelay: 0,
    showLogo: true,
    transitionIn: "none",
    transitionOut: "none",
  },
];

export const defaultProps: LaunchProps = {
  brand: defaultBrand,
  content: defaultContent,
  media: defaultMedia,
  scenes: defaultScenes,
  lighting: defaultLighting,
  transitionFrames: 18,
  tiltDegrees: 5,
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);
