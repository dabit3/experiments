import React from "react";
import { Cursor } from "../components/Cursor";
import { FeatureLayout, LEFT_SCREEN_WIDTH, TOP_SCREEN_WIDTH } from "../components/FeatureLayout";
import { Region, Screen, WEB_ASPECT } from "../components/Screen";
import { interpolate, useCurrentFrame } from "remotion";
import { dark, easeInOut, light } from "../theme";

const LEFT_H = LEFT_SCREEN_WIDTH / WEB_ASPECT;

/** Centre of a percent region, in px of a screen of the given size. */
const centre = (r: Region, w: number, h: number) => ({
  x: ((r.x + r.w / 2) / 100) * w,
  y: ((r.y + r.h / 2) / 100) * h,
});

/** Cross-fades between two stacked screens at `at`, each keeping its own move. */
const CrossFade: React.FC<{ at: number; a: React.ReactNode; b: React.ReactNode }> = ({ at, a, b }) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [at, at + 18], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  return (
    <div style={{ position: "relative" }}>
      <div style={{ opacity: 1 - p }}>{a}</div>
      <div style={{ position: "absolute", inset: 0, opacity: p }}>{b}</div>
    </div>
  );
};

// Regions measured on the source screenshots (percent of width/height).
const MAC_ROW: Region = { x: 22.4, y: 71.1, w: 17.8, h: 4.9 };
const MAC_CHIP_13: Region = { x: 33.9, y: 1.2, w: 6.2, h: 3.4 };
const SIM_ROW_10: Region = { x: 65.4, y: 52.4, w: 34.6, h: 7.9 };
const SIM_TYPING_10: Region = { x: 28.3, y: 75.6, w: 8.6, h: 6 };
const THUMB_9: Region = { x: 2.6, y: 21.6, w: 29.6, h: 46.8 };
const MERGE_9: Region = { x: 90.6, y: 36, w: 8.2, h: 5.4 };
const DARK_TILE_17: Region = { x: 30.6, y: 67.6, w: 19.8, h: 30 };
const IPAD_19: Region = { x: 7.4, y: 16.1, w: 49.7, h: 68.6 };

/** 01 — Pick macOS, Devin builds and runs the app. web-4 → web-13. */
export const ChooseMac: React.FC = () => {
  const target = centre(MAC_ROW, LEFT_SCREEN_WIDTH, LEFT_H);
  return (
    <FeatureLayout
      palette={light}
      variant="left"
      label="01 / Choose macOS"
      lines={[
        {
          at: 6,
          until: 118,
          headline: "Pick macOS.",
          body: "A Mac VM, hosted like any Devin session.",
        },
        {
          at: 128,
          headline: "Devin builds and runs it in Xcode.",
          body: "Then drives the iOS Simulator itself.",
        },
      ]}
      screen={
        <Screen
          src="screens/devin-web-4.png"
          width={LEFT_SCREEN_WIDTH}
          aspect={WEB_ASPECT}
          move={{ from: 1.02, to: 1.02, x: [0, -40], over: 220 }}
          accents={[
            { ...MAC_ROW, at: 64 },
            { ...MAC_CHIP_13, at: 124, src: "screens/devin-web-13.png" },
          ]}
          next={{ src: "screens/devin-web-13.png", at: 118 }}
        >
          <Cursor
            appearAt={14}
            stops={[
              { x: LEFT_SCREEN_WIDTH * 0.56, y: LEFT_H * 0.56, at: 20 },
              { x: target.x + 40, y: target.y + 6, at: 62, click: true },
              { x: target.x + 40, y: target.y + 6, at: 118 },
            ]}
          />
        </Screen>
      }
    />
  );
};

/** 02 — Live iPhone Simulator in the session. web-10. */
export const Simulator: React.FC = () => (
  <FeatureLayout
    palette={dark}
    variant="top"
    label="02 / Live Simulator"
    lines={[
      {
        at: 6,
        until: 112,
        headline: "A live iPhone Simulator, in the session.",
        body: "Devin taps, types, scrolls and navigates like a person.",
      },
      {
        at: 122,
        headline: "You can watch. You can tap too.",
        body: "Every step is checked and recorded.",
      },
    ]}
    screen={
      <Screen
        src="screens/devin-web-10.png"
        edge={dark.rule}
        width={TOP_SCREEN_WIDTH}
        aspect={WEB_ASPECT}
        move={{ from: 1.06, to: 1.12, y: [-110, -190], over: 216 }}
        accents={[
          { ...SIM_ROW_10, at: 40 },
          { ...SIM_TYPING_10, at: 124 },
        ]}
      />
    }
  />
);

/** 03 — Reproduce, fix, re-test, open a PR. web-9. */
export const FixAndShip: React.FC = () => {
  const merge = centre(MERGE_9, LEFT_SCREEN_WIDTH, LEFT_H);
  const thumb = centre(THUMB_9, LEFT_SCREEN_WIDTH, LEFT_H);
  return (
    <FeatureLayout
      palette={light}
      variant="left"
      label="03 / Fix and ship"
      lines={[
        {
          at: 6,
          until: 112,
          headline: "Reproduces the bug. Fixes it.",
          body: "Then re-runs the UI tests in the Simulator.",
        },
        {
          at: 122,
          headline: "Opens the PR.",
          body: "Test video attached. Ready to merge.",
        },
      ]}
      screen={
        <Screen
          src="screens/devin-web-9.png"
          width={LEFT_SCREEN_WIDTH}
          aspect={WEB_ASPECT}
          move={{ from: 1, to: 1.05, over: 216 }}
          accents={[
            { ...THUMB_9, at: 30 },
            { ...MERGE_9, at: 124 },
          ]}
        >
          <Cursor
            appearAt={40}
            stops={[
              { x: thumb.x + 60, y: thumb.y + 40, at: 44 },
              { x: thumb.x + 60, y: thumb.y + 40, at: 100 },
              { x: merge.x + 10, y: merge.y - 4, at: 150, click: true },
              { x: merge.x + 10, y: merge.y - 4, at: 220 },
            ]}
          />
        </Screen>
      }
    />
  );
};

/** 04 — Sizes, dark mode, orientations; pixel comparison. web-17 → web-19. */
export const Matrix: React.FC = () => (
  <FeatureLayout
    palette={dark}
    variant="top"
    label="04 / Every screen"
    lines={[
      {
        at: 6,
        until: 112,
        headline: "Every iPhone size. Dark mode. Both orientations.",
        body: "Screenshots and video, compared pixel for pixel.",
      },
      {
        at: 122,
        headline: "iPad too.",
        body: "One session, the whole device matrix.",
      },
    ]}
    screen={
      <CrossFade
        at={116}
        a={
          <Screen
            src="screens/devin-web-17.png"
            edge={dark.rule}
            width={TOP_SCREEN_WIDTH}
            aspect={WEB_ASPECT}
            move={{ from: 1.35, to: 1.45, x: [250, 250], y: [0, -420], over: 110 }}
            accents={[{ ...DARK_TILE_17, at: 36 }]}
          />
        }
        b={
          <Screen
            src="screens/devin-web-19.png"
            edge={dark.rule}
            width={TOP_SCREEN_WIDTH}
            aspect={WEB_ASPECT}
            move={{ from: 1.0, to: 1.04, y: [-40, -80], over: 216 }}
            accents={[{ ...IPAD_19, at: 126 }]}
          />
        }
      />
    }
  />
);
