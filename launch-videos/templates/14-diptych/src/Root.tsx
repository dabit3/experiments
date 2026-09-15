import React from "react";
import { Composition, Sequence, Still } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import { z } from "zod";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { defaultProps } from "./defaults";
import { Launch, totalDuration } from "./Launch";
import { HEIGHT, WIDTH } from "./geometry";

loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const FPS = 30;
export const POSTER_FRAME = 720;

const posterSchema = launchPropsSchema.extend({
  posterFrame: z.number().int().min(0),
});

const Poster: React.FC<z.infer<typeof posterSchema>> = ({
  posterFrame,
  ...props
}) => (
  <Sequence from={-posterFrame}>
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
      calculateMetadata={({ props }: { props: LaunchProps }) => ({
        durationInFrames: totalDuration(props.scenes),
      })}
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
