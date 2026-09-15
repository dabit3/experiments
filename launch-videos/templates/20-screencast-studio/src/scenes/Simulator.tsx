import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { easeIn, easeOut, progress } from "../anim";
import { Caption } from "../components/Caption";
import { Cursor, cursorAt } from "../components/Cursor";
import { Screen, Window } from "../components/Window";
import { HANDOFF } from "../handoff";
import { Zoom } from "../layout";
import { zoomTimeline } from "../zoom";

const FLAT: Zoom = { ...HANDOFF.promptEnd, scale: 1 };
const PHONE_A: Zoom = { scale: 1.08, x: 0.33, y: 0.45 };
const PHONE_B: Zoom = { scale: 1.18, x: 0.33, y: 0.5 };

/**
 * 5. Feature — the live iPhone Simulator player (web-13 → web-11 → web-10).
 * The screenshots already contain the recorded pointer, so our overlay cursor fades out.
 */
export const Simulator: React.FC = () => {
  const frame = useCurrentFrame();
  const cursor = cursorAt([{ frame: 0, ...HANDOFF.sessionIdle }], frame);
  const cursorOpacity = 1 - progress(frame, 0, 10, easeIn);
  const zoom = zoomTimeline(frame, [
    { from: 0, to: 26, a: HANDOFF.promptEnd, b: FLAT },
    { from: 30, to: 110, a: { ...PHONE_A, scale: 1 }, b: PHONE_A },
    { from: 110, to: 162, a: PHONE_A, b: PHONE_B },
    { from: 168, to: 212, a: PHONE_B, b: HANDOFF.simulatorEnd },
  ]);
  const loading = progress(frame, 2, 16, easeOut);
  const running = progress(frame, 104, 118, easeOut);
  return (
    <AbsoluteFill>
      <Window zoom={zoom}>
        <Screen src="devin-web-13" />
        <Screen src="devin-web-11" opacity={loading} />
        <Screen src="devin-web-10" opacity={running} />
        <Cursor state={cursor} zoom={zoom.scale} opacity={cursorOpacity} />
      </Window>
      <Caption from={8} to={86}>
        A live iPhone Simulator, right in the session.
      </Caption>
      <Caption from={92} to={166}>
        Devin taps, types and scrolls like a person.
      </Caption>
      <Caption from={172} to={240}>
        Watch along, or tap in yourself.
      </Caption>
    </AbsoluteFill>
  );
};
