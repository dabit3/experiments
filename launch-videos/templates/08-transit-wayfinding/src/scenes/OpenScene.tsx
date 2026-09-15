import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import type { LaunchProps } from "../schema";
import { RouteMap } from "../components/RouteMap";
import { Headline, TopBar, Wipe } from "../components/Chrome";
import { SAFE, TYPE, easeInOut, ramp } from "../geometry";

type Props = { props: LaunchProps; durationInFrames: number };

// Start at the origin: title, then trace the line toward the first station.
export const OpenScene: React.FC<Props> = ({ props, durationInFrames }) => {
  const frame = useCurrentFrame();
  const { brand, content, route } = props;
  const reveal = ramp(frame, 0, 34);
  const bar = ramp(frame, 0, 16);
  const head = ramp(frame, 10, 26);
  const sub = ramp(frame, 26, 26);
  const traceStart = 48;
  const progress = 0.85 * ramp(frame, traceStart, durationInFrames - traceStart, easeInOut);
  const titleOut = interpolate(frame, [durationInFrames - 16, durationInFrames - 2], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <TopBar brand={brand} content={content} opacity={bar} />
      <div style={{ position: "absolute", left: SAFE, top: 196, opacity: titleOut }}>
        <Wipe t={head}>
          <Headline brand={brand} text={content.headline} accentWord={content.headlineAccentWord} />
        </Wipe>
        <Wipe t={sub} style={{ marginTop: 28 }}>
          <div
            style={{
              fontFamily: brand.fontFamily,
              fontSize: TYPE.h5.size,
              lineHeight: TYPE.h5.lineHeight,
              letterSpacing: TYPE.h5.tracking,
              color: brand.inkMuted,
              maxWidth: 1040,
            }}
          >
            {content.subhead}
          </div>
        </Wipe>
      </div>
      <RouteMap brand={brand} route={route} progress={progress} reveal={reveal} />
    </AbsoluteFill>
  );
};
