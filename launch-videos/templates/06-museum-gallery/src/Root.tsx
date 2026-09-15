import React from "react";
import { Composition } from "remotion";
import { Launch, totalDuration } from "./Launch";
import { FPS, HEIGHT, WIDTH, defaultProps } from "./defaults";
import { launchPropsSchema } from "./schema";

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
        calculateMetadata={({ props }) => ({
          durationInFrames: totalDuration(props.scenes),
        })}
      />
    </>
  );
};
