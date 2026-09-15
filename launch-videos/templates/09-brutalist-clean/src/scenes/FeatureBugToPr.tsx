import React from "react";
import { FeatureLayout, FRAME_H, FRAME_W } from "../components/FeatureLayout";
import { Screenshot } from "../components/Screenshot";

export const FeatureBugToPr: React.FC = () => (
  <FeatureLayout
    index="03 / 04"
    kicker="Bug to PR"
    lines={["Reproduces the bug. Fixes it.", "Re-runs the UI tests. Opens the PR."]}
  >
    <Screenshot
      width={FRAME_W}
      height={FRAME_H}
      enterAt={8}
      layers={[{ src: "screens/devin-web-9.png", aspect: 2988 / 1628 }]}
      scale={{ from: 1.15, to: 1.15, over: [0, 1] }}
      focus={{ from: { x: 0.22, y: 0.3 }, to: { x: 0.74, y: 0.3 }, over: [40, 190] }}
    />
  </FeatureLayout>
);
