import React from "react";
import { AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { TerminalWindow } from "../components/TerminalWindow";
import { Blank, OutputLine, TypedCommand } from "../components/Prompt";
import { color, easeOut, font, type } from "../tokens";
import { typeFrames } from "../scenes";

export const HOOK_COMMAND = "devin --platform macos";

/** The real Devin CLI splash (ASCII mark, version, plan line) cropped out of devin-cli-3.png. */
const SPLASH = { srcW: 3130, x: 116, y: 190, w: 1200, h: 280, scale: 0.6 };

const Splash: React.FC = () => (
  <div
    style={{
      width: SPLASH.w * SPLASH.scale,
      height: SPLASH.h * SPLASH.scale,
      overflow: "hidden",
      position: "relative",
    }}
  >
    <Img
      src={staticFile("screens/devin-cli-3.png")}
      style={{
        position: "absolute",
        width: SPLASH.srcW * SPLASH.scale,
        left: -SPLASH.x * SPLASH.scale,
        top: -SPLASH.y * SPLASH.scale,
      }}
    />
  </div>
);

export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const enter = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeOut),
  });
  const typeAt = 18;
  const submitAt = typeAt + typeFrames(HOOK_COMMAND) + 12;
  const headlineAt = submitAt + 18;
  const headline = interpolate(frame, [headlineAt, headlineAt + 18], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeOut),
  });

  return (
    <AbsoluteFill>
      <TerminalWindow opacity={enter} scale={0.985 + 0.015 * enter}>
        <Splash />
        <Blank h={24} />
        <TypedCommand text={HOOK_COMMAND} at={typeAt} submitAt={submitAt} />
        <OutputLine at={submitAt + 4} prefix="✓" tone="text" prefixTone="ok">
          macOS session started
        </OutputLine>
        <Blank h={36} />
        <div
          style={{
            fontFamily: font.sans,
            fontWeight: type.weights.medium,
            fontSize: type.sizes1080p.h2,
            letterSpacing: type.tracking.heading,
            lineHeight: type.leading.heading,
            color: color.paper,
            opacity: headline,
          }}
        >
          Devin now runs in a Mac VM.
        </div>
      </TerminalWindow>
    </AbsoluteFill>
  );
};
