import React from "react";
import { Sequence } from "remotion";
import "./fonts";
import { ms } from "./anim";
import { Paper } from "./components/Layout";
import { scenes } from "./scenes";
import { color } from "./tokens";
import { Context } from "./scenes/Context";
import { EndCard } from "./scenes/EndCard";
import { Feature } from "./scenes/Feature";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { wireDeviceGrid, wireHome, wirePlayer, wireSessionPR } from "./wireframes";

const S = scenes;
const RESOLVE = ms(1200);
const LIVE = RESOLVE + ms(600);

export const Main: React.FC = () => {
  return (
    <Paper>
      <Sequence from={S.hook.from} durationInFrames={S.hook.duration} name="Hook">
        <Hook duration={S.hook.duration} />
      </Sequence>

      <Sequence from={S.context.from} durationInFrames={S.context.duration} name="Context">
        <Context />
      </Sequence>

      <Sequence from={S.feature1.from} durationInFrames={S.feature1.duration} name="Feature 1">
        <Feature
          index={1}
          title="New session"
          duration={S.feature1.duration}
          wire={wireHome}
          shots={[
            { file: "devin-web-1.png", at: RESOLVE },
            { file: "devin-web-4.png", at: LIVE + ms(2900) },
          ]}
          push={{ scaleTo: 1.04, origin: "8% 0%" }}
          typing={{
            text: "Build the iOS app, run the UI tests and open a PR",
            from: LIVE + ms(200),
            x: 0.226,
            y: 0.394,
            w: 0.4,
            h: 0.052,
            fontSize: 14.2,
            cover: color.white,
          }}
          cursor={{
            from: LIVE + ms(1800),
            keys: [
              { at: LIVE + ms(1800), x: 0.62, y: 0.78 },
              { at: LIVE + ms(2800), x: 0.252, y: 0.6, click: true },
              { at: LIVE + ms(3300), x: 0.252, y: 0.6 },
              { at: LIVE + ms(4100), x: 0.268, y: 0.73 },
            ],
          }}
          captions={[
            { text: "Type what you want built. Pick macOS.", from: ms(200), to: LIVE + ms(2900) },
            { text: "Devin builds and runs the app in Xcode.", from: LIVE + ms(3000) },
          ]}
        />
      </Sequence>

      <Sequence from={S.feature2.from} durationInFrames={S.feature2.duration} name="Feature 2">
        <Feature
          index={2}
          title="Simulator"
          duration={S.feature2.duration}
          wire={wirePlayer}
          shots={[
            { file: "devin-web-11.png", at: RESOLVE },
            { file: "devin-web-10.png", at: LIVE + ms(2200) },
          ]}
          push={{ scaleTo: 1.05, origin: "15% 50%" }}
          captions={[
            { text: "A live iPhone Simulator, right in the session.", from: ms(200), to: LIVE + ms(2200) },
            { text: "Devin taps, types and scrolls like a person.", from: LIVE + ms(2300) },
          ]}
        />
      </Sequence>

      <Sequence from={S.feature3.from} durationInFrames={S.feature3.duration} name="Feature 3">
        <Feature
          index={3}
          title="Fix and ship"
          duration={S.feature3.duration}
          wire={wireSessionPR}
          shots={[{ file: "devin-web-9.png", at: RESOLVE }]}
          push={{ scaleTo: 1.05, origin: "18% 45%" }}
          captions={[
            { text: "Devin reproduces the bug, then fixes it.", from: ms(200), to: LIVE + ms(2200) },
            { text: "Re-runs the UI tests. Opens a PR.", from: LIVE + ms(2300) },
          ]}
        />
      </Sequence>

      <Sequence from={S.feature4.from} durationInFrames={S.feature4.duration} name="Feature 4">
        <Feature
          index={4}
          title="Every screen"
          duration={S.feature4.duration}
          wire={wireDeviceGrid}
          shots={[
            { file: "devin-web-17.png", at: RESOLVE },
            { file: "devin-web-19.png", at: LIVE + ms(2600) },
          ]}
          push={{ scaleTo: 1.05, origin: "15% 55%" }}
          captions={[
            { text: "iPhone and iPad sizes, dark mode, both orientations.", from: ms(200), to: LIVE + ms(2500) },
            { text: "Screenshots compared pixel for pixel.", from: LIVE + ms(2600) },
          ]}
        />
      </Sequence>

      <Sequence from={S.outcome.from} durationInFrames={S.outcome.duration} name="Outcome">
        <Outcome duration={S.outcome.duration} />
      </Sequence>

      <Sequence from={S.end.from} durationInFrames={S.end.duration} name="End card">
        <EndCard />
      </Sequence>
    </Paper>
  );
};
