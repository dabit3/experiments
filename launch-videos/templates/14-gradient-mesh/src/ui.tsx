import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { INTER, MONO } from "./fonts";
import { TRANSITION } from "./scenes";
import { color, dur, easeIn, easeInOut, easeOut, radius, shadow, type } from "./tokens";

/* ---------- scene-level fade (entrance ease-out, exit ease-in) ---------- */

export const SceneFade: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const inO = interpolate(frame, [0, dur.base], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const outO = interpolate(frame, [durationInFrames - TRANSITION, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });
  return <AbsoluteFill style={{ opacity: Math.min(inO, outO) }}>{children}</AbsoluteFill>;
};

/* ---------- text ---------- */

/** Fade + 24px rise on entrance; optional fade on exit. */
export const useRise = (start: number, end?: number, length = dur.slow) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [start, start + length], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const out =
    end === undefined
      ? 1
      : interpolate(frame, [end - dur.fast, end], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeIn,
        });
  return { opacity: t * out, transform: `translateY(${(1 - t) * 24}px)` };
};

export const Headline: React.FC<{
  children: React.ReactNode;
  size?: keyof typeof type.sizes1080p;
  align?: "left" | "center";
  style?: React.CSSProperties;
  maxWidth?: number;
}> = ({ children, size = "h2", align = "center", style, maxWidth = 1400 }) => (
  <div
    style={{
      fontFamily: INTER,
      fontWeight: type.weights.medium,
      fontSize: type.sizes1080p[size],
      lineHeight: size === "hero" ? type.leading.tight : type.leading.heading,
      letterSpacing: size === "hero" ? type.tracking.hero : type.tracking.heading,
      color: color.ink,
      textAlign: align,
      textWrap: "balance",
      maxWidth,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Label: React.FC<{ children: React.ReactNode; style?: React.CSSProperties }> = ({ children, style }) => (
  <div
    style={{
      fontFamily: MONO,
      fontWeight: type.weights.medium,
      fontSize: type.sizes1080p.label,
      letterSpacing: type.tracking.caps,
      textTransform: "uppercase",
      color: color.accent,
      ...style,
    }}
  >
    {children}
  </div>
);

/* ---------- card + screenshot ---------- */

export const CARD_W = 1280;
export const CARD_H = 696; // matches the ~1.84:1 aspect of the screenshots
export const CARD_X = (1920 - CARD_W) / 2;
export const CARD_Y = 276;

export const Card: React.FC<{ children: React.ReactNode; enter?: number }> = ({ children, enter = 0 }) => {
  const rise = useRise(enter, undefined, dur.slow + 6);
  return (
    <div
      style={{
        position: "absolute",
        left: CARD_X,
        top: CARD_Y,
        width: CARD_W,
        height: CARD_H,
        background: color.white,
        border: `1px solid ${color.border}`,
        borderRadius: radius.lg,
        boxShadow: shadow.soft,
        overflow: "hidden",
        ...rise,
      }}
    >
      {children}
    </div>
  );
};

export type Shot = {
  /** file name inside assets/screens, without extension */
  src: string;
  /** frame (relative to the card) when this shot becomes the visible one */
  at: number;
  /** transform-origin for the push-in, as fractions of the card */
  origin?: [number, number];
};

/**
 * Cross-fades between sequential screenshots and applies one continuous
 * slow push-in across the whole card so nothing is ever static.
 */
export const ShotStack: React.FC<{ shots: Shot[]; zoom?: [number, number]; fade?: number }> = ({
  shots,
  zoom = [1, 1.06],
  fade = dur.fast,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const scale = interpolate(frame, [0, durationInFrames], zoom, {
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  return (
    <AbsoluteFill>
      {shots.map((s, i) => {
        const next = shots[i + 1];
        const inO = i === 0 ? 1 : interpolate(frame, [s.at, s.at + fade], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeInOut,
        });
        // Each shot stays fully opaque underneath the next one, which fades
        // in on top — a clean dissolve without a dip in brightness.
        const visible = next ? frame < next.at + fade : true;
        if (!visible || frame < s.at) return null;
        const [ox, oy] = s.origin ?? [0.5, 0.5];
        return (
          <Img
            key={s.src}
            src={staticFile(`screens/${s.src}.png`)}
            style={{
              position: "absolute",
              inset: 0,
              width: "100%",
              height: "100%",
              objectFit: "cover",
              objectPosition: "top center",
              opacity: inO,
              transform: `scale(${scale})`,
              transformOrigin: `${ox * 100}% ${oy * 100}%`,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

/* ---------- cursor overlay ---------- */

export type CursorKey = { at: number; x: number; y: number; click?: boolean };

/** Pointer that eases between keyframes (fractions of the card). Click = brief ring. */
export const Cursor: React.FC<{ keys: CursorKey[]; scale?: number }> = ({ keys, scale = 1 }) => {
  const frame = useCurrentFrame();
  let a = keys[0];
  let b = keys[0];
  for (let i = 0; i < keys.length; i++) {
    if (frame >= keys[i].at) {
      a = keys[i];
      b = keys[i + 1] ?? keys[i];
    }
  }
  const t =
    a === b
      ? 1
      : interpolate(frame, [a.at, b.at], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeInOut,
        });
  const x = (a.x + (b.x - a.x) * t) * CARD_W;
  const y = (a.y + (b.y - a.y) * t) * CARD_H;
  const clickKey = keys.find((k) => k.click && frame >= k.at && frame < k.at + dur.base);
  const ring = clickKey
    ? interpolate(frame, [clickKey.at, clickKey.at + dur.base], [0, 1], { easing: easeOut })
    : null;
  const appear = interpolate(frame, [keys[0].at, keys[0].at + dur.fast], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div style={{ position: "absolute", left: x, top: y, opacity: appear, pointerEvents: "none" }}>
      {ring !== null ? (
        <div
          style={{
            position: "absolute",
            left: -22 * scale,
            top: -22 * scale,
            width: 44 * scale,
            height: 44 * scale,
            borderRadius: "50%",
            border: `2px solid ${color.accent}`,
            opacity: 1 - ring,
            transform: `scale(${0.4 + ring})`,
          }}
        />
      ) : null}
      <svg width={26 * scale} height={30 * scale} viewBox="0 0 26 30" style={{ display: "block" }}>
        <path
          d="M2 2 L2 24 L8 18.5 L12.5 28 L16.5 26.2 L12 17 L20.5 17 Z"
          fill={color.ink}
          stroke={color.white}
          strokeWidth={1.8}
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};
