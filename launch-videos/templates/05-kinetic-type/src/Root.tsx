import React from "react";
import { Composition, Sequence, Still } from "remotion";
import { Launch, totalDuration } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { defaultProps, FPS, HEIGHT, HERO_FRAME, WIDTH } from "./defaults";

/** The hero frame of the film, rendered as a still. */
const Poster: React.FC<LaunchProps> = (props) => (
  <Sequence from={-HERO_FRAME} layout="none">
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
      width={WIDTH}
      height={HEIGHT}
      fps={FPS}
      durationInFrames={totalDuration(defaultProps.scenes)}
      calculateMetadata={({ props }) => ({
        durationInFrames: totalDuration(props.scenes),
      })}
    />
    <Still
      id="Poster"
      component={Poster}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      width={WIDTH}
      height={HEIGHT}
    />
  </>
);
