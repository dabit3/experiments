import React from "react";
import { Headline } from "../components/Headline";
import { Screen } from "../components/Screen";
import { CARD, FEATURE_HEADLINE_Y } from "../layout";
import { sec } from "../tokens";

export const FeaturePr: React.FC<{ duration: number }> = ({ duration }) => (
  <>
    <Headline size="h2" y={FEATURE_HEADLINE_Y} from={0} until={sec(4.4)} maxWidth={1500}>
      It reproduces the bug, fixes it, re-runs the tests{"\n"}and opens a PR.
    </Headline>
    <Screen
      {...CARD}
      motionFrames={duration}
      zoomFrom={1.08}
      zoomTo={1.08}
      panFrom={[70, 0]}
      panTo={[-70, 0]}
      layers={[{ src: "screens/devin-web-9.png", from: 0, position: "50% 0%" }]}
    />
  </>
);
