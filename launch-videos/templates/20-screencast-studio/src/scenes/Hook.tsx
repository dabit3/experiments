import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { easeOut, lerp, progress } from "../anim";
import { Caption } from "../components/Caption";
import { Cursor, cursorAt } from "../components/Cursor";
import { Screen, Window } from "../components/Window";
import { HANDOFF } from "../handoff";
import { NO_ZOOM } from "../layout";

/** 1. Hook — the window settles onto the desk. */
export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const enter = progress(frame, 0, 28, easeOut);
  const cursor = cursorAt([{ frame: 0, ...HANDOFF.idle }], frame);
  return (
    <AbsoluteFill>
      <Window zoom={NO_ZOOM} scale={lerp(0.96, 1, enter)} opacity={enter}>
        <Screen src="devin-web-1" />
        <Cursor state={cursor} zoom={1} opacity={enter} />
      </Window>
      <Caption from={18} to={102}>
        Devin now runs on Mac.
      </Caption>
    </AbsoluteFill>
  );
};
