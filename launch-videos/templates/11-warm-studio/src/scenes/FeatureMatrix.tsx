import React from "react";
import { useCurrentFrame, useVideoConfig } from "remotion";
import { FIGURE_WIDTH, FeatureLayout } from "../components/FeatureLayout";
import { ASPECT, Figure } from "../components/Figure";
import { crossfade, drift } from "../components/motion";
import { ms } from "../tokens";

export const FeatureMatrix: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const swapAt = ms(3000);
  return (
    <FeatureLayout
      label="Every screen, every size"
      beats={[
        {
          at: 4,
          text: (
            <>
              It checks iPhone and iPad sizes,
              <br />
              dark mode and orientations.
            </>
          ),
        },
        { at: ms(3600), text: "Every screenshot compared pixel for pixel." },
      ]}
    >
      <Figure
        width={FIGURE_WIDTH}
        aspect={ASPECT.ipad}
        y={-150}
        scale={drift(frame, durationInFrames, 1.06, 1)}
        origin="50% 40%"
        layers={[
          { src: "screens/devin-web-19.png" },
          { src: "screens/devin-web-17.png", opacity: crossfade(frame, swapAt) },
        ]}
      />
    </FeatureLayout>
  );
};
