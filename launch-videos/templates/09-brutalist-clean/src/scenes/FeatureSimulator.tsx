import React from "react";
import { FeatureLayout, FRAME_H, FRAME_W } from "../components/FeatureLayout";
import { Screenshot } from "../components/Screenshot";

const WEB = 2990 / 1624;

export const FeatureSimulator: React.FC = () => (
  <FeatureLayout
    index="02 / 04"
    kicker="Live Simulator"
    lines={["A live iPhone Simulator in the session.", "Devin taps, types and scrolls. So can you."]}
  >
    <Screenshot
      width={FRAME_W}
      height={FRAME_H}
      enterAt={8}
      layers={[
        { src: "screens/devin-web-11.png", aspect: WEB, fadeOut: [70, 92] },
        { src: "screens/devin-web-10.png", aspect: WEB, fadeIn: [70, 92] },
      ]}
      scale={{ from: 1, to: 1.08, over: [0, 225] }}
      focus={{ from: { x: 0.5, y: 0.5 }, to: { x: 0.42, y: 0.5 }, over: [0, 225] }}
    />
  </FeatureLayout>
);
