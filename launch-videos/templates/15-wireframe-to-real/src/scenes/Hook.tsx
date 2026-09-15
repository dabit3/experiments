import React from "react";
import { AbsoluteFill } from "remotion";
import { ms } from "../anim";
import { SketchText } from "../components/SketchText";
import { headlineStyle } from "../components/Text";
import { SIZE } from "../components/Layout";
import { type } from "../tokens";

export const Hook: React.FC<{ duration: number }> = ({ duration }) => (
  <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
    <SketchText
      from={ms(100)}
      resolveAt={ms(900)}
      to={duration}
      style={{ ...headlineStyle(SIZE.hero), letterSpacing: type.tracking.hero }}
      seed={11}
    >
      Devin now runs on Mac.
    </SketchText>
  </AbsoluteFill>
);
