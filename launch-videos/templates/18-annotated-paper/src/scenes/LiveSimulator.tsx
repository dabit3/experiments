import React from "react";
import { AbsoluteFill } from "remotion";
import { useProgress, useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { ASPECT, Figure, figureHeight } from "../components/Figure";
import { Box, Highlight } from "../components/Ink";
import { Cursor } from "../components/Cursor";
import { Narration } from "../components/Narration";
import { HandLabel, Sticky } from "../components/Sticky";
import { FIG_W, PAPER_PAD, PAPER_W, PAPER_X, TEXT_W, TEXT_X, TEXT_Y, paperY } from "../layout";
import { ease, sec } from "../theme";

// The Simulator viewport inside the session player (normalised to the screenshot).
const LIVE = { x0: 0.033, y0: 0.088, x1: 0.62, y1: 0.892 };
const SWAP = sec(2.6);

/** Feature 02: a live iPhone Simulator tab; the recording plays inside the print. */
export const LiveSimulator: React.FC = () => {
  const fade = useSceneFade();
  const h = figureHeight(FIG_W, ASPECT.web);
  const y = paperY(h);
  const live = useProgress(SWAP, sec(0.7), ease.inOut);
  const move = { from: { scale: 1.0 }, to: { scale: 1.08, x: 60, y: 10 }, duration: sec(8) };
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      <Narration
        x={TEXT_X}
        y={TEXT_Y}
        width={TEXT_W}
        label="02 — Live Simulator"
        lines={["A live iPhone Simulator.", "Devin taps, types, scrolls."]}
        at={sec(0.2)}
      />
      <Paper x={PAPER_X} y={y} width={PAPER_W} rotate={0.6} enterAt={sec(0.1)} caption="Fig. 03 — Simulator tab, iPhone 17 Pro" captionRight="12 passed · 3 failed · 2 untested">
        <div style={{ position: "relative", width: FIG_W, height: h }}>
          <Figure src="screens/devin-web-11.png" width={FIG_W} aspect={ASPECT.web} stacked move={move} />
          <Figure src="screens/devin-web-10.png" width={FIG_W} aspect={ASPECT.web} stacked opacity={live} move={move}>
            <Cursor
              path={[
                { x: 0.335, y: 0.55 },
                { x: 0.31, y: 0.807 },
                { x: 0.4, y: 0.807 },
              ]}
              at={SWAP + sec(0.4)}
              legFrames={sec(1.0)}
              clickAt={SWAP + sec(1.45)}
            />
            <Highlight from={{ x: 0.66, y: 0.116 }} to={{ x: 0.86, y: 0.116 }} height={30} at={sec(5.2)} />
          </Figure>
          <Figure width={FIG_W} aspect={ASPECT.web} stacked move={move}>
            <Box from={{ x: LIVE.x0, y: LIVE.y0 }} to={{ x: LIVE.x1, y: LIVE.y1 }} at={sec(0.9)} />
          </Figure>
        </div>
      </Paper>
      <HandLabel x={PAPER_X + PAPER_PAD + 40} y={y - 46} at={sec(1.6)} rotate={-2} size={34}>
        live — watch, or tap along
      </HandLabel>
      <Sticky x={PAPER_X + PAPER_W - 250} y={y + PAPER_PAD + h - 170} at={sec(5.8)} rotate={2} width={210}>
        every step checked
      </Sticky>
    </AbsoluteFill>
  );
};
