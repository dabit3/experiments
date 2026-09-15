import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import type { Brand, Content, Layout } from "../schema";
import { progress } from "../score";

type Props = { brand: Brand; content: Content; layout: Layout };

/** After the tracks have resolved into one line, the result and CTA sit above it. */
export const Outro: React.FC<Props> = ({ brand, content, layout }) => {
  const frame = useCurrentFrame();
  const lineIn = progress(frame, 56, 18);
  const ctaIn = progress(frame, 72, 16);
  const logoIn = progress(frame, 84, 14);
  const lineY = layout.stripTop + layout.stripHeight / 2;

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div
        style={{
          position: "absolute",
          left: layout.margin,
          top: lineY - 96 - 220,
          width: 1400,
          fontFamily: brand.fontFamily,
          fontWeight: 500,
          fontSize: 72,
          lineHeight: "80px",
          letterSpacing: -2.6,
          color: brand.ink,
          opacity: lineIn,
          transform: `translateY(${(1 - lineIn) * 14}px)`,
        }}
      >
        {content.outroLine}
      </div>
      <div
        style={{
          position: "absolute",
          left: layout.margin,
          top: lineY - 96,
          display: "flex",
          alignItems: "center",
          gap: 24,
          opacity: ctaIn,
          transform: `translateY(${(1 - ctaIn) * 10}px)`,
        }}
      >
        <div
          style={{
            height: 48,
            padding: "0 20px",
            display: "flex",
            alignItems: "center",
            background: brand.ink,
            color: brand.white,
            borderRadius: 2,
            fontFamily: brand.fontFamily,
            fontSize: 20,
            letterSpacing: -0.3,
          }}
        >
          {content.cta.label}
        </div>
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 18,
            color: brand.inkMuted,
          }}
        >
          {content.cta.url}
        </div>
      </div>
      <Img
        src={staticFile(brand.logoLight)}
        style={{
          position: "absolute",
          left: layout.margin,
          top: lineY + 28,
          height: 30,
          opacity: logoIn,
        }}
      />
    </div>
  );
};
