import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { Cursor } from "../components/Cursor";
import { Figure, zoomed } from "../components/Figure";
import { easeInOut, progress } from "../theme";
import { Feature, FIGURE_COL, FIGURE_SPAN, FIGURE_TOP, WEB_ASPECT } from "./Feature";

// The empty home screen is sparse, so it is shown enlarged around the prompt box.
const ZOOM = { scale: 1.35, originX: 0.5, originY: 0.62 };

// Points are fractions of the un-zoomed figure, measured on devin-web-1 / devin-web-4.
const PROMPT = { x: 0.56, y: 0.44 };
const CHIP = { x: 0.252, y: 0.606 };
const MACOS_ROW = { x: 0.27, y: 0.722 };

const MENU_OPEN = 58;
const PICK = 104;
const SESSION = 118;

const zx = (x: number) => zoomed(x, ZOOM.originX, ZOOM.scale);
const zy = (y: number) => zoomed(y, ZOOM.originY, ZOOM.scale);

/** 03 — choose macOS, Devin builds and runs the app. Motion: cursor move + fade. */
export const FeatureRun: React.FC<{ number: string }> = ({ number }) => {
  const frame = useCurrentFrame();

  const toChip = progress(frame, 14, 36, easeInOut);
  const toRow = progress(frame, MENU_OPEN + 10, 30, easeInOut);
  const x = interpolate(toRow, [0, 1], [interpolate(toChip, [0, 1], [PROMPT.x, CHIP.x]), MACOS_ROW.x]);
  const y = interpolate(toRow, [0, 1], [interpolate(toChip, [0, 1], [PROMPT.y, CHIP.y]), MACOS_ROW.y]);

  const pressing = (at: number) => frame >= at - 4 && frame < at + 4;
  const press = pressing(MENU_OPEN) || pressing(PICK) ? 1 : 0;

  const menu = progress(frame, MENU_OPEN, 6);
  const session = progress(frame, SESSION, 6);
  const cursorOpacity = progress(frame, 8, 8) * (frame < SESSION ? 1 : 0);

  return (
    <Feature
      number={number}
      beats={[
        { text: "Choose macOS.", enterAt: 6, exitAt: SESSION - 10 },
        { text: "Devin builds and runs the app in Xcode and the iOS Simulator.", enterAt: SESSION + 4 },
      ]}
    >
      <Figure
        col={FIGURE_COL}
        span={FIGURE_SPAN}
        top={FIGURE_TOP}
        aspect={WEB_ASPECT}
        enterAt={0}
        layers={[
          { src: "screens/devin-web-1.png", zoom: ZOOM },
          { src: "screens/devin-web-4.png", opacity: menu, zoom: ZOOM },
          { src: "screens/devin-web-13.png", opacity: session },
        ]}
      >
        <Cursor x={zx(x)} y={zy(y)} opacity={cursorOpacity} press={press} />
      </Figure>
    </Feature>
  );
};
