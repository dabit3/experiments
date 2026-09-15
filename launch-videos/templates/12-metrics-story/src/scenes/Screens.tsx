import React from "react";
import { useCurrentFrame } from "remotion";
import { count } from "../anim";
import { color } from "../tokens";
import { FeatureLayout } from "../components/FeatureLayout";
import { Numeral } from "../components/Text";

/**
 * Feature 4 (dark) — "6" screens tick up over the dark review panel's
 * grid of iPhone screenshots (web-17), then the iPad run (web-19).
 */
export const Screens: React.FC = () => {
  const frame = useCurrentFrame();
  const n = count(frame, 6, 44, 6);

  return (
    <FeatureLayout
      dark
      textColor={color.white}
      labelColor={color.gray400}
      stat={
        <Numeral size={150} color={color.white}>
          {n}
        </Numeral>
      }
      label="screens · iPhone + iPad · light + dark · pixel for pixel"
      narration="Devin checks every size, dark mode and orientation, pixel for pixel."
      shots={[
        {
          src: "screens/devin-web-17.png",
          from: 0,
          offsetY: [-458, -500],
          scale: [1.45, 1.45],
          origin: "36% 0%",
        },
        {
          src: "screens/devin-web-19.png",
          from: 118,
          fade: 22,
          offsetY: [-60, -110],
          scale: [1.02, 1.05],
          origin: "50% 50%",
        },
      ]}
    />
  );
};
