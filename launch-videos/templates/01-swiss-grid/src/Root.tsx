import { Composition, Sequence } from "remotion";
import { Launch, totalDuration } from "./Launch";
import { FPS, HEIGHT, WIDTH, defaultProps } from "./defaults";
import { launchPropsSchema, type LaunchProps } from "./schema";

const Poster = (props: LaunchProps) => (
  <Sequence from={-props.posterFrame}>
    <Launch {...props} />
  </Sequence>
);

export const RemotionRoot = () => (
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
    <Composition
      id="Poster"
      component={Poster}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      width={WIDTH}
      height={HEIGHT}
      fps={FPS}
      durationInFrames={1}
    />
  </>
);
