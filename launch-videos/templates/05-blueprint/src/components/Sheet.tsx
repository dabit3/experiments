import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { SCENES, SHEET_COUNT } from "../scenes";
import { FONT_MONO, HEIGHT, SAFE, WIDTH, bp, easeOut, type } from "../theme";

const MINOR = 40;
const MAJOR = 120;

/** Drafting-sheet background: grid + border with tick marks. Persistent under every scene. */
export const Sheet: React.FC = () => {
  const frame = useCurrentFrame();
  const fade = interpolate(frame, [0, 24], [0, 1], { extrapolateRight: "clamp", easing: easeOut });
  const w = WIDTH - SAFE * 2;
  const h = HEIGHT - SAFE * 2;
  const ticks: React.ReactNode[] = [];
  for (let x = SAFE + MAJOR; x < WIDTH - SAFE; x += MAJOR) {
    ticks.push(<line key={`t${x}`} x1={x} y1={SAFE} x2={x} y2={SAFE + 8} />);
    ticks.push(<line key={`b${x}`} x1={x} y1={HEIGHT - SAFE} x2={x} y2={HEIGHT - SAFE - 8} />);
  }
  for (let y = SAFE + MAJOR; y < HEIGHT - SAFE; y += MAJOR) {
    ticks.push(<line key={`l${y}`} x1={SAFE} y1={y} x2={SAFE + 8} y2={y} />);
    ticks.push(<line key={`r${y}`} x1={WIDTH - SAFE} y1={y} x2={WIDTH - SAFE - 8} y2={y} />);
  }
  return (
    <AbsoluteFill style={{ backgroundColor: bp.sheet }}>
      <svg width={WIDTH} height={HEIGHT} style={{ position: "absolute", inset: 0, opacity: fade }}>
        <defs>
          <pattern id="minor" width={MINOR} height={MINOR} patternUnits="userSpaceOnUse">
            <path d={`M${MINOR},0 L0,0 0,${MINOR}`} fill="none" stroke={bp.gridMinor} strokeWidth={1} />
          </pattern>
          <pattern id="major" width={MAJOR} height={MAJOR} patternUnits="userSpaceOnUse">
            <rect width={MAJOR} height={MAJOR} fill="url(#minor)" />
            <path d={`M${MAJOR},0 L0,0 0,${MAJOR}`} fill="none" stroke={bp.gridMajor} strokeWidth={1} />
          </pattern>
        </defs>
        <rect x={SAFE} y={SAFE} width={w} height={h} fill="url(#major)" />
        <rect x={SAFE} y={SAFE} width={w} height={h} fill="none" stroke={bp.lineSoft} strokeWidth={1.5} />
        <g stroke={bp.lineSoft} strokeWidth={1}>
          {ticks}
        </g>
      </svg>
      <TitleBlock />
    </AbsoluteFill>
  );
};

const BLOCK_W = 540;
const SPLIT = 380;
const BLOCK_H = 120;

/** Title block pinned to the bottom-right of the border, like a real drawing. */
const TitleBlock: React.FC = () => {
  const frame = useCurrentFrame();
  const current = [...SCENES].reverse().find((s) => frame >= s.from) ?? SCENES[0];
  const local = frame - current.from;
  const swap = interpolate(local, [0, 10], [0, 1], { extrapolateRight: "clamp", easing: easeOut });
  const x = WIDTH - SAFE - BLOCK_W;
  const y = HEIGHT - SAFE - BLOCK_H;
  const intro = interpolate(frame, [6, 30], [0, 1], { extrapolateRight: "clamp", easing: easeOut });
  const label: React.CSSProperties = {
    fontFamily: FONT_MONO,
    fontSize: 13,
    letterSpacing: type.tracking.caps,
    textTransform: "uppercase",
    color: bp.textFaint,
    lineHeight: 1,
  };
  const value: React.CSSProperties = {
    fontFamily: FONT_MONO,
    fontSize: 15,
    fontWeight: 500,
    color: bp.text,
    lineHeight: 1,
    letterSpacing: "0.01em",
    whiteSpace: "nowrap",
  };
  return (
    <div style={{ position: "absolute", left: x, top: y, width: BLOCK_W, height: BLOCK_H, opacity: intro }}>
      <svg width={BLOCK_W} height={BLOCK_H} style={{ position: "absolute", inset: 0 }}>
        <rect x={0.75} y={0.75} width={BLOCK_W - 1.5} height={BLOCK_H - 1.5} fill={bp.sheet} stroke={bp.lineSoft} strokeWidth={1.5} />
        <line x1={0} y1={60} x2={BLOCK_W} y2={60} stroke={bp.lineSoft} strokeWidth={1} />
        <line x1={SPLIT} y1={0} x2={SPLIT} y2={BLOCK_H} stroke={bp.lineSoft} strokeWidth={1} />
      </svg>
      <div style={{ position: "absolute", left: 20, top: 16 }}>
        <div style={label}>Project</div>
        <div style={{ ...value, marginTop: 10 }}>Devin — macOS · native iOS</div>
      </div>
      <div style={{ position: "absolute", left: SPLIT + 20, top: 16 }}>
        <div style={label}>Sheet</div>
        <div style={{ ...value, marginTop: 10 }}>
          {current.sheet} / {String(SHEET_COUNT).padStart(2, "0")}
        </div>
      </div>
      <div style={{ position: "absolute", left: 20, top: 76, opacity: swap }}>
        <div style={label}>Drawing</div>
        <div style={{ ...value, marginTop: 10 }}>{current.title}</div>
      </div>
      <div style={{ position: "absolute", left: SPLIT + 20, top: 76 }}>
        <div style={label}>Scale</div>
        <div style={{ ...value, marginTop: 10 }}>1 : 1 · 30 fps</div>
      </div>
    </div>
  );
};
