import React from "react";
import { AbsoluteFill } from "remotion";
import { Dimension, Leader } from "../components/Annotations";
import { DrawPath, DrawRect, useDraw } from "../components/Draw";
import { FIG } from "../components/Shell";
import { Narration } from "../components/Text";
import { HEIGHT, WIDTH, bp } from "../theme";

/** Ghosted phone outline + the 20-minute CI dimension: the "prior art" drawing. */
export const Context: React.FC = () => {
  const phoneW = 250;
  const phoneH = 520;
  const px = FIG.x + FIG.w / 2 - phoneW / 2;
  const py = FIG.y + (FIG.h - phoneH) / 2;
  const outline = useDraw(2, 18);
  const screen = useDraw(12, 14);
  const dim = useDraw(34);
  const leader = useDraw(92);
  const island = useDraw(20, 8);
  return (
    <AbsoluteFill>
      <svg width={WIDTH} height={HEIGHT} style={{ position: "absolute", inset: 0 }}>
        <DrawRect x={px} y={py} w={phoneW} h={phoneH} r={44} progress={outline} width={1.5} />
        <DrawRect x={px + 14} y={py + 14} w={phoneW - 28} h={phoneH - 28} r={32} progress={screen} width={1} stroke={bp.lineSoft} />
        <DrawPath d={`M${px + phoneW / 2 - 34},${py + 34} H${px + phoneW / 2 + 34}`} progress={island} width={10} stroke={bp.lineSoft} />
        {/* diagonal hatch = untested surface */}
        <g opacity={Math.max(0, (screen - 0.6) * 2.5) * 0.7}>
          <defs>
            <clipPath id="ctx-screen">
              <rect x={px + 14} y={py + 14} width={phoneW - 28} height={phoneH - 28} rx={32} />
            </clipPath>
          </defs>
          <g clipPath="url(#ctx-screen)" stroke={bp.lineSoft} strokeWidth={1}>
            {Array.from({ length: 30 }).map((_, i) => {
              const off = i * 28 - 200;
              return <line key={i} x1={px + off} y1={py + phoneH} x2={px + off + phoneH} y2={py} />;
            })}
          </g>
        </g>
        <Dimension
          x1={px - 160}
          y1={py + phoneH + 48}
          x2={px + phoneW + 160}
          y2={py + phoneH + 48}
          label="20+ min · CI round-trip"
          progress={dim}
          labelOffset={30}
        />
        <Leader
          tx={px + phoneW}
          ty={py + 150}
          lx={px + phoneW + 140}
          ly={py + 110}
          side="right"
          label="Unreached by agents"
          sub="manual QA only"
          progress={leader}
        />
      </svg>
      <Narration
        size={56}
        maxWidth={1160}
        lines={[
          { text: "Before: QA by hand, or a 20+ minute CI wait.", at: 6 },
          { text: "No agent could tap through an iPhone app.", at: 96 },
        ]}
      />
    </AbsoluteFill>
  );
};
