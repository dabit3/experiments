import React from "react";
import { Cursor } from "../components/Cursor";
import { FeatureLayout, FRAME_H, FRAME_W } from "../components/FeatureLayout";
import { Screenshot } from "../components/Screenshot";

const WEB = 2990 / 1624;
const CHIP = { x: 0.252, y: 0.6 }; // "macOS" platform chip in devin-web-1
const CLICK = 58;

export const FeaturePlatform: React.FC = () => (
  <FeatureLayout
    index="01 / 04"
    kicker="Build & run"
    lines={["Pick macOS. Devin builds and runs", "your app in the iOS Simulator."]}
  >
    <Screenshot
      width={FRAME_W}
      height={FRAME_H}
      enterAt={8}
      layers={[
        { src: "screens/devin-web-1.png", aspect: WEB, fadeOut: [CLICK + 4, CLICK + 18] },
        { src: "screens/devin-web-4.png", aspect: 2988 / 1622, fadeIn: [CLICK + 4, CLICK + 18] },
      ]}
      scale={{ from: 1, to: 1.06, over: [0, 210] }}
      focus={{ from: { x: 0.5, y: 0.52 }, to: { x: 0.5, y: 0.52 }, over: [0, 1] }}
    >
      {(map) => {
        const a = map({ x: 0.58, y: 0.34 });
        const b = map(CHIP);
        return (
          <Cursor
            appearAt={18}
            path={[
              { ...a, at: 18 },
              { ...b, at: CLICK - 4 },
            ]}
            clicks={[CLICK]}
          />
        );
      }}
    </Screenshot>
  </FeatureLayout>
);
