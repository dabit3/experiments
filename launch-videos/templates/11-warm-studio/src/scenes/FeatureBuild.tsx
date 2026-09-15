import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { Cursor } from "../components/Cursor";
import { FIGURE_WIDTH, FeatureLayout } from "../components/FeatureLayout";
import { ASPECT, Figure } from "../components/Figure";
import { crossfade, fadeIn } from "../components/motion";
import { SANS } from "../fonts";
import { color, dur, easeInOut, ms, type } from "../tokens";

const PROMPT = "Build a native iOS chat client and test it in the Simulator";

const typingStart = ms(700);
const typingFrames = ms(2400);
const pickerAt = ms(4200);
const cursorAt = ms(4800);
const cursorMoveAt = ms(5200);

/** Type into the real prompt box: covers the placeholder, then types over it. */
const TypedPrompt: React.FC<{ frame: number }> = ({ frame }) => {
  const chars = Math.round(
    interpolate(frame, [typingStart, typingStart + typingFrames], [0, PROMPT.length], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }),
  );
  const typing = frame >= typingStart && chars < PROMPT.length;
  const caretOn = typing || Math.floor(frame / 16) % 2 === 0;
  const fontSize = FIGURE_WIDTH * 0.01215;
  return (
    <div
      style={{
        position: "absolute",
        left: "22.3%",
        top: "39.6%",
        width: "55%",
        height: "5%",
        background: color.white,
        display: "flex",
        alignItems: "center",
        opacity: frame >= typingStart ? 1 : 0,
      }}
    >
      <span
        style={{
          fontFamily: SANS,
          fontWeight: type.weights.regular,
          fontSize,
          letterSpacing: type.tracking.body,
          color: color.ink,
          whiteSpace: "pre",
          paddingLeft: "0.9%",
        }}
      >
        {PROMPT.slice(0, chars)}
      </span>
      <span
        style={{
          width: 2,
          height: fontSize * 1.15,
          marginLeft: 2,
          background: color.ink,
          opacity: caretOn ? 1 : 0,
        }}
      />
    </div>
  );
};

export const FeatureBuild: React.FC = () => {
  const frame = useCurrentFrame();
  const toPicker = crossfade(frame, pickerAt);
  const cursorX = interpolate(frame, [cursorMoveAt, cursorMoveAt + dur.slow], [40, 26.9], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  const cursorY = interpolate(frame, [cursorMoveAt, cursorMoveAt + dur.slow], [58, 73.3], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  return (
    <FeatureLayout
      index="01"
      label="Build and run"
      beats={[
        { at: 4, text: "You describe the feature." },
        {
          at: pickerAt,
          text: (
            <>
              Pick macOS. Devin builds it in Xcode
              <br />
              and runs it in the iOS Simulator.
            </>
          ),
        },
      ]}
    >
      <Figure
        width={FIGURE_WIDTH}
        aspect={ASPECT.web}
        y={-200}
        layers={[
          { src: "screens/devin-web-1.png" },
          { src: "screens/devin-web-4.png", opacity: toPicker },
        ]}
      >
        <TypedPrompt frame={frame} />
        <Cursor x={cursorX} y={cursorY} opacity={fadeIn(frame, cursorAt, dur.base)} />
      </Figure>
    </FeatureLayout>
  );
};
