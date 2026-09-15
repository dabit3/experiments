import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { easeOut, progress } from "../anim";
import { Caption } from "../components/Caption";
import { Cursor, cursorAt } from "../components/Cursor";
import { Screen, Window } from "../components/Window";
import { HANDOFF } from "../handoff";
import { Zoom } from "../layout";
import { zoomTimeline } from "../zoom";

const FLAT: Zoom = { ...HANDOFF.simulatorEnd, scale: 1 };
const PR_START: Zoom = { ...HANDOFF.prEnd, scale: 1 };
const PR_TITLE = { x: 0.62, y: 0.2 };
export const MERGE = { x: 0.945, y: 0.387 };

/** 6. Feature — back in the session: the PR is open and ready to merge (web-10 → web-9). */
export const PullRequest: React.FC = () => {
  const frame = useCurrentFrame();
  const cursor = cursorAt(
    [
      { frame: 0, ...PR_TITLE },
      { frame: 44, ...PR_TITLE },
      { frame: 90, x: 0.66, y: 0.387 },
      { frame: 122, x: 0.66, y: 0.387 },
      { frame: 156, ...MERGE },
    ],
    frame,
  );
  const cursorOpacity = progress(frame, 22, 38, easeOut);
  const zoom = zoomTimeline(frame, [
    { from: 0, to: 36, a: HANDOFF.simulatorEnd, b: FLAT },
    { from: 66, to: 104, a: PR_START, b: HANDOFF.prEnd },
  ]);
  const session = progress(frame, 2, 16, easeOut);
  return (
    <AbsoluteFill>
      <Window zoom={zoom}>
        <Screen src="devin-web-10" />
        <Screen src="devin-web-9" opacity={session} />
        <Cursor state={cursor} zoom={zoom.scale} opacity={cursorOpacity} />
      </Window>
      <Caption from={8} to={98}>
        {"Devin reproduces the bug, fixes it,\nand re-runs the UI tests."}
      </Caption>
      <Caption from={104} to={198}>
        Then it opens the pull request.
      </Caption>
    </AbsoluteFill>
  );
};
