import React from "react";
import type { Brand, Camera } from "./schema";
import type { StationTiming } from "./timeline";
import { type } from "./type";

type Props = {
  timeline: StationTiming[];
  camera: Camera;
  brand: Brand;
  progress: number;
  activeIndex: number;
};

/**
 * The route: a hairline joining every station at `routeOffsetY` below the
 * station centres, with the travelled part in the accent colour and a dot plus
 * stage label at each stop. Lives on the canvas, so it moves with the camera.
 */
export const Route: React.FC<Props> = ({ timeline, camera, brand, progress, activeIndex }) => {
  if (!camera.showRoute || timeline.length < 2) return null;
  const pts = timeline.map((t) => ({
    x: t.station.x,
    y: t.station.y + camera.routeOffsetY,
    label: t.station.stageLabel,
    index: t.index,
  }));
  const minX = Math.min(...pts.map((p) => p.x)) - 40;
  const maxX = Math.max(...pts.map((p) => p.x)) + 40;
  const minY = Math.min(...pts.map((p) => p.y)) - 60;
  const maxY = Math.max(...pts.map((p) => p.y)) + 60;
  const path = pts.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x - minX} ${p.y - minY}`).join(" ");
  const total = pts.slice(1).reduce((acc, p, i) => acc + Math.hypot(p.x - pts[i].x, p.y - pts[i].y), 0);

  return (
    <div style={{ position: "absolute", left: minX, top: minY, width: maxX - minX, height: maxY - minY }}>
      <svg width={maxX - minX} height={maxY - minY} style={{ position: "absolute", left: 0, top: 0 }}>
        <path d={path} stroke={brand.line} strokeWidth={2} fill="none" />
        <path
          d={path}
          stroke={brand.accent}
          strokeWidth={2}
          fill="none"
          strokeDasharray={total}
          strokeDashoffset={total * (1 - progress)}
        />
        {pts.map((p) => {
          const reached = p.index <= activeIndex;
          return (
            <circle
              key={p.index}
              cx={p.x - minX}
              cy={p.y - minY}
              r={reached ? 6 : 5}
              fill={reached ? brand.accent : brand.paper}
              stroke={reached ? brand.accent : brand.inkSubtle}
              strokeWidth={2}
            />
          );
        })}
      </svg>
      {pts.map((p) =>
        p.label ? (
          <div
            key={p.index}
            style={{
              position: "absolute",
              left: p.x - minX + 18,
              top: p.y - minY - 12,
              ...type.eyebrow,
              fontFamily: brand.monoFontFamily,
              color: p.index === activeIndex ? brand.ink : brand.inkSubtle,
              whiteSpace: "nowrap",
            }}
          >
            {String(p.index).padStart(2, "0")} · {p.label}
          </div>
        ) : null,
      )}
    </div>
  );
};
