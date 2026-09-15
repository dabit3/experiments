import React from "react";
import { useCurrentFrame } from "remotion";
import { SceneFrame } from "../components/SceneFrame";
import { Glass } from "../components/Glass";
import { Narration } from "../components/Narration";
import { color, fontMono, fontSans, type } from "../tokens";
import { enter } from "../lib/motion";

const cards = [
  { label: "Speed", text: "Minutes, not 20+ minute CI round-trips." },
  { label: "Platform", text: "The only coding agent with a Mac cloud agent." },
  { label: "Cost & security", text: "Same price and security as Linux sessions." },
];

const W = 500;
const H = 300;
const GAP = 24;
const X0 = (1920 - (W * 3 + GAP * 2)) / 2;
const Y = 300;

export const Outcome: React.FC<{ sceneFrom: number }> = ({ sceneFrom }) => {
  const frame = useCurrentFrame();
  return (
    <SceneFrame>
      {cards.map((c, i) => {
        const a = enter(frame, 4 + i * 12, 30);
        return (
          <Glass
            key={c.label}
            x={X0 + i * (W + GAP)}
            y={Y}
            width={W}
            height={H}
            depth={1}
            sceneFrom={sceneFrom}
            opacity={a}
            transform={`translateY(${(1 - a) * 36}px)`}
            padding={36}
          >
            <div
              style={{
                fontFamily: fontMono,
                fontSize: type.sizes1080p.label,
                letterSpacing: type.tracking.caps,
                textTransform: "uppercase",
                color: color.gray400,
              }}
            >
              {c.label}
            </div>
            <div
              style={{
                position: "absolute",
                left: 36,
                right: 36,
                bottom: 36,
                fontFamily: fontSans,
                fontWeight: type.weights.medium,
                fontSize: 34,
                lineHeight: type.leading.heading,
                letterSpacing: type.tracking.heading,
                color: color.offWhite,
              }}
            >
              {c.text}
            </div>
          </Glass>
        );
      })}
      <Narration
        x={120}
        y={644}
        width={1680}
        align="center"
        size={type.sizes1080p.body}
        tone="secondary"
        lines={[{ text: "macOS child sessions, Declarative Repo Setup, the Devin API and automations all work on Mac.", from: 58 }]}
      />
    </SceneFrame>
  );
};
