import React from "react";
import { Scene } from "../components/Scene";
import { Line } from "../components/Text";
import { dur, grid, type } from "../theme";

export const Hook: React.FC<{ number: string }> = ({ number }) => (
  <Scene number={number} title="Launch">
    <div style={{ position: "absolute", left: grid.x(0), top: grid.rowMid, width: grid.span(12) }}>
      <Line size="hero" enterAt={4}>
        Devin now runs on Mac.
      </Line>
      <Line size="heading" enterAt={dur.slow} muted style={{ marginTop: type.text }}>
        It writes and tests code for Mac and iOS apps.
      </Line>
    </div>
  </Scene>
);
