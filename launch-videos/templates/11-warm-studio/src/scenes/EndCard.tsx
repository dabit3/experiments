import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { Scene } from "../components/Scene";
import { Body, Label } from "../components/Text";
import { fadeIn, rise } from "../components/motion";
import { color, ms } from "../tokens";

export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const lineAt = ms(900);
  const urlAt = ms(1500);
  return (
    <Scene>
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
          <Img
            src={staticFile("brand/devin-lockup-horizontal-black.png")}
            style={{
              width: 560,
              height: Math.round((560 * 1024) / 2984),
              display: "block",
              opacity: fadeIn(frame, 4),
              transform: `translateY(${rise(frame, 4, undefined, 20)}px)`,
            }}
          />
          <Body
            style={{
              color: color.ink,
              marginTop: 8,
              opacity: fadeIn(frame, lineAt),
              transform: `translateY(${rise(frame, lineAt, undefined, 16)}px)`,
            }}
          >
            Build, run and test iOS apps in the cloud.
          </Body>
          <Label
            style={{
              marginTop: 48,
              opacity: fadeIn(frame, urlAt),
              transform: `translateY(${rise(frame, urlAt, undefined, 12)}px)`,
            }}
          >
            devin.ai
          </Label>
        </div>
      </AbsoluteFill>
    </Scene>
  );
};
