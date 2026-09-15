import React from "react";
import type { Brand, Route } from "../schema";
import { TYPE } from "../geometry";

type Props = { brand: Brand; route: Route; current: number };

// Small route strip that keeps context while a recording is dominant.
export const RouteIndicator: React.FC<Props> = ({ brand, route, current }) => {
  const n = route.stations.length;
  const gap = 36;
  const w = gap * n + 16;
  const next = route.stations[current] ?? null;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16, fontFamily: brand.fontFamily }}>
      {next ? (
        <span style={{ fontSize: TYPE.label.size, letterSpacing: TYPE.label.tracking, color: brand.inkMuted }}>
          Next · {next.name}
        </span>
      ) : null}
      <svg width={w} height={24} viewBox={`0 0 ${w} 24`}>
        <line x1={8} y1={12} x2={w - 8} y2={12} stroke={brand.line} strokeWidth={3} />
        <line x1={8} y1={12} x2={8 + gap * (current - 1)} y2={12} stroke={brand.accent} strokeWidth={3} />
        <rect x={6} y={5} width={4} height={14} fill={brand.accent} />
        {route.stations.map((s, i) => {
          const x = 8 + gap * (i + 1);
          const k = i + 1;
          if (k < current) {
            return <circle key={s.id} cx={x} cy={12} r={5} fill={brand.accent} />;
          }
          if (k === current) {
            return (
              <g key={s.id}>
                <circle cx={x} cy={12} r={9} fill="none" stroke={brand.accent} strokeWidth={2} />
                <circle cx={x} cy={12} r={5} fill={brand.accent} />
              </g>
            );
          }
          return <circle key={s.id} cx={x} cy={12} r={5} fill={brand.paper} stroke={brand.inkSubtle} strokeWidth={2} />;
        })}
      </svg>
    </div>
  );
};
