import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { Brand, Content } from "../schema";
import { enter } from "../motion";
import { type } from "../layout";

type Props = {
  brand: Brand;
  content: Content;
  index: number;
  title: string;
  enterFrames: number;
};

/** Typographic segment sting on the dark surface: number, rule, segment title. */
export const ChapterScene: React.FC<Props> = ({
  brand,
  content,
  index,
  title,
  enterFrames,
}) => {
  const frame = useCurrentFrame();
  const m = brand.safeMargin;
  const p1 = enter(frame, 4, enterFrames);
  const p2 = enter(frame, 8, enterFrames);
  return (
    <AbsoluteFill style={{ background: brand.black }}>
      <div
        style={{
          position: "absolute",
          left: m,
          top: m,
          ...type.eyebrow,
          fontFamily: brand.fontFamily,
          color: brand.inkSubtle,
          opacity: p1,
        }}
      >
        {content.featureName}
      </div>
      <div
        style={{
          position: "absolute",
          left: m,
          top: 420,
          display: "flex",
          alignItems: "center",
          gap: 40,
        }}
      >
        <div
          style={{
            ...type.h2,
            fontFamily: brand.monoFontFamily,
            color: brand.white,
            opacity: p1,
            transform: `translateY(${(1 - p1) * 18}px)`,
          }}
        >
          {index.toString().padStart(2, "0")}
        </div>
        <div
          style={{
            width: 2,
            height: 72,
            background: brand.accent,
            transform: `scaleY(${p1})`,
          }}
        />
        <div
          style={{
            ...type.h2,
            fontFamily: brand.fontFamily,
            color: brand.white,
            opacity: p2,
            clipPath: `inset(0 ${(1 - p2) * 100}% 0 0)`,
          }}
        >
          {title}
        </div>
      </div>
    </AbsoluteFill>
  );
};
