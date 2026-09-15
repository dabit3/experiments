import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { easeOut, progress } from "../anim";
import { Caption } from "../components/Caption";
import { Cursor, cursorAt } from "../components/Cursor";
import { Typewriter } from "../components/Typewriter";
import { Screen, Window } from "../components/Window";
import { HANDOFF } from "../handoff";
import { NO_ZOOM, Zoom } from "../layout";
import { zoomTimeline } from "../zoom";

const SEND = { x: 0.744, y: 0.524 };
const BOX: Zoom = { scale: 1.45, x: 0.45, y: 0.44 };
const BOX_OUT: Zoom = { ...BOX, scale: 1 };
const REPLY_START: Zoom = { ...HANDOFF.promptEnd, scale: 1 };

const PROMPT = "Build a native iOS chat client, run it in the Simulator and test every screen.";

/** 4. Feature — type the brief, send it, Devin starts building (web-1 → web-13). */
export const Prompt: React.FC = () => {
  const frame = useCurrentFrame();
  const cursor = cursorAt(
    [
      { frame: 0, ...HANDOFF.promptBox },
      { frame: 6, ...HANDOFF.promptBox, click: true },
      { frame: 14, ...HANDOFF.promptBox },
      { frame: 34, x: 0.5, y: 0.49 },
      { frame: 84, x: 0.5, y: 0.49 },
      { frame: 104, ...SEND },
      { frame: 108, ...SEND, click: true },
      { frame: 128, ...SEND },
      { frame: 152, ...HANDOFF.sessionIdle },
    ],
    frame,
  );
  const zoom = zoomTimeline(frame, [
    { from: 6, to: 40, a: NO_ZOOM, b: BOX },
    { from: 94, to: 126, a: BOX, b: BOX_OUT },
    { from: 130, to: 210, a: REPLY_START, b: HANDOFF.promptEnd },
  ]);
  const session = progress(frame, 112, 124, easeOut);
  return (
    <AbsoluteFill>
      <Window zoom={zoom} press={cursor.press}>
        <Screen src="devin-web-1" />
        <Typewriter
          text={PROMPT}
          from={14}
          duration={62}
          box={{ x: 0.222, y: 0.395, w: 0.53, h: 0.05 }}
          fontSize={18}
        />
        <Screen src="devin-web-13" opacity={session} />
        <Cursor state={cursor} zoom={zoom.scale} />
      </Window>
      <Caption from={8} to={98}>
        Ask for a native iOS app.
      </Caption>
      <Caption from={122} to={210}>
        {"Devin builds and runs it in Xcode\nand the iOS Simulator."}
      </Caption>
    </AbsoluteFill>
  );
};
