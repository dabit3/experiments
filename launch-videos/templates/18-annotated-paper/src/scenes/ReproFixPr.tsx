import React from "react";
import { AbsoluteFill } from "remotion";
import { useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { ASPECT, Figure, figureHeight } from "../components/Figure";
import { Arrow, Circle, Highlight } from "../components/Ink";
import { Narration } from "../components/Narration";
import { Sticky } from "../components/Sticky";
import { FIG_W, PAPER_W, PAPER_X, TEXT_W, TEXT_X, TEXT_Y, paperHeight, paperY } from "../layout";
import { sec } from "../theme";

/** Feature 03: repro in the Simulator, fix, re-run tests, open the PR. Camera pans left → right. */
export const ReproFixPr: React.FC = () => {
  const fade = useSceneFade();
  const h = figureHeight(FIG_W, ASPECT.web);
  const y = paperY(h);
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      <Narration
        x={TEXT_X}
        y={TEXT_Y}
        width={TEXT_W}
        label="03 — Repro, fix, PR"
        lines={["Reproduce the bug. Fix it.", "Re-run tests. Open the PR."]}
        at={sec(0.2)}
      />
      <Paper x={PAPER_X} y={y} width={PAPER_W} rotate={-0.5} enterAt={sec(0.1)} caption="Fig. 04 — Session with PR panel" captionRight="#161 · 27 files · +2257 −0">
        <Figure
          src="screens/devin-web-9.png"
          width={FIG_W}
          aspect={ASPECT.web}
          move={{ from: { scale: 1.16, x: 60 }, to: { scale: 1.16, x: -60 }, start: sec(0.4), duration: sec(4.6) }}
        >
          <Circle center={{ x: 0.233, y: 0.247 }} rx={100} ry={22} at={sec(0.9)} seed={8} width={3} />
          <Highlight from={{ x: 0.727, y: 0.303 }} to={{ x: 0.79, y: 0.303 }} height={26} at={sec(3.6)} />
          <Circle center={{ x: 0.63, y: 0.387 }} rx={80} ry={26} at={sec(4.2)} seed={12} width={3} />
          <Arrow from={{ x: 0.53, y: 0.5 }} to={{ x: 0.59, y: 0.405 }} bend={-22} at={sec(4.7)} width={3} />
        </Figure>
      </Paper>
      <Sticky x={PAPER_X - 50} y={y + paperHeight(h) - 12} at={sec(1.6)} rotate={-4} width={220}>
        repro’d in the Simulator
      </Sticky>
      <Sticky x={PAPER_X + PAPER_W - 250} y={y + paperHeight(h) - 12} at={sec(5.1)} rotate={3} width={220}>
        tests green → PR open
      </Sticky>
    </AbsoluteFill>
  );
};
