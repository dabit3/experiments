import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { clock, count, easeIn, easeInOut, tween } from "../anim";
import { color } from "../tokens";
import { SceneFade, Rise } from "../components/SceneFade";
import { MonoLabel, Narration, Numeral } from "../components/Text";

const BEAT = 92;

/**
 * Problem, two beats anchored by numbers:
 *   A. a CI timer runs to 20:00+  B. "0" coding agents could run an iPhone app.
 */
export const Problem: React.FC = () => {
  const frame = useCurrentFrame();

  // Beat A: 00:00 → 20:00 over ~2s, then "+" lands.
  const seconds = count(frame, 6, 62, 20 * 60, 0, easeInOut);
  const plus = tween(frame, 70, 10);
  const aOut = tween(frame, BEAT - 12, 12, easeIn, 1, 0);

  // Beat B
  const b = frame - BEAT;
  const bIn = tween(b, 0, 14);

  return (
    <SceneFade>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity: aOut }}>
        <Rise start={0} dur={20} style={{ textAlign: "center" }}>
          <Numeral size={240} style={{ display: "inline-flex", alignItems: "baseline" }}>
            {clock(seconds)}
            <span style={{ opacity: plus, color: color.gray400 }}>+</span>
          </Numeral>
        </Rise>
        <Rise start={8} dur={18} style={{ marginTop: 20 }}>
          <MonoLabel>minutes per CI round-trip</MonoLabel>
        </Rise>
        <Rise start={22} dur={20} style={{ marginTop: 72 }}>
          <Narration style={{ textAlign: "center" }} maxWidth={1000}>
            iOS teams QA&apos;d by hand, or waited on CI to find out.
          </Narration>
        </Rise>
      </AbsoluteFill>

      {b >= 0 && (
        <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity: bIn }}>
          <Rise start={BEAT} dur={20}>
            <Numeral size={300}>0</Numeral>
          </Rise>
          <Rise start={BEAT + 8} dur={18} style={{ marginTop: 8 }}>
            <MonoLabel>coding agents that could run an iPhone app</MonoLabel>
          </Rise>
          <Rise start={BEAT + 22} dur={20} style={{ marginTop: 72 }}>
            <Narration style={{ textAlign: "center" }} maxWidth={1000}>
              None could build, run and tap through an app on its own.
            </Narration>
          </Rise>
        </AbsoluteFill>
      )}
    </SceneFade>
  );
};
