import React from "react";
import { Composition, Sequence, Still } from "remotion";
import { defaultProps, FPS, HEIGHT, POSTER_FRAME, WIDTH } from "./defaults";
import { Launch, totalDuration } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";

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
        width={WIDTH}
        height={HEIGHT}
        fps={FPS}
        durationInFrames={totalDuration(defaultProps.scenes)}
        calculateMetadata={({ props }: { props: LaunchProps }) => ({
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
};
