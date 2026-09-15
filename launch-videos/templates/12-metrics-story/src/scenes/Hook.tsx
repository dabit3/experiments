import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { count, tween, easeOut } from "../anim";
import { color } from "../tokens";
import { SceneFade, Rise } from "../components/SceneFade";
import { Heading, MonoLabel, Numeral } from "../components/Text";

const platforms = ["Ubuntu", "Windows", "macOS"];

/** Hook: a counter ticks 1 → 2 → 3 platforms; the third lights up in accent. */
export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const n = Math.max(1, count(frame, 4, 34, 3, 1));
  const isMac = n === 3;

  return (
    <SceneFade>
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          flexDirection: "column",
          gap: 0,
        }}
      >
        <Rise start={0} dur={20}>
          <Numeral size={300} color={isMac ? color.accent : color.ink}>
            {n}
          </Numeral>
        </Rise>
        <div style={{ display: "flex", gap: 28, marginTop: 8, height: 26 }}>
          {platforms.map((p, i) => {
            const on = i < n;
            const o = tween(frame, 4 + i * 12, 10, easeOut);
            return (
              <MonoLabel
                key={p}
                color={on && i === 2 ? color.accent : color.gray500}
                style={{ opacity: on ? o : 0 }}
              >
                {p}
              </MonoLabel>
            );
          })}
        </div>
        <Rise start={46} dur={20} style={{ marginTop: 64 }}>
          <Heading style={{ textAlign: "center" }}>Devin now runs on Mac.</Heading>
        </Rise>
      </AbsoluteFill>
    </SceneFade>
  );
};
