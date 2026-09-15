import React from "react";
import { Composition, Still, type CalculateMetadataFunction } from "remotion";
import { Launch, totalDuration } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { defaultProps } from "./defaults";

/** Frame used for the poster still: the Run & test stage with its leader line drawn. */
export const POSTER_FRAME = 790;

const calculateMetadata: CalculateMetadataFunction<LaunchProps> = ({ props }) => ({
  durationInFrames: totalDuration(props),
});

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Launch"
        component={Launch}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={1920}
        height={1080}
        fps={30}
        durationInFrames={totalDuration(defaultProps)}
        calculateMetadata={calculateMetadata}
      />
      <Still
        id="Poster"
        component={Launch}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={1920}
        height={1080}
      />
    </>
  );
};
