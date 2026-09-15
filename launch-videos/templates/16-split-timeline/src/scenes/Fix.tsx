import React from "react";
import { AbsoluteFill } from "remotion";
import { Figure } from "../components/Figure";
import { Narration } from "../components/Narration";
import { PromptCard } from "../components/PromptCard";
import { layout } from "../theme";

/** Feature 3: reproduce a bug in the Simulator, fix it, re-run the UI tests, open a PR. */
export const Fix: React.FC<{ duration: number }> = ({ duration }) => (
  <AbsoluteFill>
    <PromptCard
      variant="typed"
      at={4}
      typeDuration={54}
      text="The API key is lost after relaunch. Fix it and open a PR."
    />
    <Narration
      top={layout.contentTop + 250}
      lines={[
        { text: "Devin reproduces the bug and fixes it.", at: 78, until: 150 },
        { text: "Re-runs the UI tests. Opens the PR.", at: 156 },
      ]}
    />
    <Figure
      sceneDuration={duration}
      shots={[
        {
          src: "screens/devin-web-10.png",
          from: 0,
          until: 128,
          cam: { from: { scale: 1.7, x: 98, y: 0 }, to: { scale: 1.7, x: 98, y: 34 } },
        },
        {
          src: "screens/devin-web-9.png",
          from: 128,
          cam: { from: { scale: 1.16, x: 76, y: 58 }, to: { scale: 1.24, x: 78, y: 60 } },
        },
      ]}
    />
  </AbsoluteFill>
);
