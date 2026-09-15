import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand, Content } from "../schema";

/** Closing slate on paper: lockup, outro line, CTA. */
export const Outro: React.FC<{
  brand: Brand;
  content: Content;
  progress: number;
}> = ({ brand, content, progress }) => {
  const rise = (1 - progress) * 16;
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 40,
        opacity: progress,
        transform: `translateY(${rise}px)`,
      }}
    >
      <Img
        src={staticFile(brand.logoLight)}
        style={{ height: 104, width: "auto", display: "block" }}
      />
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 64,
          lineHeight: "74px",
          letterSpacing: -2.3,
          fontWeight: 500,
          color: brand.ink,
          textAlign: "center",
          maxWidth: 1200,
        }}
      >
        {content.outroLine}
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontSize: 20,
            lineHeight: "44px",
            height: 44,
            padding: "0 18px",
            borderRadius: 2,
            background: brand.ink,
            color: brand.white,
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
    </div>
  );
};
