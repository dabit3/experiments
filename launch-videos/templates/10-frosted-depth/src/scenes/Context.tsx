import React from "react";
import { useCurrentFrame, useVideoConfig } from "remotion";
import { TRANSITION } from "../scenes";
import { SceneFrame } from "../components/SceneFrame";
import { Glass } from "../components/Glass";
import { Narration } from "../components/Narration";
import { color, fontMono, type } from "../tokens";
import { enter, exit, linear } from "../lib/motion";

const SWITCH = 96;

const pad = (n: number) => String(n).padStart(2, "0");

export const Context: React.FC<{ sceneFrom: number }> = ({ sceneFrom }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const pill = Math.min(enter(frame, 14, 24), exit(frame, SWITCH - 6, 10));
  const elapsed = Math.round(linear(frame, 20, SWITCH - 6) * (21 * 60 + 48));
  const mm = Math.floor(elapsed / 60);
  const ss = elapsed % 60;
  const W = 300;
  const H = 64;
  return (
    <SceneFrame>
      <Narration
        x={160}
        y={400}
        width={1600}
        align="center"
        size={type.sizes1080p.h2}
        lines={[
          { text: "Before, iOS teams QA'd the app by hand — or waited 20+ minutes for CI.", from: 4, until: SWITCH - 6 },
          { text: "No coding agent could build, run and tap through an iPhone app on its own.", from: SWITCH - 2, until: durationInFrames - TRANSITION - 8 },
        ]}
      />
      <Glass
        x={(1920 - W) / 2}
        y={600}
        width={W}
        height={H}
        depth={0.85}
        sceneFrom={sceneFrom}
        opacity={pill}
        transform={`translateY(${(1 - pill) * 20}px)`}
        style={{ borderRadius: 999 }}
      >
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 18,
            fontFamily: fontMono,
            fontSize: type.sizes1080p.label,
            letterSpacing: type.tracking.caps,
            color: color.gray400,
            textTransform: "uppercase",
          }}
        >
          <span>CI run</span>
          <span style={{ color: color.offWhite, fontWeight: 500, fontVariantNumeric: "tabular-nums" }}>
            {pad(mm)}:{pad(ss)}
          </span>
        </div>
      </Glass>
    </SceneFrame>
  );
};
