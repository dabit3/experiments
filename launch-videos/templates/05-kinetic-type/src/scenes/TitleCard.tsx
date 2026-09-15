import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { Brand, Content, TitleScene, Typography } from "../schema";
import { enter, leave, mix } from "../motion";
import { Label } from "../components/Label";
import { WIDTH } from "../defaults";

const Headline: React.FC<{
  text: string;
  accentWord: string;
  brand: Brand;
  size: number;
}> = ({ text, accentWord, brand, size }) => {
  const i = accentWord ? text.indexOf(accentWord) : -1;
  const parts =
    i < 0
      ? [text]
      : [text.slice(0, i), accentWord, text.slice(i + accentWord.length)];
  return (
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontSize: size,
        lineHeight: 1.02,
        letterSpacing: "-0.035em",
        fontWeight: 500,
        color: brand.ink,
        textAlign: "center",
        textWrap: "balance",
      }}
    >
      {parts.map((p, idx) => (
        <span key={idx} style={{ color: idx === 1 ? brand.accent : undefined }}>
          {p}
        </span>
      ))}
    </div>
  );
};

/**
 * Opening title: eyebrow, headline with one accent word, subhead. Three
 * complete phrases, entering as units with a short stagger, then rising out.
 */
export const TitleCard: React.FC<{
  scene: TitleScene;
  brand: Brand;
  content: Content;
  typography: Typography;
}> = ({ scene, brand, content, typography }) => {
  const frame = useCurrentFrame();
  const out = leave(frame, scene.durationInFrames - 20, 18);
  const rise = mix(0, -48, 1 - out);

  const eyebrow = enter(frame, 0, 14);
  const headline = enter(frame, 6, 18);
  const subhead = enter(frame, 20, 18);

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <div
        style={{
          position: "absolute",
          left: typography.margin,
          right: typography.margin,
          top: 0,
          bottom: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 32,
          transform: `translateY(${rise}px)`,
          opacity: out,
        }}
      >
        <Label
          inline
          text={content.eyebrow}
          x={0}
          y={0}
          color={brand.accent}
          fontFamily={brand.monoFontFamily}
          opacity={eyebrow}
          offsetY={mix(16, 0, eyebrow)}
        />
        <div
          style={{
            maxWidth: WIDTH * 0.72,
            opacity: headline,
            transform: `translateY(${mix(28, 0, headline)}px)`,
          }}
        >
          <Headline
            text={content.headline}
            accentWord={content.accentWord}
            brand={brand}
            size={typography.displaySize}
          />
        </div>
        <div
          style={{
            maxWidth: 980,
            fontFamily: brand.fontFamily,
            fontSize: 27,
            lineHeight: 1.35,
            letterSpacing: "-0.012em",
            color: brand.inkMuted,
            textAlign: "center",
            textWrap: "balance",
            opacity: subhead,
            transform: `translateY(${mix(20, 0, subhead)}px)`,
          }}
        >
          {content.subhead}
        </div>
      </div>
    </AbsoluteFill>
  );
};
