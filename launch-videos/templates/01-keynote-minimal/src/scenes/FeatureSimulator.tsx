import React from "react";
import { Headline } from "../components/Headline";
import { Screen } from "../components/Screen";
import { CARD, FEATURE_HEADLINE_Y } from "../layout";
import { sec } from "../tokens";

export const FeatureSimulator: React.FC<{ duration: number }> = ({ duration }) => (
  <>
    <Headline size="h2" y={FEATURE_HEADLINE_Y} from={0} until={sec(4.4)}>
      Watch it tap, type and scroll — like a person.
    </Headline>
    <Screen
      {...CARD}
      motionFrames={duration}
      zoomFrom={1.02}
      zoomTo={1.07}
      panFrom={[0, 14]}
      panTo={[30, 26]}
      layers={[
        { src: "screens/devin-web-11.png", from: 0 },
        { src: "screens/devin-web-10.png", from: sec(2.6) },
      ]}
      crossfadeFrames={24}
    />
  </>
);
