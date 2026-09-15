import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { color, easeInOut, easeOut, radius, shadow } from "../theme";

/** Region of the screenshot, in percent of its width/height. */
export type Region = { x: number; y: number; w: number; h: number };

export type ScreenProps = {
  src: string;
  /** Rendered width in px; height follows the image's aspect ratio. */
  width: number;
  aspect: number;
  /** Slow Ken Burns move: scale and translate (px) from -> to over the scene. */
  move?: { from: number; to: number; x?: [number, number]; y?: [number, number]; over: number };
  /**
   * Regions kept in full colour (everything else is grayscale), shown one at a time in order.
   * Each becomes active at `at` and hands over to the next. `src` defaults to the base screenshot.
   */
  accents?: (Region & { at: number; src?: string })[];
  /** Cross-fade to this screenshot starting at `at`. */
  next?: { src: string; at: number };
  /** Overlays (e.g. a Cursor) positioned in px of the untransformed screen. */
  children?: React.ReactNode;
  /** 1px edge colour of the figure. */
  edge?: string;
  style?: React.CSSProperties;
};

const CROSSFADE = 18;

export const Screen: React.FC<ScreenProps> = ({
  src,
  width,
  aspect,
  move,
  accents = [],
  next,
  children,
  edge = color.gray300,
  style,
}) => {
  const frame = useCurrentFrame();
  const height = width / aspect;

  const t = move
    ? interpolate(frame, [0, move.over], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeInOut,
      })
    : 0;
  const scale = move ? move.from + (move.to - move.from) * t : 1;
  const tx = move?.x ? move.x[0] + (move.x[1] - move.x[0]) * t : 0;
  const ty = move?.y ? move.y[0] + (move.y[1] - move.y[0]) * t : 0;

  const nextOpacity = next
    ? interpolate(frame, [next.at, next.at + CROSSFADE], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeInOut,
      })
    : 0;

  const img: React.CSSProperties = {
    position: "absolute",
    inset: 0,
    width: "100%",
    height: "100%",
    display: "block",
  };

  return (
    <div
      style={{
        position: "relative",
        width,
        height,
        borderRadius: radius.md,
        overflow: "hidden",
        background: color.white,
        outline: `1px solid ${edge}`,
        outlineOffset: -1,
        boxShadow: edge === color.gray300 ? shadow.figure : undefined,
        ...style,
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          transform: `translate(${tx}px, ${ty}px) scale(${scale})`,
          transformOrigin: "50% 50%",
        }}
      >
        <Img src={staticFile(src)} style={{ ...img, filter: "grayscale(1)" }} />
        {next ? (
          <Img
            src={staticFile(next.src)}
            style={{ ...img, filter: "grayscale(1)", opacity: nextOpacity }}
          />
        ) : null}
        {accents.map((a, i) => {
          const nextAt = accents[i + 1]?.at;
          const inP = interpolate(frame, [a.at, a.at + 14], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: easeOut,
          });
          const outP =
            nextAt === undefined
              ? 0
              : interpolate(frame, [nextAt, nextAt + 10], [0, 1], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                });
          const opacity = inP * (1 - outP);
          if (opacity <= 0) return null;
          const clip = `inset(${a.y}% ${100 - a.x - a.w}% ${100 - a.y - a.h}% ${a.x}%)`;
          return (
            <React.Fragment key={a.at}>
              <Img src={staticFile(a.src ?? src)} style={{ ...img, clipPath: clip, opacity }} />
              <div
                style={{
                  position: "absolute",
                  left: `${a.x}%`,
                  top: `${a.y}%`,
                  width: `${a.w}%`,
                  height: `${a.h}%`,
                  boxShadow: `0 0 0 3px ${color.accent}`,
                  borderRadius: radius.button,
                  opacity,
                }}
              />
            </React.Fragment>
          );
        })}
        {children}
      </div>
    </div>
  );
};

export const WEB_ASPECT = 2990 / 1624;
export const DESKTOP_ASPECT = 3024 / 1898;
