import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { DrawPath, useDraw, useEnter } from "../components/Draw";
import { Label } from "../components/Text";
import { FONT_SANS, HEIGHT, MARGIN, WIDTH, bp, easeOut, type } from "../theme";

const ROWS = [
  { key: "01", name: "Cycle time", value: "Minutes, not 20+ minute CI round-trips." },
  { key: "02", name: "Platform", value: "The only coding agent with a Mac cloud agent." },
  { key: "03", name: "Security", value: "Same security as Linux and Windows VMs." },
  { key: "04", name: "Price", value: "No price increase — same as Linux cloud sessions." },
  { key: "05", name: "Works with", value: "Child sessions, repo setup, the Devin API, automations." },
];

const ROW_H = 96;
const TOP = 250;
const STEP = 22;
const TABLE_W = 1680;

/** Specification table: rows draw on one at a time, like a title-block parts list. */
export const Outcome: React.FC = () => {
  const frame = useCurrentFrame();
  const head = useEnter(4);
  const headRule = useDraw(10);
  return (
    <AbsoluteFill>
      <div style={{ position: "absolute", left: MARGIN, top: TOP - 70, opacity: head }}>
        <Label>Specifications · Devin on macOS</Label>
      </div>
      <svg width={WIDTH} height={HEIGHT} style={{ position: "absolute", inset: 0 }}>
        <DrawPath d={`M${MARGIN},${TOP} H${MARGIN + TABLE_W}`} progress={headRule} width={1.5} />
        {ROWS.map((r, i) => {
          const at = 16 + i * STEP;
          const p = interpolate(frame, [at + 8, at + 8 + 12], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: easeOut,
          });
          const y = TOP + (i + 1) * ROW_H;
          return <DrawPath key={r.key} d={`M${MARGIN},${y} H${MARGIN + TABLE_W}`} progress={p} width={1} stroke={bp.lineSoft} />;
        })}
        <DrawPath
          d={`M${MARGIN + 300},${TOP} V${TOP + ROWS.length * ROW_H}`}
          progress={interpolate(frame, [20, 20 + STEP * ROWS.length], [0, 1], { extrapolateRight: "clamp", extrapolateLeft: "clamp" })}
          width={1}
          stroke={bp.lineSoft}
        />
      </svg>
      {ROWS.map((r, i) => {
        const at = 16 + i * STEP;
        const o = interpolate(frame, [at, at + 14], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        });
        const y = TOP + i * ROW_H;
        return (
          <div key={r.key} style={{ position: "absolute", left: MARGIN, top: y, width: TABLE_W, height: ROW_H, opacity: o }}>
            <div style={{ position: "absolute", left: 0, top: 37, display: "flex", gap: 20, alignItems: "baseline" }}>
              <Label color={bp.line} style={{ fontWeight: 500 }}>
                {r.key}
              </Label>
              <Label>{r.name}</Label>
            </div>
            <div
              style={{
                position: "absolute",
                left: 340,
                top: 25,
                fontFamily: FONT_SANS,
                fontWeight: 500,
                fontSize: 46,
                lineHeight: 1,
                letterSpacing: type.tracking.heading,
                color: bp.text,
                whiteSpace: "nowrap",
                transform: `translateY(${(1 - o) * 10}px)`,
              }}
            >
              {r.value}
            </div>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};
