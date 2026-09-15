import React from "react";
import { Composition, Still, staticFile, type CalculateMetadataFunction } from "remotion";
import "./fonts";
import { Launch, totalDuration } from "./Launch";
import { launchPropsSchema, type LaunchProps } from "./schema";
import { defaultProps } from "./defaults";

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

/** Frame used for the poster still (`npm run still`): the Xcode/build scene fully revealed. */
export const POSTER_FRAME = 480;

// Optional licensed brand typeface: drop NBInternationalPro-Regular.woff2 and
// NBInternationalPro-Medium.woff2 into launch-videos/assets/fonts/ and they are
// used automatically because brand.fontFamily lists the family first.
const brandFontFace = `
@font-face { font-family: "NB International Pro"; font-weight: 400; src: url("${staticFile(
  "fonts/NBInternationalPro-Regular.woff2",
)}") format("woff2"); }
@font-face { font-family: "NB International Pro"; font-weight: 500; src: url("${staticFile(
  "fonts/NBInternationalPro-Medium.woff2",
)}") format("woff2"); }
`;

const calculateMetadata: CalculateMetadataFunction<LaunchProps> = ({ props }) => ({
  durationInFrames: totalDuration(props.scenes),
});

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <style>{brandFontFace}</style>
      <Composition
        id="Launch"
        component={Launch}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={WIDTH}
        height={HEIGHT}
        fps={FPS}
        durationInFrames={totalDuration(defaultProps.scenes)}
        calculateMetadata={calculateMetadata}
      />
      <Still
        id="Poster"
        component={Launch}
        schema={launchPropsSchema}
        defaultProps={defaultProps}
        width={WIDTH}
        height={HEIGHT}
      />
    </>
  );
};
