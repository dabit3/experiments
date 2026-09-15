import type { TileId } from "./layout";

export type Focus = { x: number; y: number };

export type Screen = { file: string; w: number; h: number };

// Natural pixel sizes of the shared screenshots (2x retina PNGs).
export const screens = {
  web9: { file: "screens/devin-web-9.png", w: 2988, h: 1628 },
  web8: { file: "screens/devin-web-8.png", w: 2990, h: 1618 },
  web10: { file: "screens/devin-web-10.png", w: 2990, h: 1624 },
  web11: { file: "screens/devin-web-11.png", w: 2986, h: 1630 },
  web13: { file: "screens/devin-web-13.png", w: 2982, h: 1620 },
  web17: { file: "screens/devin-web-17.png", w: 2978, h: 1620 },
  web19: { file: "screens/devin-web-19.png", w: 2982, h: 1626 },
  desktop9: { file: "screens/devin-desktop-9.png", w: 3024, h: 1898 },
} satisfies Record<string, Screen>;

export type Shot = {
  screen: Screen;
  from: number; // feature-local frame where this shot starts fading in
  zoom: [number, number]; // cover multiplier, start → end
  focus: [Focus, Focus]; // point of the image kept at box centre, start → end
};

export type Caption = {
  from: number; // feature-local frame
  title: string;
  sub?: string;
};

export type CursorKey = { frame: number; x: number; y: number; click?: boolean };

export type Feature = {
  tile: TileId;
  index: string;
  label: string;
  layout: "top" | "side";
  captions: Caption[];
  shots: Shot[];
  cursor?: CursorKey[];
  compact: { screen: Screen; zoom: number; focus: Focus };
};

export const features: Feature[] = [
  {
    tile: "build",
    index: "01",
    label: "Build & run",
    layout: "top",
    captions: [
      { from: 0, title: "Builds and runs the app in Xcode.", sub: "Right inside the session." },
      { from: 100, title: "Launches it in the iOS Simulator.", sub: "No local machine needed." },
    ],
    shots: [
      { screen: screens.web13, from: 0, zoom: [1, 1.08], focus: [{ x: 0.5, y: 0.62 }, { x: 0.5, y: 0.66 }] },
      { screen: screens.desktop9, from: 95, zoom: [1, 1.08], focus: [{ x: 0.4, y: 0.42 }, { x: 0.38, y: 0.46 }] },
    ],
    compact: { screen: screens.web13, zoom: 1.35, focus: { x: 0.5, y: 0.7 } },
  },
  {
    tile: "sim",
    index: "02",
    label: "Live Simulator",
    layout: "side",
    captions: [
      { from: 0, title: "A live iPhone Simulator tab.", sub: "Devin taps, types and scrolls." },
      { from: 105, title: "You can watch — and tap too." },
    ],
    shots: [
      // Zoom is held still here so the cursor stays registered to the UI.
      { screen: screens.web10, from: 0, zoom: [1.22, 1.22], focus: [{ x: 0.33, y: 0.5 }, { x: 0.33, y: 0.5 }] },
      { screen: screens.web11, from: 100, zoom: [1.22, 1.22], focus: [{ x: 0.33, y: 0.5 }, { x: 0.33, y: 0.5 }] },
    ],
    cursor: [
      { frame: 25, x: 0.82, y: 0.94 },
      { frame: 70, x: 0.593, y: 0.887, click: true },
      { frame: 120, x: 0.593, y: 0.887 },
      { frame: 165, x: 0.7, y: 0.74 },
    ],
    compact: { screen: screens.web10, zoom: 1.2, focus: { x: 0.325, y: 0.54 } },
  },
  {
    tile: "pr",
    index: "03",
    label: "Bug → PR",
    layout: "top",
    captions: [
      { from: 0, title: "Reproduces the bug. Fixes it.", sub: "Re-runs the UI tests in the Simulator." },
      { from: 100, title: "Opens the PR.", sub: "Ready to merge." },
    ],
    shots: [
      { screen: screens.web9, from: 0, zoom: [1.1, 1.18], focus: [{ x: 0.3, y: 0.45 }, { x: 0.3, y: 0.5 }] },
      { screen: screens.web8, from: 95, zoom: [1.1, 1.18], focus: [{ x: 0.72, y: 0.35 }, { x: 0.72, y: 0.38 }] },
    ],
    compact: { screen: screens.web9, zoom: 1.25, focus: { x: 0.775, y: 0.48 } },
  },
  {
    tile: "devices",
    index: "04",
    label: "Every device",
    layout: "side",
    captions: [
      { from: 0, title: "Checks every screen.", sub: "iPhone, iPad, dark mode, orientations." },
      { from: 105, title: "Compares them pixel for pixel.", sub: "Records screenshots and video." },
    ],
    shots: [
      { screen: screens.web17, from: 0, zoom: [1.2, 1.2], focus: [{ x: 0.4, y: 0.5 }, { x: 0.4, y: 0.66 }] },
      { screen: screens.web19, from: 100, zoom: [1.15, 1.22], focus: [{ x: 0.36, y: 0.48 }, { x: 0.36, y: 0.5 }] },
    ],
    compact: { screen: screens.web17, zoom: 1.3, focus: { x: 0.4, y: 0.68 } },
  },
];

export const featureByTile = (tile: TileId) => features.find((f) => f.tile === tile);

export type Outcome = { tile: TileId; label: string; text: string };

export const outcomes: Outcome[] = [
  { tile: "build", label: "Speed", text: "Minutes, not 20+ minute CI round-trips." },
  { tile: "sim", label: "Platform", text: "The only coding agent with a Mac cloud agent." },
  { tile: "pr", label: "Security", text: "Same security as Linux and Windows VMs." },
  { tile: "devices", label: "Price", text: "No price increase — same as Linux cloud sessions." },
];

export const copy = {
  hookEyebrow: "New · macOS and iOS",
  hook: "Devin now runs on Mac.",
  context1: "Before: QA by hand, or 20+ minutes waiting on CI.",
  context2: "No coding agent could build, run and tap through an iPhone app.",
  endLine: "Build, run and test iOS apps in the cloud.",
};
