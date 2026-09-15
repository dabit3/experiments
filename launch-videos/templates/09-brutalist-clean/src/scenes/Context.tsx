import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Headline } from "../components/Headline";
import { Masthead } from "../components/Masthead";
import { space } from "../theme";

const SWAP = 86;

export const Context: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      <Masthead left="Before" right="The problem" />
      <div style={{ position: "absolute", left: space.margin, top: 380 }}>
        {frame < SWAP + 8 ? (
          <Headline
            lines={["iOS teams QA'd the app by hand,", "or waited 20+ minutes for CI."]}
            size={92}
            stagger={6}
            exitAt={SWAP}
            exitDuration={8}
          />
        ) : (
          <Headline
            lines={["No coding agent could build, run", "and tap through an iPhone app."]}
            size={92}
            stagger={6}
            enterAt={SWAP + 8}
          />
        )}
      </div>
    </AbsoluteFill>
  );
};
