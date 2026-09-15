import React from "react";
import { type CalculateMetadataFunction, Composition, Still } from "remotion";
import { Launch } from "./Launch";
import { type LaunchProps, launchPropsSchema, totalDuration } from "./schema";
import { defaultProps, FPS, HEIGHT, WIDTH } from "./defaults";

export const POSTER_FRAME = 690;

const calculateLaunchMetadata: CalculateMetadataFunction<LaunchProps> = ({
  props,
}) => ({
  durationInFrames: totalDuration(props.scenes),
});

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Launch"
        component={Launch}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={WIDTH}
        height={HEIGHT}
        fps={FPS}
        durationInFrames={totalDuration(defaultProps.scenes)}
        calculateMetadata={calculateLaunchMetadata}
      />
      <Still
        id="Poster"
        component={Launch}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={WIDTH}
        height={HEIGHT}
      />
    </>
  );
};
