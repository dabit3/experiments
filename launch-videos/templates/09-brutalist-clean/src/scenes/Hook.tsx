import React from "react";
import { AbsoluteFill } from "remotion";
import { Headline } from "../components/Headline";
import { Underline } from "../components/Underline";
import { space, WIDTH } from "../theme";

export const Hook: React.FC = () => (
  <AbsoluteFill>
    <div style={{ position: "absolute", left: space.margin, top: 268 }}>
      <Headline lines={["Devin now", "runs on Mac."]} size={208} stagger={6} />
      <Underline at={26} width={WIDTH - space.margin * 2} height={16} style={{ marginTop: 56 }} />
    </div>
  </AbsoluteFill>
);
