import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { ms } from "../anim";
import { bodyStyle, labelStyle, Rise } from "../components/Text";
import { color, type } from "../tokens";

export const EndCard: React.FC = () => (
  <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
    <Rise from={0}>
      <Img
        src={staticFile("brand/devin-lockup-horizontal-black.png")}
        style={{ width: 440, height: "auto", display: "block" }}
      />
    </Rise>
    <div style={{ height: 40 }} />
    <Rise from={ms(350)} style={{ ...bodyStyle(type.sizes1080p.body), color: color.ink }}>
      Build, run and test iOS apps in the cloud.
    </Rise>
    <div style={{ height: 28 }} />
    <Rise from={ms(700)} style={{ ...labelStyle, textTransform: "none" }}>
      devin.ai
    </Rise>
  </AbsoluteFill>
);
