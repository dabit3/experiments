import React from "react";
import { useCurrentFrame } from "remotion";
import { Scene } from "../components/Scene";
import { Body, Headline, Label } from "../components/Text";
import { fadeIn, rise } from "../components/motion";
import { MARGIN, color, ms } from "../tokens";

const stats = [
  { label: "Mac cloud agent", value: "The only coding agent with one." },
  { label: "Security", value: "Same as Linux and Windows VMs." },
  { label: "Price", value: "Same as Linux cloud sessions." },
];

export const Outcome: React.FC = () => {
  const frame = useCurrentFrame();
  const headAt = 6;
  const statsAt = ms(1400);
  const stagger = ms(260);
  return (
    <Scene>
      <div style={{ position: "absolute", left: MARGIN, right: MARGIN, top: 250 }}>
        <Headline
          size="h1"
          style={{
            opacity: fadeIn(frame, headAt),
            transform: `translateY(${rise(frame, headAt, undefined, 32)}px)`,
          }}
        >
          Minutes, not
          <br />
          20-minute CI round-trips.
        </Headline>
        <div
          style={{
            display: "flex",
            gap: 64,
            marginTop: 120,
            borderTop: `1px solid ${color.border}`,
            paddingTop: 40,
          }}
        >
          {stats.map((s, i) => {
            const at = statsAt + i * stagger;
            return (
              <div
                key={s.label}
                style={{
                  flex: 1,
                  opacity: fadeIn(frame, at),
                  transform: `translateY(${rise(frame, at, undefined, 16)}px)`,
                }}
              >
                <Label style={{ marginBottom: 20 }}>{s.label}</Label>
                <Body style={{ color: color.ink }}>{s.value}</Body>
              </div>
            );
          })}
        </div>
      </div>
    </Scene>
  );
};
