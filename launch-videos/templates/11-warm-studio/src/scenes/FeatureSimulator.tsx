import React from "react";
import { useCurrentFrame, useVideoConfig } from "remotion";
import { FIGURE_WIDTH, FeatureLayout } from "../components/FeatureLayout";
import { ASPECT, Figure } from "../components/Figure";
import { crossfade, drift } from "../components/motion";
import { ms } from "../tokens";

export const FeatureSimulator: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const swapAt = ms(3000);
  return (
    <FeatureLayout
      label="Live iPhone Simulator"
      beats={[
        {
          at: 4,
          text: (
            <>
              Watch Devin tap, type and scroll
              <br />
              in a live iPhone Simulator.
            </>
          ),
        },
        { at: ms(3600), text: "You can jump in and tap too." },
      ]}
    >
      <Figure
        width={FIGURE_WIDTH}
        aspect={ASPECT.web}
        y={-110}
        scale={drift(frame, durationInFrames, 1, 1.08)}
        origin="33% 50%"
        layers={[
          { src: "screens/devin-web-11.png" },
          { src: "screens/devin-web-10.png", opacity: crossfade(frame, swapAt) },
        ]}
      />
    </FeatureLayout>
  );
};
