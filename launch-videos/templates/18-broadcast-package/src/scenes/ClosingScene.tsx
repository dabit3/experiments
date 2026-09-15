import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { Brand, Content } from "../schema";
import { Logo } from "../components/Logo";
import { enter } from "../motion";
import { type } from "../layout";

type Props = { brand: Brand; content: Content; enterFrames: number };

/** Simple closing slate: lockup, outro line, CTA button and URL. */
export const ClosingScene: React.FC<Props> = ({ brand, content, enterFrames }) => {
  const frame = useCurrentFrame();
  const m = brand.safeMargin;
  const rise = (from: number): React.CSSProperties => {
    const p = enter(frame, from, enterFrames * 2);
    return { opacity: p, transform: `translateY(${(1 - p) * 20}px)` };
  };
  return (
    <AbsoluteFill style={{ background: brand.black }}>
      <div
        style={{
          position: "absolute",
          left: m,
          right: m,
          top: 0,
          bottom: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          gap: 40,
          textAlign: "center",
        }}
      >
        <Logo brand={brand} on="dark" height={56} style={rise(4)} />
        <div
          style={{
            ...type.h2,
            fontFamily: brand.fontFamily,
            color: brand.white,
            maxWidth: 1200,
            ...rise(12),
          }}
        >
          {content.outroLine}
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 24,
            marginTop: 8,
            ...rise(22),
          }}
        >
          <div
            style={{
              background: brand.white,
              color: brand.ink,
              borderRadius: 2,
              padding: "0 20px",
              height: 48,
              display: "flex",
              alignItems: "center",
              fontFamily: brand.fontFamily,
              fontSize: 22,
              letterSpacing: -0.3,
              fontWeight: 500,
            }}
          >
            {content.cta.label}
          </div>
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              color: brand.inkSubtle,
              ...type.body,
            }}
          >
            {content.cta.url}
          </div>
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          left: m,
          bottom: m,
          ...type.eyebrow,
          fontFamily: brand.fontFamily,
          color: brand.inkSubtle,
          opacity: enter(frame, 24, enterFrames),
        }}
      >
        {content.featureName}
      </div>
    </AbsoluteFill>
  );
};
