import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { fadeInOut } from "../anim";
import { Caption } from "../components/Caption";
import { Cursor, cursorAt } from "../components/Cursor";
import { Screen, Window } from "../components/Window";
import { HANDOFF } from "../handoff";
import { NO_ZOOM, Zoom } from "../layout";
import { zoomTimeline } from "../zoom";

const CHIP = { x: 0.253, y: 0.602 };
const MACOS_ROW = { x: 0.27, y: 0.733 };
const PICKER: Zoom = { scale: 1.55, x: 0.31, y: 0.72 };
const PICKER_OUT: Zoom = { ...PICKER, scale: 1 };

/** 3. Feature — open the platform picker and choose macOS (web-1 → web-4 → web-1). */
export const ChoosePlatform: React.FC = () => {
  const frame = useCurrentFrame();
  const cursor = cursorAt(
    [
      { frame: 0, ...HANDOFF.idle },
      { frame: 12, ...HANDOFF.idle },
      { frame: 42, ...CHIP },
      { frame: 46, ...CHIP, click: true },
      { frame: 76, ...CHIP },
      { frame: 104, ...MACOS_ROW },
      { frame: 110, ...MACOS_ROW, click: true },
      { frame: 150, ...MACOS_ROW },
      { frame: 190, ...HANDOFF.promptBox },
    ],
    frame,
  );
  const zoom = zoomTimeline(frame, [
    { from: 46, to: 82, a: NO_ZOOM, b: PICKER },
    { from: 124, to: 162, a: PICKER, b: PICKER_OUT },
  ]);
  const menu = fadeInOut(frame, 46, 118, 8, 8);
  return (
    <AbsoluteFill>
      <Window zoom={zoom} press={cursor.press}>
        <Screen src="devin-web-1" />
        <Screen src="devin-web-4" opacity={menu} />
        <Cursor state={cursor} zoom={zoom.scale} />
      </Window>
      <Caption from={6} to={102}>
        Pick macOS as the platform.
      </Caption>
      <Caption from={114} to={216}>
        {"Devin gets a Mac VM with Xcode\nand the iOS Simulator."}
      </Caption>
    </AbsoluteFill>
  );
};
