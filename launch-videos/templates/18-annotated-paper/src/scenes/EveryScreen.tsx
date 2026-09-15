import React from "react";
import { AbsoluteFill } from "remotion";
import { useProgress, useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { ASPECT, Figure, figureHeight, type Crop } from "../components/Figure";
import { Check, Circle } from "../components/Ink";
import { Narration } from "../components/Narration";
import { Sticky } from "../components/Sticky";
import { FIG_W, PAPER_W, PAPER_X, TEXT_W, TEXT_X, TEXT_Y, paperHeight, paperY } from "../layout";
import { color, ease, sec } from "../theme";

// Dark review panel, cropped to the six-up device grid (same aspect as the full print).
const GRID: Crop = { x: 0.1, y: 0.34, w: 0.65, h: 0.65 };
const SWAP = sec(4.0);

const CELLS = [
  { x: 0.231, y: 0.535 },
  { x: 0.407, y: 0.535 },
  { x: 0.579, y: 0.535 },
  { x: 0.223, y: 0.86 },
  { x: 0.404, y: 0.86 },
  { x: 0.584, y: 0.86 },
];

/** Feature 04: device matrix, dark mode, iPad — ticked off one by one, then the iPad print. */
export const EveryScreen: React.FC = () => {
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
        label="04 — Every screen"
        lines={["Sizes, dark mode, rotation.", "Compared pixel for pixel."]}
        at={sec(0.2)}
      />
      <Paper x={PAPER_X} y={y} width={PAPER_W} rotate={0.7} enterAt={sec(0.1)} caption="Fig. 05 — Device matrix → iPad Pro 13″" captionRight="iPhone · iPad · dark mode">
        <div style={{ position: "relative", width: FIG_W, height: h }}>
          <Figure
            src="screens/devin-web-17.png"
            width={FIG_W}
            aspect={ASPECT.web}
            crop={GRID}
            stacked
            move={{ from: { scale: 1.0 }, to: { scale: 1.06, x: 30 }, duration: sec(4.5) }}
          >
            {CELLS.map((c, i) => (
              <Check key={i} at_={c} at={sec(0.9 + i * 0.32)} size={30} width={4} stroke={color.white} />
            ))}
          </Figure>
          <Figure
            src="screens/devin-web-19.png"
            width={FIG_W}
            aspect={ASPECT.web}
            stacked
            opacity={xfade}
            move={{ from: { scale: 1.08, x: 30 }, to: { scale: 1.0, x: 0 }, start: SWAP, duration: sec(3) }}
          >
            <Circle center={{ x: 0.066, y: 0.103 }} rx={62} ry={20} at={SWAP + sec(0.7)} seed={14} width={3} />
            <Check at_={{ x: 0.66, y: 0.116 }} at={SWAP + sec(1.3)} size={28} width={3.5} />
          </Figure>
        </div>
      </Paper>
      <Sticky x={PAPER_X - 50} y={y + paperHeight(h) - 12} at={sec(3.0)} rotate={-3} width={220}>
        6 states, all green
      </Sticky>
      <Sticky x={PAPER_X + PAPER_W - 200} y={y - 30} at={SWAP + sec(1.6)} rotate={2} width={210}>
        iPad too
      </Sticky>
    </AbsoluteFill>
  );
};
