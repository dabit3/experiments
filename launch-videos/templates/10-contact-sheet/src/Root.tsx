import React from "react";
import { Composition, Freeze, Still } from "remotion";
import type { LaunchProps } from "./schema";
import { Launch, totalDuration } from "./Launch";
import { launchPropsSchema } from "./schema";
import { defaultProps, FPS, HEIGHT, WIDTH } from "./defaults";
import "./fonts";

/** Hero frame used for out/poster.png (mid-outro, final artifact enlarged). Keep in sync with the `still` script. */
export const POSTER_FRAME = 1290;

const Poster: React.FC<LaunchProps> = (props) => (
  <Freeze frame={POSTER_FRAME}>
    <Launch {...props} />
  </Freeze>
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
        durationInFrames={totalDuration(defaultProps)}
        calculateMetadata={({ props }) => ({ durationInFrames: totalDuration(props) })}
      />
      <Still id="Poster" component={Poster} schema={launchPropsSchema} defaultProps={defaultProps} width={WIDTH} height={HEIGHT} />
    </>
  );
};
