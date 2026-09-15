import React from "react";
import { AbsoluteFill, Img, interpolateColors, staticFile, useCurrentFrame } from "remotion";
import type { Brand, Content, EndScene, Typography } from "../schema";
import { enter, mix, move } from "../motion";
import { Phrase } from "../components/Phrase";
import { estimateLines, LINE_HEIGHT } from "../layout";
import { HEIGHT, WIDTH } from "../defaults";

/**
 * Closing: the outcome line stands alone on black, then lifts and shrinks into
 * a kicker above the feature-name lockup (logo + feature name + CTA).
 */
export const EndCard: React.FC<{
  scene: EndScene;
  brand: Brand;
  content: Content;
  typography: Typography;
}> = ({ scene, brand, content, typography }) => {
  const frame = useCurrentFrame();

  const bg = interpolateColors(frame, [0, 14], [brand.paper, brand.black]);

  // Outro line: laid out at kicker size, shown scaled up while it stands alone.
  const kickerSize = 28;
  const outroSize = Math.min(typography.phraseSize + 8, 72);
  const scale = outroSize / kickerSize;
  const kickerWidth = Math.min(1400 / scale, 720);
  const lines = estimateLines(content.outroLine, kickerSize, kickerWidth);
  const blockH = lines * kickerSize * LINE_HEIGHT;

  const lockupTop = HEIGHT / 2 - 40;
  const alone = {
    x: (WIDTH - kickerWidth * scale) / 2,
    y: (HEIGHT - blockH * scale) / 2,
    scale,
  };
  const settled = { x: (WIDTH - kickerWidth) / 2, y: lockupTop - 72 - blockH, scale: 1 };

  // The lockup always gets the last >= 3s; the outro line takes whatever is left.
  const shiftStart = Math.max(40, Math.min(70, scene.durationInFrames - 110));
  const outroIn = enter(frame, 8, 16);
  const shift = move(frame, shiftStart, 22);
  const lockupIn = enter(frame, shiftStart + 14, 18);
  const ctaIn = enter(frame, shiftStart + 30, 16);

  const kickerColor = interpolateColors(shift, [0, 1], [brand.white, brand.inkSubtle]);

  return (
    <AbsoluteFill style={{ backgroundColor: bg }}>
      <Phrase
        text={content.outroLine}
        width={kickerWidth}
        fontSize={kickerSize}
        fontFamily={brand.fontFamily}
        color={kickerColor}
        from={alone}
        to={settled}
        progress={shift}
        opacity={outroIn}
        offsetY={mix(28, 0, outroIn)}
        align="center"
      />

      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: lockupTop,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 28,
          opacity: lockupIn,
          transform: `translateY(${mix(24, 0, lockupIn)}px)`,
        }}
      >
        <Img src={staticFile(brand.logoDark)} style={{ height: 44 }} />
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontSize: typography.displaySize + 12,
            lineHeight: 1,
            letterSpacing: "-0.035em",
            fontWeight: 500,
            color: brand.white,
            textAlign: "center",
            maxWidth: WIDTH - 2 * typography.margin,
          }}
        >
          {content.featureName}
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: lockupTop + 44 + 28 + typography.displaySize + 12 + 56,
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          gap: 20,
          opacity: ctaIn,
          transform: `translateY(${mix(16, 0, ctaIn)}px)`,
        }}
      >
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontSize: 22,
            fontWeight: 500,
            color: brand.ink,
            background: brand.white,
            borderRadius: 2,
            padding: "0 22px",
            height: 52,
            display: "flex",
            alignItems: "center",
          }}
        >
          {content.cta.label}
        </div>
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 20,
            color: brand.inkSubtle,
          }}
        >
          {content.cta.url}
        </div>
      </div>
    </AbsoluteFill>
  );
};
