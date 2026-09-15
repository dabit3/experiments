import React from "react";
import { AbsoluteFill } from "remotion";
import { Heading, Label, ScreenCard, Shot, Typed } from "./components";
import { RAIL_Y, railX } from "./Graph";
import { Scene, STEPS, STEP_ACTIVATION, StepIndex } from "./scenes";
import { MARGIN, easeIn, easeOut, lerp, ramp, type, useFrame } from "./theme";

export type FeatureStep = {
  index: StepIndex;
  shot: Shot;
  headline: string;
  log: string;
};

const CARD_W = 1080;
const CARD_H = 587;
const CARD_X = 1920 - MARGIN - CARD_W;
const CARD_Y = 176;
const TEXT_W = CARD_X - MARGIN - 80;

export const FeatureScene: React.FC<{ scene: Scene; steps: FeatureStep[] }> = ({ scene, steps }) => {
  const frame = useFrame();
  const first = steps[0];
  const act0 = STEP_ACTIVATION[first.index];

  // Card grows out of the active node on the rail.
  const enter = ramp(frame, act0, 28, easeOut);
  const exit = ramp(frame, scene.to - 12, 12, easeIn);
  const nodeX = railX(first.index);
  const cardCx = CARD_X + CARD_W / 2;
  const cardCy = CARD_Y + CARD_H / 2;
  const scale = lerp(0.04, 1, enter) * lerp(1, 0.97, exit);
  const tx = lerp(nodeX - cardCx, 0, enter);
  const ty = lerp(RAIL_Y - cardCy, 0, enter);
  const opacity = ramp(frame, act0, 12, easeOut) * (1 - exit);

  return (
    <AbsoluteFill>
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          top: CARD_Y,
          width: TEXT_W,
          height: CARD_H,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          gap: 28,
        }}
      >
        {steps.map((s, i) => {
          const from = STEP_ACTIVATION[s.index] + 6;
          const to = i < steps.length - 1 ? STEP_ACTIVATION[steps[i + 1].index] + 2 : scene.to;
          if (frame < from - 2 || frame > to) return null;
          const n = String(s.index + 1).padStart(2, "0");
          return (
            <div
              key={s.index}
              style={{
                position: "absolute",
                left: 0,
                right: 0,
                top: "50%",
                transform: "translateY(-50%)",
                display: "flex",
                flexDirection: "column",
                gap: 28,
              }}
            >
              <Label from={from} to={to}>
                Step {n} / {String(STEPS.length).padStart(2, "0")} · {STEPS[s.index].label}
              </Label>
              <Heading from={from} to={to} size={type.sizes1080p.h3}>
                {s.headline}
              </Heading>
              <Typed from={from + 14} to={to} text={s.log} />
            </div>
          );
        })}
      </div>

      <div
        style={{
          position: "absolute",
          left: CARD_X,
          top: CARD_Y,
          transform: `translate(${tx}px, ${ty}px) scale(${scale})`,
          opacity,
        }}
      >
        <ScreenCard
          width={CARD_W}
          height={CARD_H}
          until={scene.to}
          shots={steps.map((s) => ({ shot: s.shot, from: STEP_ACTIVATION[s.index] }))}
        />
      </div>
    </AbsoluteFill>
  );
};
