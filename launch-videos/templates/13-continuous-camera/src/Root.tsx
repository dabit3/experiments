import React from "react";
import { Composition, Sequence } from "remotion";
import { Launch } from "./Launch";
import { defaultProps } from "./defaults";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { buildTimeline, totalFrames } from "./timeline";

/** Hero frame: the middle of the "taps" station hold (falls back to mid-video). */
export const posterFrame = (props: LaunchProps): number => {
  const t = buildTimeline(props.scenes).find((s) => s.station.id === "taps");
  if (!t) return Math.floor(totalFrames(props.scenes) / 2);
  return Math.floor((t.arrive + t.leave) / 2);
};

const Poster: React.FC<LaunchProps> = (props) => (
  <Sequence from={-posterFrame(props)} layout="none">
    <Launch {...props} />
  </Sequence>
);

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="Launch"
      component={Launch}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      width={1920}
      height={1080}
      fps={30}
      durationInFrames={totalFrames(defaultProps.scenes)}
      calculateMetadata={({ props }) => ({
        durationInFrames: totalFrames(props.scenes),
      })}
    />
    <Composition
      id="Poster"
      component={Poster}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      width={1920}
      height={1080}
      fps={30}
      durationInFrames={1}
    />
  </>
);
