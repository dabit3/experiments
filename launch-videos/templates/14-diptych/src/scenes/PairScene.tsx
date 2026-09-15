import React from "react";
import { useCurrentFrame } from "remotion";
import type { LaunchProps, PairScene as PairSceneProps } from "../schema";
import { diptychSlots } from "../geometry";
import { enter, exit, move } from "../motion";
import { Media } from "../components/Media";
import { Caption, Divider, PanelLabel, TopBar } from "../components/Chrome";

export const EXIT_FRAMES = 8;

type Props = {
  scene: PairSceneProps;
  props: LaunchProps;
  /** Action-panel ratio the divider is coming from (previous scene). */
  prevRatio: number;
  /** When true the result panel is handed to the next (result) scene unfaded. */
  handOffResult: boolean;
};

export const PairScene: React.FC<Props> = ({
  scene,
  props,
  prevRatio,
  handOffResult,
}) => {
  const frame = useCurrentFrame();
  const { brand, layout, media, content } = props;
  const action = media[scene.actionMedia];
  const result = media[scene.resultMedia];
  if (!action || !result) {
    throw new Error(
      `Scene "${scene.id}" references unknown media "${scene.actionMedia}" / "${scene.resultMedia}"`,
    );
  }

  // Divider: slide in from the previous ratio, then to the balanced ratio at balanceAt.
  const arrive = move(frame, 0, layout.moveDuration);
  const settle = move(frame, scene.sync.balanceAt, layout.moveDuration);
  const ratioIn = prevRatio + (scene.split.active - prevRatio) * arrive;
  const ratio = ratioIn + (scene.split.balanced - ratioIn) * settle;
  const { left, right, dividerX } = diptychSlots(ratio, layout);

  const inAction = enter(frame, 0, layout.enterDuration);
  const inResult = enter(frame, scene.sync.revealAt, layout.enterDuration);
  const out = exit(frame, scene.durationInFrames, EXIT_FRAMES);
  const resultOut = handOffResult ? 1 : out;
  const shiftAction = (1 - inAction) * 16;
  const shiftResult = (1 - inResult) * 16;

  const caption = content.captions[scene.captionIndex] ?? "";

  return (
    <>
      <TopBar
        brand={brand}
        layout={layout}
        featureName={content.featureName}
        opacity={1}
      />
      <Divider brand={brand} layout={layout} x={dividerX} opacity={1} />

      <PanelLabel
        brand={brand}
        layout={layout}
        x={left.x}
        w={left.w}
        text={scene.actionLabel}
        opacity={inAction * out}
        shift={shiftAction}
      />
      <Media
        slot={action}
        into={{ ...left, y: left.y + shiftAction }}
        fit="contain"
        brand={brand}
        radius={layout.panelRadius}
        frame={1}
        opacity={inAction * out}
      />

      <PanelLabel
        brand={brand}
        layout={layout}
        x={right.x}
        w={right.w}
        text={scene.resultLabel}
        opacity={inResult * resultOut}
        shift={shiftResult}
      />
      <Media
        slot={result}
        into={{ ...right, y: right.y + shiftResult }}
        fit="contain"
        brand={brand}
        radius={layout.panelRadius}
        frame={1}
        opacity={inResult * resultOut}
      />

      <Caption
        brand={brand}
        layout={layout}
        text={caption}
        opacity={inAction * out}
        shift={shiftAction * 0.5}
      />
    </>
  );
};
