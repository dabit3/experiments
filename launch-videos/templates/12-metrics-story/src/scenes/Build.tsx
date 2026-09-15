import React from "react";
import { useCurrentFrame } from "remotion";
import { count } from "../anim";
import { color } from "../tokens";
import { FeatureLayout, FIGURE } from "../components/FeatureLayout";
import { Cursor } from "../components/Cursor";
import { Numeral } from "../components/Text";

const IMG_H = FIGURE.width / 1.842; // screenshots are ~1.84:1

/**
 * Feature 1 — one prompt, macOS picked, the app builds and runs.
 * web-4 (platform picker; cursor clicks macOS) → web-13 (session executing).
 */
export const Build: React.FC = () => {
  const frame = useCurrentFrame();
  const n = count(frame, 6, 20, 1);

  return (
    <FeatureLayout
      stat={
        <Numeral size={150} color={color.accent}>
          {n}
        </Numeral>
      }
      label="prompt · macOS VM · Xcode + iOS Simulator"
      narration="Devin builds and runs the app in Xcode and the iOS Simulator, inside the session."
      shots={[
        {
          src: "screens/devin-web-4.png",
          from: 0,
          offsetY: [-150, -230],
          scale: [1, 1.04],
          origin: "30% 70%",
          overlay: (
            <Cursor
              width={FIGURE.width}
              height={IMG_H}
              from={[0.46, 0.5]}
              to={[0.262, 0.732]}
              start={24}
              dur={40}
              clickAt={70}
              appear={14}
            />
          ),
        },
        {
          src: "screens/devin-web-13.png",
          from: 100,
          fade: 20,
          offsetY: [0, -70],
          scale: [1, 1.03],
          origin: "50% 100%",
        },
      ]}
    />
  );
};
