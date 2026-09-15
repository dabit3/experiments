import React from "react";
import { AbsoluteFill } from "remotion";
import { useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { ASPECT, Figure, figureHeight, type Crop } from "../components/Figure";
import { Circle } from "../components/Ink";
import { Narration } from "../components/Narration";
import { Sticky } from "../components/Sticky";
import { Typing } from "../components/Typing";
import { FIG_W, PAPER_W, PAPER_X, TEXT_W, TEXT_X, paperHeight, paperY } from "../layout";
import { sec } from "../theme";

// Home screen, cropped to the prompt box and the macOS platform chip.
const CROP: Crop = { x: 0.19, y: 0.28, w: 0.62, h: 0.4 };
const SWAP = sec(3.1);

/** Problem → context. Copy swaps once; the prompt gets typed and the macOS chip is circled. */
export const Context: React.FC = () => {
  const fade = useSceneFade();
  const h = figureHeight(FIG_W, ASPECT.web, CROP);
  const y = paperY(h) + 10;
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      <Narration
        x={TEXT_X}
        y={380}
        width={TEXT_W}
        label="Before"
        lines={["iOS teams QA'd by hand,", "or waited 20+ min for CI."]}
        at={sec(0.2)}
        until={SWAP}
      />
      <Narration
        x={TEXT_X}
        y={380}
        width={TEXT_W}
        label="Now"
        lines={["Devin runs in a Mac VM.", "It writes and tests iOS apps."]}
        at={SWAP + sec(0.1)}
      />
      <Paper x={PAPER_X} y={y} width={PAPER_W} rotate={0.8} enterAt={sec(0.15)} caption="Fig. 01 — New session" captionRight="app.devin.ai">
        <Figure
          src="screens/devin-web-1.png"
          width={FIG_W}
          aspect={ASPECT.web}
          crop={CROP}
          move={{ from: { scale: 1 }, to: { scale: 1.05, y: -6 }, duration: sec(6.5) }}
        >
          <Typing
            cover={{ x: 0.222, y: 0.4, w: 0.36, h: 0.045 }}
            text="Build the iOS app and tap through it in the Simulator"
            at={sec(0.9)}
            sizeN={0.0245}
          />
          <Circle center={{ x: 0.252, y: 0.603 }} rx={66} ry={26} at={SWAP + sec(0.3)} seed={2} />
        </Figure>
      </Paper>
      <Sticky x={PAPER_X - 40} y={y + paperHeight(h) - 14} at={SWAP + sec(0.9)} rotate={-3} width={270}>
        hosted macOS — same VM, new OS
      </Sticky>
    </AbsoluteFill>
  );
};
