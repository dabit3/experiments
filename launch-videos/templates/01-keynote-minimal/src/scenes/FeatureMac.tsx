import React from "react";
import { Sequence } from "remotion";
import { Cursor } from "../components/Cursor";
import { Headline } from "../components/Headline";
import { Screen } from "../components/Screen";
import { CARD, FEATURE_HEADLINE_Y } from "../layout";
import { sec } from "../tokens";

// Screenshot-space positions (fractions of the web-1 / web-4 frame) mapped into the card.
const IMG_W = CARD.width;
const IMG_H = CARD.width * (1624 / 2990);
const pt = (fx: number, fy: number): [number, number] => [fx * IMG_W, fy * IMG_H];

const chip = pt(0.252, 0.601); // "macOS" platform chip under the prompt box
const menuItem = pt(0.27, 0.733); // "macOS" row in the open platform picker

const SWITCH_TO_SIMULATOR = sec(3.9);

export const FeatureMac: React.FC<{ duration: number }> = ({ duration }) => (
  <>
    <Headline size="h2" y={FEATURE_HEADLINE_Y} from={0} until={sec(3.2)}>
      Choose macOS. Start a session.
    </Headline>
    <Headline size="h2" y={FEATURE_HEADLINE_Y} from={sec(4.3)} until={sec(7.0)}>
      Devin builds and runs the app in the iOS Simulator.
    </Headline>

    {/* New-session home, pushed in on the prompt box; the pointer opens the platform picker and picks macOS. */}
    <Screen
      {...CARD}
      motionFrames={SWITCH_TO_SIMULATOR}
      zoomFrom={1.28}
      zoomTo={1.34}
      panFrom={[0, 20]}
      panTo={[0, 0]}
      layers={[
        { src: "screens/devin-web-1.png", from: 0 },
        { src: "screens/devin-web-4.png", from: sec(1.9) },
      ]}
      crossfadeFrames={12}
      exitAt={SWITCH_TO_SIMULATOR + 8}
      exitFrames={18}
    >
      <Cursor
        path={[
          [sec(0.4), 880, 640],
          [sec(1.4), chip[0] + 6, chip[1] + 4],
          [sec(2.3), chip[0] + 6, chip[1] + 4],
          [sec(2.9), menuItem[0], menuItem[1]],
        ]}
        clicks={[sec(1.55), sec(3.05)]}
        until={SWITCH_TO_SIMULATOR}
      />
    </Screen>

    {/* The session with the iPhone Simulator running the app. */}
    <Sequence from={SWITCH_TO_SIMULATOR - 6} layout="none">
      <Screen
        {...CARD}
        motionFrames={duration - SWITCH_TO_SIMULATOR}
        zoomFrom={1}
        zoomTo={1.05}
        enterFrames={26}
        layers={[{ src: "screens/devin-desktop-9.png", from: 0, position: "50% 50%" }]}
      />
    </Sequence>
  </>
);
