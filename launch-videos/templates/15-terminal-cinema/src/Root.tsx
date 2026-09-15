import React from "react";
import { CalculateMetadataFunction, Composition, Sequence, Still, staticFile } from "remotion";
import { getImageDimensions, getVideoMetadata } from "@remotion/media-utils";
import { launchPropsSchema, type LaunchProps, type MediaSlot } from "./schema";
import { defaultProps, FPS, HEIGHT, WIDTH } from "./defaults";
import { Launch, totalDuration } from "./Launch";
import "./fonts";

export const POSTER_FRAME = 720;

const resolveAspect = async (slot: MediaSlot): Promise<MediaSlot> => {
  if (slot.sourceAspect) {
    return slot;
  }
  const src = staticFile(slot.src);
  if (slot.kind === "video") {
    const meta = await getVideoMetadata(src);
    return { ...slot, sourceAspect: meta.width / meta.height };
  }
  const dims = await getImageDimensions(src);
  return { ...slot, sourceAspect: dims.width / dims.height };
};

const resolveMedia = async (props: LaunchProps): Promise<LaunchProps> => {
  const entries = await Promise.all(
    Object.entries(props.media).map(async ([key, slot]) => [key, await resolveAspect(slot)] as const),
  );
  return { ...props, media: Object.fromEntries(entries) };
};

const calculateMetadata: CalculateMetadataFunction<LaunchProps> = async ({ props }) => {
  return {
    durationInFrames: totalDuration(props),
    props: await resolveMedia(props),
  };
};

const calculateStillMetadata: CalculateMetadataFunction<LaunchProps> = async ({ props }) => {
  return { props: await resolveMedia(props) };
};

const PosterFrame: React.FC<LaunchProps> = (props) => (
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
        calculateMetadata={calculateMetadata}
        width={WIDTH}
        height={HEIGHT}
        fps={FPS}
        durationInFrames={totalDuration(defaultProps)}
      />
      <Still
        id="Poster"
        component={PosterFrame}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        calculateMetadata={calculateStillMetadata}
        width={WIDTH}
        height={HEIGHT}
      />
    </>
  );
};
