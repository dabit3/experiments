import React from "react";
import { AbsoluteFill } from "remotion";
import { useProgress, useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { Underline } from "../components/Ink";
import { color, ease, font, sec, type } from "../theme";

const W = 1440;

/** Hook: one printed line, the reviewer underlines "Mac". */
export const Hook: React.FC = () => {
  const fade = useSceneFade();
  const text = useProgress(sec(0.35), sec(0.6), ease.out);
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      <Paper x={(1920 - W) / 2} y={318} width={W} rotate={-0.6} padding={72} caption="Devin · launch review" captionRight="macOS · native iOS">
        <div style={{ position: "relative", height: 300 }}>
          <div
            style={{
              position: "absolute",
              left: 0,
              top: 72,
              opacity: text,
              transform: `translateY(${(1 - text) * 16}px)`,
              fontFamily: font.sans,
              fontWeight: 500,
              fontSize: type.sizes1080p.hero,
              letterSpacing: type.tracking.hero,
              lineHeight: type.leading.tight,
              color: color.ink,
              whiteSpace: "nowrap",
            }}
          >
            Devin now runs on Mac.
          </div>
          {/* underline sits beneath "Mac." — measured against Inter Medium 112px */}
          <Underline from={{ x: 940, y: 196 }} to={{ x: 1200, y: 192 }} at={sec(1.1)} width={5} seed={11} />
        </div>
      </Paper>
    </AbsoluteFill>
  );
};
