import React from "react";
import { Composition, Sequence } from "remotion";
import { Launch } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { FPS, FRAME_HEIGHT, FRAME_WIDTH, defaultProps, totalDuration } from "./defaults";

/** Frame used for `npm run still` and the Poster composition. */
export const POSTER_FRAME = 270;

const Poster: React.FC<LaunchProps> = (props) => (
  <Sequence from={-POSTER_FRAME} layout="none">
    <Launch {...props} />
  </Sequence>
);

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Launch"
        component={Launch}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={FRAME_WIDTH}
        height={FRAME_HEIGHT}
        fps={FPS}
        durationInFrames={totalDuration(defaultProps.scenes)}
        calculateMetadata={({ props }: { props: LaunchProps }) => ({
          durationInFrames: totalDuration(props.scenes),
        })}
      />
      <Composition
        id="Poster"
        component={Poster}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={FRAME_WIDTH}
        height={FRAME_HEIGHT}
        fps={FPS}
        durationInFrames={1}
      />
    </>
  );
};
