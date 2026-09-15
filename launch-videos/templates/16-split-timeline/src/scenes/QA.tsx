import React from "react";
import { AbsoluteFill } from "remotion";
import { Figure } from "../components/Figure";
import { Narration } from "../components/Narration";
import { PromptCard } from "../components/PromptCard";
import { layout } from "../theme";

/** Feature 4: check screens across devices, dark mode and orientations. */
export const QA: React.FC<{ duration: number }> = ({ duration }) => (
  <AbsoluteFill>
    <PromptCard variant="spoken" at={4} text="Check every screen before we ship." />
    <Narration
      top={layout.contentTop + 250}
      lines={[
        { text: "iPhone and iPad. Dark mode. Every orientation.", at: 40 },
        { text: "Screenshots compared pixel for pixel.", at: 130, muted: true },
      ]}
    />
    <Figure
      sceneDuration={duration}
      shots={[
        {
          src: "screens/devin-web-17.png",
          from: 0,
          until: 118,
          cam: { from: { scale: 1.5, x: 38, y: 48 }, to: { scale: 1.5, x: 42, y: 72 } },
        },
        {
          src: "screens/devin-web-19.png",
          from: 118,
          cam: { from: { scale: 1.06, x: 0, y: 52 }, to: { scale: 1.14, x: 0, y: 50 } },
        },
      ]}
    />
  </AbsoluteFill>
);
