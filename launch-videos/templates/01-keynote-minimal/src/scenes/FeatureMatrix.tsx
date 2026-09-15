import React from "react";
import { Headline } from "../components/Headline";
import { Screen } from "../components/Screen";
import { CARD, FEATURE_HEADLINE_Y } from "../layout";
import { sec } from "../tokens";

export const FeatureMatrix: React.FC<{ duration: number }> = ({ duration }) => (
  <>
    <Headline size="h2" y={FEATURE_HEADLINE_Y} from={0} until={sec(4.4)} maxWidth={1500}>
      Every size. Dark mode. Every orientation.{"\n"}Compared pixel for pixel.
    </Headline>
    <Screen
      {...CARD}
      motionFrames={duration}
      zoomFrom={1.0}
      zoomTo={1.05}
      panFrom={[0, 0]}
      panTo={[70, -12]}
      layers={[{ src: "screens/devin-web-17.png", from: 0, position: "0% 0%" }]}
    />
  </>
);
