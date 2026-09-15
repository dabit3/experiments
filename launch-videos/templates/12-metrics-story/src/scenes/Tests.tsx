import React from "react";
import { useCurrentFrame } from "remotion";
import { count } from "../anim";
import { color, fontSans, track } from "../tokens";
import { FeatureLayout } from "../components/FeatureLayout";
import { SegmentBar } from "../components/Bar";
import { Numeral } from "../components/Text";

const results = [
  { value: 12, label: "passed", color: color.success },
  { value: 3, label: "failed", color: color.danger },
  { value: 2, label: "untested", color: color.warning },
];

/**
 * Feature 3 — 12 / 3 / 2 test results tick up with a segment bar,
 * over the session view with the PR open (web-9).
 */
export const Tests: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <FeatureLayout
      stat={
        <div>
          <div style={{ display: "flex", gap: 56, alignItems: "baseline" }}>
            {results.map((r, i) => (
              <div key={r.label} style={{ display: "flex", alignItems: "baseline", gap: 14 }}>
                <Numeral size={150} color={i === 0 ? color.ink : color.gray400}>
                  {count(frame, 6 + i * 6, 40, r.value)}
                </Numeral>
                <span
                  style={{
                    fontFamily: fontSans,
                    fontWeight: 500,
                    fontSize: 32,
                    letterSpacing: track.body,
                    color: r.color,
                  }}
                >
                  {r.label}
                </span>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 22 }}>
            <SegmentBar segments={results} start={8} dur={50} width={760} height={10} />
          </div>
        </div>
      }
      label="UI tests re-run in the Simulator · PR #161 open"
      narration="Devin reproduces the bug, fixes it, re-runs the UI tests and opens a PR."
      shots={[
        {
          src: "screens/devin-web-9.png",
          from: 0,
          offsetY: [0, -20],
          scale: [1, 1.07],
          origin: "72% 0%",
        },
      ]}
    />
  );
};
