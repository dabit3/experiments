import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import type { Brand, Layout } from "../schema";
import {
  cueX,
  easeInOut,
  playheadKeyframes,
  playheadX,
  progress,
  type TimedScene,
} from "../score";

type Props = {
  brand: Brand;
  layout: Layout;
  trackLabels: string[];
  timeline: TimedScene[];
};

const BAR_H = 10;
const BAR_PAD = 14;
const TICK = 8;

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

/**
 * The score: one row per workflow stage, hairline staves, a bar per stage on its track,
 * event ticks where footage events land, and a playhead that steps from bar to cue.
 * Horizontal position is narrative order, not elapsed time.
 */
export const ScoreStrip: React.FC<Props> = ({ brand, layout, trackLabels, timeline }) => {
  const frame = useCurrentFrame();
  const { width } = useVideoConfig();

  const left = layout.margin;
  const stripW = width - layout.margin * 2;
  const staffX0 = left + layout.labelColumnWidth;
  const staffW = stripW - layout.labelColumnWidth;
  const rows = trackLabels.length;
  const rowH = layout.stripHeight / rows;
  const rowY = (i: number) => layout.stripTop + i * rowH + rowH / 2;
  const centerY = layout.stripTop + layout.stripHeight / 2;
  const xAt = (t: number) => staffX0 + t * staffW;

  const intro = timeline.find((s) => s.kind === "intro");
  const outro = timeline.find((s) => s.kind === "outro");
  const stages = timeline.filter((s) => s.kind === "stage");
  const keys = playheadKeyframes(timeline);
  const headX = xAt(playheadX(frame, keys, layout.playheadEaseFrames));

  const introFrom = intro?.from ?? 0;
  const staffReveal = progress(frame, introFrom, 30);
  const barsReveal = progress(frame, introFrom + 36, 14);
  const headReveal = progress(frame, introFrom + 60, 12);

  // Outro: the tracks converge onto one line and settle into the accent colour.
  const resolve = outro ? progress(frame, outro.from + 18, 36, easeInOut) : 0;
  const fadeChrome = 1 - resolve;

  const activeStage = stages.find(
    (s) => frame >= s.from && frame < s.from + s.durationInFrames,
  );

  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      {/* system line at the head of the staves */}
      <div
        style={{
          position: "absolute",
          left: staffX0,
          top: layout.stripTop,
          width: 1,
          height: layout.stripHeight,
          background: brand.ink,
          opacity: staffReveal * fadeChrome,
        }}
      />

      {trackLabels.map((label, i) => {
        const y = lerp(rowY(i), centerY, resolve);
        const labelIn = progress(frame, introFrom + 8 + i * 6, 14);
        const stage = stages.find((s) => s.track === i);
        const done = stage ? frame >= stage.from + stage.durationInFrames : false;
        const active = activeStage?.track === i;
        const color = active ? brand.ink : done ? brand.inkMuted : brand.inkSubtle;
        return (
          <React.Fragment key={label}>
            <div
              style={{
                position: "absolute",
                left: staffX0,
                top: y,
                width: staffW,
                height: 1,
                background: brand.line,
                transformOrigin: "left center",
                transform: `scaleX(${staffReveal})`,
                opacity: fadeChrome,
              }}
            />
            <div
              style={{
                position: "absolute",
                left: left,
                top: y - 11,
                width: layout.labelColumnWidth - 24,
                fontFamily: brand.fontFamily,
                fontSize: 18,
                lineHeight: "22px",
                letterSpacing: -0.15,
                fontWeight: active ? 500 : 400,
                color,
                opacity: labelIn * fadeChrome,
                transform: `translateX(${(1 - labelIn) * -8}px)`,
                whiteSpace: "nowrap",
              }}
            >
              <span
                style={{
                  display: "inline-block",
                  width: 28,
                  fontFamily: brand.monoFontFamily,
                  fontSize: 13,
                  color: active ? brand.accent : brand.inkSubtle,
                }}
              >
                {String(i + 1).padStart(2, "0")}
              </span>
              {label}
            </div>
          </React.Fragment>
        );
      })}

      {stages.map((stage) => {
        const track = stage.track ?? 0;
        const y = lerp(rowY(track), centerY, resolve);
        const pad = BAR_PAD * (1 - resolve);
        const x0 = xAt(stage.span.start) + pad;
        const x1 = xAt(stage.span.end) - pad;
        const w = Math.max(0, x1 - x0);
        const arrived = frame >= stage.from;
        const arrive = progress(frame, stage.from, 12);
        const fillTo = arrived ? Math.min(Math.max(headX, x0), x1) : x0;
        const h = lerp(BAR_H, 2, resolve);
        const cues = stage.cues ?? [];
        return (
          <React.Fragment key={stage.id}>
            <div
              style={{
                position: "absolute",
                left: x0,
                top: y - h / 2,
                width: w,
                height: h,
                boxSizing: "border-box",
                border: `1px solid ${arrived ? brand.ink : brand.line}`,
                borderRadius: 2,
                background: arrived ? "transparent" : brand.paper,
                opacity: barsReveal * (1 - resolve),
                transformOrigin: "left center",
                transform: `scaleX(${arrived ? arrive : 1})`,
              }}
            />
            <div
              style={{
                position: "absolute",
                left: x0,
                top: y - h / 2,
                width: resolve > 0 ? w : Math.max(0, fillTo - x0),
                height: h,
                background: brand.ink,
                borderRadius: 2,
                opacity: arrived ? 1 - resolve : 0,
              }}
            />
            <div
              style={{
                position: "absolute",
                left: x0,
                top: y - h / 2,
                width: w,
                height: h,
                background: brand.accent,
                opacity: resolve,
              }}
            />
            {cues.map((cue, ci) => {
              const cx = xAt(cueX(stage, ci));
              const at = stage.from + cue.at;
              const fired = frame >= at;
              const pulse = cue.accent === false ? 0 : progress(frame, at, 12);
              const ring = interpolate(pulse, [0, 1], [TICK, 40]);
              return (
                <React.Fragment key={cue.label}>
                  <div
                    style={{
                      position: "absolute",
                      left: cx - TICK / 2,
                      top: y - TICK / 2,
                      width: TICK,
                      height: TICK,
                      boxSizing: "border-box",
                      borderRadius: 1,
                      border: `1px solid ${arrived ? brand.ink : brand.inkSubtle}`,
                      background: fired ? brand.accent : brand.paper,
                      borderColor: fired ? brand.accent : undefined,
                      opacity: barsReveal * (1 - resolve),
                    }}
                  />
                  {fired && pulse < 1 ? (
                    <div
                      style={{
                        position: "absolute",
                        left: cx - ring / 2,
                        top: y - ring / 2,
                        width: ring,
                        height: ring,
                        borderRadius: "50%",
                        border: `1.5px solid ${brand.accent}`,
                        opacity: 1 - pulse,
                      }}
                    />
                  ) : null}
                </React.Fragment>
              );
            })}
          </React.Fragment>
        );
      })}

      {/* playhead */}
      <div
        style={{
          position: "absolute",
          left: headX - 1,
          top: layout.stripTop - 10,
          width: 2,
          height: layout.stripHeight + 20,
          background: brand.accent,
          opacity: headReveal * fadeChrome,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: headX - 6,
          top: layout.stripTop - 18,
          width: 0,
          height: 0,
          borderLeft: "6px solid transparent",
          borderRight: "6px solid transparent",
          borderTop: `8px solid ${brand.accent}`,
          opacity: headReveal * fadeChrome,
        }}
      />
    </div>
  );
};
