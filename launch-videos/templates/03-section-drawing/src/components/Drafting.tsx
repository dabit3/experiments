import React from "react";
import { AbsoluteFill } from "remotion";
import type { Brand, Content } from "../schema";
import { CONTENT, HEIGHT, MARGIN, WIDTH } from "../layout";

/** Subtle drafting grid on the paper. `opacity` lets scenes fade it out under demos. */
export const Grid: React.FC<{ brand: Brand; opacity: number }> = ({ brand, opacity }) => {
  if (opacity <= 0) {
    return null;
  }
  const s = brand.gridSize;
  return (
    <AbsoluteFill
      style={{
        opacity: opacity * brand.gridOpacity,
        backgroundImage: `linear-gradient(${brand.line} 1px, transparent 1px), linear-gradient(90deg, ${brand.line} 1px, transparent 1px)`,
        backgroundSize: `${s}px ${s}px`,
        backgroundPosition: `${MARGIN}px ${MARGIN}px`,
      }}
    />
  );
};

/** Corner ticks marking the 96px safe margin, like a drawing sheet's trim marks. */
export const SheetMarks: React.FC<{ brand: Brand; opacity: number }> = ({ brand, opacity }) => {
  if (opacity <= 0) {
    return null;
  }
  const len = 18;
  const corners = [
    [CONTENT.x, CONTENT.y, 1, 1],
    [CONTENT.x + CONTENT.w, CONTENT.y, -1, 1],
    [CONTENT.x, CONTENT.y + CONTENT.h, 1, -1],
    [CONTENT.x + CONTENT.w, CONTENT.y + CONTENT.h, -1, -1],
  ];
  return (
    <svg
      width={WIDTH}
      height={HEIGHT}
      style={{ position: "absolute", left: 0, top: 0, opacity }}
      shapeRendering="crispEdges"
    >
      {corners.map(([x, y, dx, dy], i) => (
        <path
          key={i}
          d={`M ${x} ${y + dy * len} L ${x} ${y} L ${x + dx * len} ${y}`}
          stroke={brand.inkSubtle}
          strokeWidth={1}
          fill="none"
        />
      ))}
    </svg>
  );
};

/** Architectural title block in the bottom-right corner of the sheet. */
export const TitleBlock: React.FC<{
  brand: Brand;
  content: Content;
  opacity: number;
  stageLabel?: string;
}> = ({ brand, content, opacity, stageLabel }) => {
  if (opacity <= 0) {
    return null;
  }
  const cell: React.CSSProperties = {
    padding: "8px 14px",
    borderLeft: `1px solid ${brand.line}`,
    fontFamily: brand.monoFontFamily,
    fontSize: 15,
    lineHeight: "20px",
    letterSpacing: 0.28,
    textTransform: "uppercase",
    color: brand.inkMuted,
    whiteSpace: "nowrap",
  };
  return (
    <div
      style={{
        position: "absolute",
        right: MARGIN,
        bottom: MARGIN - 40,
        display: "flex",
        border: `1px solid ${brand.line}`,
        borderRadius: 2,
        background: brand.paper,
        opacity,
      }}
    >
      <div style={{ ...cell, borderLeft: "none", color: brand.ink }}>{content.sheet.number}</div>
      <div style={cell}>{content.sheet.title}</div>
      {stageLabel ? <div style={cell}>{stageLabel}</div> : null}
      <div style={cell}>Scale {content.sheet.scale}</div>
    </div>
  );
};

/** A horizontal dimension line with end ticks and a centered mono label. */
export const DimensionLine: React.FC<{
  brand: Brand;
  x1: number;
  x2: number;
  y: number;
  label?: string;
  progress: number;
  color?: string;
}> = ({ brand, x1, x2, y, label, progress, color }) => {
  if (progress <= 0) {
    return null;
  }
  const stroke = color ?? brand.inkSubtle;
  const len = (x2 - x1) * progress;
  return (
    <>
      <svg
        style={{ position: "absolute", left: 0, top: 0 }}
        width={WIDTH}
        height={HEIGHT}
        shapeRendering="crispEdges"
      >
        <line x1={x1} y1={y} x2={x1 + len} y2={y} stroke={stroke} strokeWidth={1} />
        <line x1={x1 + 0.5} y1={y - 6} x2={x1 + 0.5} y2={y + 6} stroke={stroke} strokeWidth={1} />
        {progress >= 1 ? (
          <line x1={x2 - 0.5} y1={y - 6} x2={x2 - 0.5} y2={y + 6} stroke={stroke} strokeWidth={1} />
        ) : null}
      </svg>
      {label && progress >= 1 ? (
        <div
          style={{
            position: "absolute",
            left: x1,
            width: x2 - x1,
            top: y - 26,
            textAlign: "center",
            fontFamily: brand.monoFontFamily,
            fontSize: 15,
            letterSpacing: 0.28,
            textTransform: "uppercase",
            color: stroke,
          }}
        >
          {label}
        </div>
      ) : null}
    </>
  );
};
