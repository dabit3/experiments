import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { Glass } from "./Glass";
import { radius } from "../tokens";
import { enter, linear, move } from "../lib/motion";

export type Shot = {
  /** Path under launch-videos/assets, e.g. "screens/devin-web-1.png". */
  src: string;
  /** Frame the shot becomes fully visible (its cross-fade starts CROSSFADE frames earlier). */
  from: number;
  /** Ken Burns push: scale from → to across the shot's life. */
  scale?: [number, number];
  /** transform-origin for the push, as CSS percentages. */
  origin?: string;
  /** Optional pan in image-fraction units (e.g. y from 0 → -0.08) applied alongside the push. */
  pan?: { x?: [number, number]; y?: [number, number] };
  /** Overlays positioned in image-fraction coordinates; rendered inside the shot so they move with it. */
  overlay?: React.ReactNode;
};

type Props = {
  shots: Shot[];
  sceneFrom: number;
  /** Frame the card itself enters (fade + rise). */
  enterAt?: number;
  /** Entrance rise in px; 0 when the card dissolves over a held card from the previous scene. */
  rise?: number;
  x?: number;
  y?: number;
  width?: number;
  height?: number;
};

export const CROSSFADE = 14;
const PAD = 14;
/** Slight overscan so the screenshots' own rounded window corners never peek into the frame. */
const OVERSCAN = 1.012;

/**
 * Front depth layer: a frosted card holding the "screen recording". Screenshots are shown at their
 * native aspect (all web shots are ~1.84:1) inside a fixed window; adjacent shots cross-fade and
 * each one gets a slow push so nothing is ever static.
 */
export const ScreenCard: React.FC<Props> = ({
  shots,
  sceneFrom,
  enterAt = 0,
  rise = 40,
  x = 288,
  y = 104,
  width = 1344,
  height = 715 + PAD * 2,
}) => {
  const frame = useCurrentFrame();
  const a = enter(frame, enterAt, 26);
  const innerW = width - PAD * 2;
  const innerH = height - PAD * 2;

  return (
    <Glass
      x={x}
      y={y}
      width={width}
      height={height}
      depth={1}
      sceneFrom={sceneFrom}
      padding={PAD}
      opacity={a}
      transform={`translateY(${(1 - a) * rise}px)`}
    >
      <div
        style={{
          position: "relative",
          width: innerW,
          height: innerH,
          borderRadius: radius.md,
          overflow: "hidden",
          background: "#F7F6F5",
        }}
      >
        {shots.map((shot, i) => {
          const next = shots[i + 1];
          const fadeIn = i === 0 ? 1 : linear(frame, shot.from - CROSSFADE, shot.from);
          const fadeOut = next ? 1 - linear(frame, next.from - CROSSFADE, next.from) : 1;
          const opacity = Math.min(fadeIn, fadeOut);
          if (opacity <= 0) return null;
          const life0 = shot.from - CROSSFADE;
          const life1 = next ? next.from : Number.POSITIVE_INFINITY;
          const span = Number.isFinite(life1) ? life1 - life0 : 240;
          const [s0, s1] = shot.scale ?? [1, 1.06];
          const scale = move(frame, life0, life0 + span, s0, s1) * OVERSCAN;
          const px = shot.pan?.x ? move(frame, life0, life0 + span, shot.pan.x[0], shot.pan.x[1]) * innerW : 0;
          const py = shot.pan?.y ? move(frame, life0, life0 + span, shot.pan.y[0], shot.pan.y[1]) * innerH : 0;
          return (
            <div
              key={shot.src + shot.from}
              style={{
                position: "absolute",
                inset: 0,
                opacity,
                transform: `translate(${px}px, ${py}px) scale(${scale})`,
                transformOrigin: shot.origin ?? "50% 50%",
              }}
            >
              <Img
                src={staticFile(shot.src)}
                style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
              />
              {shot.overlay}
            </div>
          );
        })}
      </div>
    </Glass>
  );
};
