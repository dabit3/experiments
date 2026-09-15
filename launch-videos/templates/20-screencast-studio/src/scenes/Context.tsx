import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Caption } from "../components/Caption";
import { Cursor, cursorAt } from "../components/Cursor";
import { Screen, Window } from "../components/Window";
import { HANDOFF } from "../handoff";
import { NO_ZOOM } from "../layout";
import { zoomBetween } from "../zoom";

/** 2. Problem / context — a slow push-in on the empty prompt while the captions set up the problem. */
export const Context: React.FC = () => {
  const frame = useCurrentFrame();
  const zoom = zoomBetween(frame, 0, 156, NO_ZOOM, { scale: 1.06, x: 0.5, y: 0.47 });
  const cursor = cursorAt([{ frame: 0, ...HANDOFF.idle }], frame);
  return (
    <AbsoluteFill>
      <Window zoom={zoom}>
        <Screen src="devin-web-1" />
        <Cursor state={cursor} zoom={zoom.scale} />
      </Window>
      <Caption from={4} to={76}>
        {"Before, iOS teams QA'd by hand\nor waited 20+ minutes for CI."}
      </Caption>
      <Caption from={80} to={156}>
        {"No coding agent could build, run\nand tap through an iPhone app."}
      </Caption>
    </AbsoluteFill>
  );
};
