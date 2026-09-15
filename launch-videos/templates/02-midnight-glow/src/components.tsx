import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { color, easeIn, easeInOut, easeOut, hairline, radius, sec, textGlow } from "./tokens";
import { MONO, SANS } from "./fonts";

/* ------------------------------------------------------------------ */
/* Helpers                                                             */
/* ------------------------------------------------------------------ */

export const clamp = (v: number, a = 0, b = 1) => Math.min(b, Math.max(a, v));

/** Ease-out entrance progress 0..1 starting at `start` (frames) lasting `dur` (frames). */
export const enter = (frame: number, start: number, dur = sec(0.6)) =>
  interpolate(frame, [start, start + dur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });

/** Ease-in exit progress 1..0 ending at `end`, lasting `dur`. */
export const exit = (frame: number, end: number, dur = sec(0.4)) =>
  interpolate(frame, [end - dur, end], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });

/** Ease-in-out move between two values over [start, start+dur]. */
export const move = (frame: number, start: number, dur: number, from: number, to: number) =>
  interpolate(frame, [start, start + dur], [from, to], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });

/* ------------------------------------------------------------------ */
/* Scene shell: near-black bg + one radial glow                        */
/* ------------------------------------------------------------------ */

export const Backdrop: React.FC<{
  glowX?: number;
  glowY?: number;
  glowSize?: number;
  glowOpacity?: number;
}> = ({ glowX = 960, glowY = 620, glowSize = 1400, glowOpacity = 1 }) => {
  return (
    <AbsoluteFill style={{ backgroundColor: color.darkBg }}>
      <div
        style={{
          position: "absolute",
          left: glowX - glowSize / 2,
          top: glowY - glowSize / 2,
          width: glowSize,
          height: glowSize,
          borderRadius: "50%",
          opacity: glowOpacity,
          background:
            "radial-gradient(circle, rgba(34,0,255,0.42) 0%, rgba(34,0,255,0.16) 32%, rgba(34,0,255,0.0) 66%)",
        }}
      />
      <Grain />
    </AbsoluteFill>
  );
};

/** Fine film grain that breaks up 8-bit banding in the dark gradients. */
const Grain: React.FC = () => (
  <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%", opacity: 0.045, mixBlendMode: "overlay" }}>
    <filter id="grain">
      <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" stitchTiles="stitch" />
      <feColorMatrix type="saturate" values="0" />
    </filter>
    <rect width="100%" height="100%" filter="url(#grain)" />
  </svg>
);

/** Wraps a scene so it dissolves in and out at its edges. */
export const SceneFade: React.FC<{
  children: React.ReactNode;
  inDur?: number;
  outDur?: number;
}> = ({ children, inDur = sec(0.35), outDur = sec(0.35) }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const a = interpolate(frame, [0, inDur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const b = interpolate(frame, [durationInFrames - outDur, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return <AbsoluteFill style={{ opacity: a * b }}>{children}</AbsoluteFill>;
};

/* ------------------------------------------------------------------ */
/* Type                                                                */
/* ------------------------------------------------------------------ */

type HeadlineProps = {
  children: React.ReactNode;
  size?: number;
  start?: number;
  x?: number;
  y?: number;
  width?: number;
  align?: "left" | "center";
  glow?: number;
  color?: string;
  weight?: 400 | 500;
  holdUntil?: number;
};

/** Headline with faint glow bloom. Entrance: fade + 24px rise (ease-out). */
export const Headline: React.FC<HeadlineProps> = ({
  children,
  size = 56,
  start = 0,
  x = 120,
  y = 120,
  width = 1680,
  align = "left",
  glow = 1,
  color: c = color.white,
  weight = 500,
  holdUntil,
}) => {
  const frame = useCurrentFrame();
  const p = enter(frame, start, sec(0.7));
  const out = holdUntil === undefined ? 1 : exit(frame, holdUntil);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        fontFamily: SANS,
        fontWeight: weight,
        fontSize: size,
        lineHeight: 1.1,
        letterSpacing: "-0.037em",
        color: c,
        textAlign: align,
        opacity: p * out,
        transform: `translateY(${(1 - p) * 24}px)`,
        textShadow: glow ? textGlow(glow) : undefined,
        whiteSpace: "pre-line",
      }}
    >
      {children}
    </div>
  );
};

/** Small uppercase mono label. */
export const Label: React.FC<{
  children: React.ReactNode;
  x: number;
  y: number;
  start?: number;
  color?: string;
  align?: "left" | "center";
  width?: number;
}> = ({ children, x, y, start = 0, color: c = color.gray400, align = "left", width }) => {
  const frame = useCurrentFrame();
  const p = enter(frame, start);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        textAlign: align,
        fontFamily: MONO,
        fontSize: 18,
        fontWeight: 500,
        letterSpacing: "0.04em",
        textTransform: "uppercase",
        color: c,
        opacity: p,
        transform: `translateY(${(1 - p) * 12}px)`,
      }}
    >
      {children}
    </div>
  );
};

/* ------------------------------------------------------------------ */
/* Screenshot frame                                                    */
/* ------------------------------------------------------------------ */

export type KenBurns = {
  /** scale at start / end */
  scale: [number, number];
  /** translate (px, in frame space) at start / end */
  x?: [number, number];
  y?: [number, number];
  /** transform origin, e.g. "50% 30%" */
  origin?: string;
  /** frames over which the move happens (default: whole scene) */
  start?: number;
  dur?: number;
};

type ScreenFrameProps = {
  src: string;
  x: number;
  y: number;
  width: number;
  /** intrinsic aspect ratio w/h of the screenshot so it is never stretched */
  aspect: number;
  start?: number;
  kenBurns?: KenBurns;
  /** entrance rise in px (0 for a pure cross-dissolve over a previous frame) */
  rise?: number;
  /** entrance duration in frames */
  enterDur?: number;
  children?: React.ReactNode;
  radius?: number;
  glow?: boolean;
};

/**
 * Screenshot framed on dark: 1px hairline border, 10px radius, accent glow
 * underneath. The image is clipped by the frame and slowly pushed/panned.
 * Children (callouts) are positioned in frame space and travel with it.
 */
export const ScreenFrame: React.FC<ScreenFrameProps> = ({
  src,
  x,
  y,
  width,
  aspect,
  start = 0,
  kenBurns,
  rise = 40,
  enterDur = sec(0.9),
  children,
  radius: r = radius.md,
  glow = true,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const height = Math.round(width / aspect);
  const p = enter(frame, start, enterDur);

  const kbStart = kenBurns?.start ?? 0;
  const kbDur = kenBurns?.dur ?? durationInFrames - kbStart;
  const scale = kenBurns ? move(frame, kbStart, kbDur, kenBurns.scale[0], kenBurns.scale[1]) : 1;
  const tx = kenBurns?.x ? move(frame, kbStart, kbDur, kenBurns.x[0], kenBurns.x[1]) : 0;
  const ty = kenBurns?.y ? move(frame, kbStart, kbDur, kenBurns.y[0], kenBurns.y[1]) : 0;

  const motion: React.CSSProperties = {
    position: "absolute",
    inset: 0,
    transformOrigin: kenBurns?.origin ?? "50% 50%",
    transform: `translate(${tx}px, ${ty}px) scale(${scale})`,
  };
  const imgStyle: React.CSSProperties = { ...motion, width: "100%", height: "100%", display: "block" };

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        height,
        opacity: p,
        transform: `translateY(${(1 - p) * rise}px)`,
      }}
    >
      {glow ? (
        <div
          style={{
            position: "absolute",
            left: -80,
            right: -80,
            top: 40,
            bottom: -80,
            borderRadius: r + 80,
            background:
              "radial-gradient(ellipse at 50% 40%, rgba(34,0,255,0.28) 0%, rgba(34,0,255,0.0) 70%)",
            filter: "blur(40px)",
          }}
        />
      ) : null}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: r,
          overflow: "hidden",
          backgroundColor: color.darkSurface,
          boxShadow: `inset 0 0 0 1px ${hairline}, 0 40px 80px -20px rgba(0,0,0,0.6)`,
        }}
      >
        <Img src={staticFile(src)} style={imgStyle} />
        {/* keep the hairline above the image */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: r,
            boxShadow: `inset 0 0 0 1px ${hairline}`,
            pointerEvents: "none",
          }}
        />
      </div>
      {/* callouts share the image's motion so anchors stay pinned to the UI */}
      <div style={motion}>{children}</div>
    </div>
  );
};

/* ------------------------------------------------------------------ */
/* Pill callout with hairline                                          */
/* ------------------------------------------------------------------ */

type PillProps = {
  label: string;
  /** anchor point on the UI element, in the parent frame's space */
  anchor: { x: number; y: number };
  /** where the pill sits (its near edge), relative to the frame */
  pill: { x: number; y: number };
  /** which edge the pill slides in from */
  from?: "left" | "right";
  start: number;
  end?: number;
  tone?: "accent" | "neutral" | "success";
};

/**
 * Small pill label connected by a hairline to the anchored UI element.
 * Entrance: slide from edge + fade. The hairline draws from the pill to the anchor.
 */
export const Pill: React.FC<PillProps> = ({
  label,
  anchor,
  pill,
  from = "right",
  start,
  end,
  tone = "neutral",
}) => {
  const frame = useCurrentFrame();
  const p = enter(frame, start, sec(0.7));
  const out = end === undefined ? 1 : exit(frame, end);
  const line = interpolate(frame, [start + sec(0.25), start + sec(0.85)], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const slide = (1 - p) * 48 * (from === "right" ? 1 : -1);

  const dx = anchor.x - pill.x;
  const dy = anchor.y - pill.y;
  const len = Math.hypot(dx, dy);
  const ang = (Math.atan2(dy, dx) * 180) / Math.PI;

  const dot = tone === "accent" ? color.accent : tone === "success" ? color.success : "#6E5CFF";
  const border =
    tone === "accent" ? "rgba(110,92,255,0.9)" : tone === "success" ? "rgba(31,157,85,0.8)" : "rgba(255,255,255,0.22)";
  const bg = tone === "accent" ? "#1B12A8" : color.darkSurface;

  return (
    <div style={{ position: "absolute", left: 0, top: 0, opacity: p * out }}>
      {/* hairline */}
      <div
        style={{
          position: "absolute",
          left: pill.x,
          top: pill.y,
          width: len * line,
          height: 1,
          background: dot,
          opacity: 0.9,
          transformOrigin: "0 0",
          transform: `rotate(${ang}deg)`,
        }}
      />
      {/* anchor dot */}
      <div
        style={{
          position: "absolute",
          left: anchor.x - 4,
          top: anchor.y - 4,
          width: 8,
          height: 8,
          borderRadius: 4,
          background: dot,
          boxShadow: `0 0 0 3px rgba(255,255,255,0.9), 0 0 16px ${dot}`,
          opacity: line,
        }}
      />
      {/* pill */}
      <div
        style={{
          position: "absolute",
          left: from === "right" ? pill.x : undefined,
          right: from === "left" ? -pill.x : undefined,
          top: pill.y,
          transform: `translate(${slide}px, -50%)`,
          padding: "10px 16px",
          borderRadius: 999,
          fontFamily: MONO,
          fontSize: 18,
          fontWeight: 500,
          letterSpacing: "0.02em",
          color: color.white,
          background: bg,
          boxShadow: `inset 0 0 0 1px ${border}, 0 8px 24px rgba(0,0,0,0.5)`,
          whiteSpace: "nowrap",
        }}
      >
        {label}
      </div>
    </div>
  );
};

/* ------------------------------------------------------------------ */
/* Cursor overlay                                                      */
/* ------------------------------------------------------------------ */

type CursorProps = {
  /** waypoints in frame space; cursor eases between consecutive points */
  path: { x: number; y: number; at: number }[];
  /** frames at which a click ripple fires */
  clicks?: number[];
  size?: number;
};

export const Cursor: React.FC<CursorProps> = ({ path, clicks = [], size = 28 }) => {
  const frame = useCurrentFrame();
  let x = path[0].x;
  let y = path[0].y;
  for (let i = 0; i < path.length - 1; i++) {
    const a = path[i];
    const b = path[i + 1];
    if (frame >= a.at) {
      x = move(frame, a.at, b.at - a.at, a.x, b.x);
      y = move(frame, a.at, b.at - a.at, a.y, b.y);
    }
  }
  const visible = enter(frame, path[0].at, sec(0.3));
  return (
    <div style={{ position: "absolute", left: 0, top: 0, opacity: visible }}>
      {clicks.map((c) => {
        const r = interpolate(frame, [c, c + sec(0.6)], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        });
        if (frame < c || r >= 1) return null;
        return (
          <div
            key={c}
            style={{
              position: "absolute",
              left: x - 24 * r,
              top: y - 24 * r,
              width: 48 * r,
              height: 48 * r,
              borderRadius: "50%",
              border: `1.5px solid rgba(34,0,255,${1 - r})`,
              background: `rgba(34,0,255,${0.25 * (1 - r)})`,
            }}
          />
        );
      })}
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        style={{ position: "absolute", left: x - 3, top: y - 2, filter: "drop-shadow(0 2px 6px rgba(0,0,0,0.6))" }}
      >
        <path
          d="M5 3l14 8.5-6.2 1.4L9.5 19z"
          fill="#fff"
          stroke="#191919"
          strokeWidth="1.5"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};
