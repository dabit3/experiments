import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import type { Brand, Content, LayoutSettings } from "../schema";
import { enter } from "../motion";

/** Restrained CTA: logo, outro line, one button, the URL. */
export const Outro: React.FC<{
  brand: Brand;
  content: Content;
  layout: LayoutSettings;
}> = ({ brand, content, layout }) => {
  const frame = useCurrentFrame();
  const logoIn = enter(frame, 4, 14);
  const lineIn = enter(frame, 12, 15);
  const ctaIn = enter(frame, 26, 14);

  return (
    <AbsoluteFill>
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
          alignItems: "center",
          textAlign: "center",
          color: brand.white,
        }}
      >
        <Img src={staticFile(brand.logoDark)} style={{ height: 40, opacity: logoIn }} />
        <div
          style={{
            marginTop: 48,
            fontSize: 64,
            lineHeight: "74px",
            letterSpacing: -2.3,
            fontWeight: 500,
            maxWidth: 1400,
            opacity: lineIn,
            transform: `translateY(${(1 - lineIn) * 12}px)`,
          }}
        >
          {content.outroLine}
        </div>
        <div
          style={{
            marginTop: 44,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 20,
            opacity: ctaIn,
            transform: `translateY(${(1 - ctaIn) * 8}px)`,
          }}
        >
          <div
            style={{
              background: brand.white,
              color: brand.ink,
              fontSize: 20,
              lineHeight: "24px",
              letterSpacing: -0.3,
              fontWeight: 500,
              padding: "12px 20px",
              borderRadius: 2,
            }}
          >
            {content.cta.label}
          </div>
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 16,
              lineHeight: "22px",
              color: brand.inkSubtle,
            }}
          >
            {content.cta.url}
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
