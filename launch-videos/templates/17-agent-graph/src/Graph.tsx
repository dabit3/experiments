import React from "react";
import { AbsoluteFill } from "remotion";
import { ALL_DONE, HEIGHT, SCENES, STEPS, STEP_ACTIVATION, StepIndex, WIDTH } from "./scenes";
import { color, easeIn, easeInOut, easeOut, font, lerp, ramp, useFrame } from "./theme";

type Pt = { x: number; y: number };

/** Free-form network layout used for the plan and outcome scenes. */
const HERO: Pt[] = [
  { x: 260, y: 620 },
  { x: 500, y: 480 },
  { x: 760, y: 690 },
  { x: 1000, y: 510 },
  { x: 1230, y: 710 },
  { x: 1460, y: 530 },
  { x: 1700, y: 650 },
];

/** Flattened rail along the bottom, used while a step's screen is on display. */
export const RAIL_Y = 940;
export const railX = (i: number) => 260 + (i * 1400) / (STEPS.length - 1);
const RAIL: Pt[] = STEPS.map((_, i) => ({ x: railX(i), y: RAIL_Y }));

const CHAIN = STEPS.slice(0, -1).map((_, i) => [i, i + 1] as const);
/** Secondary dependency edges (drawn as arcs, hero layout only). */
const ARCS: ReadonlyArray<readonly [number, number]> = [
  [1, 5], // build artifacts feed the UI tests
  [3, 5], // repro steps become test cases
];

/** -1 = left of node, 0 = below, 1 = right (hero layout only). */
const HERO_LABEL_SIDE: ReadonlyArray<-1 | 0 | 1> = [0, -1, 0, -1, 0, 1, 0];

type NodeState = "idle" | "active" | "done";

const stateAt = (i: StepIndex, frame: number): NodeState => {
  const start = STEP_ACTIVATION[i];
  const end = i === STEPS.length - 1 ? ALL_DONE : STEP_ACTIVATION[(i + 1) as StepIndex];
  if (frame < start) return "idle";
  if (frame < end) return "active";
  return "done";
};

/** How far the graph has moved from hero (0) to rail (1). */
export const layoutT = (frame: number) => {
  const toRail = ramp(frame, SCENES.build.from - 12, 34, easeInOut);
  const toHero = ramp(frame, SCENES.outcome.from - 4, 40, easeInOut);
  return toRail * (1 - toHero);
};

/** Container transform for the outcome scene (graph shrinks into the lower half). */
const outcomeT = (frame: number) => ramp(frame, SCENES.outcome.from - 4, 40, easeInOut);

const CHECK = "M -6 0.5 L -2 4.5 L 6 -4";

export const Graph: React.FC = () => {
  const frame = useFrame();
  const t = layoutT(frame);
  const ot = outcomeT(frame);

  const pts = HERO.map((h, i) => ({ x: lerp(h.x, RAIL[i].x, t), y: lerp(h.y, RAIL[i].y, t) }));
  const nodeR = lerp(20, 9, t);
  const labelGap = lerp(52, 40, t);
  const labelSize = lerp(24, 20, t);

  const scale = lerp(1, 0.78, ot);
  const shiftY = lerp(0, 150, ot);

  const reveal = SCENES.plan.from + 6;
  const fadeOut = 1 - ramp(frame, SCENES.end.from - 14, 14, easeIn);

  const arcOpacity = (1 - t) * 0.9;

  return (
    <AbsoluteFill style={{ opacity: fadeOut }}>
      <svg
        width={WIDTH}
        height={HEIGHT}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        style={{
          transform: `translateY(${shiftY}px) scale(${scale})`,
          transformOrigin: `${WIDTH / 2}px ${HEIGHT / 2}px`,
        }}
      >
        <defs>
          <filter id="glow" x="-100%" y="-100%" width="300%" height="300%">
            <feGaussianBlur stdDeviation="10" />
          </filter>
        </defs>

        {/* dependency arcs */}
        {ARCS.map(([a, b], k) => {
          const pa = pts[a];
          const pb = pts[b];
          const mx = (pa.x + pb.x) / 2;
          const my = Math.min(pa.y, pb.y) - 150 - k * 30;
          const d = `M ${pa.x} ${pa.y} Q ${mx} ${my} ${pb.x} ${pb.y}`;
          const draw = ramp(frame, reveal + 60 + k * 10, 36, easeOut);
          const lit = stateAt(b as StepIndex, frame) !== "idle";
          return (
            <path
              key={`arc-${k}`}
              d={d}
              fill="none"
              stroke={lit ? color.accent : color.gray500}
              strokeOpacity={arcOpacity * (lit ? 1 : 0.45)}
              strokeWidth={1.5}
              strokeDasharray={lit ? undefined : "6 8"}
              style={{ clipPath: `inset(0 ${(1 - draw) * 100}% 0 0)` }}
            />
          );
        })}

        {/* chain edges */}
        {CHAIN.map(([a, b], k) => {
          const pa = pts[a];
          const pb = pts[b];
          const dx = pb.x - pa.x;
          const dy = pb.y - pa.y;
          const len = Math.hypot(dx, dy);
          const ux = dx / len;
          const uy = dy / len;
          const pad = nodeR + 8;
          const x1 = pa.x + ux * pad;
          const y1 = pa.y + uy * pad;
          const L = len - pad * 2;

          const draw = ramp(frame, reveal + 10 + k * 9, 28, easeOut);
          // light travels a→b just before b activates
          const travel = ramp(frame, STEP_ACTIVATION[b as StepIndex] - 20, 20, easeInOut);
          const px = x1 + ux * L * travel;
          const py = y1 + uy * L * travel;
          const pulseOn = travel > 0 && travel < 1;

          return (
            <g key={`edge-${k}`}>
              <line
                x1={x1}
                y1={y1}
                x2={x1 + ux * L * draw}
                y2={y1 + uy * L * draw}
                stroke={color.gray500}
                strokeOpacity={0.45}
                strokeWidth={1.5}
              />
              {travel > 0 && (
                <line
                  x1={x1}
                  y1={y1}
                  x2={x1 + ux * L * travel}
                  y2={y1 + uy * L * travel}
                  stroke={color.accent}
                  strokeWidth={2}
                />
              )}
              {pulseOn && (
                <>
                  <circle cx={px} cy={py} r={9} fill={color.accent} filter="url(#glow)" />
                  <circle cx={px} cy={py} r={3.5} fill={color.accentSoft} />
                </>
              )}
            </g>
          );
        })}

        {/* nodes */}
        {pts.map((p, i) => {
          const s = stateAt(i as StepIndex, frame);
          const appear = ramp(frame, reveal + i * 8, 20, easeOut);
          const r = nodeR * lerp(0.4, 1, appear);
          const breathe = 0.55 + 0.45 * Math.sin(frame / 9);
          const lightUp = ramp(frame, STEP_ACTIVATION[i as StepIndex], 10, easeOut);
          // Hero layout: labels sit beside the nodes that carry arcs so nothing crosses text.
          const side = HERO_LABEL_SIDE[i];
          const textW = STEPS[i].label.length * labelSize * 0.62;
          const heroDx = side === 0 ? 0 : side * (nodeR + 16 + textW / 2);
          const heroDy = side === 0 ? labelGap + labelSize * 0.85 : labelSize * 0.35;
          const lx = p.x + lerp(heroDx, 0, t);
          const ly = p.y + lerp(heroDy, labelGap + labelSize * 0.85, t);
          const fill = s === "idle" ? color.darkSurface2 : color.accent;
          const labelColor = s === "idle" ? color.gray500 : s === "active" ? color.white : color.gray300;
          return (
            <g key={STEPS[i].id} opacity={appear}>
              {s === "active" && (
                <circle
                  cx={p.x}
                  cy={p.y}
                  r={r * 2.3}
                  fill={color.accent}
                  opacity={breathe * 0.55 * lightUp}
                  filter="url(#glow)"
                />
              )}
              <circle
                cx={p.x}
                cy={p.y}
                r={r}
                fill={fill}
                stroke={s === "idle" ? color.gray500 : color.accentSoft}
                strokeOpacity={s === "idle" ? 0.7 : 0.9}
                strokeWidth={1.5}
              />
              {s === "done" && (
                <path
                  d={CHECK}
                  transform={`translate(${p.x} ${p.y}) scale(${r / 20})`}
                  fill="none"
                  stroke={color.white}
                  strokeWidth={2.4}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              )}
              <text
                x={lx}
                y={ly}
                textAnchor="middle"
                fill={labelColor}
                fontFamily={font.mono}
                fontSize={labelSize}
                fontWeight={500}
                letterSpacing="0.04em"
                style={{ textTransform: "uppercase" }}
              >
                {STEPS[i].label.toUpperCase()}
              </text>
            </g>
          );
        })}
      </svg>
    </AbsoluteFill>
  );
};
