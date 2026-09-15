import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { useProgress, useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { Underline } from "../components/Ink";
import { color, ease, font, sec, type } from "../theme";

const W = 1000;

/** End card: lockup printed on the last sheet, one line, the URL. */
export const EndCard: React.FC = () => {
  const fade = useSceneFade(sec(0.4), sec(0.5));
  const logo = useProgress(sec(0.3), sec(0.7), ease.out);
  const line = useProgress(sec(0.9), sec(0.6), ease.out);
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      <Paper x={(1920 - W) / 2} y={276} width={W} rotate={-0.4} padding={64} caption="devin.ai" captionRight="macOS · native iOS">
        <div style={{ position: "relative", height: 380, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
          <Img
            src={staticFile("brand/devin-lockup-horizontal-black.png")}
            style={{ width: 440, height: "auto", opacity: logo, transform: `translateY(${(1 - logo) * 14}px)`, display: "block" }}
          />
          <div
            style={{
              marginTop: 8,
              opacity: line,
              transform: `translateY(${(1 - line) * 12}px)`,
              fontFamily: font.sans,
              fontWeight: 500,
              fontSize: type.sizes1080p.h3,
              letterSpacing: type.tracking.heading,
              lineHeight: 1.1,
              color: color.ink,
              textAlign: "center",
            }}
          >
            Build, run and test iOS apps in the cloud.
          </div>
          <Underline from={{ x: 598, y: 304 }} to={{ x: 794, y: 300 }} at={sec(1.6)} width={4} seed={21} />
        </div>
      </Paper>
    </AbsoluteFill>
  );
};
