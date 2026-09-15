import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { SceneFrame } from "../components/SceneFrame";
import { Glass } from "../components/Glass";
import { color, fontSans, type } from "../tokens";
import { enter } from "../lib/motion";

export const Hook: React.FC<{ sceneFrom: number }> = ({ sceneFrom }) => {
  const frame = useCurrentFrame();
  const tile = enter(frame, 0, 28);
  const text = enter(frame, 12, 28);
  const TILE = 128;
  return (
    <SceneFrame>
      <Glass
        x={(1920 - TILE) / 2}
        y={330}
        width={TILE}
        height={TILE}
        depth={1}
        sceneFrom={sceneFrom}
        opacity={tile}
        transform={`translateY(${(1 - tile) * 30}px)`}
      >
        <Img
          src={staticFile("brand/devin-mark-white.png")}
          style={{ position: "absolute", left: 28, top: 28, width: TILE - 56, height: TILE - 56 }}
        />
      </Glass>
      <div
        style={{
          position: "absolute",
          left: 120,
          top: 520,
          width: 1680,
          textAlign: "center",
          fontFamily: fontSans,
          fontWeight: type.weights.medium,
          fontSize: 96,
          lineHeight: type.leading.tight,
          letterSpacing: type.tracking.hero,
          color: color.offWhite,
          opacity: text,
          transform: `translateY(${(1 - text) * 30}px)`,
        }}
      >
        Devin now runs on Mac.
      </div>
    </SceneFrame>
  );
};
