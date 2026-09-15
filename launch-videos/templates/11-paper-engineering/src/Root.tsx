import React from "react";
import { Composition, Sequence, type CalculateMetadataFunction } from "remotion";
import { Launch } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { defaultProps, posterFrame } from "./defaults";
import { HEIGHT, WIDTH, totalDuration } from "./lib";

const FPS = 30;

const calculateMetadata: CalculateMetadataFunction<LaunchProps> = ({ props }) => ({
  durationInFrames: totalDuration(props.scenes),
  fps: FPS,
  width: WIDTH,
  height: HEIGHT,
});

/** Single-frame composition that shows the Launch video at `posterFrame`. */
const Poster: React.FC<LaunchProps> = (props) => (
  <Sequence from={-posterFrame} layout="none">
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
      calculateMetadata={calculateMetadata}
      durationInFrames={totalDuration(defaultProps.scenes)}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
    <Composition
      id="Poster"
      component={Poster}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      durationInFrames={1}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
  </>
);
