import React from "react";
import { AbsoluteFill } from "remotion";
import { useProgress, useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { ASPECT, Figure, figureHeight } from "../components/Figure";
import { Circle, Highlight } from "../components/Ink";
import { Cursor } from "../components/Cursor";
import { Narration } from "../components/Narration";
import { Sticky } from "../components/Sticky";
import { FIG_W, PAPER_W, PAPER_X, TEXT_W, TEXT_X, TEXT_Y, paperHeight, paperY } from "../layout";
import { ease, sec } from "../theme";

const SWAP = sec(3.6);

/** Feature 01: pick macOS, Devin builds, runs and tests in the Simulator. */
export const BuildRun: React.FC = () => {
  const fade = useSceneFade();
  const h = figureHeight(FIG_W, ASPECT.web);
  const y = paperY(h);
  const xfade = useProgress(SWAP, sec(0.6), ease.inOut);
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      <Narration
        x={TEXT_X}
        y={TEXT_Y}
        width={TEXT_W}
        label="01 — Build & run"
        lines={["Devin builds and runs the app", "in Xcode and the Simulator."]}
        at={sec(0.2)}
      />
      <Paper x={PAPER_X} y={y} width={PAPER_W} rotate={-0.7} enterAt={sec(0.1)} caption="Fig. 02 — Platform picker → session" captionRight="Ubuntu · macOS · Windows">
        <div style={{ position: "relative", width: FIG_W, height: h }}>
          <Figure
            src="screens/devin-web-4.png"
            width={FIG_W}
            aspect={ASPECT.web}
            stacked
            opacity={1 - xfade}
            move={{ from: { scale: 1.12, x: 110, y: -70 }, to: { scale: 1.22, x: 200, y: -120 }, duration: sec(4.2) }}
          >
            <Cursor
              path={[
                { x: 0.4, y: 0.5 },
                { x: 0.278, y: 0.736 },
              ]}
              at={sec(0.6)}
              legFrames={sec(0.9)}
              clickAt={sec(1.6)}
            />
            <Circle center={{ x: 0.27, y: 0.734 }} rx={78} ry={24} at={sec(1.7)} seed={4} />
          </Figure>
          <Figure
            src="screens/devin-web-13.png"
            width={FIG_W}
            aspect={ASPECT.web}
            stacked
            opacity={xfade}
            move={{ from: { scale: 1.06, y: 20 }, to: { scale: 1.0, y: 0 }, start: SWAP, duration: sec(3.4) }}
          >
            <Highlight from={{ x: 0.548, y: 0.618 }} to={{ x: 0.786, y: 0.618 }} height={26} at={SWAP + sec(0.7)} />
            <Highlight from={{ x: 0.245, y: 0.648 }} to={{ x: 0.36, y: 0.648 }} height={26} at={SWAP + sec(1.1)} seed={9} />
            <Circle center={{ x: 0.305, y: 0.767 }} rx={92} ry={22} at={SWAP + sec(1.5)} seed={6} />
          </Figure>
        </div>
      </Paper>
      <Sticky x={PAPER_X + PAPER_W - 210} y={y - 30} at={sec(2.4)} rotate={3} width={200}>
        macOS, hosted
      </Sticky>
      <Sticky x={PAPER_X - 60} y={y + paperHeight(h) - 20} at={SWAP + sec(1.9)} rotate={-4} width={230}>
        build → run → test, on its own
      </Sticky>
    </AbsoluteFill>
  );
};
