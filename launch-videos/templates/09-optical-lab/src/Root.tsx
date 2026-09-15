import React from "react";
import { Composition, Still } from "remotion";
import { defaultProps } from "./defaults";
import { Launch, totalDuration } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";

export const POSTER_FRAME = 250;

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="Launch"
      component={Launch}
      width={1920}
      height={1080}
      fps={30}
      durationInFrames={totalDuration(defaultProps.scenes)}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      calculateMetadata={({ props }: { props: LaunchProps }) => ({
        durationInFrames: totalDuration(props.scenes),
      })}
    />
    <Still
      id="Poster"
      component={Launch}
      width={1920}
      height={1080}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
    />
  </>
);
