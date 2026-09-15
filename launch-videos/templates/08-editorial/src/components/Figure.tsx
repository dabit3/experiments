import React from 'react';
import {Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {color, easeInOut, easeOut, ms, radius, shadow} from '../tokens';

export type Crop = {x: number; y: number; w: number};

export type Plate = {
  src: string;
  // Scene-local frame at which this plate is fully visible; earlier plates
  // cross-fade into it over `fade` frames.
  at: number;
  // Overrides the figure-level crop for this plate.
  crop?: Crop;
};

// Geometry of the image inside the frame, so overlays (Cursor) can be placed
// in screenshot coordinates rather than frame coordinates.
export type FigureGeometry = {width: number; height: number; aspect: number; crop: Crop};
export const FigureContext = React.createContext<FigureGeometry | null>(null);

export const toFrameSpace = (g: FigureGeometry, p: {x: number; y: number}) => {
  const w = g.width / g.crop.w;
  const h = w / g.aspect;
  return {x: ((p.x - g.crop.x) * w) / g.width, y: ((p.y - g.crop.y) * h) / g.height};
};

type Props = {
  width: number;
  height: number;
  // Intrinsic width / height of the screenshot; needed to place a crop.
  aspect: number;
  crop?: Crop;
  plates: Plate[];
  // Scene-local frame at which the figure enters.
  at: number;
  // Slow push-in over the life of the figure (Ken Burns). [from, to] scale.
  push?: [number, number];
  // Vertical drift of the image inside the frame, in px. [from, to].
  pan?: [number, number];
  duration: number;
  fade?: number;
  dark?: boolean;
  children?: React.ReactNode;
  style?: React.CSSProperties;
};

// A screenshot treated like a photograph: fixed frame, hairline border,
// paper shadow, slow push-in. `children` are overlays (cursor etc.) that live
// in the same transformed space as the image so they track its motion.
export const Figure: React.FC<Props> = ({
  width,
  height,
  aspect,
  crop,
  plates,
  at,
  push = [1, 1.04],
  pan = [0, 0],
  duration,
  fade = ms(600),
  dark = false,
  children,
  style,
}) => {
  const frame = useCurrentFrame();

  const enter = interpolate(frame, [at, at + ms(900)], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeOut,
  });
  const t = interpolate(frame, [at, at + duration], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeInOut,
  });
  const scale = push[0] + (push[1] - push[0]) * t;
  const drift = pan[0] + (pan[1] - pan[0]) * t;

  const imgStyle = (c: Crop | undefined): React.CSSProperties => {
    if (!c) {
      return {position: 'absolute', inset: 0, width, height, objectFit: 'cover'};
    }
    const w = width / c.w;
    const h = w / aspect;
    return {position: 'absolute', width: w, height: h, left: -c.x * w, top: -c.y * h};
  };
  const geometry: FigureGeometry = {width, height, aspect, crop: crop ?? {x: 0, y: 0, w: 1}};

  return (
    <div
      style={{
        position: 'relative',
        width,
        height,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 24}px)`,
        borderRadius: radius.md,
        boxShadow: dark ? shadow.dark : shadow.soft,
        ...style,
      }}
    >
      <div
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: radius.md,
          overflow: 'hidden',
          background: dark ? color.darkSurface : color.white,
        }}
      >
        <div
          style={{
            position: 'absolute',
            inset: 0,
            transform: `scale(${scale}) translateY(${drift}px)`,
            transformOrigin: '50% 50%',
          }}
        >
          {plates.map((plate, i) => {
            const opacity =
              i === 0
                ? 1
                : interpolate(frame, [plate.at - fade, plate.at], [0, 1], {
                    extrapolateLeft: 'clamp',
                    extrapolateRight: 'clamp',
                    easing: easeInOut,
                  });
            return (
              <Img key={plate.src} src={staticFile(plate.src)} style={{...imgStyle(plate.crop ?? crop), opacity}} />
            );
          })}
          <FigureContext.Provider value={geometry}>{children}</FigureContext.Provider>
        </div>
      </div>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: radius.md,
          boxShadow: `inset 0 0 0 1px ${dark ? color.darkBorder : color.border}`,
          pointerEvents: 'none',
        }}
      />
    </div>
  );
};
