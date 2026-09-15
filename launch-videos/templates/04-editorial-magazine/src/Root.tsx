import React from "react";
import { Composition, Sequence, Still } from "remotion";
import { defaultProps } from "./defaults";
import { calculateLaunchMetadata, Launch } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { FRAME_H, FRAME_W } from "./Scenes";

/** Frame of the cover used for the poster still (text fully entered). */
export const POSTER_FRAME = 60;

const Poster: React.FC<LaunchProps> = (props) => (
  <Sequence from={-POSTER_FRAME}>
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
      width={FRAME_W}
      height={FRAME_H}
      fps={30}
      durationInFrames={1200}
    />
    <Still
      id="Poster"
      component={Poster}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      width={FRAME_W}
      height={FRAME_H}
    />
  </>
);
