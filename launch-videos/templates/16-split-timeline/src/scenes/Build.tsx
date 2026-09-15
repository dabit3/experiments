import React from "react";
import { AbsoluteFill } from "remotion";
import { Figure } from "../components/Figure";
import { Narration } from "../components/Narration";
import { PromptCard } from "../components/PromptCard";
import { layout } from "../theme";

/** Feature 1: typed prompt → Devin builds and runs the app in the iOS Simulator. */
export const Build: React.FC<{ duration: number }> = ({ duration }) => (
  <AbsoluteFill>
    <PromptCard
      variant="typed"
      at={4}
      typeDuration={64}
      text="Add 30 locations and 80 fish species, then rebuild and rerun the tests."
    />
    <Narration
      top={layout.contentTop + 250}
      lines={[{ text: "Devin builds and runs the app in the iOS Simulator.", at: 92 }]}
    />
    <Figure
      sceneDuration={duration}
      shots={[
        {
          src: "screens/devin-web-13.png",
          from: 0,
          until: 118,
          cam: { from: { scale: 1.15, x: 40, y: 70 }, to: { scale: 1.22, x: 38, y: 74 } },
        },
        {
          src: "screens/devin-desktop-7.png",
          from: 118,
          cam: { from: { scale: 1.85, x: 66, y: 39 }, to: { scale: 1.98, x: 64, y: 40 } },
        },
      ]}
    />
  </AbsoluteFill>
);
