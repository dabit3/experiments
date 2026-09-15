import React from "react";
import { FeatureLayout, FRAME_H, FRAME_W } from "../components/FeatureLayout";
import { Screenshot } from "../components/Screenshot";

export const FeatureMatrix: React.FC = () => (
  <FeatureLayout
    index="04 / 04"
    kicker="Every screen"
    lines={["iPhone and iPad. Dark mode. Both orientations.", "Screenshots compared pixel for pixel."]}
  >
    <Screenshot
      width={FRAME_W}
      height={FRAME_H}
      enterAt={8}
      layers={[
        { src: "screens/devin-web-17.png", aspect: 2978 / 1620, fadeOut: [112, 134] },
        { src: "screens/devin-web-19.png", aspect: 2982 / 1626, fadeIn: [112, 134] },
      ]}
      scale={{ from: 1.34, to: 1.0, over: [104, 210] }}
      focus={{ from: { x: 0.37, y: 0.62 }, to: { x: 0.4, y: 0.5 }, over: [104, 210] }}
    />
  </FeatureLayout>
);
