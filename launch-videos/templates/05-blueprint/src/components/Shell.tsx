import React from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { SceneId, TRANSITION, scene } from "../scenes";
import { easeIn, easeOut } from "../theme";

/** Places a scene on the timeline and cross-dissolves it with its neighbours. */
export const Shell: React.FC<{ id: SceneId; children: React.ReactNode }> = ({ id, children }) => {
  const s = scene(id);
  return (
    <Sequence from={s.from} durationInFrames={s.duration} name={id}>
      <Dissolve first={s.from === 0} duration={s.duration}>
        {children}
      </Dissolve>
    </Sequence>
  );
};

const Dissolve: React.FC<{ first: boolean; duration: number; children: React.ReactNode }> = ({
  first,
  duration,
  children,
}) => {
  const frame = useCurrentFrame();
  const fadeIn = first
    ? 1
    : interpolate(frame, [0, TRANSITION], [0, 1], { extrapolateRight: "clamp", easing: easeOut });
  const fadeOut = interpolate(frame, [duration - TRANSITION, duration], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });
  return <AbsoluteFill style={{ opacity: fadeIn * fadeOut }}>{children}</AbsoluteFill>;
};

/** Shared figure box: 1180×640 sits between the top border and the narration band. */
export const FIG = { x: 370, y: 160, w: 1180, h: 640 };
