import React from "react";
import { Composition, Sequence, Still } from "remotion";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { defaultProps } from "./defaults";
import { Launch, calculateLaunchMetadata } from "./Launch";

// Poster = the Launch composition frozen at props.posterFrame.
const Poster: React.FC<LaunchProps> = (props) => (
  <Sequence from={-props.posterFrame} layout="none">
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
      calculateMetadata={calculateLaunchMetadata}
      width={1920}
      height={1080}
      fps={30}
      durationInFrames={1350}
    />
    <Still
      id="Poster"
      component={Poster}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      width={1920}
      height={1080}
    />
  </>
);
