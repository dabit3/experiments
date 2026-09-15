import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import type { Brand, Content, LayoutSettings, StatementScene } from "../schema";
import { enter, exit } from "../motion";

export const AccentHeadline: React.FC<{
  text: string;
  accentWord: string;
  accent: string;
}> = ({ text, accentWord, accent }) => {
  if (!accentWord || !text.includes(accentWord)) {
    return <>{text}</>;
  }
  const [before, after] = text.split(accentWord);
  return (
    <>
      {before}
      <span style={{ color: accent }}>{accentWord}</span>
      {after}
    </>
  );
};

/** Opening feature statement in a mostly empty frame. */
export const Statement: React.FC<{
  scene: StatementScene;
  brand: Brand;
  content: Content;
  layout: LayoutSettings;
}> = ({ scene, brand, content, layout }) => {
  const frame = useCurrentFrame();
  const out = exit(frame, scene.durationInFrames, 10);

  const eyebrowIn = enter(frame, 6, 12);
  const headlineIn = enter(frame, 14, 15);
  const subheadIn = enter(frame, 42, 15);
  const logoIn = enter(frame, 20, 15);

  const eyebrow = scene.eyebrow ?? content.eyebrow;
  const headline = scene.headline ?? content.headline;
  const subhead = scene.subhead ?? content.subhead;

  return (
    <AbsoluteFill style={{ opacity: out }}>
      <div
        style={{
          position: "absolute",
          left: layout.safeMargin,
          right: layout.safeMargin,
          top: 0,
          bottom: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          color: brand.white,
        }}
      >
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 14,
            lineHeight: "20px",
            letterSpacing: 1.4,
            textTransform: "uppercase",
            color: brand.inkSubtle,
            opacity: eyebrowIn,
            display: "flex",
            alignItems: "center",
            gap: 12,
          }}
        >
          <span style={{ width: 24, height: 1, background: brand.accent, display: "inline-block" }} />
          {eyebrow}
          <span style={{ color: brand.inkMuted }}>·</span>
          {content.featureName}
        </div>
        <div
          style={{
            marginTop: 28,
            fontSize: 88,
            lineHeight: "92px",
            letterSpacing: -3.2,
            fontWeight: 500,
            maxWidth: 1200,
            opacity: headlineIn,
            transform: `translateY(${(1 - headlineIn) * 14}px)`,
          }}
        >
          <AccentHeadline text={headline} accentWord={content.headlineAccentWord} accent={brand.accent} />
        </div>
        <div
          style={{
            marginTop: 28,
            fontSize: 26,
            lineHeight: "36px",
            letterSpacing: -0.4,
            fontWeight: 400,
            color: brand.inkSubtle,
            maxWidth: 900,
            opacity: subheadIn,
            transform: `translateY(${(1 - subheadIn) * 10}px)`,
          }}
        >
          {subhead}
        </div>
      </div>
      {scene.showLogo ? (
        <Img
          src={staticFile(brand.logoDark)}
          style={{
            position: "absolute",
            left: layout.safeMargin,
            bottom: layout.safeMargin - 8,
            height: 30,
            opacity: logoIn,
          }}
        />
      ) : null}
    </AbsoluteFill>
  );
};
