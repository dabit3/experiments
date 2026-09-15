import type { LaunchProps, Rect, Scene, ScenePanel } from "./schema";

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

/**
 * Page geometry. 64px safe margin, 12 columns, 24px gutters (brand.md).
 * The header sits in the top margin, captions in the bottom margin, panels in
 * the content box between them.
 */
export const MARGIN = 64;
export const GUTTER = 24;
export const COLUMNS = 12;
export const CONTENT_TOP = 136;
export const CONTENT_BOTTOM = 944;
export const CONTENT_W = WIDTH - 2 * MARGIN; // 1792
export const CONTENT_H = CONTENT_BOTTOM - CONTENT_TOP; // 808
export const COL_W = (CONTENT_W - (COLUMNS - 1) * GUTTER) / COLUMNS; // ~127
export const COL_STEP = COL_W + GUTTER; // ~151

/** x of column `i` (0-based). */
export const colX = (i: number) => MARGIN + i * COL_STEP;
/** Width of `n` adjacent columns including inner gutters. */
export const colW = (n: number) => n * COL_STEP - GUTTER;
/** Panel height for a width at a given media aspect (w/h). */
export const fitH = (w: number, aspect: number) => Math.round(w / aspect);

const rect = (x: number, y: number, w: number, h: number): Rect => ({
  x: Math.round(x),
  y: Math.round(y),
  w: Math.round(w),
  h: Math.round(h),
});

// Source aspects (from ffprobe) and crop aspects, so panel sizes match media.
const WEB = 2990 / 1624; // devin-web-*.png
const REC = 1918 / 1080; // screen recordings
const SIM_SRC = 1920 / 1148; // androidios.mp4

const HERO_CROP = { x: 0.15, y: 0.22, w: 0.66, h: 0.44 };
const PICK_CROP = { x: 0.2, y: 0.365, w: 0.4, h: 0.475 };
const SIM_CROP = { x: 0.13, y: 0.12, w: 0.23, h: 0.68 };
const LIVE_CROP = { x: 0, y: 0, w: 1, h: 1 };

const cropAspect = (aspect: number, c: { w: number; h: number }) =>
  (aspect * c.w) / c.h;
const HERO = cropAspect(WEB, HERO_CROP); // ~2.76
const PICK = cropAspect(WEB, PICK_CROP); // ~1.47
const SIM = cropAspect(SIM_SRC, SIM_CROP); // ~0.57
const LIVE = cropAspect(WEB, LIVE_CROP); // ~1.84

const active = (slot: string, r: Rect, revealDelay?: number): ScenePanel => ({
  slot,
  rect: r,
  role: "active",
  ...(revealDelay === undefined ? {} : { revealDelay }),
});
const context = (slot: string, r: Rect): ScenePanel => ({
  slot,
  rect: r,
  role: "context",
});

// Common rects
const wideActive = rect(
  colX(3),
  CONTENT_TOP + (CONTENT_H - fitH(colW(9), REC)) / 2,
  colW(9),
  fitH(colW(9), REC),
); // ~1320x743
const ctxW = colW(3); // ~430
const ctxTop = (h: number) => rect(colX(0), CONTENT_TOP, ctxW, h);
const ctxBelow = (above: Rect, h: number) =>
  rect(colX(0), above.y + above.h + GUTTER, ctxW, h);

const simH = CONTENT_H;
const simW = Math.round(simH * SIM); // ~426
const simActive = rect(colX(3), CONTENT_TOP, simW, simH);
const liveX = simActive.x + simActive.w + GUTTER * 2;
const liveW = WIDTH - MARGIN - liveX;
const liveActive = rect(
  liveX,
  CONTENT_TOP + (CONTENT_H - fitH(liveW, LIVE)) / 2,
  liveW,
  fitH(liveW, LIVE),
);

const scene = (
  s: Partial<Scene> & Pick<Scene, "id" | "durationInFrames" | "panels">,
): Scene => ({
  kind: "storyboard",
  captionIndex: null,
  captionPlacement: "bottom",
  stage: null,
  showHeader: true,
  ...s,
});

export const defaultScenes: Scene[] = [
  // 0:00 Title + first small panel: the request.
  scene({
    id: "title",
    kind: "title",
    durationInFrames: 105,
    panels: [
      active(
        "hero",
        rect(colX(6), CONTENT_TOP + (CONTENT_H - fitH(colW(6), HERO)) / 2, colW(6), fitH(colW(6), HERO)),
        30,
      ),
    ],
  }),
  // 0:03.5 Establishing sequence: two small stable beats.
  scene({
    id: "establish",
    durationInFrames: 120,
    stage: 0,
    captionIndex: 0,
    panels: [
      context("hero", rect(colX(0), CONTENT_TOP + 96, colW(5), fitH(colW(5), HERO))),
      active("pick", rect(colX(5), CONTENT_TOP + 96, colW(5), fitH(colW(5), PICK)), 10),
    ],
  }),
  // 0:07.5 The selector recording expands to inspectable size.
  scene({
    id: "pick",
    durationInFrames: 180,
    stage: 0,
    captionIndex: 0,
    panels: [
      context("hero", ctxTop(fitH(ctxW, HERO))),
      context("pick", ctxBelow(ctxTop(fitH(ctxW, HERO)), fitH(ctxW, PICK))),
      active("selector", wideActive),
    ],
  }),
  // 0:13.5 Build: Devin working.
  scene({
    id: "build",
    durationInFrames: 195,
    stage: 1,
    captionIndex: 1,
    panels: [
      context("pick", ctxTop(fitH(ctxW, PICK))),
      context("selector", ctxBelow(ctxTop(fitH(ctxW, PICK)), fitH(ctxW, REC))),
      active("work", wideActive),
    ],
  }),
  // 0:20 Run & test: tall iPhone Simulator panel, caption in the right margin.
  scene({
    id: "run",
    durationInFrames: 180,
    stage: 2,
    captionIndex: 2,
    captionPlacement: "beside",
    panels: [
      context("selector", ctxTop(fitH(ctxW, REC))),
      context("work", ctxBelow(ctxTop(fitH(ctxW, REC)), fitH(ctxW, REC))),
      active("simulator", simActive),
    ],
  }),
  // 0:26 Live Simulator inside the session (stable beat) opens beside the phone.
  scene({
    id: "live",
    durationInFrames: 120,
    stage: 2,
    captionIndex: 3,
    panels: [
      context("work", ctxTop(fitH(ctxW, REC))),
      context("simulator", simActive),
      active("live", liveActive),
    ],
  }),
  // 0:30 Verify: the testing recording with its pass list.
  scene({
    id: "verify",
    durationInFrames: 180,
    stage: 3,
    captionIndex: 4,
    panels: [
      context("simulator", rect(colX(0), CONTENT_TOP, 200, fitH(200, SIM))),
      context(
        "live",
        rect(colX(0), CONTENT_TOP + fitH(200, SIM) + GUTTER, ctxW, fitH(ctxW, LIVE)),
      ),
      active("verify", wideActive),
    ],
  }),
  // 0:36 PR: the delivered outcome.
  scene({
    id: "ship",
    durationInFrames: 105,
    stage: 4,
    captionIndex: 6,
    panels: [
      context("live", ctxTop(fitH(ctxW, LIVE))),
      context("verify", ctxBelow(ctxTop(fitH(ctxW, LIVE)), fitH(ctxW, REC))),
      active(
        "result",
        rect(colX(3), CONTENT_TOP + (CONTENT_H - fitH(colW(9), WEB)) / 2, colW(9), fitH(colW(9), WEB)),
      ),
    ],
  }),
  // 0:39.5 The final panel becomes the full frame.
  scene({
    id: "full",
    durationInFrames: 90,
    stage: 4,
    showHeader: false,
    panels: [active("result", rect(0, 0, WIDTH, HEIGHT))],
  }),
  // 0:42.5 Outro slate.
  scene({
    id: "outro",
    kind: "outro",
    durationInFrames: 75,
    showHeader: false,
    panels: [],
  }),
];

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
      "Build, run, and test Mac and iOS apps in a cloud Mac, with a live iPhone Simulator in your session.",
    captions: [
      "Pick macOS when you start a session. Same price as Linux.",
      "Devin builds the app in Xcode and runs the full test suite.",
      "It taps, types, and scrolls through the app like a person.",
      "Watch it live in the iPhone Simulator tab, and tap in yourself.",
      "Reproduce a bug, fix it, and prove the fix on screen.",
      "Check iPhone and iPad sizes, dark mode, and orientations.",
      "Ship with a PR that shows the app working, not a 20-minute CI wait.",
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
      aspect: WEB,
      crop: HERO_CROP,
    },
    pick: {
      src: "screenshots/devin-web-4.png",
      kind: "image",
      aspect: WEB,
      crop: PICK_CROP,
    },
    selector: {
      src: "recordings/agent-selector-cloud.mp4",
      kind: "video",
      aspect: REC,
      startFrom: 0,
      durationInFrames: 275,
    },
    work: {
      src: "recordings/devin-working-4.mp4",
      kind: "video",
      aspect: REC,
      startFrom: 0,
      durationInFrames: 441,
    },
    simulator: {
      src: "recordings/androidios.mp4",
      kind: "video",
      aspect: SIM_SRC,
      startFrom: 0,
      durationInFrames: 672,
      crop: SIM_CROP,
    },
    live: {
      src: "screenshots/devin-web-14.png",
      kind: "image",
      aspect: WEB,
      crop: LIVE_CROP,
    },
    verify: {
      src: "recordings/devin-testing-2.mp4",
      kind: "video",
      aspect: REC,
      startFrom: 750,
      durationInFrames: 1774,
    },
    result: {
      src: "screenshots/devin-web-12.png",
      kind: "image",
      aspect: 2978 / 1622,
    },
  },
  scenes: defaultScenes,
  storyboard: {
    margin: MARGIN,
    gutter: GUTTER,
    panelRadius: 12,
    contextOpacity: 0.5,
    revealFrames: 15,
    moveFrames: 18,
    exitFrames: 10,
    captionFadeFrames: 10,
    showPanelNumbers: false,
  },
};
