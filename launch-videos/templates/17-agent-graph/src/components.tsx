import React from "react";
import { Img, Sequence, staticFile } from "remotion";
import { OffsetCtx, color, easeIn, easeInOut, easeOut, font, lerp, radius, ramp, shadow, type, useFrame } from "./theme";

export const Seq: React.FC<{ from: number; dur: number; name: string; children: React.ReactNode }> = ({ from, dur, name, children }) => (
  <Sequence from={from} durationInFrames={dur} name={name}>
    <OffsetCtx.Provider value={from}>{children}</OffsetCtx.Provider>
  </Sequence>
);

/** Fade + rise entrance, fade exit. `to` is the absolute frame at which the exit completes. */
export const useEnterExit = (from: number, to: number, enterDur = 22, exitDur = 12) => {
  const frame = useFrame();
  const enter = ramp(frame, from, enterDur, easeOut);
  const exit = ramp(frame, to - exitDur, exitDur, easeIn);
  return { opacity: enter * (1 - exit), rise: lerp(20, 0, enter) };
};

type TextProps = {
  from: number;
  to: number;
  children: React.ReactNode;
  size?: number;
  colorOverride?: string;
  align?: "left" | "center";
  maxWidth?: number;
};

export const Heading: React.FC<TextProps> = ({ from, to, children, size = type.sizes1080p.h2, colorOverride, align = "left", maxWidth }) => {
  const { opacity, rise } = useEnterExit(from, to);
  return (
    <div
      style={{
        fontFamily: font.sans,
        fontWeight: 500,
        fontSize: size,
        lineHeight: type.leading.heading,
        letterSpacing: type.tracking.heading,
        color: colorOverride ?? color.white,
        textAlign: align,
        maxWidth,
        opacity,
        transform: `translateY(${rise}px)`,
        whiteSpace: "pre-line",
      }}
    >
      {children}
    </div>
  );
};

export const Label: React.FC<TextProps> = ({ from, to, children, colorOverride, align = "left" }) => {
  const { opacity, rise } = useEnterExit(from, to);
  return (
    <div
      style={{
        fontFamily: font.mono,
        fontWeight: 500,
        fontSize: type.sizes1080p.label,
        letterSpacing: type.tracking.caps,
        textTransform: "uppercase",
        color: colorOverride ?? color.gray400,
        textAlign: align,
        opacity,
        transform: `translateY(${rise}px)`,
      }}
    >
      {children}
    </div>
  );
};

/** Monospace line typed out one character at a time. */
export const Typed: React.FC<{ from: number; to: number; text: string; cps?: number }> = ({ from, to, text, cps = 38 }) => {
  const frame = useFrame();
  const chars = Math.max(0, Math.floor(((frame - from) / 30) * cps));
  const shown = text.slice(0, chars);
  const done = chars >= text.length;
  const caret = !done && Math.floor(frame / 8) % 2 === 0;
  const exit = ramp(frame, to - 12, 12, easeIn);
  return (
    <div
      style={{
        fontFamily: font.mono,
        fontWeight: 400,
        fontSize: type.sizes1080p.caption,
        letterSpacing: "0",
        color: color.gray400,
        opacity: frame >= from ? 1 - exit : 0,
        whiteSpace: "pre-wrap",
      }}
    >
      <span style={{ color: color.gray500 }}>$ </span>
      {shown}
      <span style={{ opacity: caret ? 1 : 0, color: color.accentSoft }}>▍</span>
    </div>
  );
};

export type Shot = {
  file: string;
  /** transform-origin for the slow push-in, e.g. "50% 40%" */
  origin?: string;
  /** object-position for non-16:9 sources */
  position?: string;
  /** base scale, for sources with transparent padding around the window */
  scale?: number;
};

/** Screenshot with a slow push-in; sequential shots cross-fade. */
export const ScreenCard: React.FC<{
  shots: { shot: Shot; from: number }[];
  width: number;
  height: number;
  until: number;
}> = ({ shots, width, height, until }) => {
  const frame = useFrame();
  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius.md,
        overflow: "hidden",
        background: color.darkSurface,
        boxShadow: `${shadow.dark}, 0 0 0 1px rgba(255,255,255,0.08)`,
        position: "relative",
      }}
    >
      {shots.map(({ shot, from }, i) => {
        const next = shots[i + 1]?.from ?? until;
        const fadeIn = i === 0 ? 1 : ramp(frame, from, 12, easeOut);
        const fadeOut = i === shots.length - 1 ? 0 : ramp(frame, next - 8, 8, easeInOut);
        const base = shot.scale ?? 1;
        const zoom = base * lerp(1, 1.07, ramp(frame, from - 8, next - from + 8, easeInOut));
        if (frame < from - 8 || frame > next) return null;
        return (
          <Img
            key={shot.file}
            src={staticFile(shot.file)}
            style={{
              position: "absolute",
              inset: 0,
              width: "100%",
              height: "100%",
              objectFit: "cover",
              objectPosition: shot.position ?? "50% 0%",
              transform: `scale(${zoom})`,
              transformOrigin: shot.origin ?? "50% 40%",
              opacity: fadeIn * (1 - fadeOut),
            }}
          />
        );
      })}
    </div>
  );
};
