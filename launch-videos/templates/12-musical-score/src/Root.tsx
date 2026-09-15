import React from "react";
import { Composition } from "remotion";
import { Launch } from "./Launch";
import { launchPropsSchema } from "./schema";
import { defaultProps, FPS } from "./defaultProps";
import { totalDuration } from "./score";

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
        fps={FPS}
        durationInFrames={totalDuration(defaultProps.scenes)}
        calculateMetadata={({ props }) => ({
          durationInFrames: totalDuration(props.scenes),
        })}
      />
    </>
  );
};
