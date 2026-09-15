import React from "react";
import { useCurrentFrame } from "remotion";
import type { Brand, Content, Layout } from "../schema";
import { progress } from "../score";

type Props = { brand: Brand; content: Content; layout: Layout; durationInFrames: number };

const AccentedHeadline: React.FC<{ text: string; accent: string; color: string }> = ({
  text,
  accent,
  color,
}) => {
  const i = accent ? text.indexOf(accent) : -1;
  if (i < 0) return <>{text}</>;
  return (
    <>
      {text.slice(0, i)}
      <span style={{ color }}>{accent}</span>
      {text.slice(i + accent.length)}
    </>
  );
};

export const Intro: React.FC<Props> = ({ brand, content, layout, durationInFrames }) => {
  const frame = useCurrentFrame();
  const eyebrowIn = progress(frame, 6, 12);
  const headIn = progress(frame, 14, 16);
  const subIn = progress(frame, 30, 16);
  const out = 1 - progress(frame, durationInFrames - 14, 14);

  return (
    <div
      style={{
        position: "absolute",
        left: layout.margin,
        top: layout.mediaTop + 150,
        width: 1200,
        opacity: out,
      }}
    >
      <div
        style={{
          display: "inline-block",
          fontFamily: brand.monoFontFamily,
          fontSize: 14,
          lineHeight: "20px",
          letterSpacing: 0.4,
          textTransform: "uppercase",
          color: brand.white,
          background: brand.ink,
          borderRadius: 8,
          padding: "3px 10px",
          opacity: eyebrowIn,
        }}
      >
        {content.eyebrow}
      </div>
      <div
        style={{
          marginTop: 28,
          fontFamily: brand.fontFamily,
          fontWeight: 500,
          fontSize: 88,
          lineHeight: "92px",
          letterSpacing: -3.2,
          color: brand.ink,
          opacity: headIn,
          transform: `translateY(${(1 - headIn) * 14}px)`,
        }}
      >
        <AccentedHeadline
          text={content.headline}
          accent={content.headlineAccent}
          color={brand.accent}
        />
      </div>
      <div
        style={{
          marginTop: 28,
          maxWidth: 980,
          fontFamily: brand.fontFamily,
          fontSize: 27,
          lineHeight: "36px",
          letterSpacing: -0.4,
          color: brand.inkMuted,
          opacity: subIn,
          transform: `translateY(${(1 - subIn) * 10}px)`,
        }}
      >
        {content.subhead}
      </div>
    </div>
  );
};
