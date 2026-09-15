import React from "react";
import { AbsoluteFill } from "remotion";
import type { Brand, Route } from "../schema";
import { HEIGHT, TYPE, WIDTH, clamp01, progressToX, routeXs } from "../geometry";

type Props = {
  brand: Brand;
  route: Route;
  // Position of the head of the accent line, in station units (0 = origin).
  progress: number;
  // 0..1 reveal of the base map (gray line + labels), wiped left to right.
  reveal?: number;
  // Station index (1-based) whose marker is currently pulsing, with pulse 0..1.
  pulse?: { station: number; t: number };
  opacity?: number;
};

const BRANCH_RISE = 64;
const BRANCH_SPREAD = 160;

export const RouteMap: React.FC<Props> = ({ brand, route, progress, reveal = 1, pulse, opacity = 1 }) => {
  const xs = routeXs(route);
  const y = route.y;
  const r = route.markerRadius;
  const headX = progressToX(route, progress);
  const revealX = WIDTH * reveal;

  return (
    <AbsoluteFill style={{ opacity }}>
      <svg width={WIDTH} height={HEIGHT} viewBox={`0 0 ${WIDTH} ${HEIGHT}`} style={{ position: "absolute" }}>
        <defs>
          <clipPath id="route-reveal">
            <rect x={0} y={0} width={revealX} height={HEIGHT} />
          </clipPath>
        </defs>

        <g clipPath="url(#route-reveal)">
          {/* Base route: hairline + hollow markers */}
          <line x1={xs[0]} y1={y} x2={xs[xs.length - 1]} y2={y} stroke={brand.line} strokeWidth={route.lineWidth} />
          {route.stations.map((s, i) => {
            const x = xs[i + 1];
            const reached = progress >= i + 1 - 0.001;
            return (
              <g key={s.id}>
                {s.branches ? (
                  <Branches
                    brand={brand}
                    x={x}
                    y={y}
                    r={r}
                    lineWidth={route.lineWidth}
                    reached={reached}
                    labels={s.branches}
                    font={brand.fontFamily}
                  />
                ) : null}
                <circle cx={x} cy={y} r={r} fill={brand.paper} stroke={reached ? brand.accent : brand.inkSubtle} strokeWidth={3} />
              </g>
            );
          })}
        </g>

        {/* Accent line traced so far, square caps for a crisp head */}
        {headX > xs[0] ? (
          <line x1={xs[0]} y1={y} x2={headX} y2={y} stroke={brand.accent} strokeWidth={route.lineWidth} strokeLinecap="butt" />
        ) : null}

        {/* Origin terminus */}
        <g clipPath="url(#route-reveal)">
          <rect x={xs[0] - 5} y={y - r - 6} width={10} height={2 * r + 12} fill={progress > 0 ? brand.accent : brand.inkSubtle} />
        </g>

        {/* Visited markers: filled accent */}
        {route.stations.map((s, i) => {
          const x = xs[i + 1];
          const reached = progress >= i + 1 - 0.001;
          if (!reached) {
            return null;
          }
          return <circle key={`${s.id}-filled`} cx={x} cy={y} r={r} fill={brand.accent} />;
        })}

        {/* Arrival pulse: one ring, no bounce */}
        {pulse ? (
          <circle
            cx={xs[pulse.station]}
            cy={y}
            r={r + 4 + 26 * clamp01(pulse.t)}
            fill="none"
            stroke={brand.accent}
            strokeWidth={2}
            opacity={1 - clamp01(pulse.t)}
          />
        ) : null}
      </svg>

      {/* Labels (HTML for proper font rendering) */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          clipPath: `inset(0 ${WIDTH - revealX}px 0 0)`,
          fontFamily: brand.fontFamily,
        }}
      >
        <div
          style={{
            position: "absolute",
            left: xs[0] - 8,
            top: y + r + 22,
            fontSize: TYPE.label.size,
            letterSpacing: TYPE.label.tracking,
            color: progress > 0 ? brand.ink : brand.inkMuted,
            fontWeight: 500,
            whiteSpace: "nowrap",
          }}
        >
          {route.originLabel}
        </div>
        {route.stations.map((s, i) => {
          const x = xs[i + 1];
          const reached = progress >= i + 1 - 0.001;
          return (
            <div
              key={s.id}
              style={{
                position: "absolute",
                left: x - 140,
                width: 280,
                top: y + r + 18,
                textAlign: "center",
              }}
            >
              <div
                style={{
                  fontFamily: brand.monoFontFamily,
                  fontSize: 16,
                  letterSpacing: TYPE.eyebrow.tracking,
                  color: reached ? brand.accent : brand.inkSubtle,
                  fontWeight: 500,
                }}
              >
                {String(i + 1).padStart(2, "0")}
              </div>
              <div
                style={{
                  marginTop: 4,
                  fontSize: TYPE.h3.size,
                  letterSpacing: TYPE.h3.tracking,
                  lineHeight: TYPE.h3.lineHeight,
                  fontWeight: 500,
                  color: reached ? brand.ink : brand.inkMuted,
                  whiteSpace: "nowrap",
                }}
              >
                {s.name}
              </div>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

type BranchesProps = {
  brand: Brand;
  x: number;
  y: number;
  r: number;
  lineWidth: number;
  reached: boolean;
  labels: { label: string; chosen: boolean }[];
  font: string;
};

// A small junction above a station: the supported choices, with the one taken in accent.
const Branches: React.FC<BranchesProps> = ({ brand, x, y, r, lineWidth, reached, labels, font }) => {
  const n = labels.length;
  const topY = y - r - BRANCH_RISE;
  const gray = brand.line;
  return (
    <g>
      {labels.map((b, i) => {
        const bx = n === 1 ? x : x - BRANCH_SPREAD / 2 + (BRANCH_SPREAD * i) / (n - 1);
        const active = b.chosen && reached;
        const stroke = active ? brand.accent : gray;
        return (
          <g key={b.label}>
            <path
              d={`M ${x} ${y - r} L ${x} ${y - r - BRANCH_RISE / 2} L ${bx} ${topY + 8} L ${bx} ${topY}`}
              fill="none"
              stroke={stroke}
              strokeWidth={active ? lineWidth : lineWidth - 2}
              strokeLinejoin="miter"
            />
            <circle cx={bx} cy={topY} r={7} fill={active ? brand.accent : brand.paper} stroke={active ? brand.accent : brand.inkSubtle} strokeWidth={2} />
            <text
              x={bx}
              y={topY - 16}
              textAnchor="middle"
              fontFamily={font}
              fontSize={16}
              fontWeight={500}
              letterSpacing={TYPE.eyebrow.tracking}
              fill={active ? brand.ink : brand.inkSubtle}
            >
              {b.label}
            </text>
          </g>
        );
      })}
    </g>
  );
};
