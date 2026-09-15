import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { ELAPSED_END, chrome, phases, scenes } from "../scenes";
import { HEIGHT, MARGIN, WIDTH, color, font, layout, sizes, tracking, weight } from "../theme";
import { lifetime } from "./anim";

export const formatClock = (s: number) => {
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return `${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
};

/** Simulated agent wall-clock, in seconds, for a composition frame. */
export const elapsedAt = (frame: number) => {
  const feature = [scenes.build, scenes.drive, scenes.fix, scenes.qa];
  const xs = [...feature.map((s) => s.from), scenes.qa.from + scenes.qa.duration];
  const ys = [...feature.map((s) => s.elapsed), ELAPSED_END];
  return interpolate(frame, xs, ys, { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
};

const mono: React.CSSProperties = {
  fontFamily: font.mono,
  fontSize: sizes.label,
  fontWeight: weight.medium,
  letterSpacing: tracking.caps,
  textTransform: "uppercase",
  color: color.gray500,
  lineHeight: 1,
};

/** Thin timeline across the top: elapsed readout, track with accent progress, phase label. */
export const Timeline: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = lifetime(frame, chrome.fadeIn, chrome.fadeOut, 20, 14);
  const elapsed = elapsedAt(frame);
  const progress = elapsed / ELAPSED_END;
  const phase = [...phases].reverse().find((p) => frame >= p.from);
  const running = frame >= scenes.build.from && frame < scenes.outcome.from;

  const readoutW = 200;
  const trackX = MARGIN + readoutW;
  const trackW = WIDTH - MARGIN * 2 - readoutW * 2;
  const y = layout.timelineY;

  return (
    <AbsoluteFill style={{ opacity }}>
      <div style={{ ...mono, position: "absolute", left: MARGIN, top: y - 9, color: color.ink }}>
        <span style={{ color: color.gray500 }}>Elapsed </span>
        {formatClock(elapsed)}
      </div>
      <div
        style={{
          position: "absolute",
          left: trackX,
          top: y - 1,
          width: trackW,
          height: 2,
          background: color.gray300,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: trackX,
          top: y - 1,
          width: trackW * progress,
          height: 2,
          background: color.accent,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: trackX + trackW * progress - 5,
          top: y - 5,
          width: 10,
          height: 10,
          borderRadius: 999,
          background: color.accent,
          boxShadow: running ? `0 0 0 6px ${color.accentGlow}` : "none",
        }}
      />
      <div
        style={{
          ...mono,
          position: "absolute",
          right: MARGIN,
          top: y - 9,
          width: readoutW,
          textAlign: "right",
          color: running ? color.accent : color.gray500,
        }}
      >
        {phase && running ? phase.label : "Devin · macOS"}
      </div>
    </AbsoluteFill>
  );
};

/** Vertical divider and the You / Devin panel labels. */
export const Split: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = lifetime(frame, chrome.fadeIn, chrome.splitFadeOut, 20, 14);
  const grow = interpolate(frame, [chrome.fadeIn, chrome.fadeIn + 30], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const top = layout.panelLabelY - 10;
  const bottom = HEIGHT - MARGIN;
  return (
    <AbsoluteFill style={{ opacity }}>
      <div
        style={{
          position: "absolute",
          left: layout.dividerX,
          top,
          width: 1,
          height: (bottom - top) * grow,
          background: color.border,
        }}
      />
      <div style={{ ...mono, position: "absolute", left: layout.left.x, top: layout.panelLabelY - 9 }}>
        You
      </div>
      <div style={{ ...mono, position: "absolute", left: layout.right.x, top: layout.panelLabelY - 9 }}>
        Devin
      </div>
    </AbsoluteFill>
  );
};
