import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { Brand, Content } from "../schema";
import { Headline } from "../components/Headline";
import { Logo } from "../components/Logo";
import { enter } from "../motion";
import { type } from "../layout";

type Props = { brand: Brand; content: Content; enterFrames: number };

/** Opening title treatment: eyebrow chip, headline with one accent phrase, subhead. */
export const TitleScene: React.FC<Props> = ({ brand, content, enterFrames }) => {
  const frame = useCurrentFrame();
  const m = brand.safeMargin;
  const rise = (from: number): React.CSSProperties => {
    const p = enter(frame, from, enterFrames * 2);
    return { opacity: p, transform: `translateY(${(1 - p) * 24}px)` };
  };
  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <Logo
        brand={brand}
        on="light"
        height={40}
        style={{ position: "absolute", left: m, top: m, ...rise(0) }}
      />
      <div
        style={{
          position: "absolute",
          left: m,
          right: m,
          top: 360,
          display: "flex",
          flexDirection: "column",
          gap: 28,
        }}
      >
        <div style={{ display: "flex", ...rise(4) }}>
          <span
            style={{
              ...type.eyebrow,
              fontFamily: brand.fontFamily,
              color: brand.ink,
              border: `1px solid ${brand.ink}`,
              borderRadius: 9999,
              padding: "6px 14px",
            }}
          >
            {content.eyebrow}
          </span>
          <span
            style={{
              ...type.eyebrow,
              fontFamily: brand.fontFamily,
              color: brand.inkMuted,
              padding: "7px 16px",
            }}
          >
            {content.featureName}
          </span>
        </div>
        <Headline
          brand={brand}
          text={content.headline}
          accent={content.headlineAccent}
          color={brand.ink}
          style={{ ...type.display, maxWidth: 1400, ...rise(10) }}
        />
        <div
          style={{
            ...type.h5,
            fontFamily: brand.fontFamily,
            color: brand.inkMuted,
            maxWidth: 1040,
            ...rise(18),
          }}
        >
          {content.subhead}
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          left: m,
          right: m,
          bottom: m,
          height: 1,
          background: brand.line,
          transform: `scaleX(${enter(frame, 12, enterFrames * 3)})`,
          transformOrigin: "left",
        }}
      />
    </AbsoluteFill>
  );
};
