import React from "react";
import { useCurrentFrame } from "remotion";
import { clock, easeInOut, tween } from "../anim";
import { color } from "../tokens";
import { FeatureLayout } from "../components/FeatureLayout";
import { Numeral } from "../components/Text";

/**
 * Feature 2 — a live iPhone Simulator tab. The player timecode ticks
 * 0:00 → 0:11 while web-11 (0:02) cross-fades to web-10 (0:11).
 */
export const Live: React.FC = () => {
  const frame = useCurrentFrame();
  const t = tween(frame, 6, 120, easeInOut, 0, 11);

  return (
    <FeatureLayout
      stat={
        <Numeral size={150} style={{ display: "inline-flex", alignItems: "baseline" }}>
          {clock(t)}
          <span style={{ fontSize: 56, color: color.gray400, marginLeft: 16 }}>/ 2:40</span>
        </Numeral>
      }
      label="live iPhone Simulator · iPhone 17 Pro · iOS 26.5"
      narration="Devin taps, types and scrolls like a person. You can watch — and tap — too."
      shots={[
        {
          src: "screens/devin-web-11.png",
          from: 0,
          offsetY: [-66, -96],
          scale: [1, 1.02],
          origin: "50% 60%",
        },
        {
          src: "screens/devin-web-10.png",
          from: 92,
          fade: 22,
          offsetY: [-130, -180],
          scale: [1.02, 1.05],
          origin: "50% 70%",
        },
      ]}
    />
  );
};
