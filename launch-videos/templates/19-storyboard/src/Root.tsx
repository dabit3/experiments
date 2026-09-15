import React from "react";
import { Composition } from "remotion";
import { Launch } from "./Launch";
import { launchPropsSchema } from "./schema";
import { FPS, HEIGHT, WIDTH, defaultProps } from "./defaults";
import { totalDuration } from "./timeline";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="Launch"
      component={Launch}
      width={WIDTH}
      height={HEIGHT}
      fps={FPS}
      durationInFrames={totalDuration(defaultProps.scenes)}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      calculateMetadata={({ props }) => ({
        durationInFrames: totalDuration(props.scenes),
      })}
    />
  );
};
