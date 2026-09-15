import React from "react";
import { useCurrentFrame } from "remotion";
import type { LaunchProps, Scene } from "../schema";
import { HEIGHT, diptychSlots } from "../geometry";
import { enter, exit } from "../motion";
import { Divider, TopBar, type } from "../components/Chrome";
import { EXIT_FRAMES } from "./PairScene";

type Props = {
  scene: Scene;
  props: LaunchProps;
  /** Ratio the first diptych opens with; the divider is introduced here. */
  nextRatio: number;
};

const Headline: React.FC<{ text: string; accent: string; color: string }> = ({
  text,
  accent,
  color,
}) => {
  const i = accent ? text.indexOf(accent) : -1;
  if (i < 0) return <>{text}</>;
  return (
    <>
      {text.slice(0, i)}
      <span style={{ color }}>{accent}</span>
      {text.slice(i + accent.length)}
    </>
  );
};

export const TitleScene: React.FC<Props> = ({ scene, props, nextRatio }) => {
  const frame = useCurrentFrame();
  const { brand, layout, content } = props;
  const { left, dividerX } = diptychSlots(nextRatio, layout);
  const out = exit(frame, scene.durationInFrames, EXIT_FRAMES);
  const a = enter(frame, 0, layout.enterDuration);
  const b = enter(frame, 8, layout.enterDuration);
  const c = enter(frame, 16, layout.enterDuration);
  const d = enter(frame, 30, layout.moveDuration);

  return (
    <>
      <TopBar
        brand={brand}
        layout={layout}
        featureName={content.featureName}
        opacity={a}
      />
      <Divider brand={brand} layout={layout} x={dividerX} opacity={d} />
      <div
        style={{
          position: "absolute",
          left: left.x,
          width: left.w,
          top: HEIGHT / 2 - 150,
          fontFamily: brand.fontFamily,
          color: brand.ink,
        }}
      >
        <div
          style={{
            ...type.eyebrow,
            color: brand.inkMuted,
            opacity: a * out,
            transform: `translateY(${(1 - a) * 12}px)`,
          }}
        >
          {content.eyebrow}
        </div>
        <div
          style={{
            ...type.display,
            marginTop: 20,
            maxWidth: 900,
            opacity: b * out,
            transform: `translateY(${(1 - b) * 16}px)`,
          }}
        >
          <Headline
            text={content.headline}
            accent={content.headlineAccent}
            color={brand.accent}
          />
        </div>
        <div
          style={{
            ...type.h5,
            marginTop: 28,
            maxWidth: 760,
            color: brand.inkMuted,
            opacity: c * out,
            transform: `translateY(${(1 - c) * 16}px)`,
          }}
        >
          {content.subhead}
        </div>
      </div>
    </>
  );
};
