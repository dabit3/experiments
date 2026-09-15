import React from "react";
import { AbsoluteFill } from "remotion";
import { Figure } from "../components/Figure";
import { Narration } from "../components/Narration";
import { PromptCard } from "../components/PromptCard";
import { layout } from "../theme";

/** Feature 2: live Simulator — Devin taps, types and scrolls like a person. */
export const Drive: React.FC<{ duration: number }> = ({ duration }) => (
  <AbsoluteFill>
    <PromptCard variant="spoken" at={4} text="Sign in with the key, send a message, then stop the reply mid-stream." />
    <Narration
      top={layout.contentTop + 250}
      lines={[
        { text: "Devin taps, types and scrolls like a person.", at: 40 },
        { text: "Watch live — or tap in yourself.", at: 120, muted: true },
      ]}
    />
    <Figure
      sceneDuration={duration}
      shots={[
        {
          src: "screens/devin-web-11.png",
          from: 0,
          until: 100,
          cam: { from: { scale: 1.2, x: 30, y: 55 }, to: { scale: 1.2, x: 34, y: 55 } },
        },
        {
          src: "screens/devin-web-10.png",
          from: 100,
          cam: { from: { scale: 1.2, x: 34, y: 55 }, to: { scale: 1.2, x: 60, y: 50 } },
        },
      ]}
    />
  </AbsoluteFill>
);
