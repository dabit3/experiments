import React from "react";
import { AbsoluteFill } from "remotion";
import { Accent, Headline, Label } from "../components/Text";
import { light, MARGIN, size } from "../theme";

export const Hook: React.FC = () => (
  <AbsoluteFill style={{ background: light.bg }}>
    <div style={{ position: "absolute", left: MARGIN, top: MARGIN }}>
      <Label palette={light} at={4}>
        Devin · macOS
      </Label>
    </div>
    <div
      style={{
        position: "absolute",
        left: MARGIN,
        right: MARGIN,
        top: 0,
        bottom: 0,
        display: "flex",
        alignItems: "center",
      }}
    >
      <Headline palette={light} fontSize={size.hero} at={6} rise={40}>
        Devin now runs on <Accent>Mac.</Accent>
      </Headline>
    </div>
  </AbsoluteFill>
);
