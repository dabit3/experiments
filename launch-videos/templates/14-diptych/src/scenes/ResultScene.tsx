import React from "react";
import { useCurrentFrame } from "remotion";
import type { LaunchProps, ResultScene as ResultSceneProps } from "../schema";
import {
  croppedAspect,
  diptychSlots,
  fitRect,
  fullFrame,
  lerpRect,
} from "../geometry";
import { exit, move } from "../motion";
import { Media } from "../components/Media";
import { Backdrop, Divider, PanelLabel, TopBar } from "../components/Chrome";

type Props = {
  scene: ResultSceneProps;
  props: LaunchProps;
  /** Ratio of the diptych the result panel is taken over from. */
  prevRatio: number;
};

/** The delivered result grows from its diptych panel until it fills the frame. */
export const ResultScene: React.FC<Props> = ({ scene, props, prevRatio }) => {
  const frame = useCurrentFrame();
  const { brand, layout, media, content } = props;
  const slot = media[scene.media];
  if (!slot) {
    throw new Error(`Scene "${scene.id}" references unknown media "${scene.media}"`);
  }
  const aspect = croppedAspect(slot);
  const { right, dividerX } = diptychSlots(prevRatio, layout);
  const start = fitRect(right, aspect, "contain");
  const end = fitRect(fullFrame, aspect, "cover");

  const grow = move(frame, scene.expandAt, layout.moveDuration * 1.5);
  const chrome = 1 - move(frame, scene.expandAt, layout.moveDuration);
  const rect = lerpRect(start, end, grow);
  const toBlack = 1 - exit(frame, scene.durationInFrames, 10);

  return (
    <>
      <TopBar
        brand={brand}
        layout={layout}
        featureName={content.featureName}
        opacity={chrome}
      />
      <Divider brand={brand} layout={layout} x={dividerX} opacity={chrome} />
      <PanelLabel
        brand={brand}
        layout={layout}
        x={right.x}
        w={right.w}
        text={scene.label}
        opacity={chrome}
      />
      <Media
        slot={slot}
        into={rect}
        fit="contain"
        brand={brand}
        radius={layout.panelRadius}
        frame={1 - grow}
      />
      <div style={{ opacity: toBlack, position: "absolute", inset: 0 }}>
        <Backdrop color={brand.black} />
      </div>
    </>
  );
};
