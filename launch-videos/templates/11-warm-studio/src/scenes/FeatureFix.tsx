import React from "react";
import { useCurrentFrame, useVideoConfig } from "remotion";
import { FIGURE_WIDTH, FeatureLayout } from "../components/FeatureLayout";
import { ASPECT, Figure } from "../components/Figure";
import { crossfade, drift } from "../components/motion";
import { ms } from "../tokens";

export const FeatureFix: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const swapAt = ms(3200);
  const toPr = crossfade(frame, swapAt);
  return (
    <FeatureLayout
      index="03"
      label="Reproduce, fix, ship"
      beats={[
        { at: 4, text: "It reproduces the bug and fixes it." },
        {
          at: ms(3600),
          text: (
            <>
              Re-runs the UI tests.
              <br />
              Opens the pull request.
            </>
          ),
        },
      ]}
    >
      <div style={{ position: "relative" }}>
        {/* Desktop window screenshot ships with its own shadow/padding; crop it out. */}
        <Figure
          width={FIGURE_WIDTH}
          aspect={ASPECT.desktopWide}
          scale={1.1}
          origin="50% 47%"
          y={drift(frame, durationInFrames, -230, -290)}
          layers={[{ src: "screens/devin-desktop-7.png" }]}
        />
        <Figure
          width={FIGURE_WIDTH}
          aspect={ASPECT.web}
          y={-120}
          layers={[{ src: "screens/devin-web-9.png" }]}
          style={{ position: "absolute", top: 0, left: 0, opacity: toPr }}
        />
      </div>
    </FeatureLayout>
  );
};
