import React from "react";
import { AbsoluteFill } from "remotion";
import { Cursor } from "../components/Cursor";
import { Figure } from "../components/Figure";
import { Narration } from "../components/Narration";
import { layout } from "../theme";

const still = { scale: 1, x: 50, y: 50 };

/** Problem / context: how iOS QA used to work, while the developer picks macOS. */
export const Context: React.FC<{ duration: number }> = ({ duration }) => (
  <AbsoluteFill>
    <Narration
      top={layout.contentTop + 40}
      lines={[
        { text: "iOS teams QA'd apps by hand.", at: 10, until: 128 },
        { text: "Or waited 20+ minutes for CI.", at: 58, until: 128 },
        { text: "No coding agent could tap through an iPhone app.", at: 136 },
      ]}
    />
    <Figure
      sceneDuration={duration}
      shots={[
        { src: "screens/devin-web-1.png", from: 0, until: 118, cam: { from: still, to: still } },
        { src: "screens/devin-web-4.png", from: 118, cam: { from: still, to: still } },
      ]}
    >
      <Cursor
        stops={[
          { frame: 20, x: 62, y: 78 },
          { frame: 60, x: 41, y: 46 },
          { frame: 100, x: 25.4, y: 60.4, click: true },
        ]}
      />
    </Figure>
  </AbsoluteFill>
);
