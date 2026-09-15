import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { count, tween } from "../anim";
import { color, fontSans, MARGIN, radius, sizes, track } from "../tokens";
import { Bar } from "../components/Bar";
import { SceneFade, Rise } from "../components/SceneFade";
import { Heading, MonoLabel, Numeral } from "../components/Text";

const W = 1920 - MARGIN * 2;
const BAR_W = W - 300;

const stats: { value: string; frames: [number, number]; label: string }[] = [
  { value: "0%", frames: [0, 0], label: "price increase — same as Linux cloud sessions" },
  { value: "1", frames: [0, 1], label: "the only coding agent with a Mac cloud agent" },
  { value: "3", frames: [0, 3], label: "platforms, one security model — Linux, Windows, macOS" },
];

/**
 * Outcome — comparison bars (20+ min CI vs. minutes) then three stat cards.
 */
export const Outcome: React.FC = () => {
  const frame = useCurrentFrame();
  const ciMin = count(frame, 14, 40, 20);
  const ciPlus = tween(frame, 52, 8);

  return (
    <SceneFade>
      <AbsoluteFill style={{ justifyContent: "center", paddingLeft: MARGIN, paddingRight: MARGIN }}>
      <div style={{ width: W }}>
        <Rise start={0} dur={20}>
          <Heading size={sizes.h2}>Minutes, not 20+ minute CI round-trips.</Heading>
        </Rise>

        <div style={{ marginTop: 72, display: "grid", gridTemplateColumns: "180px 1fr 120px", rowGap: 28, columnGap: 0, alignItems: "center" }}>
          <Rise start={10}>
            <MonoLabel>CI round-trip</MonoLabel>
          </Rise>
          <Bar fraction={1} start={14} dur={44} width={BAR_W} height={28} fill={color.gray300} />
          <Rise start={12} style={{ justifySelf: "end" }}>
            <Numeral size={32} color={color.gray500} style={{ display: "inline-flex" }}>
              {ciMin}
              <span style={{ opacity: ciPlus }}>+</span>
              <span style={{ fontWeight: 400, marginLeft: 8 }}>min</span>
            </Numeral>
          </Rise>

          <Rise start={36}>
            <MonoLabel color={color.accent}>Devin on Mac</MonoLabel>
          </Rise>
          <Bar fraction={0.18} start={40} dur={34} width={BAR_W} height={28} fill={color.accent} />
          <Rise start={38} style={{ justifySelf: "end" }}>
            <Numeral size={32} color={color.accent} style={{ fontWeight: 400 }}>
              minutes
            </Numeral>
          </Rise>
        </div>

        <div style={{ marginTop: 88, display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 24 }}>
          {stats.map((s, i) => {
            const start = 70 + i * 10;
            const n = count(frame, start + 6, 30, s.frames[1], s.frames[0]);
            return (
              <Rise key={s.label} start={start} dur={20}>
                <div
                  style={{
                    backgroundColor: color.white,
                    border: `1px solid ${color.border}`,
                    borderRadius: radius.lg,
                    padding: "44px 44px 40px",
                    height: 330,
                    boxSizing: "border-box",
                    display: "flex",
                    flexDirection: "column",
                    justifyContent: "space-between",
                  }}
                >
                  <Numeral size={120} color={i === 1 ? color.accent : color.ink}>
                    {s.value === "0%" ? `${n}%` : n}
                  </Numeral>
                  <div
                    style={{
                      fontFamily: fontSans,
                      fontWeight: 400,
                      fontSize: sizes.body,
                      lineHeight: 1.3,
                      letterSpacing: track.body,
                      color: color.gray700,
                    }}
                  >
                    {s.label}
                  </div>
                </div>
              </Rise>
            );
          })}
        </div>
      </div>
      </AbsoluteFill>
    </SceneFade>
  );
};
