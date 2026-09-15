import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { easeInOut, PICTURE_HEIGHT, WIDTH } from "../tokens";

export type CameraPose = {
  /** Image-space point (px of the source PNG) that sits at the centre of the picture. */
  x: number;
  y: number;
  /** Output px per image px. 1 = the 2x screenshot shown at native size. */
  scale: number;
};

export type Project = (x: number, y: number) => { x: number; y: number };

type Props = {
  src: string;
  imgWidth: number;
  imgHeight: number;
  from: CameraPose;
  to: CameraPose;
  /** Frames over which the dolly runs (defaults to the whole scene / a long take). */
  moveDuration?: number;
  moveDelay?: number;
  /** Radius (output px) of the sharp region. The ellipse is 1.6x wider than tall. */
  focusRadius?: number;
  /** Optional focus point in image space; defaults to the camera target. */
  focus?: { x: number; y: number };
  /** Out-of-focus blur in output px. */
  blur?: number;
  /** Opacity multiplier for cross-dissolves inside a scene. */
  opacity?: number;
  /** Overlays drawn in output space on top of the sharp layer. */
  children?: (project: Project, scale: number) => React.ReactNode;
};

/**
 * A single slow dolly on a screenshot with a shallow depth-of-field mask.
 * Two layers of the same image: a blurred plate and a sharp plate masked to a soft ellipse.
 */
export const MacroShot: React.FC<Props> = ({
  src,
  imgWidth,
  imgHeight,
  from,
  to,
  moveDuration = 600,
  moveDelay = 0,
  focusRadius = 260,
  focus,
  blur = 14,
  opacity = 1,
  children,
}) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [moveDelay, moveDelay + moveDuration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });

  const x = from.x + (to.x - from.x) * t;
  const y = from.y + (to.y - from.y) * t;
  const scale = from.scale + (to.scale - from.scale) * t;

  const tx = WIDTH / 2 - x * scale;
  const ty = PICTURE_HEIGHT / 2 - y * scale;
  const transform = `translate(${tx}px, ${ty}px) scale(${scale})`;

  const project: Project = (px, py) => ({ x: tx + px * scale, y: ty + py * scale });

  const f = project(focus?.x ?? x, focus?.y ?? y);
  const rx = focusRadius * 1.6;
  const ry = focusRadius;
  const mask = `radial-gradient(${rx}px ${ry}px at ${f.x}px ${f.y}px, #000 0%, #000 42%, rgba(0,0,0,0.6) 68%, transparent 100%)`;

  const plate: React.CSSProperties = {
    position: "absolute",
    left: 0,
    top: 0,
    width: imgWidth,
    height: imgHeight,
    transformOrigin: "0 0",
    transform,
    willChange: "transform",
  };

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        opacity,
      }}
    >
      <Img
        src={staticFile(src)}
        style={{ ...plate, filter: `blur(${blur / scale}px)` }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          WebkitMaskImage: mask,
          maskImage: mask,
        }}
      >
        <Img src={staticFile(src)} style={plate} />
      </div>
      {children ? (
        <div style={{ position: "absolute", inset: 0 }}>{children(project, scale)}</div>
      ) : null}
    </div>
  );
};
