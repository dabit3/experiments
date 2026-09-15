import React from "react";
import { Composition, Sequence, Still } from "remotion";
import { z } from "zod";
import { Launch, totalDuration } from "./Launch";
import { launchPropsSchema } from "./schema";
import { defaultProps } from "./defaults";
import { HEIGHT, WIDTH } from "./geometry";

export const POSTER_FRAME = 903;

const posterSchema = launchPropsSchema.extend({ posterFrame: z.number().int().min(0) });

const Poster: React.FC<z.infer<typeof posterSchema>> = ({ posterFrame, ...props }) => (
  <Sequence from={-posterFrame}>
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
        fps={30}
        durationInFrames={totalDuration(defaultProps)}
        calculateMetadata={({ props }) => ({ durationInFrames: totalDuration(props) })}
      />
      <Still
        id="Poster"
        component={Poster}
        schema={posterSchema}
        defaultProps={{ ...defaultProps, posterFrame: POSTER_FRAME }}
        width={WIDTH}
        height={HEIGHT}
      />
    </>
  );
};
