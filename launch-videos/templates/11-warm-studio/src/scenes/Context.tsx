import React from "react";
import { AbsoluteFill } from "remotion";
import { Narration } from "../components/Narration";
import { Scene } from "../components/Scene";
import { ms } from "../tokens";

export const Context: React.FC = () => (
  <Scene>
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
      <Narration
        size="h1"
        align="center"
        maxWidth={1680}
        beats={[
          {
            at: 6,
            text: (
              <>
                Before, you tested iPhone apps by hand —<br />
                or waited 20 minutes for CI.
              </>
            ),
          },
          {
            at: ms(3300),
            text: (
              <>
                No coding agent could build, run and
                <br />
                tap through an iPhone app on its own.
              </>
            ),
          },
        ]}
      />
    </AbsoluteFill>
  </Scene>
);
