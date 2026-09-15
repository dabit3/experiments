import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { color, easeIn, easeInOut, easeOut, radius, shadow } from "../tokens";

export type Layer = {
  /** Path under launch-videos/assets, e.g. "screens/devin-web-4.png". */
  src: string;
  /** Frame at which this layer is fully visible. Earlier layers crossfade into later ones. */
  from: number;
  /** Optional focal point for cover-cropping, as CSS object-position. */
  position?: string;
};

type Props = {
  layers: Layer[];
  /** Card box in composition px. Aspect ratio of the box drives the crop; the image is cover-fit so it never stretches. */
  x: number;
  y: number;
  width: number;
  height: number;
  /** Ken Burns push: scale of the image inside the card at the start and end of the scene. */
  zoomFrom?: number;
  zoomTo?: number;
  /** Pan of the image inside the card, px at start and end. */
  panFrom?: [number, number];
  panTo?: [number, number];
  /** Frames over which the push/pan runs. */
  motionFrames: number;
  /** Entrance: card rises 40px and fades in over these frames. Set 0 for no entrance. */
  enterFrames?: number;
  /** Optional exit: the card fades out over `exitFrames` ending at this frame. */
  exitAt?: number;
  exitFrames?: number;
  crossfadeFrames?: number;
  children?: React.ReactNode;
};

/**
 * A floating product screenshot: cover-cropped inside a 10px-radius figure with the soft 40px shadow,
 * with a slow push-in and optional cross-fades between sequential screenshots.
 */
export const Screen: React.FC<Props> = ({
  layers,
  x,
  y,
  width,
  height,
  zoomFrom = 1,
  zoomTo = 1.04,
  panFrom = [0, 0],
  panTo = [0, 0],
  motionFrames,
  enterFrames = 30,
  exitAt,
  exitFrames = 20,
  crossfadeFrames = 20,
  children,
}) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [0, motionFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  const scale = zoomFrom + (zoomTo - zoomFrom) * t;
  const px = panFrom[0] + (panTo[0] - panFrom[0]) * t;
  const py = panFrom[1] + (panTo[1] - panFrom[1]) * t;

  const enterOpacity = interpolate(frame, [0, enterFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const enterRise = interpolate(frame, [0, enterFrames], [40, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const exitOpacity =
    exitAt === undefined
      ? 1
      : interpolate(frame, [exitAt - exitFrames, exitAt], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeIn,
        });

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        height,
        opacity: Math.min(enterFrames > 0 ? enterOpacity : 1, exitOpacity),
        transform: enterFrames > 0 ? `translateY(${enterRise}px)` : undefined,
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: radius.md,
          overflow: "hidden",
          background: color.white,
          boxShadow: shadow.soft,
          border: `1px solid ${color.border}`,
        }}
      >
        <div
          style={{
            position: "absolute",
            inset: 0,
            transform: `translate(${px}px, ${py}px) scale(${scale})`,
            transformOrigin: "50% 50%",
          }}
        >
          {layers.map((layer, i) => {
            const opacity =
              i === 0
                ? 1
                : interpolate(frame, [layer.from - crossfadeFrames, layer.from], [0, 1], {
                    extrapolateLeft: "clamp",
                    extrapolateRight: "clamp",
                    easing: easeInOut,
                  });
            return (
              <Img
                key={layer.src}
                src={staticFile(layer.src)}
                style={{
                  position: "absolute",
                  inset: 0,
                  width: "100%",
                  height: "100%",
                  objectFit: "cover",
                  objectPosition: layer.position ?? "50% 0%",
                  opacity,
                }}
              />
            );
          })}
          {children}
        </div>
      </div>
    </div>
  );
};
