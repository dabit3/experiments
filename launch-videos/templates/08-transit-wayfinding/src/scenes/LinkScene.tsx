import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { LaunchProps, LinkScene as LinkSceneProps } from "../schema";
import { RouteMap } from "../components/RouteMap";
import { TopBar } from "../components/Chrome";
import { easeInOut, lerp, ramp, stationIndex } from "../geometry";

type Props = { props: LaunchProps; scene: LinkSceneProps };

// Brief return to the map: the line travels from one station toward the next.
export const LinkScene: React.FC<Props> = ({ props, scene }) => {
  const frame = useCurrentFrame();
  const { brand, route, content } = props;
  const from = stationIndex(route, scene.from);
  const to = stationIndex(route, scene.to);
  const t = ramp(frame, 3, scene.durationInFrames - 4, easeInOut);
  const progress = lerp(from, to - 0.15, t);
  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <TopBar brand={brand} content={content} />
      <RouteMap brand={brand} route={route} progress={progress} />
    </AbsoluteFill>
  );
};
